## Enabling support for Snapshots with CAM
To use cloud-provider snapshots with CAM, it is important to ensure that all of
the necessary preconditions are met. This document contains provider-specific
configuration information required for snapshot support.

## Snapshot vs Filesystem Copy
The user has the ability to select **snapshot** or **filesystem** as the **Copy
Method** of a selected Persistent Volume.

**Snapshot** Copy 
 - Uses cloud-provider native snapshot API to snapshot the underlying PV disk
 - Fast and robust, but requires a compatible OpenShift cluster pair
   - Requires PVs provisioned by public cloud-providers (AWS, GCP, Azure)
   - Requires source and target clusters on the same cloud-provider + region
 - See the **Prerequisites** section below for more information

**Filesystem** Copy 
 - Uses Restic to take a copy of the PV filesystem
 - Works independently of the backing storage type for PV being copied


### Prerequisites
The CAM web console must contain the following:
* Source cluster
* Target cluster, which is added automatically during the CAM tool installation
* Both source and target cluster must be running on the same cloud provider and in the same region
  * For each Azure cluster, provide the unique Resource Group that the cluster was provisioned into. For more information see  [Cluster.md](https://github.com/konveyor/mig-operator/blob/master/docs/usage/Cluster.md#procedure)
* Replication repository
  * S3
    * [Configure the S3 Replication Repository](https://github.com/konveyor/mig-operator/blob/master/docs/usage/ObjectStorage.md#s3-object-storage)
  * GCP
    * [Configure the GCP Storage Replication Repository](https://github.com/konveyor/mig-operator/blob/master/docs/usage/ObjectStorage.md#gcp-object-storage)
  * Azure
    * [Configure the Azure Storage Replication Repository](https://github.com/konveyor/mig-operator/blob/master/docs/usage/ObjectStorage.md#azure-object-storage)

### Specifying Snapshot Usage in Migration Plan
When creating the migration plan, you can now specify **snapshot** as the
**Copy Method** when specifying the storage class for the migrated Persistent
Volumes. For more information, see step #11 in the [Plan Procedure
document](https://github.com/konveyor/mig-operator/blob/master/docs/usage/Plan.md#procedure).

---
[Home](./README.md)
