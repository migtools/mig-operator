# Migration Log Reader

When running a container migration with MTC, logs may be written from migration related Pods:

 - mig-controller
 - velero
 - restic

Aggregated and collated Pod logs can be viewed through a special `migration-log-reader` Pod, deployable through mig-operator on MTC 1.4.0+.

## Deploying migration-log-reader

The migration-log-reader Pod will deploy on MTC 1.4.0+ if the `MigrationController` resource is set as shown below:

```
spec:
  [...]
  migration_log_reader: true
  [...]
```

## Viewing logs

Colorized logs:
```
oc logs -f --selector logreader=mig -n openshift-migration -c color
```

Plain logs:
```
oc logs -f --selector logreader=mig -n openshift-migration -c plain
```

