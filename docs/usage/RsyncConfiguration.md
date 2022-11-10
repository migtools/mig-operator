
## Configuring Rsync for Direct Volume Migration

Direct Volume Migration (DVM) in MTC uses Rsync to synchronize files between the source and the target persistent volume using a direct connection between the two.

By default, the Rsync command used by DVM is optimized for clusters operating under ideal conditions. In some environments, the default Rsync configuration _may_ be inadequate. It _may_ also need fine-tuning for performance purposes. Moreover, users _may_ wish to use different modes for copying files than the default. To address all of these issues, MTC allows users override the default Rsync options through _MigrationController_ CR. See [this section](#configuring-rsync-command-using-migrationController-cr) for more information.

The users can also customize the resource limits on the Rsync Pods. See [this section](#configuring-resource-limits-on-rsync-pods) for more information. 

---

### Configuring Rsync command using MigrationController CR

_MigrationController_ CR exposes following variables to configure Rsync options in Direct Volume Migration (DVM):

| Variable            	| Type   	| Default                                          	| Description                                                                              	|
|---------------------	|--------	|--------------------------------------------------	|------------------------------------------------------------------------------------------	|
| rsync_opt_bwlimit   	| int    	| Not set                                          	| When set to a positive integer, `--bwlimit=<int>` option will be added to Rsync command. 	|
| rsync_opt_archive   	| bool   	| true                                             	| Sets `--archive` option in Rsync command.                                                	|
| rsync_opt_partial   	| bool   	| true                                             	| Sets `--partial` option in Rsync command.                                                	|
| rsync_opt_delete    	| bool   	| true                                             	| Sets `--delete` option in Rsync command.                                                 	|
| rsync_opt_hardlinks 	| bool   	| true                                             	| Sets `--hard-links` option is Rsync command.                                             	|
| rsync_opt_info      	| string 	| COPY2,DEL2,REMOVE2,SKIP2,FLIST2,PROGRESS2,STATS2 	| Enables detailed logging in Rsync Pod.                                                   	|
| rsync_opt_extras    	| string 	| Empty                                            	| Reserved for any other arbitrary options.                                                	|


Please note that the options set through the variables above are _global_ for all migrations. The configuration will take effect for all future migrations as soon as the operator successfully reconciles the _MigrationController_ CR. Any ongoing migration _may_ or _may not_ use the updated settings depending on which step it currently is in. Therefore, it is recommended that the settings be applied prior to running a migration. The users can always update the settings as needed.

Please use `rsync_opt_extras` variable with extreme caution. Any options passed using this variable will be appended to Rsync command as-is. Make sure you add whitespaces when specifying more than one options. Any human error in specifying options _may_ lead to failed migrations. But thanks to Migration Operator, you can always _correct_ your mistakes by updating the _MigrationController_ CR as many times as you want for future migrations.

Customizing `rsync_opt_info` flag can adversely affect MTC's progress reporting capabilities. However, removing progress reporting can have performance advantage. This option should only be used when the performance of Rsync operation is observed to be unaccepteable.  

Please note that the default configuration used by DVM is tested in variouos environments and is deemed apt for most production use cases provided the clusters are healthy and performing well. These configuration variables should be used in case the default settings do not work and fail the Rsync operation. Please see [known issues section](#known-issues) for more information about issues we have frequently observed and how to solve them using different Rsync configurations.

### Choosing alternate endpoint for data transfer

By default, DVM uses _OpenShift Route_ as an endpoint to transfer PV data to destination cluster. Endpoints are created on the destination cluster. Alternatively, if cluster topologies allow, users can choose other type of supported endpoints.

For every cluster, an endpoint can be configured by setting `rsync_endpoint_type` variable on respective cluster in _MigrationController_:

```
apiVersion: migration.openshift.io/v1alpha1
kind: MigrationController
metadata:
  name: migration-controller
  namespace: openshift-migration
spec:
  [...]
  rsync_endpoint_type: [NodePort|ClusterIP|Route]
```

> Note that this is a cluster specific config and it needs to be set on the destination cluster.

### Configuring resource limits on Rsync Pods

_MigrationController_ CR exposes following variables to configure resource usage requirements and limits on Rsync and Stunnel pods:

| Variable                  	      | Type   	| Default 	| Description                          	|
|---------------------------------  |--------	|---------	|--------------------------------------	|
| source_rsync_pod_cpu_limits	      | string 	| "1"     	| Source Rsync Pod's cpu limit         	|
| source_rsync_pod_memory_limits   	| string 	| "1Gi"   	| Source Rsync Pod's memory limit      	|
| source_rsync_pod_cpu_requests    	| string 	| "400m"  	| Source Rsync Pod's cpu requests      	|
| source_rsync_pod_memory_requests 	| string 	| "1Gi"   	| Source Rsync Pod's memory requests   	|
| target_rsync_pod_cpu_limits   	  | string 	| "1"     	| Target Rsync Pod's cpu limit         	|
| target_rsync_pod_cpu_requests 	  | string 	| "400m"  	| Target Rsync Pod's cpu requests      	|
| target_rsync_pod_memory_limits   	| string 	| "1Gi"   	| Target Rsync Pod's memory limit      	|
| target_rsync_pod_memory_requests 	| string 	| "1Gi"   	| Target Rsync Pod's memory requests   	|
| stunnel_pod_cpu_limits    	      | string 	| "1"     	| Source Stunnel Pod's cpu limit       	|
| stunnel_pod_cpu_requests  	      | string 	| "400m"  	| Source Stunnel Pod's cpu requests    	|
| stunnel_pod_memory_limits    	    | string 	| "1Gi"   	| Source Stunnel Pod's memory limit    	|
| stunnel_pod_memory_requests  	    | string 	| "1Gi"   	| Source Stunnel Pod's memory requests 	|

### Configuring Supplemental Groups for Rsync Pods

If PVCs are using a shared storage, the access to storage can be configured by adding supplemental groups to Rsync Pod definitions in order for the Pods to allow access:

|          Variable          	|  Type  	| Default 	| Description                                                                                                                                                                                                                                                 	|
|:--------------------------:	|:------:	|---------	|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------	|
|   src_supplemental_groups  	| string 	| Not Set 	| Comma separated list of supplemental groups for source Rsync Pods                                                                                                                                                                                           	|
| target_supplemental_groups 	| string 	| Not Set 	| Comma separated list of supplemental groups for target Rsync Pods                                                                                                                                                                                           	|

#### Example Usage

_MigrationController_ CR can be updated to set the above values:

```yaml
spec:
  src_supplemental_groups: "1000,2000"
  target_supplemental_groups: "2000,3000"
```

### Configuring retries for Rsync

MTC 1.4.3 onwards, a new ability of retrying a failed Rsync operation is introduced. By default, the migration controller will retry Rsync until all of the data is successfully transferred from the source to the target volume or a specified number of retries is met. The default retry limit is set to `20`. For larger volumes, the limit `20` may not be sufficient. It can be increased by using the following variable in _MigrationController_ CR:

```
apiVersion: migration.openshift.io/v1alpha1
kind: MigrationController
metadata:
  name: migration-controller
  namespace: openshift-migration
spec:
  [...]
  rsync_backoff_limit: 40
```

The above will set the retry limit to `40`.

---

### Rsync behavior in OpenShift 4.12 and above

_This section applies to cases when the destination cluster is OpenShift 4.12 and above_

OpenShift 4.12+ environments have PodSecurityAdmission controller enabled by default. It requires cluster admins to enforce Pod Security Standards via namespace labels. All workloads in the cluster are expected to run at a Pod Security Standard level set by cluster admins. The three different policies are _Privileged, Baseline and Restricted_. Every cluster has its own default policy set. 

To guarantee successful data transfer in all environments, MTC 1.7.5 introduces changes in Rsync Pods. Rsync Pod is run as non-root user by default. It ensures that data transfer is possible even for workloads that do not necessarily require higher privileges. Note that its best to run workloads with lowest level of privileges possible. 

While this works in most cases, data transfer may fail when workloads are running as root user on the source side. MTC provides two ways to manually override default non-root operation for data transfer. In both cases, the namespaces that are running workloads with higher privileges need to have certain labels set on them prior to migration. The labels set an exception to the destination cluster's default security policy and allow pods to run with higher privileges than the enforced defaults. For all such namespaces, users are expected to set following labels on the source side:

```yaml
pod-security.kubernetes.io/enforce: privileged
pod-security.kubernetes.io/audit: privileged
pod-security.kubernetes.io/warn: privileged
```

During the migration, these labels will be copied to destination namespaces and workloads will continue running with higher privileges. Once the labels are set on namespaces, users need to override default non-root operation either via _MigrationController_ config or on per _MigMigration_ basis.

> In the absence of these labels, Rsync will automatically fallback to non-root user even if below mentioned config is present.

#### Configuring root / non-root for all migrations

On the destination cluster, _MigrationController_ can be configured to run rsync as root:

```yaml
apiVersion: migration.openshift.io/v1alpha1
kind: MigrationController
metadata:
  name: migration-controller
  namespace: openshift-migration
spec:
  [...]
  migration_rsync_privileged: true
```

This config will apply to all migrations that take place after the update.

#### Configuring root / non-root per migration

MTC 1.7.5 introduces three fields in _MigMigration_ CR to allow users to configure root/non-root operation along with some additional UID / GID settings. These settings take place at migration level and are not applicable to all migrations.

- `RunAsRoot` - By default the value is not set and field is omitted. If passed `true`, rsync pod will run with `privileged` SCC. Takes precedence over below mentioned two fields.
- `RunAsGroup` - By default the value is not set and field is omitted. The value of this field should be within allowed range of gid on the namespace.
- `RunAsUser` - By default the value is not set and field is omitted. The value of this field should be within allowed range of uid on the namespace.

An example of the migration CR running rsync operations as root:

```
apiVersion: migration.openshift.io/v1alpha1
kind: MigMigration
metadata:
  name: migration-controller
  namespace: openshift-migration
spec:
  [...]
  runAsRoot: true
```

An example of migration CR running rsync operations with uid/gid:
```
apiVersion: migration.openshift.io/v1alpha1
kind: MigMigration
metadata:
  name: migration-controller
  namespace: openshift-migration
spec:
  [...]
  runAsUser: 10010001
  runAsGroup: 3
```

**Note**: The above settings are only available via API.

#### Why/When to run rsync with root/non-root?

Kubelet makes the decision of changing file ownership with `chown` per plugin. 

- For in-tree plugins:
    - Each plugin has a `SetUpAt()` function implemented which can call `volume.SetVolumeOwnership`, thus indicating kubelet to change permissions of the files. The example of such in-tree plugins are - `aws_ebs`, `vsphere_volume`, `portworx`, `configmap`, `secret`, `azuredd`, `rbd`, `iscsi`, `flexvolume`. Detailed list of all the plugins calling to `volume.SetVolumeOwnership` can be found [here](https://github.com/kubernetes/kubernetes/search?p=1&q=SetVolumeOwnership). 
    - The rest of the in-tree plugins such as `nfs`, `azure_file`, `cephfs` are examples of plugins that are not changing ownership since these plugins are not making a call to `volume.SetVolumeOwnership`.

- For CSI plugins:
    - Before K8s 1.19, OpenShift 4.5 or earlier:
        1. If `fstype` is "", then skip `fsgroup` (could be an indication of a non-block filesystem), and not change the permissions
        2. if `fstype` is provided and `pv.AccessMode == ReadWriteOnly` and `!c.spec.ReadOnly` then apply `fsgroup` and change the file permissions
    - At or after 1.19, OpenShift 4.6 and onward, `CSIDriver.Spec.FSGroupPolicy` is used by kubelet to decide on changing the ownership, which can have following possible values. More details on this can be found [here](https://github.com/kubernetes/enhancements/tree/master/keps/sig-storage/1682-csi-driver-skip-permission):          
         - `ReadWriteOnceWithFSType` --> Current behavior. Attempt to modify the volume ownership and permissions to the defined fsGroup when the volume is mounted if accessModes is RWO.
         - `None` --> New behavior. Attach the volume without attempting to modify volume ownership or permissions.
         - `File` --> New behavior. Always attempt to apply the defined fsGroup to modify volume ownership and permissions regardless of fstype or access mode.

[This doc](https://docs.google.com/document/d/12XbFpkMbMvBH1Vy3lk9e2-_pkIfCNODPkY_xbYti4Fo/edit) talks about how kubelet acts in response to different plugins in detail.

##### Making the decision of how to run rsync operations

If kubelet will change the permissions for volume, you should not care about running rsync with root or specific UID/GID. 

For the plugins for which kubelet won't change the permissions, you can choose to preserve permissions by running rsync with root, or change the permissions to specific UID/GID, or change permissions to default UID/GID provided by SCC.

### Known Issues

#### Rsync fails with 'Connection reset by peer' error

The migration will fail with a Warning when Rsync fails. In the UI, MTC will display the namespace and the name of the client Rsync Pod which failed. The users can run `oc logs <namespace>/<rsync-pod-name>` to determine whether `Connection reset by peer` error shows up in the log. If it does, then it's highly likely that the connection is unexpectedly closed by a network entity which is not necessarily under MTC's control. 

In clusters running on AWS, an OpenShift Route is behind an AWS ELB. MTC uses OpenShift Route to expose the target Rsync Pod. In our prior experiments with such clusters, we have found that the `Connection reset by peer` is caused when the AWS ELB closes the connection unexpectedly. This can be caused when the target Pod processes incoming data at a slower rate than the rate at which the source Pod sends it. This makes the ELB believe that the target Pod is not capable of handling anymore data making it drop the connection. Since AWS ELB is not designed for the purposes of sending high volume of data, there is no definite solution to avoid this issue. However, there are ways to alleviate the underlying problem of mismatch in processing speed. This can be simply done by using the `--bwlimit=<>` option for Rsync operation. See [this section](#limiting-bandwidth-on-rsync-operation) to understand how you can configure this option using the configuration variables discussed in the previous section. With an optimum bandwidth value set, it is possible to completely avoid the issue and also guarantee accepteable performance for transfer. However, there is no one perfect value which will fit all the environments. Therefore, we recommend experimenting with a higher value and then reducing it further until an optimum value of bandwidth is found as we did in our experiments.

Another possible solution is to limit the resources on the source Rsync Pod to make it send data at a slower rate. This can be done using additional variables available in the _MigrationController_ CR as described in [this section](#configuring-resource-limits-on-rsync-pods). The users can intentionally set lower limits on the source while setting higher limits for the target pods.

---

### Example Scenarios

#### Limiting bandwidth on Rsync operation

Rsync bandwidth limit is expressed in KB/sec. You can set `rsync_opt_bwlimit` as follows:

```yml
apiVersion: migration.openshift.io/v1alpha1
kind: MigrationController
metadata:
  name: migration-controller
  namespace: openshift-migration
spec:
  [...]
  rsync_opt_bwlimit: 10000
```

The above will limit the bandwidth to 10000KB/sec which is equivalent to 10MB/sec.

#### Not preserving hard links 

Rsync preserves hard links when `--hard-links` is specified. This is an expensive operation incurring significant cost on transfer time. It can be disabled by setting `rsync_opt_hardlinks` to `false`:

```yml
apiVersion: migration.openshift.io/v1alpha1
kind: MigrationController
metadata:
  name: migration-controller
  namespace: openshift-migration
spec:
  [...]
  rsync_opt_hardlinks: false
```

#### Performing a dry run

Rsync allows performing a dry run without actually making changes on the target or source using `--dry-run` option. `rsync_opt_extras` can be used to perform a dry run:

```yml
apiVersion: migration.openshift.io/v1alpha1
kind: MigrationController
metadata:
  name: migration-controller
  namespace: openshift-migration
spec:
  [...]
  rsync_opt_extras: "--dry-run"
```

#### Compressing file data during transfer

`rsync_opt_extras` can be used to instruct Rsync to compress files during transfer:

```yml
apiVersion: migration.openshift.io/v1alpha1
kind: MigrationController
metadata:
  name: migration-controller
  namespace: openshift-migration
spec:
  [...]
  rsync_opt_extras: "--compress"
```

#### Preserving ACLs and Extended Attributes

To preserve ACLs and extended attrs, simply use `rsync_opt_extras` as follows:

```yml
apiVersion: migration.openshift.io/v1alpha1
kind: MigrationController
metadata:
  name: migration-controller
  namespace: openshift-migration
spec:
  [...]
  rsync_opt_extras: "--acls --xattrs"
```

For full list of available Rsync options, please see Rsync man page: `man rsync` 
