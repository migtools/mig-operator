# Storage Conversion

Storage conversion allows users to convert storage class of in-use _PersistentVolumeClaim_ resources. It lets users map storage classes of the source _PersistentVolumeClaims_ with desired destination storage classes. It creates new destination _PersistentVolumeClaims_ with the mapped storage classes in the same namespace and migrates _PersistentVolume_ data to the new volumes using Rsync. Moreover, it updates the application definitions to use the new _PersistentVolumeClaims_ automatically.

## Usage

The _MigPlan_ and the _MigMigration_ APIs need be used to perform a storage conversion:

### Configure Migration Plan

#### Step 1: Configure MigClusters

- Point the source and the target clusters to the same _MigCluster_ resource:

```yaml
apiVersion: migration.openshift.io/v1alpha1
kind: MigPlan
metadata:
  name: migplan-01
  namespace: openshift-migration
spec:
  srcMigClusterRef:
    name: remote-cluster            <--- (Source cluster)
    namespace: openshift-migration
  destMigClusterRef:
    name: remote-cluster            <--- (Target cluster)
    namespace: openshift-migration
  [...]
```

#### Step 2: Namespaces

- Since storage conversion creates new _PersistentVolumeClaims_ in the same namespace as the source namespace, make sure that the namespaces are not mapped to different destination namespaces:

```yaml
apiVersion: migration.openshift.io/v1alpha1
kind: MigPlan
metadata:
  name: migplan-01
  namespace: openshift-migration
spec:
  namespaces:
  - source-namespace            <--- (No mapping)
  [...]
```

- Once the _MigPlan_ is reconciled, the controller will add a new condition identifying it as a storage conversion plan:

```yaml
apiVersion: migration.openshift.io/v1alpha1
kind: MigPlan
metadata:
  name: migplan-01
  namespace: openshift-migration
spec:
  srcMigClusterRef:
    name: remote-cluster            <--- (Source cluster)
    namespace: openshift-migration
  destMigClusterRef:
    name: remote-cluster            <--- (Target cluster)
    namespace: openshift-migration
  namespaces:
  - source-namespace                <--- (No mapping)
status:
  conditions:
  - category: Advisory
    durable: true
    lastTransitionTime: "2021-12-08T21:20:59Z"
    message: This is an intra-cluster migration plan and none of the source namespaces are mapped to different destination namespaces. This plan can only be used for Storage Conversion.
    reason: StorageConversionPlan
    status: "True"
    type: MigrationTypeIdentified   <--- (Identifying condition)
  [...]
```

#### Step 3: PersistentVolumeClaims

- Since the new _PersistentVolumeClaims_ will be created in the same namespace, each of the new PVCs _must_ have a distinct name. The controller will automatically map the names of the source PVCs by adding `-new` as a suffix to the source PVC names. 

```yaml
apiVersion: migration.openshift.io/v1alpha1
kind: MigPlan
metadata:
  name: migplan-01
  namespace: openshift-migration
spec:
  persistentVolumes:
  - capacity: 1Gi
    name: pvc-0ef0b0aa-461c-4d0c-bc75-c526ff0b76d1
    proposedCapacity: 1Gi
    pvc:
      accessModes:
      - ReadWriteOnce
      hasReference: true
      name: pvc-01:pvc-01-new   <--- (Automatically mapped name)
      namespace: sparse-file
    [...]
  [...]
```

No user action is required to configure the _PersistentVolumeClaims_ except for an edge case

##### Edge case

- When the source _PersistentVolumeClaim_ has a name longer than 251 characters in length, the controller cannot add the `-new` suffix automatically as the creation of resulting PVC will fail due to limits. The controller will add a _Critical_ condition on the plan when this happens:

```yaml
conditions:
  - category: Error
    lastTransitionTime: "2021-12-13T15:33:02Z"
    message: This is a storage migration plan and source PVCs [aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa] are not mapped to distinct destination PVCs. This either indicates a problem in user input or controller failing to automatically add a prefix to destination PVC name. Please map the PVC names correctly.
    status: "True"
    type: PvNameConflict
```

To fix the issue, the users need to map the PVC name manually. It can be done by editing the _MigPlan_. The persistent volume claim can be found in the `.spec.persistentVolumes` section of the plan:

```yaml
apiVersion: migration.openshift.io/v1alpha1
kind: MigPlan
metadata:
  name: migplan-01
  namespace: openshift-migration
spec:
  persistentVolumes:
  - capacity: 1Gi
    name: pvc-0ef0b0aa-461c-4d0c-bc75-c526ff0b76d1
    proposedCapacity: 1Gi
    pvc:
      accessModes:
      - ReadWriteOnce
      hasReference: true
      name: aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa:distinct-name   <--- (Map name of the PVC manually)
```
The mapping uses the format `<src_pvc_name>:<dest_pvc_name>` where the `<dest_pvc_name>` is the name of the new PVC resource.

### Create Migration

The storage conversion uses the existing migration API to migrate _PersistentVolume_ data from the old PVCs to the new PVCs. The users can either perform a _cutover_ transfer directly or transfer the data incrementally one or more times and then perform a final cutover.

#### Step 1: Migrate PV data incrementally

Once the _MigPlan_ is correctly configured and is in _Ready_ state, _MigMigration_ resource can be created to begin converting PVC storage class.

- _migrateState_ field needs to be set to `true` to instruct the controller to migrate PV data. 

- _quiescePods_ field needs to be set to `false` to instruct the controller to not perform a final cutover.

```yaml
apiVersion: migration.openshift.io/v1alpha1
kind: MigMigration
metadata:
  name: storage-conversion-1
  namespace: openshift-migration
spec:
  migPlanRef:
    name: migplan-01
    namespace: openshift-migration
  stage: false 
  migrateState: true    <--- (Migrates PV data)
  quiescePods: false
```

In this step, the controller will only perform a data transfer.

#### Step 2: Cutover

This is similar to the previous step except _quiescePods_ field can be set to `true` to instruct the controller to perform a final cutover:

```yaml
apiVersion: migration.openshift.io/v1alpha1
kind: MigMigration
metadata:
  name: storage-conversion-2
  namespace: openshift-migration
spec:
  migPlanRef:
    name: migplan-01
    namespace: openshift-migration
  stage: false 
  migrateState: true    <--- (Migrates PV data)
  quiescePods: true     <--- (Cutover)
```

During the final cutover, the controller will quiesce the workloads, transfer the data and update the workloads to use the new _PersistentVolumeClaim_ resources automatically. Once the workloads are updated, the controller will unquiesce them before reaching to completion.

> NOTE: The automatic workload updates are only supported for the following workload resources: DaemonSets, DeploymentConfigs, Deployments, ReplicaSets, StatefulSets, Jobs, CronJobs