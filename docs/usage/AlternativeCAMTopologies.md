# Alternative CAM Topologies

## Overview
The CAM suite is flexible and can be configured to run with varying topologies.
CAM is installed in two different modes:

* **Control Cluster:** The cluster that runs the CAM controller & UI.
* **Remote Cluster:** A source or destination cluster for a migration that runs
Velero. The Control Cluster communicates with Remote clusters via the Velero API
to drive migrations.

> NOTE: Usually your Control Cluster will also be a source or destination used
for a migration. If this is the case, it must also be a Remote Cluster and
have Velero installed as well.

In a typical scenario from OCP3 to 4, we recommend designating the target 4 cluster
as the Control Cluster. The CAM controller, Velero, and the UI are installed
into this cluster. The source OCP3 cluster is designated as a Remote Cluster,
and only requires Velero. The default spec of the `MigrationController` CR seen
in the OCP4 OLM console will contain configuration to install all 3 of the major
CAM components, the controller, UI, and Velero. This allows users to use their OCP4 cluster as
their Control Cluster, as well as use it as a destination for their migrations.

Similarly, the default `controller-3.yml` [yaml file](https://github.com/konveyor/mig-operator/blob/master/deploy/non-olm/v1.2.0/controller-3.yml),
has its default configuration set to disable the controller and UI. Only Velero
is installed and required as a "Remote Cluster".

However, as mentioned previously, CAM is flexible in its configuration.
Users may wish to run OCP3->3 migrations, designate their source cluster as the Control Cluster
in an OCP3->4 migration, or perform OCP4->4 migrations. Users may even run
CAM in a third cluster that is distinct from their source and destination
remote clusters.

## Component Configuration

The major components (CAM controller, Velero, and the UI) can be individually
enabled or disabled on a cluster via the `MigrationController` CR spec with the
following vars:

```yml
spec:
  migration_velero: true|false
  migration_controller: true|false
  migration_ui: true|false
```

## Configuring an OCP3 Control Cluster

For OCP3->3 migrations (and users that would like to use their 3 cluster as the
Control Cluster for an OCP3->4 migration), one of the 3.x clusters must be
configured as a "Control Cluster". With OCP3, there is some additional
configuration required that is generally handled automatically via the operator
on OCP4 (CORS).

### MigrationController Spec
After the operator has been deployed on the OCP3 Control Cluster using the
`operator.yml` [yaml file](https://github.com/konveyor/mig-operator/blob/master/deploy/non-olm/v1.2.0/operator.yml)
the `controller-3.yml` [yaml file](https://github.com/konveyor/mig-operator/blob/master/deploy/non-olm/v1.2.0/controller-3.yml)
must be customized to switch on the `migration_controller` and `migration_ui`.
The API server URL of the cluster must also be set, since it cannot be retrieved
automatically as it can on OCP4. Example 3.x Control Cluster `MigrationController`:

```yml
apiVersion: migration.openshift.io/v1alpha1
kind: MigrationController
metadata:
  name: migration-controller
  namespace: openshift-migration
spec:
  azure_resource_group: ''
  cluster_name: host
  migration_velero: true
  migration_controller: true
  migration_ui: true
  restic_timeout: 1h
  mig_pv_limit: 100
  mig_pod_limit: 100
  mig_namespace_limit: 10
  mig_ui_cluster_api_endpoint: <INSERT API ENDPOINT>
```

### Configuring CORS on the OCP3 Control Cluster

In order to enable the UI, CORS (Cross-Origin Resource Sharing) must be configured
in the OCP3 Control Cluster masters so the UI is whitelisted to communicate with
the cluster's API.

[Please see the main README for manual CORS configuration instructions](https://github.com/konveyor/mig-operator/blob/master/README.md#openshift-3).

### Configuring OCP3 Remote Cluster

The OCP3 Remote Cluster is configured as you normally would, and the default
values in the `controller-3.yml` file can be used.

## Configuring an OCP4 cluster as a Remote Cluster

If you would like to use an OCP4 cluster as a Remote Cluster (the typical use case
here would be for OCP4->4 migrations), install the operator as you normally would
via the OLM console. Following the operator's deployment, create a `MigrationCluster`
CR via the OLM console, but the controller and UI should be disabled:

```yml
apiVersion: migration.openshift.io/v1alpha1
kind: MigrationController
metadata:
  name: migration-controller
  namespace: openshift-migration
spec:
  azure_resource_group: ''
  cluster_name: host
  migration_velero: true
  migration_controller: false
  migration_ui: false
  restic_timeout: 1h
```
