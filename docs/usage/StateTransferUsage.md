# Using State Transfer in MTC

In MTC 1.6.0 and above, _State Migration_ enables migration of Persistent Volume data. In special cases, it also allows migrating a subset of Kubernetes resources which constitute the application state. It differs from other migration types in that the State migration does not migrate entire namespaces. It only migrates _PersistentVolumeClaims_ and data on the persistent volumes. It is specifically designed to be used in conjuction with external CD mechanisms such as OpenShift Gitops. The idea is to migrate application manifests using GitOps, while migrating the state using MTC.

## Using State Migration in conjunction with GitOps (ArgoCD)

This section recommends sequence of actions to perform a state-only migration in conjunction with OpenShift Gitops. In order to keep the document concise and relevant to MTC, we will skip the details of ArgoCD deployment. We will make certain assumptions about the environments: 
- Application manifests are available in a central repository accessible by both source & target clusters. 
- Application on the source cluster has persisted state in _PersistentVolumes_ provisioned through _PersistentVolumeClaims_. 

### Migration

- Step 1: Migrate persistent volume data from source to target cluster
  - This is the staging phase where we will migrate application data using State Migration. It can be performed as many times as needed. The source applications will continue running. See [this section](#migrating-pv-data) for details on data migration.

- Step 2: Quiesce down source application
  - In this step, we will quiesce down the application on source cluster. This can be done by setting the replicas of workload resources to 0. It can either be done directly on the source cluster or by updating the manifests in GitHub before re-syncing the ArgoCD application. 

- Step 3: Clone application manifests to target cluster
  - ArgoCD can be used to clone the same application to the target cluster.

- Step 4: Migrate remaining volume data from source to target cluster
  - In this step, any new data created by the application during Step 1 & Step 2 can be migrated by performing a final data migration. 

- Step 5: Un-quiesce destination application
  - This step is only applicable if the cloned application is in quiesced state.

- Step 6: Switch DNS
  - Finally, DNS can be switched over to the destination cluster to re-direct user traffic to the migrated application.

> NOTE: MTC 1.6 cannot quiesce the application automatically when using State Migration. It can only migrate PV data. Therefore, the users are required to use their CD mechanisms to handle quiescing/unquiescing of applications. MTC 1.7 improves user experience around State Migration by introducing explicit Stage and Cutover flows. Staging can be used to perform initial data transfers as many times as needed. Finally, a Cutover can be performed in which the quiescing of source applications will be handled automatically.

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

