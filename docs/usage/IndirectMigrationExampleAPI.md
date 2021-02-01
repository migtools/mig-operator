#Indirect Migration using API

Please setup, deploy and configure the Migration Operator as well as the Migration Controller
appropriately before proceeding further.

We will be performing a migration of a Django Application consisting of persistent volumes and image streams, this
application is already present on the source cluster used in the following migration example.

The steps to perform a InDirect Migration using Migration Toolkit for Containers (MTC) are as follows:

**1. Add Migration clusters**<br>
This step involves addition and configuration of the source as well as the destination clusters 
involved in the migration.

- At first, let's create a MigCluster instance in order to add the destination cluster. 
In our case this cluster is also the host cluster where Migration controller resides and is
already configured, you do not need to add this cluster. 

Store the destination MigCluster yaml manifest in `destination-migcluster.yaml`:
```
apiVersion: migration.openshift.io/v1alpha1
kind: MigCluster
metadata:
  name: host
  namespace: openshift-migration
spec:
  isHostCluster: true
```

Command to create destination MigCluster instance:
``` 
oc create -f destination-migcluster.yaml
```

- Now let's add the second cluster, that is the source cluster.

Store the source MigCluster yaml manifest in `source-migcluster.yaml`:
``` 
apiVersion: migration.openshift.io/v1alpha1
kind: MigCluster
metadata:
  name: src-ocp-3-cluster
  namespace: openshift-migration
spec:
  insecure: true
  isHostCluster: false
  serviceAccountSecretRef:
    name: src-ocp-3-cluster-k2vnk
    namespace: openshift-config
  url: 'https://master.ocp3.mycluster.com/'
```
Command to create source MigCluster instance:
``` 
oc create -f source-migcluster.yaml
```

Before moving ahead, please verify that both the MigCluster instances are in a `Ready` state and there are no 
critical conditions associated with these instances, if there are any issues or critical conditions present, please 
resolve them.

**2. Configure Migration storage**<br>
This step involves the configuration of the object storage to be utilized during the 
migration.

For our example we will be configuring AWS S3 object storage as our MigStorage.
This step is to be carried out on host cluster (where the Migration Controller resides).

Store the MigStorage yaml manifest in `migstorage.yaml`

``` 
apiVersion: migration.openshift.io/v1alpha1
kind: MigStorage
metadata:
  name: aws-s3
  namespace: openshift-migration
spec:
  backupStorageConfig:
    awsBucketName: mybucket-6109f5e9711c8c58131acdd2f490f451
    credsSecretRef:
      name: aws-s3-jg74j
      namespace: openshift-config
  backupStorageProvider: aws
  volumeSnapshotConfig:
    credsSecretRef:
      name: aws-s3-jg74j
      namespace: openshift-config
  volumeSnapshotProvider: aws
```

Command to create MigStorage instance:
``` 
oc create -f migstorage.yaml
```

**Note:** Please ensure that the secrets referenced in the `credsSecretRef` of 
`backupStorageConfig` as well as the `volumeSnapshotConfig:` exist in the specifications provided.

Once again, before moving further please ensure that the MigStorage instance is in `Ready` state 
and there are not critical conditions associated with the same, if there are any issues or critical conditions present,
please resolve them.

**3. Create Migration Plan**<br>
Again, switch the context to host cluster (where the Migration controller is deployed), let's create an
instance of MigPlan.

The yaml manifest of MigPlan consists of details pertaining to cluster references, storage reference,
namespace reference of the application to be migration as well as the persistent volumes
associated with the application to be migrated.

Store the MigPlan yaml manifest in `migplan.yaml`

``` 
apiVersion: migration.openshift.io/v1alpha1
kind: MigPlan
metadata:
  name: mtc-api-example
  namespace: openshift-migration
spec:
  destMigClusterRef:
    name: host
    namespace: openshift-migration
  indirectImageMigration: true
  indirectVolumeMigration: true
  migStorageRef:
    name: aws-s3
    namespace: openshift-migration
  namespaces:
    - django-app
  persistentVolumes:
    - capacity: 1Gi
      name: pvc-af0be31d-5b39-11eb-aceb-029d2246b63f
      pvc:
        accessModes:
          - ReadWriteOnce
        hasReference: true
        name: postgresql
        namespace: django-app
      selection:
        action: copy
        copyMethod: filesystem
        storageClass: gp2
      storageClass: glusterfs-storage
      supported:
        actions:
          - copy
          - move
        copyMethods:
          - filesystem
          - snapshot
  srcMigClusterRef:
    name: src-ocp-3-cluster
    namespace: openshift-migration
```

Command to create MigPlan instance:
``` 
oc create -f migplan.yaml
```

Again, ensure that the MigPlan instance is in a `Ready` state and there no critical 
conditions associated before going forward, if there are any issues or critical conditions present, please 
resolve them.

**Note:** Please ensure that the flags `indirectVolumeMigration` as well as the 
`indirectVolumeMigration`  are set to `true` in order to carryout a purely _Indirect Migration._

**4. Execute Migration**<br>

Finally, let's execute the migration from source cluster to destination cluster, for this purpose we need to
create an instance of MigMigration.

Store the MigMigration yaml manifest in `migmigration.yaml`:

``` 
apiVersion: migration.openshift.io/v1alpha1
kind: MigMigration
metadata:
  name: 982ba500-5b3a-11eb-bd49-4734b4f50789
  namespace: openshift-migration
spec:
  migPlanRef:
    name: mtc-api-example
    namespace: openshift-migration
  quiescePods: true
  stage: false
```
Command to create MigMigration instance:
``` 
oc create -f migmigration.yaml
```

**Note:** You can monitor the progress of the Migration itinerary by performing an `oc describe` of the MigMigration
instance, it gives a holistic view of the ongoing migration phase.