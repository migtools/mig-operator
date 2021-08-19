# Post-migration cleanup

If you've finished migrating your apps with Crane and you want to cleanly remove Crane and associated migration resources from the cluster, follow these steps:


## Clean up steps

For _all clusters_ where Crane is installed:

1. Login to the cluster
1. Remove the `openshift-migration` namespace where Crane is installed
    ```
    oc delete namespace openshift-migration
    ```
1. Remove Crane API objects and CRDs
    ```
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
1. Remove cluster-scoped RBAC resources installed by Crane
   ```
   oc delete clusterrolebinding migration-controller
   oc delete clusterrole migration-controller
   ```
