## Enabling support for Snapshots with CAM
To use cloud-provider snapshots with CAM, it is important to ensure that all of
the necessary preconditions are met. This document contains provider-specific
configuration information required for snapshot support.

## Snapshot vs Filesystem Copy
The user has the ability to select **snapshot** or **filesystem** as the **Copy
Method** of a selected Persistent Volume.

**snapshot** uses the cloud-provider native snapshot API to take snapshots of
the Persistent Volume. This only works for cloud provider Persistent Volumes
and it is required that both the source and target clusters are in the same
region. Please see the **Prerequisites** section below for more information.

**filesystem** uses Restic to take a copy of the filesystem and is completely
independent of the type of Persistent Volume being copied.

**snapshot** will generally provide the user with a faster copy, but is more
restrictive so be sure to read the below to find out if **snapshot** is right
for your migration plan.

### Prerequisites
The CAM web console must contain the following:
* Source cluster
* Target cluster, which is added automatically during the CAM tool installation
* Both source and target cluster must be running on the same cloud provider and in the same region
  * For each Azure cluster, provide the unique Resource Group that the cluster was provisioned into. For more information see  [Cluster.md](https://github.com/fusor/mig-operator/blob/master/docs/usage/Cluster.md#procedure)
* Replication repository
  * S3
    * [Configure the S3 Replication Repository](https://github.com/fusor/mig-operator/blob/master/docs/usage/ObjectStorage.md#s3-object-storage)
  * GCP
    * [Configure the GCP Storage Replication Repository](https://github.com/fusor/mig-operator/blob/master/docs/usage/ObjectStorage.md#gcp-object-storage)
  * Azure
    * [Configure the Azure Storage Replication Repository](https://github.com/fusor/mig-operator/blob/master/docs/usage/ObjectStorage.md#azure-object-storage)

### Specifying Snapshot Usage in Migration Plan
When creating the migration plan, you can now specify **snapshot** as the
**Copy Method** when specifying the storage class for the migrated Persistent
Volumes. For more information, see step #11 in the [Plan Procedure
document](https://github.com/fusor/mig-operator/blob/master/docs/usage/Plan.md#procedure).

---
[Home](./README.md)
