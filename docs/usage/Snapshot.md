## Enabling support for Snapshots with CAM
When using cloud-provider snapshots with CAM, it is important to ensure that
all of the necessary preconditions are met. This document contains any
provider-specific configuration information required to get snapshot support.

### Prerequisites
The CAM web console must contain the following:
* Source cluster
* Target cluster, which is added automatically during the CAM tool installation
* Both source and target cluster must be running on the same cloud provider and in the same region
  * For Azure clusters, ensure that the Resource Group is the same for both the source and target cluster. For more information see step #4 [here](https://github.com/fusor/mig-operator/blob/master/docs/usage/Cluster.md#procedure)
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
