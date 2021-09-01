# Using State Transfer in MTC

In MTC 1.6.0 and above, _State Migration_ enables migration of Persistent Volume data along with a subset of Kubernetes resources which constitute the application state. To use State Migration, a Migration Plan needs to be created for the source namespaces. Once the plan is Ready, State Migration will be available in the Migration Plan actions menu. It differs from other Migration Types (Stage/Cutover) in that the State migration shouldn't be used to migrate the entire namespaces. It should only be used to migrate application state.


## Migrating PV data

State Migrations offers several different options for migrating PV data from the source to the target cluster. 

### Selecting PVCs to migrate

When performing a state transfer, the users can select _State_ from the _MigPlan_ actions. In the modal, individual PVCs can be selected using a checkbox. All the checked PVCs will be included in the Migration. 

In the API, the same thing can be accomplished by updating the _MigPlan_ spec fields. Once the _MigPlan_ PV discovery is complete, `migplan.spec.persistentVolumes` field is populated with discovered PVCs in the source cluster. For each PVC present in the list, the users can set `selection.action` field to `skip` to indicate that the PVC must be skipped from the migration. This is equivalent to unchecking the checkbox in the plan wizard.

```yaml
apiVersion: migration.openshift.io/v1alpha1
kind: MigPlan
metadata:
  name: migplan-01
  namespace: openshift-migration
spec:
  [...]
  persistentVolumes:
  - capacity: 10Gi
    name: pvc-daaa250f-c8e2-44a2-bbfe-975b029ebdf6
    pvc:
      [...]
    selection:
      action: skip  <----------- Set this to 'skip'
      [...]
```

### Migrating to pre-provisioned PVCs

State migrations allow migrating data from source PVCs to pre-provisioned target PVCs. This is useful when PVC objects are not migrated using MTC. In such cases, users can use the _State_ migration modal from the _MigPlan_ actions to map the PVC names. Each source PVC can be mapped to a distinct target PVC. If a target PVC by the mapped name already exists in the target cluster, MTC will simply migrate data into it. If the target PVC by that name does not exist, MTC will create a new PVC. 

In the API, this can be achieved by updating _MigPlan_ spec. The `.pvc.name` field of each PV listed under `.spec.persistentVolumes` can be updated to provide the mapping in below format:

```yaml
apiVersion: migration.openshift.io/v1alpha1
kind: MigPlan
metadata:
  name: migplan-01
  namespace: openshift-migration
spec:
  [...]
  persistentVolumes:
  - capacity: 10Gi
    name: pvc-daaa250f-c8e2-44a2-bbfe-975b029ebdf6
    pvc:
      name: source-pvc:target-pvc    <-------- PVC name mapping
      [...]
  [...]
```

The general mapping format is `<source_pvc_name>:<target_pvc_name>`. 

> Please note that the `.name` field above is the name of the PV object, while `.pvc.name` is the name of the PVC object. The mapping is only applicable to PVC objects, not the PV objects.

## Migrating Kubernetes resources selectively

Once all of the PV data is migrated, users can migrate a subset of Kubernetes resources from the source to the target cluster. This is particularly useful for State Transfers when the users only want to migrate resources that constitute the application state. The users can configure _MigPlan_ fields to provide a list of Kubernetes resources with an additional label selector to further filter those resources, and then perform a _Final_ migration to migrate those resources selectively. Since incremental migration of Kubernetes resources is not supported by MTC, this can only be done once. The _MigPlan_ will be closed after this migration. 

### Selecting GVKs to migrate

`.spec.includedResources` in the _MigPlan_ takes a list of Group-Kind as input. When this field is specified, only resources present in the list will be included in the migration. 

```yaml
apiVersion: migration.openshift.io/v1alpha1
kind: MigPlan
metadata:
  name: migplan-01
  namespace: openshift-migration
spec:
  includedResources:
  - kind: Secret
    group: ""
  - kind: ConfigMap
    group: ""

  [...]
```

Each resource present in `.spec.includedResources` is defined as Group & Kind as shown in above example. When a _Final_ migration is run on above _MigPlan_, only _Secret_ and _ConfigMap_ resources will be migrated to the target namespaces. 

### Specifying label selector

`.spec.labelSelector` field in the _MigPlan_ takes an optional label selector to further filter the resources included in the _MigPlan_. When this field is specified, only resources matching the label selector will be included in the migration.

```yaml
apiVersion: migration.openshift.io/v1alpha1
kind: MigPlan
metadata:
  name: migplan-01
  namespace: openshift-migration
spec:
  labelSelector:
    matchLabels:
      app: frontend 
  [...]
```

In the above example, all resources with labels 'app: frontend' will be included in the migration. If `.spec.includedResources` and `.spec.labelSelector` are both configured, then the labelSelector will be applied on the includedResources. For instance, in the following example, _Secret_ and _ConfigMap_ resources having labels 'app: frontend' set on them will be migrated.

```yaml
apiVersion: migration.openshift.io/v1alpha1
kind: MigPlan
metadata:
  name: migplan-01
  namespace: openshift-migration
spec:
  labelSelector:
    matchLabels:
      app: frontend 
  includedResources:
  - kind: Secret
    group: ""
  - kind: ConfigMap
    group: ""
  [...]
```

