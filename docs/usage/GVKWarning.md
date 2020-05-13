## OpenShift API incompatibility warnings

Every OpenShift resource object has a *Group-Version-Kind (GVK)*, and each GVK has an API schema. As OpenShift features stabilize over time, alpha and beta OpenShift API GVKs are deprecated in favor of stable APIs. 

```
apiVersion: extensions/v1beta1
kind: Deployment
```

If you're migrating apps from an OpenShift 3.x cluster over to OpenShift 4.x, its likely that your migration will be affected by API deprecations due to the large gap in underlying Kubernetes versions.

More info on [Kubernetes 1.16 API deprecations](https://kubernetes.io/blog/2019/07/18/api-deprecations-in-1-16/).


## CAM API incompatibility warning system

CAM provides a warning system to help you realize when a Migration Plan you've configured will be migrating resources with GVKs unsupported on the destination cluster. 

 - Web UI - warning displayed on the final page of the Migration Plan wizard.
 - CLI - warning displayed as Warning Condition on the MigPlan resource.

```
$ oc get migplan move-my-cronjobs

apiVersion: migration.openshift.io/v1alpha1
kind: MigPlan
metadata:
  name: move-my-cronjobs
  namespace: openshift-migration
spec:
  [...]
  namespaces:
  - phronetic
status:
  [...]
  conditions:
  - category: Warn
    lastTransitionTime: 2020-04-30T17:16:23Z
    message: 'Some namespaces contain GVKs incompatible with destination cluster.
      See: `incompatibleNamespaces` for details'
    status: "True"
    type: GVKsIncompatible
  incompatibleNamespaces:
  - gvks:
    - group: batch
      kind: cronjobs
      version: v2alpha1
    - group: batch
      kind: scheduledjobs
      version: v2alpha1
```

## Migrating workloads containing GVK incompatibilities

If CAM detects that an OpenShift resource can't be migrated to the destination cluster, you can still run the migration, but the resources with incompatible API GVKs will be skipped on the restore phase and won't be available after the migration runs.

#### Steps to migrate resources with incompatible GVKs

1. Download the respective Velero "Initial Backup" archive
2. Manually extract the Backup archive YAML contents
3. Run `oc convert` in offline mode on the extracted resources to convert them to the desired version
4. Restore the converted resources with `oc create -f`

Further instructions on this process can be found in an upcoming blog post.
