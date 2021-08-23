# Post-migration cleanup

If you've finished migrating your apps with Crane and you want to cleanly remove Crane and associated migration resources from the cluster, follow these steps:


## Clean up steps

### For _control clusters_ where mig-controller is installed:

1. Login to the cluster
1. Set `spec.closed: true` on all MigPlans to run cleanup routines for each plan. This will remove migration related resources spread across the cluster.
    ```sh
    for migplan in $(oc get migplan -n openshift-migration -o jsonpath='{.items[*].metadata.name}'); do oc -n openshift-migration patch migplan $migplan --type=json --patch '[{ "op": "add", "path": "/spec/closed", "value": true }]'; done
    ```
1. Wait for each MigPlan status.conditions to reflect that the plan is closed.
    ```sh
    watch oc get migplan -n openshift-migration -o json
    ```
1. Follow instructions below for common removal steps.


### For _all clusters_ where Crane is installed:

1. Login to the cluster
1. Remove the `openshift-migration` namespace where Crane is installed
    ```sh
    oc delete namespace openshift-migration
    ```
1. Remove Crane API objects and CRDs
    ```sh
    # Remove mig-operator CRD
    oc delete customresourcedefinition migrationcontrollers.migration.openshift.io

    # Remove mig-controller CRDs
    oc delete customresourcedefinition directimagemigrations.migration.openshift.io
    oc delete customresourcedefinition directimagestreammigrations.migration.openshift.io
    oc delete customresourcedefinition directvolumemigrationprogresses.migration.openshift.io
    oc delete customresourcedefinition directvolumemigrations.migration.openshift.io
    oc delete customresourcedefinition miganalytics.migration.openshift.io
    oc delete customresourcedefinition migclusters.migration.openshift.io
    oc delete customresourcedefinition mighooks.migration.openshift.io
    oc delete customresourcedefinition migmigrations.migration.openshift.io
    oc delete customresourcedefinition migplans.migration.openshift.io
    oc delete customresourcedefinition migstorages.migration.openshift.io
    ```
1. For non-OLM installs: Remove cluster-scoped RBAC resources installed by Crane
   ```sh
   # Cluster Role Bindings
   oc delete clusterrolebinding migration-controller
   oc delete clusterrolebinding migration-operator
   oc delete clusterrolebinding migration-velero

   # Cluster Roles
   oc delete clusterrole migration-controller
   oc delete clusterrole migration-operator
   oc delete clusterrole migration-velero
   ```