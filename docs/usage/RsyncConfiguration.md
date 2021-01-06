
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


### Configuring resource limits on Rsync Pods

_MigrationController_ CR exposes following variables to configure resource usage requirements and limits on Rsync and Stunnel pods:

| Variable                  	| Type   	| Default 	| Description                          	|
|---------------------------	|--------	|---------	|--------------------------------------	|
| client_pod_cpu_limit      	| string 	| "1"     	| Source Rsync Pod's cpu limit         	|
| client_pod_memory_limit   	| string 	| "1Gi"   	| Source Rsync Pod's memory limit      	|
| client_pod_cpu_request    	| string 	| "400m"  	| Source Rsync Pod's cpu requests      	|
| client_pod_memory_request 	| string 	| "1Gi"   	| Source Rsync Pod's memory requests   	|
| transfer_pod_cpu_limits   	| string 	| "1"     	| Target Rsync Pod's cpu limit         	|
| transfer_pod_cpu_requests 	| string 	| "400m"  	| Target Rsync Pod's cpu requests      	|
| transfer_pod_mem_limits   	| string 	| "1Gi"   	| Target Rsync Pod's memory limit      	|
| transfer_pod_mem_requests 	| string 	| "1Gi"   	| Target Rsync Pod's memory requests   	|
| stunnel_pod_cpu_limits    	| string 	| "1"     	| Source Stunnel Pod's cpu limit       	|
| stunnel_pod_cpu_requests  	| string 	| "400m"  	| Source Stunnel Pod's cpu requests    	|
| stunnel_pod_mem_limits    	| string 	| "1Gi"   	| Source Stunnel Pod's memory limit    	|
| stunnel_pod_mem_requests  	| string 	| "1Gi"   	| Source Stunnel Pod's memory requests 	|

---

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
