# mig-operator
This operator will install velero with customized migration plugins, the migration controller, and migration UI used for migrating workloads from Openshift 3 to Openshift 4.

## Operator Installation with OLM on Openshift 4
1. `oc create -f mig-operator-source.yaml`
1. Create a openshift-migration namespace
1. In the left menu select Operator Hub and find `Migration Operator` in the list
1. Click Install and install it in the mig namespace
1. Once installation is complete select `Installed Operators` on the left menu
1. Create a `MigrationController` CR. The default vales should be acceptable.

## Operator Installation without OLM

`oc create -f operator.yml` 

## Migration Controller Installation
'controller-3.yml' and 'controller-4.yml' contain the recommended settings for OCP 3 and 4 respectively.

Edit `controller.yml` and adjust options if desired.

Recommended settings for Openshift 3 are:
```
  migration_velero: true
  migration_controller: false
  migration_ui: false
```

Recommended settings for Openshift 4 are:
```
  migration_velero: true
  migration_controller: true
  migration_ui: true
```

It is possible to reverse this setup and install the controller and UI pods on Openshift 3, but you will also need to provide the cluster endpoint in `controller-3.yml` via the `mig_ui_cluster_api_endpoint` parameter. Additional setup will also be required on the Openshift 4 cluster if you take this route. See the manual CORS configuration section below for more details. `migration_velero` is required on every cluster that will act as a source or destination for migrated workloads.

Once you've made your configuration choices run `oc create -f controller.yml`.

## Manual CORS (Cross-Origin Resource Sharing) Configuration

### Openshift 3
In order to enable the UI to talk to an Openshift 3 cluster (whether local or remote) it is necessary to edit the master-config.yaml and restart the Openshift master nodes. 

To determine the CORS URL that needs to be added retrieve the route URL after installing the controller.
`oc get -n openshift-migration route/migration -o go-template='{{ .spec.host }}{{ println }}'`

Add the hostname to /etc/origin/master/master-config.yaml under corsAllowedOrigins, for instance:
```
corsAllowedOrigins:
- //$output-from-previous-command
```

After making these changes on 3.x you'll need to restart OpenShift components to pick up the changed config values. The process for restarting 3.x control plane components [differs based on the OpenShift version](https://docs.openshift.com/container-platform/3.10/architecture/infrastructure_components/kubernetes_infrastructure.html#control-plane-static-pods).

```
# In OpenShift 3.7-3.9, the control plane runs within systemd services
$ systemctl restart atomic-openshift-master-api
$ systemctl restart atomic-openshift-master-controllers


# In OpenShift 3.10-3.11, the control plane runs in 'Static Pods'
$ /usr/local/bin/master-restart api
$ /usr/local/bin/master-restart controller
```


### Openshift 4
On Openshift 4 cluster resources are modified by the operator if the controller is installed there and you can skip these steps. If you chose not to install the controller on your Openshift 4 cluster you will need to perform these steps manually.

If you haven't already, determine the CORS URL that needs to be added retrieve the route URL
`oc get -n openshift-migration route/migration -o go-template='{{ .spec.host }}{{ println }}'`

`oc edit authentication.operator cluster` and ensure the following exist:
```
spec:
  unsupportedConfigOverrides:
    corsAllowedOrigins:
    - //localhost(:|$)
    - //127.0.0.1(:|$)
    - //$output-from-previous-command
```

`oc edit kubeapiserver.operator cluster` and ensure the following exist:
```
spec:
  unsupportedConfigOverrides:
    corsAllowedOrigins:
    - //$output-from-previous-command
```

## Obtaining a remote cluster serviceaccount token
When adding a remote cluster in the migration UI you will be prompted for a serviceaccount token.

To get a serviceaccount token use the following command:
```
oc sa get-token -n openshift-migration mig
```

## Cleanup
To clean up all the resources created by the operator you can do the following:
```
oc delete namespace openshift-migration

oc delete crd backups.velero.io backupstoragelocations.velero.io deletebackuprequests.velero.io downloadrequests.velero.io migrationcontrollers.migration.openshift.io podvolumebackups.velero.io podvolumerestores.velero.io resticrepositories.velero.io restores.velero.io schedules.velero.io serverstatusrequests.velero.io volumesnapshotlocations.velero.io

oc delete clusterrolebindings migration-operator velero mig-cluster-admin

oc delete oauthclient migration
```


