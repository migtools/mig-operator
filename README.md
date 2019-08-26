# mig-operator
This operator will install velero with customized migration plugins, the migration controller, and migration UI used for migrating workloads from Openshift 3 to Openshift 4.

## Operator Installation with OLM on Openshift 4
1. `oc create -f mig-operator-source.yaml`
1. Create a openshift-migration-operator namespace
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
`oc get -n openshift-migration-operator route/migration -o go-template='{{ .spec.host }}{{ println }}'`

Add the hostname to /etc/origin/master/master-config.yaml under corsAllowedOrigins, for instance:
```
corsAllowedOrigins:
- //$output-from-previous-command
```

### Openshift 4
On Openshift 4 cluster resources are modified by the operator if the controller is installed there and you can skip these steps. If you chose not to install the controller on your Openshift 4 cluster you will need to perform these steps manually.

If you haven't already, determine the CORS URL that needs to be added retrieve the route URL
`oc get -n openshift-migration-operator route/migration -o go-template='{{ .spec.host }}{{ println }}'`

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
oc sa get-token -n openshift-migration-operator mig
```

## Cleanup
To clean up all the resources created by the operator you can do the following:
```
oc delete namespace openshift-migration

oc delete namespace openshift-migration-operator

oc delete crd backups.velero.io backupstoragelocations.velero.io deletebackuprequests.velero.io downloadrequests.velero.io migrationcontrollers.migration.openshift.io podvolumebackups.velero.io podvolumerestores.velero.io resticrepositories.velero.io restores.velero.io schedules.velero.io serverstatusrequests.velero.io volumesnapshotlocations.velero.io

oc delete clusterrolebindings migration-operator velero mig-cluster-admin

oc delete oauthclient migration
```

## Testing Changes to the mig-operator CSV with OLM
1. Edit [mig-operator CSV](https://github.com/fusor/mig-operator/blob/master/deploy/olm-catalog/mig-operator/0.0.1/mig-operator.v0.0.1.clusterserviceversion.yaml) making desired changes.
2. Edit [mig-operator-source.yaml](https://github.com/fusor/mig-operator/blob/master/mig-operator-source.yaml) setting 'registryNamespace' to an unused repo name under your quay.io org.
```
apiVersion: operators.coreos.com/v1
kind: OperatorSource
[...]
spec:
  [...]
  # set to an unused quay.io repo name under your user or organization
  registryNamespace: mig-operator
  [...]
```
3. Get [auth token](https://github.com/operator-framework/operator-courier#authentication) from quay.io
4. Use [operator-courier](https://github.com/operator-framework/operator-courier) to push the packaged CSV as an 'app' to your quay.io org. 
```
# Before doing this, ensure the quay.io org you're pushing to doesn't have any existing 'repo' or 'app' by the same name.
# Visit https://quay.io/application/ and check to see if the 'app' you're trying to push already exists.
# Remove any existing 'app' or 'repo' by the same name if one is found.

operator-courier --verbose push ./deploy/olm-catalog/mig-operator/0.0.1/ your-quay-org mig-operator 0.0.1 "$AUTH_TOKEN"

# After a successful push, visit https://quay.io/application/your-quay-org/mig-operator?tab=settings and set the app to public
```

5. On an OpenShift 4 cluster, create the mig-operator OperatorSource. After some time has passed, you should see the Migration Controller appear within OperatorHub in the Web Console. From OperatorHub, click "Install" on the "Migration Operator" to create an OLM subscription and start mig-operator.
```
oc create -f mig-operator-source.yaml
```

6. From the 'Catalog -> Installed Operators' tab in the Web Console, open the 'Migration Operator' item and create a 'MigrationController' CR to test the full system functionality.


