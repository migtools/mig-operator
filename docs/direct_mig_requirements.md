# Direct Migration Requirements

Direct Migration is available as a feature from Migration Toolkit for Containers (MTC) release 1.4.0. There are two parts of the Direct Migration - Direct 
Volume Migration and Direct Image Migration. Direct Migration enables the migration of persistent volumes and internal
images directly from the source cluster to the destination cluster without an intermediary replication repository (object storage)
There are some requirements which are to be satisfied before you can use the Direct Migration feature of MTC.

1. The clusters (source as well as destination) involved in the migration should expose their respective internal registries
for external traffic.

2. The remote source and destination clusters should be able to communicate via OpenShift routes on port 443.

3. The exposed registry route must be configured in the source and destination MigClusters, this can be done by specifying
the `spec.exposedRegistryPath` field or via the MTC UI. Please keep in mind that if the destination cluster is same as the 
host cluster (where migration controller exists), in such a scenario there is no need to configure the exposed registry 
route for that particular MigCluster. Also, `spec.exposedRegistryPath` is only required for *Direct Image Migration* and not *Direct Volume Migration.*

4. The two spec flags in MigPlan CR - `indirectImageMigration` and `indirectVolumeMigration` , both of these flags need to
be set to `false` for Direct Migration to be executed. Default value for these flags is `false`.

**Note:** The Direct Migration feature of MTC uses the Rsync utility, for more details pertaining to its usage, configuration and
know issues please refer the [Rsync Configuration](usage/RsyncConfiguration.md) document.
