#Direct Migration using API

Please setup, deploy and configure the Migration Operator as well as the Migration Controller
appropriately before proceeding further.

We will be performing a migration of a Django Application consisting of persistent volumes and image streams, this
application is already present on the source cluster used in the following migration example.

The steps to perform a Direct Migration using Migration Toolkit for Containers (MTC) are as follows:

**1. Add Migration clusters**<br>
This step involves addition and configuration of the source as well as the destination clusters 
involved in the migration.

At first, let's create a MigCluster instance in order to add the destination cluster. 
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

Before adding the remote source cluster, we need to create a Service Account Secret on the host cluster. This is needed so
that the Migration Controller can perform migration operations and actions on the remote source cluster.

Store the Service Account Secret yaml manifest in `sa-secret-remote.yaml`
```
apiVersion: v1
kind: Secret
metadata:
  name: sa-token-remote
  namespace: openshift-config
type: Opaque
data:
  # [!] Change saToken to contain a base64 encoded SA token with cluster-admin 
  #     privileges on the remote cluster.
  #     `oc sa get-token migration-controller -n openshift-migration | base64 -w 0`
  saToken: <your-base64-encoded-aws-sa-token-here>
``` 

Command to create Service Account Secret instance:
``` 
oc create -f sa-secret-remote.yaml
```

Now let's add the second cluster, that is the source cluster.

Store the source MigCluster yaml manifest in `source-migcluster.yaml`:
``` 
apiVersion: migration.openshift.io/v1alpha1
kind: MigCluster
metadata:
  name: src-ocp-3-cluster
  namespace: openshift-migration
spec:
  exposedRegistryPath: docker-registry-default.apps.mycluster-ocp3.mg.dog8code.com
  insecure: true
  isHostCluster: false
  serviceAccountSecretRef:
    name: sa-token-remote
    namespace: openshift-config
  url: 'https://master.ocp3.mycluster.com/'
```
Command to create source MigCluster instance:
``` 
oc create -f source-migcluster.yaml
```

**Note:** Please ensure that the `exposedRegistryPath` is appropriately specified, it is a must for
facilitating **Direct Image Migration.** Also, make sure the `serviceAccountSecretRef` details refer to
the same Service Account Secret we created before addition of the source cluster.

Before moving ahead, please verify that both the MigCluster instances are in a `Ready` state and there are no 
critical conditions associated with these instances, if there are any issues or critical conditions present, please 
resolve them.

**2. Configure Migration storage**<br>
This step involves the configuration of the object storage to be utilized during the 
migration.

For our example we will be configuring AWS S3 object storage as our MigStorage.

Before creating the MigStorage instance, we need a Secret to hold the storage authentication details.

Store the storage Secret yaml manifest in `mig-storage-creds.yaml`

```
---
apiVersion: v1
kind: Secret
metadata:
  namespace: openshift-config
  name: migstorage-creds
type: Opaque
data:
  # [!] If using S3 / AWS, change aws-access-key-id and aws-secret-access-key to contain the base64
  #      encoded keys needed to authenticate with the storage specified in migstorage.
  
  # [!] CAUTION: It's easy to miss the step of base64 encoding your AWS credentials when inputting
  #     them to this secret. since AWS credentials are base64 compatible already. Be _sure_ to run
  #     `echo -n "<key>" | base64 -w 0` on your access and secret key before providing them below.
  
  # [Note] these credentials will be injected into cloud-credentials in the 'velero' namespace.
  aws-access-key-id: aGVsbG8K
  aws-secret-access-key: aGVsbG8K
```

Command to create MigStorage Secret instance:
``` 
oc create -f mig-storage-creds.yaml
```

Now, lets create the MigStorage instance.

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
      name: migstorage-creds
      namespace: openshift-config
  backupStorageProvider: aws
  volumeSnapshotConfig:
    credsSecretRef:
      name: migstorage-creds
      namespace: openshift-config
  volumeSnapshotProvider: aws
```

Command to create MigStorage instance:
``` 
oc create -f migstorage.yaml
```

**Note:** Please ensure that the secrets referenced in the `credsSecretRef` of 
`backupStorageConfig` as well as the `volumeSnapshotConfig:` exist in the specifications provided (in our example it's the
same secret we created before creation of MigStorage instance).

Once again, before moving further please ensure that the MigStorage instance is in `Ready` state 
and there are not critical conditions associated with the same, if there are any issues or critical conditions present,
please resolve them.

**3. Create Migration Plan**<br>
Now, switch the context to host cluster (where the Migration controller is deployed), let's create an
instance of MigPlan.

The yaml manifest of MigPlan consists of details pertaining to cluster references, storage reference,
namespace reference of the application to be migration as well as the persistent volumes
associated with the application to be migrated.

Store the MigPlan yaml manifest in `migplan.yaml`

``` 
apiVersion: migration.openshift.io/v1alpha1
kind: MigPlan
metadata:
  name: mtc-api-example-migplan
  namespace: openshift-migration
spec:
  destMigClusterRef:
    name: host
    namespace: openshift-migration
  indirectImageMigration: false
  indirectVolumeMigration: false
  migStorageRef:
    name: aws-s3
    namespace: openshift-migration
  namespaces:
    - django-app
  persistentVolumes:
    - capacity: 1Gi
      name: pvc-336ecd0a-5ae1-11eb-aceb-029d2246b63f
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
        verify: false
      storageClass: glusterfs-storage
      supported:
        actions:
          - copy
          - move
        copyMethods:
          - filesystem
          - snapshot
  refresh: true
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
`indirectVolumeMigration`  are set to `false` in order to carryout a purely _Direct Migration._

**4. Execute Migration**<br>

Finally, let's execute the migration from source cluster to destination cluster, for this purpose we need to
create an instance of MigMigration.

Store the MigMigration yaml manifest in `migmigration.yaml`:

``` 
apiVersion: migration.openshift.io/v1alpha1
kind: MigMigration
metadata:
  name: mtc-api-example-migration
  namespace: openshift-migration
spec:
  migPlanRef:
    name: mtc-api-example-migplan
    namespace: openshift-migration
  quiescePods: true
  stage: false
```
Command to create MigMigration instance:
``` 
oc create -f migmigration.yaml
```

**Note:** You can monitor the progress of the Migration itinerary by performing an `oc describe` of the MigMigration
instance, it gives a holistic view of the ongoing migration phase, further more, if you
want to monitor the progress of the persistent volumes associated with the application migrated,
you can perform an `oc describe` on DirectVolumeMigrationProgress instance, it is created per PV.
