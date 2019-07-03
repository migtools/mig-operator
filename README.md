# mig-operator
This operator will install velero with customized migration plugins, the migration controller, and migration UI used for migrating workloads from Openshift 3 to Openshift 4.

## Operator Installation
1. `oc create -f operator.yml`

## Migration Controller Installation
1. Edit `controller.yml` and adjust desired options
1. `oc create -f controller.yml`

## Openshift 3 CORS (Cross-Origin Resource Sharing) Configuration
In order to enable the UI on Openshift 3 it is necessary to edit the master-config.yaml and restart the Openshift master nodes. On Openshift 4 Cluster Resources are modified by the operator so these steps are not necessary. It is therefore recommended, though not necessary, that the migration controller and UI are run on the Openshift 4 cluster.

### TODO:
- Add steps here for configuring CORS on Openshift 3.
- [origin3-dev](https://github.com/fusor/origin3-dev/blob/master/ansible/roles/openshift_setup/tasks/main.yml#L347-L353) can be used as a rough guide for pulling these instructions together.
