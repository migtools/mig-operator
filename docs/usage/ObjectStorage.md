## Object Storage Setup

CAM components use object storage as temporary scratch space when performing migrations. This document covers the process of setting up compatible Object Storage to use with CAM on a cloud provider of your choice. The Object Storage credentials obtained from this document are needed for *configuring CAM Replication Repositories*.


### Supported Providers


- **S3 Bucket** *(Any storage medium that exposes an `S3 compatible` interface)*
- **GCP Storage Bucket**
- **Azure Storage Container**

If you wish to use S3-compatible storage, we have tested AWS S3, NooBaa, and Minio successfully. Using NooBaa or Minio enables migrations when Cloud Provider connectivity isn't possible, or if self-hosting is desired for other reasons.

GCP Storage Buckets and Azure Storage Containers have also been tested successfully. We recommend provisioning Object Storage on the same Cloud Provider where OpenShift clusters are running to avoid additional data costs and increase access speeds.


## S3 Object Storage

This section covers setup of S3 Object Storage on these providers:
 - NooBaa S3
 - AWS S3

### S3 Object Storage Setup with NooBaa

NooBaa can run on an OpenShift cluster to provide an S3 compatible endpoint for migration scratch space. We recommend loading NooBaa onto the destination cluster. NooBaa is especially useful when clusters don't have network connectivity to AWS S3.

1. Download the noobaa v1.1.0 CLI from https://github.com/noobaa/noobaa-operator/releases.
2. Ensure you have available PVs with capacities of 10 Gi, 50Gi. The NooBaa installer will create PVCs to consume these PVs.
```
# NooBaa PV usage requirements
NAME                          CAPACITY   ACCESS MODES
logdir-noobaa-core-0          10Gi       RWO
mongo-datadir-noobaa-core-0   50Gi       RWO,RWX
```

3. Using the `noobaa` CLI tool, install NooBaa to the _destination cluster_. Take note of the output values for 'AWS_ACCESS_KEY_ID' and 'AWS_SECRET_ACCESS_KEY' that will be produced for a later step. Also note that an initial bucket has been created called 'first.bucket'
```
$ noobaa install --namespace noobaa

[...]
INFO[0002] System Status:
INFO[0003] ✅ Exists: NooBaa "noobaa"
INFO[0003] ✅ System Phase is "Ready"
[...]
INFO[0003] AWS_ACCESS_KEY_ID: ygeJ5GzAwbBJiSukw8Lv
INFO[0003] AWS_SECRET_ACCESS_KEY: so2C5X/ttRhiX00DZrOnv0MxV0r5VlOkYmptTU91
```

4. Expose the NooBaa S3 service to hosts outside the cluster. This is necessary so that both the _source_ and _destination_ cluster will be able to connect to S3 scratch space.
```
$ oc expose svc s3 -n noobaa
```

5. Take note of the NooBaa S3 route URL for a later step.
```
$ oc get route s3 -n noobaa -o jsonpath='http://{.spec.host}'
http://s3-noobaa.apps.destcluster.com
```

6. If you have the [`aws` CLI](https://aws.amazon.com/cli/) installed, you can use it to test that NooBaa is serving the S3 bucket 'first.bucket' from the route obtained in the previous step using the S3 credentials generated during NooBaa install.
```
$ AWS_ACCESS_KEY_ID="ygeJ5GzAwbBJiSukw8Lv" \
AWS_SECRET_ACCESS_KEY="so2C5X/ttRhiX00DZrOnv0MxV0r5VlOkYmptTU91" \
aws s3 ls --endpoint http://s3-noobaa.apps.destcluster.com

2019-09-04 13:21:20 first.bucket
```

### Object Storage Setup with AWS S3

AWS S3 can serve as migration scratch space as long as both clusters involved in a migration have connectivity to AWS.


#### Create S3 bucket

```bash
aws s3api create-bucket \
    --bucket <YOUR_BUCKET_NAME> \
    --region us-east-1
```

#### Create IAM user

1. Create the IAM user:

    ```bash
    aws iam create-user --user-name velero
    ```

2. Attach policies to give `velero` the necessary permissions:

    ```bash
    # Use this policy to grant access to ec2 volumes for PV snapshot purposes
    cat > velero-ec2-snapshot-policy.json <<EOF
    {
        "Version": "2012-10-17",
        "Statement": [
            {
                "Effect": "Allow",
                "Action": [
                    "ec2:DescribeVolumes",
                    "ec2:DescribeSnapshots",
                    "ec2:CreateTags",
                    "ec2:CreateVolume",
                    "ec2:CreateSnapshot",
                    "ec2:DeleteSnapshot"
                ],
                "Resource": "*"
            }
        ]
    }
    EOF
    ```

    ```bash
    # [Option 1] Grant access to a single S3 bucket. Fill in value for `${BUCKET}`.

    BUCKET=<YOUR_BUCKET_NAME>
    cat > velero-s3-policy.json <<EOF
    {
        "Version": "2012-10-17",
        "Statement": [
            {
                "Effect": "Allow",
                "Action": [
                    "s3:GetObject",
                    "s3:DeleteObject",
                    "s3:PutObject",
                    "s3:AbortMultipartUpload",
                    "s3:ListMultipartUploadParts"
                ],
                "Resource": [
                    "arn:aws:s3:::${BUCKET}/*"
                ]
            },
            {
                "Effect": "Allow",
                "Action": [
                    "s3:ListBucket",
                    "s3:GetBucketLocation",
                    "s3:ListBucketMultipartUploads"
                ],
                "Resource": [
                    "arn:aws:s3:::${BUCKET}"
                ]
            }
        ]
    }
    EOF
    ```

    ```bash
    # [Option 2] Grant access to all S3 buckets.

    cat > velero-s3-policy.json <<EOF
    {
        "Version": "2012-10-17",
        "Statement": [
            {
                "Effect": "Allow",
                "Action": [
                    "s3:GetObject",
                    "s3:DeleteObject",
                    "s3:PutObject",
                    "s3:AbortMultipartUpload",
                    "s3:ListMultipartUploadParts"
                ],
                "Resource": [
                    "arn:aws:s3:::*"
                ]
            },
            {
                "Effect": "Allow",
                "Action": [
                    "s3:ListBucket",
                    "s3:GetBucketLocation",
                    "s3:ListBucketMultipartUploads"
                ],
                "Resource": [
                    "arn:aws:s3:::*"
                ]
            }
        ]
    }
    EOF
    ```

    ```bash
    # Attach policy granting IAM access to EC2 EBS
    aws iam put-user-policy \
      --user-name velero \
      --policy-name velero-ebs \
      --policy-document file://velero-ec2-snapshot-policy.json
    ```

    ```bash
    # Attach policy granting IAM access to AWS S3
    aws iam put-user-policy \
      --user-name velero \
      --policy-name velero-s3 \
      --policy-document file://velero-s3-policy.json
    ```


3. Create an access key for the user:

    ```bash
    aws iam create-access-key --user-name velero
    ```

    The result should look like:

    ```json
     {
        "AccessKey": {
              "UserName": "velero",
              "Status": "Active",
              "CreateDate": "2017-07-31T22:24:41.576Z",
              "SecretAccessKey": <AWS_SECRET_ACCESS_KEY>,
              "AccessKeyId": <AWS_ACCESS_KEY_ID>
          }
     }
    ```

---

## GCP Object Storage

This section covers setup of Object Storage with [*GCP Storage Buckets*](https://cloud.google.com/storage/docs/creating-buckets).

### Create GCP Storage Bucket

```bash
# Set name of GCP Bucket
BUCKET=<BUCKET_NAME_HERE>

# Use the gsutil CLI to create the Storage Bucket
gsutil mb gs://$BUCKET/
```

### Create a GCP Service Account for Velero to assume

```bash
# Set PROJECT_ID var to the currently active project
PROJECT_ID=$(gcloud config get-value project)

# Create a GCP Service Account
gcloud iam service-accounts create velero \
    --display-name "Velero Storage"

# Set SERVICE_ACCOUNT_EMAIL to the email associated with the new Service Account
SERVICE_ACCOUNT_EMAIL=$(gcloud iam service-accounts list \
  --filter="displayName:Velero Storage" \
  --format 'value(email)')


# Grant necessary permissions to the new Service Account with the gsutil CLI
ROLE_PERMISSIONS=(
    compute.disks.get
    compute.disks.create
    compute.disks.createSnapshot
    compute.snapshots.get
    compute.snapshots.create
    compute.snapshots.useReadOnly
    compute.snapshots.delete
    compute.zones.get
)

gcloud iam roles create velero.server \
    --project $PROJECT_ID \
    --title "Velero Server" \
    --permissions "$(IFS=","; echo "${ROLE_PERMISSIONS[*]}")"

gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member serviceAccount:$SERVICE_ACCOUNT_EMAIL \
    --role projects/$PROJECT_ID/roles/velero.server

gsutil iam ch serviceAccount:$SERVICE_ACCOUNT_EMAIL:objectAdmin gs://${BUCKET}
```

### Dump GCP Service Account credentials

```bash
# Dump Service Account credentials to `credentials-velero` in the current directory
gcloud iam service-accounts keys create credentials-velero \
    --iam-account $SERVICE_ACCOUNT_EMAIL
```

### Creating a GCP Replication Repository from CAM UI

Keep track of the `credentials-velero` file you've just created, and refer to [ReplicationRepository.md](./ReplicationRepository.md).

### Creating a GCP Replication Repository from OpenShift CLI

If you'd prefer to create your Replication Repository from the OpenShift CLI, follow the directions below.

```bash
# Load b64 encoded contents of credentials into migstorage-gcp-creds secret

cat << EOF  > ./mig-storage-creds-gcp.yaml
---
apiVersion: v1
kind: Secret
metadata:
  namespace: openshift-migration
  name: migstorage-gcp-creds
type: Opaque
data:
  gcp-credentials: $(base64 credentials-velero -w 0)

EOF

oc create -f mig-storage-creds-gcp.yaml
```

```bash
# Create migstorage configured against GCP Storage Bucket

cat << EOF  > ./mig-storage-gcp.yaml
---
apiVersion: migration.openshift.io/v1alpha1
kind: MigStorage
metadata:
  labels:
    controller-tools.k8s.io: "1.0"
  name: migstorage-sample
  namespace: openshift-migration
spec:
  backupStorageProvider: gcp
  volumeSnapshotProvider: gcp

  backupStorageConfig:
    gcpBucket: ${BUCKET}

    credsSecretRef:
      namespace: openshift-migration
      name: migstorage-gcp-creds

  volumeSnapshotConfig:
    credsSecretRef:
      namespace: openshift-migration
      name: migstorage-gcp-creds

EOF

oc create -f mig-storage-gcp.yaml
```

---

## Azure Object Storage

This section covers setup of Object Storage with [*Azure Storage Containers*](https://docs.microsoft.com/en-us/azure/storage/blobs/storage-blobs-introduction).

Execute all steps below and then use the final command to dump all necessary credentials to a *credentials blob* for CAM to use.

### Create Azure Resource Group + Storage Account

All resources on Azure *must* exist inside a *Resource Group*.

```bash
# Set Azure Resource Group name
AZURE_RESOURCE_GROUP=Velero_Backups

# Use the Azure CLI to create the Resource Group in your desired region
az group create -n $AZURE_RESOURCE_GROUP --location CentralUS
```

Blob Storage resources on Azure *must* exist inside a *Storage Account*.

```bash
# Set Azure Storage Account Name
AZURE_STORAGE_ACCOUNT_ID=velerobackups

# Create Azure Storage Account
az storage account create \
     --name $AZURE_STORAGE_ACCOUNT_ID \
     --resource-group $AZURE_RESOURCE_GROUP \
     --sku Standard_GRS \
     --encryption-services blob \
     --https-only true \
     --kind BlobStorage \
     --access-tier Hot
```

### Create Azure Blob Storage Container

The *Blob Storage Container* will be used as a shared location for migration data between clusters.

```bash
# Set Azure Blob Storage Container name
BLOB_CONTAINER=velero

# Create Azure Blob Storage Container
az storage container create -n $BLOB_CONTAINER --public-access off --account-name $AZURE_STORAGE_ACCOUNT_ID
```

### Create Azure Service Principal

We want to grant CAM components the ability to access the Azure Blob Storage we've just created via a *Service Principal* credential set.

```bash
# Create Service Principal for CAM to act as
AZURE_SUBSCRIPTION_ID=`az account list --query '[?isDefault].id' -o tsv`
AZURE_TENANT_ID=`az account list --query '[?isDefault].tenantId' -o tsv`
AZURE_CLIENT_SECRET=`az ad sp create-for-rbac --name "velero" --role "Contributor" --query 'password' -o tsv`
AZURE_CLIENT_ID=`az ad sp list --display-name "velero" --query '[0].appId' -o tsv`
```

### Dump Azure Credentials

Dump secret credentials `credentials-velero`. We'll this into an *Azure Credentials* OpenShift Secret in the next.

```bash
cat << EOF  > ./credentials-velero
AZURE_SUBSCRIPTION_ID=${AZURE_SUBSCRIPTION_ID}
AZURE_TENANT_ID=${AZURE_TENANT_ID}
AZURE_CLIENT_ID=${AZURE_CLIENT_ID}
AZURE_CLIENT_SECRET=${AZURE_CLIENT_SECRET}
AZURE_RESOURCE_GROUP=${AZURE_RESOURCE_GROUP}
AZURE_CLOUD_NAME=AzurePublicCloud
EOF
```

### Creating an Azure Replication Repository from CAM UI

Keep track of the `credentials-velero` file you've just created, and refer to [ReplicationRepository.md](./ReplicationRepository.md)..

### Creating an Azure Replication Repository from OpenShift CLI

If you'd prefer to create your Replication Repository from the OpenShift CLI, follow the directions below.

```bash
# Load b64 encoded contents of credentials into migstorage-azure-creds secret

cat << EOF  > ./mig-storage-creds-azure.yaml
---
apiVersion: v1
kind: Secret
metadata:
  namespace: openshift-migration
  name: migstorage-azure-creds
type: Opaque
data:
  azure-credentials: $(base64 credentials-velero -w 0)

EOF

oc create -f mig-storage-creds-azure.yaml
```

```bash
# Create migstorage configured against Azure Blob Storage

cat << EOF  > ./mig-storage-azure.yaml
---
apiVersion: migration.openshift.io/v1alpha1
kind: MigStorage
metadata:
  labels:
    controller-tools.k8s.io: "1.0"
  name: migstorage-sample
  namespace: openshift-migration
spec:
  backupStorageProvider: azure
  volumeSnapshotProvider: azure

  backupStorageConfig:
    azureStorageAccount: ${AZURE_STORAGE_ACCOUNT_ID}
    azureStorageContainer: ${BLOB_CONTAINER}
    azureResourceGroup: ${AZURE_RESOURCE_GROUP}

    credsSecretRef:
      namespace: openshift-migration
      name: migstorage-azure-creds

  volumeSnapshotConfig:
    azureResourceGroup: ${AZURE_RESOURCE_GROUP}
    azureApiTimeout: 30s
    credsSecretRef:
      namespace: openshift-migration
      name: migstorage-azure-creds

EOF

oc create -f mig-storage-azure.yaml
```


---
[Home](./README.md)
