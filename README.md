#### mig-operator
This operator will install velero with customized migration plugins, the migration controller, and migration UI used for migrating workloads from Openshift 3 to Openshift 4.

## Operator Installation with OLM on Openshift 4
1. `oc create -f mig-operator-source.yaml`
1. Create a openshift-migration namespace
1. In the left menu select Operator Hub and find `Migration Operator` in the list
1. Click Install and install it in the mig namespace
  * There are two channels to select from: latest and release-v1.
  * latest roughly corresponds to beta.
1. Once installation is complete select `Installed Operators` on the left menu
1. Create a `MigrationController` CR. The default vales should be acceptable for 4.2
1. For 4.1 add `deprecated_cors_configuration: true` under `spec:`
1. The default `restic_timeout` is 1 hour, specified as `1h`. You can increase this if you anticipate doing large backups that will take longer than 1 hour so that your backups will succeed. The downside to increasing this value is that it may delay returning from unanticipated errors in some scenarios. Valid units are s, m, and h, which stand for second, minute, and hour.

## Operator Installation without OLM
The same channels are available for use without OLM. Do one of the following to install the desired version:

`oc create -f deploy/non-olm/latest/operator.yml` 
`oc create -f deploy/non-olm/v1.0/operator.yml` 

## Migration Controller Installation
`controller-3.yml` and `controller-4.yml` in the `deploy/nom-olm/latest` and `v1.0` directories contain the recommended settings for OCP 3 and 4 respectively.

Edit `controller-3.yml` or `controller-4.yml` and adjust options if desired.

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

If you are using Openshift 4.1 ensure `deprecated_cors_configuration: true` is uncommented. This option is not required with 4.2+
```
  migration_velero: true
  migration_controller: true
  migration_ui: true
  deprecated_cors_configuration: true
```

The default `restic_timeout` is 1 hour, specified as `1h`. You can increase this if you anticipate doing large backups that will take longer than 1 hour so that your backups will succeed. The downside to increasing this value is that it may delay returning from unanticipated errors in some scenarios. Valid units are s, m, and h, which stand for second, minute, and hour.

It is possible to reverse this setup and install the controller and UI pods on Openshift 3, but you will also need to provide the cluster endpoint in `controller-3.yml` via the `mig_ui_cluster_api_endpoint` parameter. Additional setup will also be required on the Openshift 4 cluster if you take this route. See the manual CORS configuration section below for more details. `migration_velero` is required on every cluster that will act as a source or destination for migrated workloads.

Once you've made your configuration choices run oc create against the edited yaml configuration, for example `oc create -f deploy/non-olm/latest/controller-3.yml`.


### Migration Controller Installation:  Adjusting Limits
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

## Manual CORS (Cross-Origin Resource Sharing) Configuration

### Openshift 3
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


### Openshift 4
On Openshift 4 cluster resources are modified by the operator if the controller is installed there and you can skip these steps. If you chose not to install the controller on your Openshift 4 cluster you will need to perform these steps manually.

If you haven't already, determine the CORS URL that needs to be added retrieve the route URL:  
`oc get -n openshift-migration route/migration -o go-template='(?i)//{{ .spec.host }}(:|\z){{ println }}' | sed 's,\.,\\.,g'`

Output from this command will look something like this, but will be different for every cluster:  
`(?i)//migration-openshift-migration\.apps\.foo\.bar\.baz\.com(:|\z)`

#### For Openshift 4.2
`oc edit apiserver cluster` and ensure the following exist:
```
spec:
  additionalCORSAllowedOrigins:
  - (?i)//migration-openshift-migration\.apps\.foo\.bar\.baz\.com(:|\z)
```

#### For OpenShift 4.1:
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

oc delete clusterrole migration-manager-role manager-role

oc delete clusterrolebindings migration-operator velero mig-cluster-admin migration-manager-rolebinding manager-rolebinding

oc delete oauthclient migration
```

## Downstream test helpers

See [test-helpers](./deploy/test-helpers) for some scripts that help test
downstream images.
