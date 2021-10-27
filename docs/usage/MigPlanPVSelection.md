# PV Selection for MigPlan volumes

After a MigPlan is created and in a `Ready` state, the PVs are
discovered. The `spec.persistentVolumes` block, which contains
metadata for the volumes to be migrated, is added to the MigPlan. You
can edit the default values of the `selection` block.

```
spec:
  persistentVolumes:
  - capacity: 10Gi
    name: pvc-2ba60854-8b27-11ea-a10d-02e5ce94b826
    pvc:
      accessModes:
      - ReadWriteOnce
      name: mysql
      namespace: mysql-persistent
    selection:
      action: copy
      copyMethod: filesystem
      storageClass: gp2
      verify: true
      accessMode: ReadWriteOnce
    storageClass: gp2
    supported:
      actions:
      - skip
      - copy
      - move
      copyMethods:
      - filesystem
      - snapshot
```

## Selection subfields

`selection` is the only user-editable field within
`persistentVolumes`. Any changes made elsewhere will be overwritten on
the next reconcile. Selection subfields include:

| Field        | Description | Default value | Allowed values |
|--------------|-------------|---------------|----------------|
| action       | The action to undertake for the volume. | If there is only one supported action, that value will be the default. If multiple actions are supported, then `copy` will be the default. | "move", "copy", "skip"|
| storageClass | The name of the storageclass to use for the PVC in the destination cluster. If left blank, the destination PVC will have no storage class. | For gluster or nfs source volumes, the default will be cephfs (for RWX) or cephrbd (for RWO) if available in the destination cluster. If unavailable (and for non-gluster, non-NFS volumes), default to the dest storageclass with the same provisioner (if available). If the above does not identify a particular storage class on dest, then the default storageclass for the dest cluster will be the default value. | Blank, or any name found in `status.destStorageClasses` |
| copyMethod   | The method which will be used to copy the volume. "snapshot" will use the underlying storage provider's snapshot method, while "filesystem" will use restic (for indirect migration), or rsync (for DVM). Snapshot copy requires the same underlying storage type to be used for both source and destination storage classes, that the storage provider matches the one used for the configured MigStorage, and that it be of a type which supports snapshots -- currently ebs, azure, and gcp. In addition, in most cases, both source and destination clusters must use the same provider region. | "filesystem" | "snapshot", "filesystem" |
| accessMode   | The access mode to use for the PVC in the destination cluster. If empty, the source cluster PVC's access mode will be used.   | <empty> | "ReadWriteOnce", "ReadWriteMany" |
| verify       | Whether or not to perform filesystem copy verification after copying volume contents. This is only applicable to filesystem copy. | false | true, false |

Note that `accessMode` is not currently exposed via the web user
interface, which means that editing the MigPlan yaml is the only way
to set this value.

The `supported` field will list the available actions and copy methods
for a given volume. The `selection` value for these fields must be
found there. For `storageClass`, the selection must be found in the
list from `migplan.status.destStorageClasses`.

## Other persistent volume fields

The full list of migplan `persistentVolumes` fields is as follows:

| Field             | Description |
|-------------------|-------------|
| name              | The name of the source PV |
| capacity          | The capacity of the source PV |
| storageClass      | The source PV storageClass |
| supported         | Supported actions and copy methods for the volume |
| selection         | User selections for the volume |
| pvc               | Source PVC metadata (see below for fields) |
| nfs               | NFS volumesource information copied from PV for NFS volumes |
| staged            | Internal field used for managing updates |
| proposedCapacity  | Used for PV resizing for nearly-full volumes |
| capacityConfirmed | Used for PV resizing for nearly-full volumes |

`pvc` subfields:

| Field        | Description |
|--------------|-------------|
| namespace    | The PVC namespace |
| name         | The PVC name |
| accessModes  | PVC accessModes |
| hasReference | Whether or not this PVC is referenced by pods or pod template resources |

## Storageclass status fields

`status.srcStorageClasses` and `status.destStorageClasses` follow the
same format. The value is a slice of storageclass values. The
`destStorageClasses` value is the one which is relevant to volume
selection. `selection.storageClass` must match the `name` field in one
of the values in `status.destStorageClasses`. The storage class subfields are as follows:

| Field       | Description |
|-------------|-------------|
| Name        | The name of the storage class |
| Provisioner | The provisioner used by the storage class |
| Default     | Whether or not this is the default storage class |
| AccessModes | A list of access modes that are known to be supported by the storage class (may not be complete) |
