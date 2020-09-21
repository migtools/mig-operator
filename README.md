# Konveyor Operator
This operator will install velero with customized migration plugins, the migration controller, and migration UI used for migrating workloads from Openshift 3 to Openshift 4.

## Development
See [hacking.md](./docs/hacking.md).

## Operator Installation on OpenShift 4 with OLM
Konveyor Operator is available in Operator Hub. This is the recommended installation method for OpenShift 4.
1. Browse or search for Konveyor Operator.
1. Install the desired version.
1. For pre-release versions see the development guide above.

## Operator Installation on OpenShift 3 without OLM
The same versions are available for use without OLM. Run the command corresponding to the version you wish to use:

`oc create -f deploy/non-olm/latest/operator.yml`  
`oc create -f deploy/non-olm/v1.2/operator.yml`  
`oc create -f deploy/non-olm/v1.1/operator.yml`  

## Operator Upgrade Procedure
See the [CAM Upgrade Documentation](./docs/usage/UpgradingCAM.md).

## Component Installation and Configuration
Component installation and configuration is accomplished by creating or modifying a MigrationController CR.

### Topology
In a typical migration there will be at least one source cluster and one destination cluster. In the event that both OpenShift 3 and OpenShift 4 clusters are involved in migrations we recommend installing the Controller and UI components on the OpenShift 4 cluster. Installing the Controller on OpenShift 3 will require manually setting the api endpoint and CORS configuration.

### Component Installation Parameters
Component installation is handled with three parameters
- `migration_velero`: If set to true this will install velero and restic, which are required on all source and destination clusters.
- `migration_controller`:  This will install the migration controller and is required on one cluster.
- `migration_ui`: This will install the migration UI and should be installed on the same cluster as the controller if desired.

### MigrationController CR Creation
#### OpenShift 4
1. In the OpenShift console navigate to Operators>Installed Operators.
1. Click on Application Migration Operator.
1. Scroll the top menu until you see MigrationController and click on it.
1. Click Create MigrationController, adjust settings if desired, and click Creare.

#### OpenShift 3
1. Retrieve on of the example controller-3.yml files in the `deploy/nom-olm/latest`, `v1.2`, and `v1.1` directories.
1. Adjust settings if desired.
1. If installing the controller on OpenShift 3 set the `mig_ui_cluster_api_endpoint` to point at the clusters API URL/Port.
1. Run `oc create -f controller-3.yml`

### Additional Component Configuration

#### Restic Timeout
The default `restic_timeout` is 1 hour, specified as `1h`. You can increase this if you anticipate doing large backups that will take longer than 1 hour so that your backups will succeed. The downside to increasing this value is that it may delay returning from unanticipated errors in some scenarios. Valid units are s, m, and h, which stand for second, minute, and hour.

#### Adjusting Limits
Several limits have been put in place on a per MigPlan basis to serve as guidance when begining to perform migrations at scale.  

The default limits are:
  - 10 namespaces per MigPlan
  - 100 Pods per MigPlan
  - 100 Persistent Volumes per MigPlan

Resource limits can be adjusted by configuring the MigrationController resource responsible for deploying mig-controller.
```
  [...]
  migration_controller: true
  
  # This configuration is loaded into mig-controller, and should be set on the
  # cluster where `migration_controller: true`
  mig_pv_limit: 100
  mig_pod_limit: 100
  mig_namespace_limit: 10
  [...]
```

## CORS (Cross-Origin Resource Sharing) Configuration
These steps are only required if you are using a Konveyor version older than 1.1.1 OR are installing the controller/UI on OpenShift 3.

### OpenShift 4
If installing the controller/UI on a 4.x cluster using a version older than Konveyor 1.1.1 CORS will be configured on the cluster automatically. 

If you are installing a controller older than 1.1.1 on OpenShift 4.1 you will need to add this to the MigrationController CR spec section: `deprecated_cors_configuration: true`


### Manual CORS Configuration

#### Openshift 3
OpenShift 3 CORS configuration needs to be done manually.

In order to enable the UI to talk to an Openshift 3 cluster (whether local or remote) it is necessary to edit the master-config.yaml and restart the Openshift master nodes. 

To determine the CORS URL that needs to be added retrieve the route URL after installing the controller, run the following command (NOTE: This must be run on the cluster that is serving your web UI):  
`oc get -n openshift-migration route/migration -o go-template='(?i)//{{ .spec.host }}(:|\z){{ println }}' | sed 's,\.,\\.,g'`

Output from this command will look something like this, but will be different for every cluster:  
`(?i}//migration-openshift-migration\.apps\.foo\.bar\.baz\.com(:|\z)`

Add the output to /etc/origin/master/master-config.yaml under corsAllowedOrigins, for instance:
```
corsAllowedOrigins:
- (?i}//migration-openshift-migration\.apps\.foo\.bar\.baz\.com(:|\z)
```

After making these changes on 3.x you'll need to restart OpenShift components to pick up the changed config values. The process for restarting 3.x control plane components [differs based on the OpenShift version](https://docs.openshift.com/container-platform/3.10/architecture/infrastructure_components/kubernetes_infrastructure.html#control-plane-static-pods).

```
# In OpenShift 3.7-3.9, the control plane runs within systemd services
$ systemctl restart atomic-openshift-master-api
$ systemctl restart atomic-openshift-master-controllers


# In OpenShift 3.10-3.11, the control plane runs in 'Static Pods'
$ /usr/local/bin/master-restart api
$ /usr/local/bin/master-restart controllers
```

#### Openshift 4.3+
On Openshift 4 cluster resources are modified by the operator if the controller is installed there and you can skip these steps. If you chose not to install the controller on your Openshift 4 cluster you will need to perform these steps manually.

If you haven't already, determine the CORS URL that needs to be added retrieve the route URL:  
`oc get -n openshift-migration route/migration -o go-template='(?i)//{{ .spec.host }}(:|\z){{ println }}' | sed 's,\.,\\.,g'`

Output from this command will look something like this, but will be different for every cluster:  
`(?i)//migration-openshift-migration\.apps\.foo\.bar\.baz\.com(:|\z)`

#### Openshift 4.2
On Openshift 4 cluster resources are modified by the operator if the controller is installed there and you can skip these steps. If you chose not to install the controller on your Openshift 4 cluster you will need to perform these steps manually.

`oc edit apiserver cluster` and ensure the following exist:
```
spec:
  additionalCORSAllowedOrigins:
  - (?i)//migration-openshift-migration\.apps\.foo\.bar\.baz\.com(:|\z)
```

#### OpenShift 4.1
On Openshift 4 cluster resources are modified by the operator if the controller is installed there and you can skip these steps. If you chose not to install the controller on your Openshift 4 cluster you will need to perform these steps manually.

`oc edit authentication.operator cluster` and ensure the following exist:
```
spec:
  unsupportedConfigOverrides:
    corsAllowedOrigins:
    - //localhost(:|$)
    - //127.0.0.1(:|$)
    - (?i)//migration-openshift-migration\.apps\.foo\.bar\.baz\.com(:|\z)
```

`oc edit kubeapiserver.operator cluster` and ensure the following exist:
```
spec:
  unsupportedConfigOverrides:
    corsAllowedOrigins:
    - (?i)//migration-openshift-migration\.apps\.foo\.bar\.baz\.com(:|\z)
```

## Cleanup
To clean up all the resources created by the operator you can do the following:
```
oc delete namespace openshift-migration

oc delete crd backups.velero.io backupstoragelocations.velero.io deletebackuprequests.velero.io downloadrequests.velero.io migrationcontrollers.migration.openshift.io podvolumebackups.velero.io podvolumerestores.velero.io resticrepositories.velero.io restores.velero.io schedules.velero.io serverstatusrequests.velero.io volumesnapshotlocations.velero.io

oc delete clusterrole migration-manager-role manager-role

oc delete clusterrolebindings migration-operator velero mig-cluster-admin migration-manager-rolebinding manager-rolebinding

oc delete oauthclient migration
```

## Downstream test helpers
See [test-helpers](./deploy/test-helpers) for some scripts that help test
downstream images.
