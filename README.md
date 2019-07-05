# mig-operator
This operator will install velero with customized migration plugins, the migration controller, and migration UI used for migrating workloads from Openshift 3 to Openshift 4.

## Operator Installation
1. `oc create -f operator.yml`

## Migration Controller Installation
1. Edit `controller.yml` and adjust desired options
1. `oc create -f controller.yml`

## Manual CORS (Cross-Origin Resource Sharing) Configuration
In order to enable the UI to talk to an Openshift 3 cluster (whether local or remote) it is necessary to edit the master-config.yaml and restart the Openshift master nodes. 

To determine the CORS URL that needs to be added retrieve the route URL
`oc get -n mig route/migration -o go-template='{{ .spec.host }}{{ println }}'`

Add the hostname for /etc/origin/master/master-config.yaml under corsAllowedOrigins, for instance:
```
corsAllowedOrigins:
- //$output-from-previous-command
```

On Openshift 4 Cluster Resources are modified by the operator so these steps are not necessary if you install the controller and UI on the Openshift 4 cluster. If you chose not to configure the UI and Controller on Openshift 4 you will need to do this manually.

If you haven't already, determine the CORS URL that needs to be added retrieve the route URL
`oc get -n mig route/migration -o go-template='{{ .spec.host }}{{ println }}'`

`oc edit authentication.operator cluster` and ensure the following exist:
```
spec:
  unsupportedConfigOverrides:
    corsAllowedOrigins:
    - //localhost(:|$)
    - //127.0.0.1(:|$)
    - //$output-from-previous-command
``

`oc edit kubeapiserver.operator cluster` and ensure the following exist:
```
spec:
  unsupportedConfigOverrides:
    corsAllowedOrigins:
    - //$output-from-previous-command
```

## Creating a service account to connect to the remote cluster.
When adding a remote cluster in the migration UI you will be prompted for a serviceaccount token. 

On the remote cluster you can create a service account and token with the following commands:
```
oc new-project mig
oc create sa -n mig mig
oc adm policy add-cluster-role-to-user cluster-admin system:serviceaccount:mig:mig
oc sa get-token -n mig mig
```
