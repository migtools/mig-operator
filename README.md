# Konveyor Operator
Konveyor Operator (mig-operator) installs a system of migration components for moving workloads from OpenShift 3 to 4.

| Installable Component | Repository |
|---|---|
| Velero + Custom Migration Plugins | [velero](https://github.com/konveyor/velero), [openshift-migration-plugin](https://github.com/konveyor/openshift-velero-plugin)|
| Migration Controller | [mig-controller](https://github.com/konveyor/mig-controller) |
| Migration UI | [mig-ui](https://github.com/konveyor/mig-ui) |

---

## Contents

* [Development](#Development)
* [Konveyor Operator Installation](#KonveyorOperatorInstallation)
	* [Konveyor Operator Upgrades](#KonveyorOperatorUpgrades)
* [Component Installation and Configuration](#ComponentInstallationandConfiguration)
	* [Installation Topology](#InstallationTopology)
	* [Customizing your Installation](#CustomizingyourInstallation)
	* [Installing Konveyor Components](#InstallingKonveyorComponents)
	* [Additional Settings](#AdditionalSettings)
		* [Restic Timeout](#ResticTimeout)
		* [Migration Limits](#MigrationLimits)
		* [Rollback on Migration Failure](#RollbackonMigrationFailure)
* [CORS (Cross-Origin Resource Sharing) Configuration](#CORSCross-OriginResourceSharingConfiguration)
* [Removing Konveyor Operator](#RemovingKonveyorOperator)

---

## Development
See [hacking.md](./docs/hacking.md) for instructions on installing _unreleased_ versions of mig-operator.

## Konveyor Operator Installation

### OpenShift 4

Konveyor Operator is installable on OpenShift 4 via OperatorHub.

#### Installing _released versions_ 

1. Visit the OpenShift Web Console.
1. Navigate to _Operators => OperatorHub_.
1. Search for _Konveyor Operator_.
1. Install the desired _Konveyor Operator_ version.

#### Installing _latest_

See [hacking.md](./docs/hacking.md)


### OpenShift 3

Konveyor Operator is installable on OpenShift 3 via OpenShift manifest.

#### Installing _released versions_

```
oc create -f deploy/non-olm/v1.3/operator.yml  
```

#### Installing _latest_

```
oc create -f deploy/non-olm/latest/operator.yml  
```

#### Konveyor Operator Upgrades

See the [MTC Upgrade Documentation](./docs/usage/UpgradingCAM.md).


## Component Installation and Configuration

Component installation and configuration is accomplished by creating or modifying a `MigrationController` CR.

### Installation Topology

You must install Konveyor Operator and components on all OpenShift clusters involved in a migration. 

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


### Installing Konveyor Components

Creating a `MigrationController` CR will tell Konveyor Operator to install Migration Components.

#### OpenShift 4

1. In the OpenShift console navigate to _Operators => Installed Operators_.
1. Click on _Konveyor Operator_.
1. Find _MigrationController_ on the _Provided APIs_ page and click _Create Instance_.
1. On OpenShift 4.5+, click the _Configure via: YAML view_ radio button.
1. Customize settings (_component selections_, _migration size limits_) in the YAML editor, and click _Create_.

#### OpenShift 3

1. Find the appropriately versioned controller-3.yml manifest in `deploy/nom-olm/<version>`.
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

#### Rollback on Migration Failure

```
spec:
  mig_failure_rollback: false
```

The default _rollback on failure_ setting is false.

```
 [...]
 
 # Rollback configuration is loaded into mig-controller, and should be set on the
 # cluster where `migration_controller: true`
 migration_controller: true

 # [Default] Setting 'mig_failure_rollback: false' leaves the partially migrated workloads 
 # in place on the target cluster.
 mig_failure_rollback: false

 # Setting 'mig_failure_rollback: true' removes the partially migrated workloads from the
 # target cluster and scales them back up on the source cluster.
 mig_failure_rollback: true
 [...]
```

## CORS (Cross-Origin Resource Sharing) Configuration

You must follow the [CORs configuration steps](./docs/cors.md) _only if_:

- You are installing Konveyor Operator 1.1.1 or older
- You are installing Migration Controller and Migration UI on OpenShift 3


## Removing Konveyor Operator 
To clean up all the resources created by the operator you can do the following:
```
oc delete namespace openshift-migration

oc delete crd backups.velero.io backupstoragelocations.velero.io deletebackuprequests.velero.io downloadrequests.velero.io migrationcontrollers.migration.openshift.io podvolumebackups.velero.io podvolumerestores.velero.io resticrepositories.velero.io restores.velero.io schedules.velero.io serverstatusrequests.velero.io volumesnapshotlocations.velero.io

oc delete clusterrole migration-manager-role manager-role

oc delete clusterrolebindings migration-operator velero mig-cluster-admin migration-manager-rolebinding manager-rolebinding

oc delete oauthclient migration
```
