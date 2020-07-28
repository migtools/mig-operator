# Resource Exclusion
Starting with CAM 1.2.4 it is possible to exclude PV data migration, ImageStream migration, and migration of specific Kubernetes resources kinds. This can be done to allow migration of data or images with an alternative tool or to prevent migration of problematic kubernetes resources.

# Exclude ImageStream Migration
Modify the MigrationController CR and add `disable_image_migration: true` to the spec section.

```
apiVersion: migration.openshift.io/v1alpha1
kind: MigrationController
metadata:
  name: migration-controller
  namespace: openshift-migration
spec:
  disable_image_migration: true
...
```

# Exclude PV Migration
Modify the MigrationController CR and add `disable_pv_migration: true` to the spec section.

```
apiVersion: migration.openshift.io/v1alpha1
kind: MigrationController
metadata:
  name: migration-controller
  namespace: openshift-migration
spec:
  disable_pv_migration: true
...
```

Disabling pv migration will also disable PV discovery during plan creation.

# Exclude Kubernetes Resources
To modify the default list of excluded resources add an `excluded_resources` parameter to the MigrationController CR.

It is suggested that you only add to the list since migrating resources on this list is known to be problematic.

To obtain the current list of excluded resources run the following command.
```
$ oc get deployment -n openshift-migration migration-controller -o yaml | grep EXCLUDED_RESOURCES -A1
        - name: EXCLUDED_RESOURCES
          value: imagetags,templateinstances,clusterserviceversions,packagemanifests,subscriptions,servicebrokers,servicebindings,serviceclasses,serviceinstances,serviceplans
```

If you have set either `disable_image_migration` or `disable_pv_migration` you will see `imagestreams`, `persistentvolumes`, and `persistentvolumeclaims` in the output as well. It is not necessary or desirable to add them to the list in the MigrationController CR, since you willl also need to remove them from the `exclude_resources` list to properly reenable either of those features.

```
apiVersion: migration.openshift.io/v1alpha1
kind: MigrationController
metadata:
  name: migration-controller
  namespace: openshift-migration
spec:
  excluded_resources:
  - imagetags
  - templateinstances
  - clusterserviceversions
  - packagemanifests
  - subscriptions
  - servicebrokers
  - servicebindings
  - serviceclasses
  - serviceinstances
  - serviceplans
...
```
