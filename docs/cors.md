## CORS (Cross-Origin Resource Sharing) Configuration
These steps are only required if you are using a Crane version older than 1.1.1 OR are installing the controller/UI on OpenShift 3.

### OpenShift 4
If installing the controller/UI on a 4.x cluster using a version older than Crane 1.1.1 CORS will be configured on the cluster automatically. 

If you are installing a controller older than 1.1.1 on OpenShift 4.1 you will need to add this to the MigrationController CR spec section: `deprecated_cors_configuration: true`


### Manual CORS Configuration

#### Openshift 3
OpenShift 3 CORS configuration needs to be done manually.

In order to enable the UI to talk to an Openshift 3 cluster (whether local or remote) it is necessary to edit the master-config.yaml and restart the Openshift master nodes. 

To determine the CORS URL that needs to be added retrieve the route URL after installing the controller, run the following command (NOTE: This must be run on the cluster that is serving your web UI):  
`oc get -n openshift-migration route/migration -o go-template='(?i)//{{ .spec.host }}(:|\z){{ println }}' | sed 's,\.,\\.,g'`

Output from this command will look something like this, but will be different for every cluster:  
`(?i)//migration-openshift-migration\.apps\.foo\.bar\.baz\.com(:|\z)`

Add the output to /etc/origin/master/master-config.yaml under corsAllowedOrigins, for instance:
```
corsAllowedOrigins:
- (?i)//migration-openshift-migration\.apps\.foo\.bar\.baz\.com(:|\z)
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
