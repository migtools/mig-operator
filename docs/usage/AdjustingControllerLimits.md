# Adjusting controller limits
The controller has memory and CPU limits specified to prevent it from using an excess of resources. The memory limit can be adjusted with `mig_controller_limits_memory`, which may be useful if you notice the controller restarting due to OOMKilled errors.

To adjust the limits, create or edit the MigrationController CR and include the paramters `mig_controller_limits_cpu` and `mig_controller_limits_memory` under spec with the desired values.

For example:
```
apiVersion: migration.openshift.io/v1alpha1
kind: MigrationController
metadata:
  name: migration-controller
  namespace: openshift-migration
spec:
  mig_controller_limits_cpu: "100m"
  mig_controller_limits_memory: "800Mi"
  mig_namespace_limit: '10'
  migration_ui: true
  mig_pod_limit: '100'
  migration_controller: true
  mig_failure_rollback: false
  olm_managed: true
  cluster_name: host
  restic_timeout: 1h
  migration_velero: true
  mig_pv_limit: '100'
  version: 1.0 (OLM)
  azure_resource_group: ''
```
