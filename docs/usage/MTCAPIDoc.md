# MTC API Documentation

MTC has several APIs which are needed to carry out migrations. This document explains specs for each API used in migrations.

## Direct Image Migration

```
apiVersion: migration.openshift.io/v1alpha1
kind: DirectImageMigration
metadata:
  labels:
    controller-tools.k8s.io: "1.0"
  name: directimagemigration-sample
spec:
  srcMigClusterRef:
    name: migcluster-local
    namespace: openshift-migration

  destMigClusterRef:
    name: migcluster-remote
    namespace: openshift-migration

  namespaces:
  - nginx-example
```

-   spec.destMigClusterRef: ObjectReference contains enough information to let you inspect or modify the referred object. Contains name and namespace of the destination mig cluster where the operator is installed.

-   spec.namespaces:  A list of all namespaces to run DIM to get all the imagestreams in these namespaces.

-   spec.srcMigClusterRef: ObjectReference contains enough information to let you inspect or modify the referred object. Contains name and namespace of the source mig cluster where the operator is installed.

## Direct ImageStream Migration

```
apiVersion: migration.openshift.io/v1alpha1
kind: DirectImageStreamMigration
metadata:
  labels:
    controller-tools.k8s.io: "1.0"
  name: directimagestreammigration-sample
spec:
  srcMigClusterRef:
    name: migcluster-local
    namespace: openshift-migration

  destMigClusterRef:
    name: migcluster-remote
    namespace: openshift-migration

  imageStreamRef:
    name: nginx
    namespace: nginx-example

  destNamespace: new-namespace
  ```

- spec.destMigClusterRef: ObjectReference contains enough information to let you inspect or modify the referred object. Contains name and namespace of the destination mig cluster where the operator is installed.

- spec.destNamespace: A string holding the name of the namespace on destination cluster where imagestreams should be migrated.

- spec.imageStreamRef: ObjectReference contains enough information to let you inspect or modify the referred object. Contains name and namespace of the source mig cluster where the imagesstream is present.


- spec.srcMigClusterRef: ObjectReference contains enough information to let you inspect or modify the referred object. Contains name and namespace of the source mig cluster where the operator is installed.

     
## Direct Volume Migration

```
apiVersion: migration.openshift.io/v1alpha1
kind: DirectVolumeMigration
metadata:
  name: direct1
  namespace: openshift-migration
spec:
  createDestinationNamespaces: false
  deleteProgressReportingCRs: false
  destMigClusterRef:
    name: host
    namespace: openshift-migration
  persistentVolumeClaims:
  - name: pvc-0
    namespace: pvc-migrate-bmark-1
  - name: pvc-0
    namespace: pvc-migrate-bmark-2
  - name: pvc-0
    namespace: pvc-migrate-bmark-3
  - name: pvc-1
    namespace: pvc-migrate-bmark-3
  srcMigClusterRef:
    name: ocp3
    namespace: openshift-migration
```

- spec.createDestinationNamespaces: A boolean flag that is set True to create namespaces in destination cluster

- spec.deleteProgressReportingCRs: A boolean flag to specify if progress reporting CRs needs to be deleted or not

- spec.destMigClusterRef: ObjectReference contains enough information to let you inspect or modify the referred object. Contains name and namespace of the destination mig cluster where the operator is installed.


- spec.persistentVolumeClaims: A list of all the PVCs that are to be migrated with direct volume migration

- spec.srcMigClusterRef: ObjectReference contains enough information to let you inspect or modify the referred object. Contains name and namespace of the source mig cluster where the operator is installed.


## Direct Volume Migration Progress

```
apiVersion: migration.openshift.io/v1alpha1
kind: DirectVolumeMigrationProgress
metadata:
  labels:
    controller-tools.k8s.io: "1.0"
  name: directvolumemigrationprogress-sample
spec:
  # [!] Change clusterRef to point to the cluster where the pod is running
  clusterRef:
    name: sample-source-3110
    namespace: openshift-migration
  # [!] Change podRef to point to the name and namespace of the running pod
  podRef:
    name: directmigration-sample-pod-0
    namespace: openshift-migration
```

- spec.clusterRef: ObjectReference contains enough information to let you inspect or modify the referred object.

- spec.podRef: ObjectReference contains enough information to let you inspect or modify the referred object.


## Mig Analytics

```
apiVersion: migration.openshift.io/v1alpha1
kind: MigAnalytic
metadata:
  annotations:
    migplan: test
  name: mtest
  namespace: openshift-migration
  labels:
    migplan: test
spec:
  analyzeImageCount: true
  analyzeK8SResources: true
  analyzePVCapacity: true
  migPlanRef:
    name: test
    namespace: openshift-migration
```

- spec.analyzeImageCount: A boolean flag to enable analysis of image count. This is a required field.

- spec.analyzeK8SResources: A boolean flag to enable analysis of k8s resources. This is a required field.

- spec.analyzePVCapacity: A boolean flag to enable analysis of persistent volume capacity. This is a required field.

- spec.listImages: A boolean flag to enable used in analysis of image count

- spec.listImagesLimit: An integer representing limit on image counts

- spec.migPlanRef: ObjectReference contains enough information to let you inspect or modify the referred object. This is a required field.

## Mig Cluster

Local Mig cluster: 
```
 
apiVersion: migration.openshift.io/v1alpha1
kind: MigCluster
metadata:
  labels:
    controller-tools.k8s.io: "1.0"
  name: migcluster-local
  namespace: openshift-migration
spec:
  # [!] Change isHostCluster to 'false' if you want to use a clusterRef and serviceAccountSecretRef
  #     instead of using the mig-controller detected kubeconfig. Refer to mig-cluster-aws.yaml for an example.
  isHostCluster: true

  # [!] Change refresh to 'true' to force a manual reconcile
  refresh: false
  ```

  Remote Mig cluster:

  ```
  apiVersion: migration.openshift.io/v1alpha1
kind: MigCluster
metadata:
  labels:
    controller-tools.k8s.io: "1.0"
  name: migcluster-remote
  namespace: openshift-config
spec:
  # [!] Change isHostCluster to 'true' if you'll be running the controller on this cluster.
  #     Setting 'isHostCluster' to true will bypass using the clusterRef and serviceAccountSecretRef below.
  isHostCluster: false

  url: "https://my-remote-cluster-ip.nip.io:8443"

  serviceAccountSecretRef:
    name: sa-token-remote
    namespace: openshift-config

  # [!] Change refresh to 'true' to force a manual reconcile
  refresh: false
  ```
- spec.azureResourceGroup: For azure clusters -- it's the resource group that in-cluster volumes use.

- spec.caBundle: If the migcluster needs SSL verification for connections a user can supply a custom CA bundle.

- spec.exposedRegistryPath: Stores the path of registry route when using direct migration.

- spec.insecure: If set false, user will need to provide CA bundle for TSL connection to the remote cluster.

- spec.isHostCluster: Specifies if the cluster is host (where the controller is installed) or not. This is a required field.

- spec.refresh: If set True, forces the controller to run a full suite of validations on migcluster.

- spec.restartRestic: An override setting to tell the controller that the source cluster restic needs to be restarted after stage pod creation.

- spec.serviceAccountSecretRef: ObjectReference contains enough information to let you inspect or modify the referred object.

- spec.url: Stores the url of the remote cluster. The field is only required for the source cluster object.

## MigHooks

```
apiVersion: migration.openshift.io/v1alpha1
kind: MigHook
metadata:
  generateName: test-
  name: test-btmv5
  namespace: openshift-migration
spec:
  custom: false
  image: 'quay.io/konveyor/hook-runner:latest'
  playbook: >-
    LSBuYW1lOiBTbGVlcCBmb3IgMTAgc2Vjb25kcyBhbmQgY29udGludWUgd2l0aCBwbGF5CiAgd2FpdF9mb3I6CiAgIadsfwerq0OiAxMA==
  targetCluster: source
```

- spec.activeDeadlineSeconds: Specifies the highest amount of time for which the hook will run.

- spec.custom: Implies whether the hook is a custom Ansible playbook or a pre-built image. The value of this field is required. This is a required field.

- spec.image: Specifies the image of the hook to be executed. This is a required field.

- spec.playbook: Specifies the contents of the custom Ansible playbook in base64 format, it is used in conjunction with the custom boolean flag.

- spec.targetCluster: Specifies the cluster on which the hook is to be executed. This is a required field.



## MigMigrations

```
apiVersion: migration.openshift.io/v1alpha1
kind: MigMigration
metadata:
  labels:
    controller-tools.k8s.io: "1.0"
  name: migmigration-sample
  namespace: openshift-migration
spec:
  # [!] Set 'canceled: true' will cancel the migration
  canceled: false
  # [!] Set 'rollback: true' will rollback the migration's plan
  rollback: true
  # [!] Set 'stage: true' to run a 'Stage Migration' and skip quiescing of Pods on the source cluster.
  stage: false
  # [!] Set 'quiescePods: true' to scale down Pods on the source cluster after the 'Backup' stage of a migration has finished
  quiescePods: false
  # [!] Set 'keepAnnotations: true' to retain labels and annotations applied by the migration
  keepAnnotations: false

  migPlanRef:
    name: migplan-sample
    namespace: openshift-migration
```

- spec.canceled: Invokes the cancel migration operation, when set to true the migration controller switches to cancel itinerary.

- spec.keepAnnotations: Specifies whether to retain the annotations set by the migration controller or not.

- spec.migPlanRef: ObjectReference contains enough information to let you inspect or modify the referred object.

- spec.quiescePods: Specifies whether to quiesce the application pods before migration or not.

- spec.rollback: Invokes the rollback migration operation, when set to true the migration controller switches to rollback itinerary.

- spec.stage:Invokes the stage operation, when set to true the migration controller switches to stage itinerary. This is a required field.

- spec.verify: Specifies whether to verify the health of the migrated pods or not.


## MigPlans

```
apiVersion: migration.openshift.io/v1alpha1
kind: MigPlan
metadata:
  labels:
    controller-tools.k8s.io: "1.0"
  name: migplan-sample
  namespace: openshift-migration
spec:

  srcMigClusterRef:
    name: migcluster-local
    namespace: openshift-migration

  destMigClusterRef:
    name: migcluster-remote
    namespace: openshift-migration
  
  hooks:
    - executionNamespace: openshift-migration
      phase: PreBackup
      reference:
        name: test-6h58j
        namespace: openshift-migration
      serviceAccount: migration-controller

  indirectImageMigration: true

  indirectVolumeMigration: false

  migStorageRef:
    name: migstorage-sample
    namespace: openshift-migration

  # [!] Change namespaces to adjust which OpenShift namespaces should be migrated from source to destination cluster
  namespaces:
  - nginx-example

  # [!] Change refresh to 'true' to force a manual reconcile
  refresh: false
```

- spec.closed: If the migration was successful for a migplan, this value can be set True indicating that after one successful migration no new migrations can be carried out for this migplan.

- spec.destMigClusterRef: ObjectReference contains enough information to let you inspect or modify the referred object.

- spec.hooks: Holds a reference to a MigHook along with the desired phase to run it in.
    -   spec.hooks.executionNamespace: Holds the name of the namespace where hooks should be implemented.
    -   spec.hooks.phase: Indicates the phase when the hooks will be executed.

- spec.indirectImageMigration: If set True, disables direct image migrations.

- spec.indirectVolumeMigration: If set True, disables direct volume migrations.

- spec.migStorageRef: ObjectReference contains enough information to let you inspect or modify the referred object.

- spec.namespaces: A list of string of all the namespaces to be included in migration.

- spec.persistentVolumes: Holds list of all the persistent volumes found for the namespaces included in migplan. Each entry in the list is a persistent volume with the information. Name - The PV name. Capacity - The PV storage capacity. StorageClass - The PV storage class name. Supported - Lists of what is supported. Selection - Choices made from supported. PVC - Associated PVC. NFS - NFS properties. staged - A PV has been explicitly added/updated.

- spec.refresh: If set True, the controller is forces to check if the migplan is in Ready state or not.

- spec.srcMigClusterRef: ObjectReference contains enough information to let you inspect or modify the referred object.


## MigStorages

```
apiVersion: migration.openshift.io/v1alpha1
kind: MigStorage
metadata:
  labels:
    controller-tools.k8s.io: "1.0"
  name: migstorage-sample
  namespace: openshift-migration
spec:
  backupStorageProvider: aws
  volumeSnapshotProvider: aws
  
  backupStorageConfig:
    # [!] Change awsBucketName to contain the S3 bucket name to be used for migration
    awsBucketName: foo
    # [!] Change awsRegion to contain the region name (e.g. 'us-east-1') where the S3 bucket presides
    awsRegion: foo
    credsSecretRef:
      namespace: openshift-config
      name: migstorage-creds

    # Optional backupStorageConfig parameters
    #awsKmsKeyId: foo
    #awsPublicUrl: foo
    #awsSignatureVersion: "4"

  volumeSnapshotConfig:
    # [!] Change awsRegion to contain the region name (e.g. 'us-east-1') where Volume Snapshots should take place
    awsRegion: foo
    credsSecretRef:
      namespace: openshift-config
      name: migstorage-creds

  # [!] Change refresh to 'true' to force a manual reconcile
  refresh: false

```

- spec.backupStorageConfig: Defines config for creating and storing Backups. This is a required field.

- spec.backupStorageProvider: Holds the provider name whose object storage is used for backup storage location. This is a required field.

- spec.refresh: A boolean used to trigger a reconcile for the MigStorage CRD.

- spec.volumeSnapshotConfig: Defines config for taking Volume Snapshots.

- spec.volumeSnapshotProvider: Holds the provider name whose object storage is used for backup storage location.
