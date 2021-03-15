# Crane Operator
Crane Operator (mig-operator) installs a system of migration components for moving workloads from OpenShift 3 to 4.

| Installable Component | Repository |
|---|---|
| Velero + Custom Migration Plugins | [velero](https://github.com/konveyor/velero), [openshift-migration-plugin](https://github.com/konveyor/openshift-velero-plugin)|
| Migration Controller | [mig-controller](https://github.com/konveyor/mig-controller) |
| Migration UI | [mig-ui](https://github.com/konveyor/mig-ui) |

---
## Demos
* [MTC Getting Started 1: Installation and Configuration](https://www.youtube.com/watch?v=uQ7VhpYEU5U&list=PL4aUFFbk56EN8bEPbpTVC3RAoUY--_MVf&index=1)
* [MTC Getting Started 2: Migrating an Example Workload](https://www.youtube.com/watch?v=p8V4YxBdA4s&list=PL4aUFFbk56EN8bEPbpTVC3RAoUY--_MVf&index=2)

## Contents

* [Development](#development)
* [Crane Operator Installation](#crane-operator-installation)
	* [Crane Operator Upgrades](#crane-operator-upgrades)
* [Component Installation and Configuration](#component-installation-and-configuration)
	* [Installation Topology](#installation-topology)
	* [Customizing your Installation](#customizing-your-installation)
	* [Installing Crane Components](#installing-crane-components)
	* [Additional Settings](#additional-settings)
		* [Restic Timeout](#restic-timeout)
		* [Migration Limits](#migration-limits)
		* [Rollback on Migration Failure](#rollback-on-migration-failure)
* [Migration Example Using API](#migration-example-using-api)
* [CORS (Cross-Origin Resource Sharing) Configuration](#cors-cross-origin-resource-sharing-configuration)
* [Removing Crane Operator](#removing-crane-operator)
* [Resources Migrated By Crane Operator](#resource-migrated-by-crane-operator)
* [Direct Migration Requirements](#direct-migration-requirements)

---

## Development
See [hacking.md](./docs/hacking.md) for instructions on installing _unreleased_ versions of mig-operator.

## Crane Operator Installation

### OpenShift 4

Crane Operator is installable on OpenShift 4 via OperatorHub.

#### Installing _released versions_ 

1. Visit the OpenShift Web Console.
1. Navigate to _Operators => OperatorHub_.
1. Search for _Crane Operator_.
1. Install the desired _Crane Operator_ version.

#### Installing _latest_

See [hacking.md](./docs/hacking.md)


### OpenShift 3

Crane Operator is installable on OpenShift 3 via OpenShift manifest.

#### Installing _released versions_
Obtain the operator.yml and controller-3.yml for the desired version. Visit [Quay](https://quay.io/repository/konveyor/mig-operator-container?tab=tags) for a list of valid tags. Stable releases are tagged as release-x.y.z. Latest is used for development and may be unstable.

```
podman cp $(podman create quay.io/konveyor/mig-operator-container:<tag>):/operator.yml ./
podman cp $(podman create quay.io/konveyor/mig-operator-container:<tag>):/controller-3.yml ./
```

```
oc create -f operator.yml
```

#### Crane Operator Upgrades

See the [MTC Upgrade Documentation](./docs/usage/UpgradingCAM.md).


## Component Installation and Configuration

Component installation and configuration is accomplished by creating or modifying a `MigrationController` CR.

### Installation Topology

You must install Crane Operator and components on all OpenShift clusters involved in a migration. 

|Use Case|Recommended Topology|
|---|---|
| Migrating from _OpenShift 3 => 4_ | Install _Velero_ on all clusters. Install the _Controller_ and _UI_ on the OpenShift 4 cluster. |
| Migrating from _OpenShift 3 => 3_ | Install _Velero_ on all clusters. Install the _Controller_ and _UI_ on the target cluster. |


### Customizing your Installation

You can choose components to install by setting parameters `MigrationController` CR spec 

| Parameter Name | Usage | Recommended Setting |
|---|---|---|
| `migration_velero` | Set to `true` to install Velero and Restic. | Set to `true` on all clusters. |
| `migration_controller` | Set to `true` to install the Migration Controller | Set to `true` only on one cluster, preferably OpenShift 4. |
| `migration_ui` | Set to `true` to install the Migration UI | Set to `true` only where `migration_controller: true`. |


### Installing Crane Components

Creating a `MigrationController` CR will tell Crane Operator to install Migration Components.

#### OpenShift 4

1. In the OpenShift console navigate to _Operators => Installed Operators_.
1. Click on _Crane Operator_.
1. Find _MigrationController_ on the _Provided APIs_ page and click _Create Instance_.
1. On OpenShift 4.5+, click the _Configure via: YAML view_ radio button.
1. Customize settings (_component selections_, _migration size limits_) in the YAML editor, and click _Create_.

#### OpenShift 3

1. Review the controller-3.yml retrieved earlier.
1. Adjust settings (_component selections_, _migration size limits_) if desired.
1. Set `mig_ui_cluster_api_endpoint` to point at the Controller cluster APIserver URL/Port.
1. Run `oc create -f controller-3.yml`

### Additional Settings

Additional settings can be applied by editing the `MigrationController` CR.

```
oc edit migrationcontroller -n openshift-migration
```

#### Restic Timeout

```
spec:
  restic_timeout: 1h
```

The default `restic_timeout` is 1 hour, specified as `1h`. You can increase this if you anticipate doing large backups that will take longer than 1 hour so that your backups will succeed. The downside to increasing this value is that it may delay returning from unanticipated errors in some scenarios. Valid units are s, m, and h, which stand for second, minute, and hour.

#### Migration Limits

```
spec:
  mig_pv_limit: '100'
  mig_pod_limit: '100'
  mig_namespace_limit: '10'
```

Setting for the max allowable number of resources in a Migration Plan. The default limits serve as a recommendation to break up large scale migrations into several smaller Migration Plans.

## Migration Example Using API

- [Direct Migration using API](./docs/usage/DirectMigrationExampleAPI.md)
- [Indirect Migration using API](./docs/usage/IndirectMigrationExampleAPI.md)
- [MTC API refernce](./docs/usage/MTCAPIDoc.md)

## CORS (Cross-Origin Resource Sharing) Configuration

You must follow the [CORs configuration steps](./docs/cors.md) _only if_:

- You are installing Crane Operator 1.1.1 or older
- You are installing Migration Controller and Migration UI on OpenShift 3


## Removing Crane Operator 
To clean up all the resources created by the operator you can do the following:
```
oc delete namespace openshift-migration

oc delete crd backups.velero.io backupstoragelocations.velero.io deletebackuprequests.velero.io downloadrequests.velero.io migrationcontrollers.migration.openshift.io podvolumebackups.velero.io podvolumerestores.velero.io resticrepositories.velero.io restores.velero.io schedules.velero.io serverstatusrequests.velero.io volumesnapshotlocations.velero.io

oc delete clusterrole migration-manager-role manager-role

oc delete clusterrolebindings migration-operator velero mig-cluster-admin migration-manager-rolebinding manager-rolebinding

oc delete oauthclient migration
```

## Resources Migrated By Crane Operator

Please refer to [Resources Migrated By Crane Operator](./docs/resources_migrated.md) in order to gain insights regarding what kind of objects/resources
get migrated by the Crane Operator.


## Direct Migration Requirements

In MTC 1.4.0, a new feature called Direct Migration is available that will yield significant time savings for most customers migrating persistent volumes
and/or internal images. Direct Migration enables the migration of persistent volumes and internal images directly from the source cluster to the destination
cluster without an intermediary replication repository. This introduces a significant performance enhancement while also providing better error and progress
reporting information back to the end-user. Please refer the [Direct Migration Requirements](./docs/direct_mig_requirements.md) documentation for more details.
