# mig-operator
This operator is compatible with Openshift 4

## Operator Installation
1. `oc create -f operator.yml`

## Migration Controller Installation
1. Optionally edit `controller.yml` and change the `cluster_name` to configure the MigCluster resource with
1. `oc create -f controller.yml`
