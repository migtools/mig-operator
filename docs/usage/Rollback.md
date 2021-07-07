# Rollback

MTC allows for rollback of Migration Plans. Rollback can be used to revert namespaces migrated by MTC Migration Plans back to their original states.

## Effects of rollback

Rolling back the migration plan will revert migrated resources and volumes to their original states and locations, including:

**Source Cluster**
- Restoring original replica counts (Un-Quiescing) on:
  - Deployments
  - DeploymentConfigs
  - StatefulSets
  - ReplicaSets
  - DaemonSets
  - CronJobs
  - Jobs

**Target Cluster**
- Deleting migrated resources

**Both Clusters**
- Deleting Velero Backups and Restores created during the migration
- Removing migration annotations and labels from:
  - PVs
  - PVCs
  - Pods
  - ImageStreams
  - Namespaces

### Leftover resources

As of MTC 1.5.0, Rollback intentionally leaves some resources created by Direct Volume Migration behind on the source and the target clusters. The leftover resources assist debugging a failed migration. All of these resources are automatically deleted when performing a subsequent migration and do not require manual cleanup.

On the source side, _ConfigMap_, _Secret_ and Rsync _Pods_ are left behind in each of the namespaces present in the _MigPlan_. 

On the destination side, _ConfigMap_, _Secret_, _Service_ and _Route_ resources are left behind in each of the namespaces present in the _MigPlan_.
 
Please note that these resources are only left behind when a migration fails for debugging purposes. A subsequent successful migration will automatically clean them up before reaching completion.

## Triggering a Rollback

### Rollback from the Web UI

From mig-ui, use the Migration Plan kebab menu (three dots) and click "Rollback". This will prompt you to confirm that you want to rollback all migration
actions taken by the Migration Plan so far.

### Rollback from the CLI

From the CLI, create a new MigMigration as with `rollback` and `stage` set as below. Make sure to set `migPlanRef` to the Migration Plan you want to rollback.

```
spec:
  migPlanRef:
    name: sample-plan
    namespace: openshift-migration
  rollback: true
  stage: false
```

### Monitoring Rollback Progress
A rollback is just another MigMigration resource, so you can monitor it from the Migration UI or CLI just like a normal migration. When viewing from the CLI, you'll
see that `ROLLBACK: true` is visible on a rollback migration.

```
$ oc get migmigration

NAME                                   READY   PLAN                 STAGE   ROLLBACK   ITINERARY   PHASE       AGE
7e5e83b0-35b8-11eb-9a62-5bf841982771           plan-demo-rollback   false              Final       Completed   4d17h
9798bcc0-396d-11eb-9f2d-53e4cf90519e           plan-demo-rollback   false   true       Rollback    Completed   2m54s
```
