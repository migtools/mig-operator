# Migration Controller Configuration

This document consolidates various configuration options available for `MigrationController` Custom Resource of the Migration Operator and provides navigation links to detailed documents wherever available. 

The custom resource can be edited by running:

```
oc edit migrationcontroller migration-controller -n openshift-migration
```

## Adjusting Migration Controller Pod Limits

|           Variable           	|  Type  	| Required? 	| Default 	|                Description               	|   	|
|:----------------------------:	|:------:	|:---------:	|:-------:	|:----------------------------------------:	|:-:	|
|   mig_controller_limits_cpu  	| string 	|     N     	|   "1"   	|   CPU limit on Migration Controller Pod  	|   	|
| mig_controller_limits_memory 	| string 	|     N     	|  "10Gi" 	| Memory limit on Migration Controller Pod 	|   	|

See full doc [here](./AdjustingControllerLimits.md)

## Configuring Migration Components

|       Variable       	| Type 	| Required? |          Description         	|
|:--------------------:	|:----:	|:---------:|:----------------------------:	|
|   migration_velero   	| bool 	|     Y     |        Install Velero        	|
| migration_controller 	| bool 	|     Y     | Install Migration Controller 	|
|     migration_ui     	| bool 	|     Y     |     Install Migration UI     	|

See full doc [here](./AlternativeCAMTopologies.md#component_configuration)

## Migration Limits


|       Variable      	|  Type  	| Required? 	| Default 	|                        Description                       	|
|:-------------------:	|:------:	|:---------:	|:-------:	|:--------------------------------------------------------:	| 
|     mig_pv_limit    	| string 	|     N     	|  "100"  	|     Maximum number of PVs allowed in a Migration Plan    	|
|    mig_pod_limit    	| string 	|     N     	|  "100"  	|    Maximum number of Pods allowed in a Migration Plan    	|
| mig_namespace_limit 	| string 	|     N     	|   "10"  	| Maximum number of Namespaces allowed in a Migration Plan 	|

## Migration Cluster Configuration

| Variable                             	| Type   	| Required 	| Description                                                              	|
|--------------------------------------	|--------	|----------	|--------------------------------------------------------------------------	|
| migration_stage_image_fqin           	| string 	| No       	| Image to use for Stage Pods (only applicable to IndirectVolumeMigration) 	|
| migration_registry_image_fqin        	| string 	| No       	| Image to use for Migration Registry                                      	|
| rsync_transfer_image_fqin            	| string 	| No       	| Image to use for Rsync Pods (only applicable to DirectVolumeMigration)   	|
| migration_rsync_privileged           	| bool   	| No       	| Whether to run Rsync Pods as privileged or not                           	|
| cluster_subdomain                    	| string 	| No       	| Cluster's subdomain                                                      	|
| migration_registry_readiness_timeout 	| int    	| No       	| Readiness timeout (in seconds) for Migration Registry Deployment         	|
| migration_registry_liveness_timeout  	| int    	| No       	| Liveness timeout (in seconds) for Migration Registry Deployment          	|

See full doc [here](./MigClusterConfiguration.md)

## Excluding Resources

|         Variable        	|     Type     	| Required? 	| Default 	|                       Description                      	|
|:-----------------------:	|:------------:	|:---------:	|:-------:	|:------------------------------------------------------:	|
| disable_image_migration 	|     bool     	|     N     	|  false  	|   Exclude Image/Imagestream resources from migration   	|
|   disable_pv_migration  	|     bool     	|     N     	|  false  	|        Exclude Persistent Volumes from migration       	|
|    excluded_resources   	| list[string] 	|     N     	|   See below  	| List of Kubernetes resources to exclude from migration 	|

Default exluded resources:

```
  - imagetags
  - templateinstances
  - clusterserviceversions
  - packagemanifests
  - subscriptions
  - servicebrokers
  - servicebindings
  - serviceclasses
  - serviceinstances
  - serviceplans
  - operatorgroups
  - events
  - events.events.k8s.io
  - rolebindings.authorization.openshift.io
```

See full doc [here](./ExcludeResources.md)

## Direct Volume Migration Configuration

|        Variable        	|  Type  	| Required? 	| Default 	|                                   Description                                  	|
|:----------------------:	|:------:	|:---------:	|:-------:	|:------------------------------------------------------------------------------:	|
|    stunnel_tcp_proxy   	| string 	|     N     	|  Empty  	|    Configures Proxy for DVM (See full doc [here](./DVMProxyConfiguration.md))  	|
| enable_dvm_pv_resizing 	|  bool  	|     N     	|  false  	| Enables automatic PV resizing (See full doc [here](./IntelligentPVResizing.md))  	|

### Rsync specific configuration

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
| rsync_opt_bwlimit   	| int    	| Not set                                          	| When set to a positive integer, `--bwlimit=<int>` option will be added to Rsync command. 	|
| rsync_opt_archive   	| bool   	| true                                             	| Sets `--archive` option in Rsync command.                                                	|
| rsync_opt_partial   	| bool   	| true                                             	| Sets `--partial` option in Rsync command.                                                	|
| rsync_opt_delete    	| bool   	| true                                             	| Sets `--delete` option in Rsync command.                                                 	|
| rsync_opt_hardlinks 	| bool   	| true                                             	| Sets `--hard-links` option is Rsync command.                                             	|
| rsync_opt_info      	| string 	| COPY2,DEL2,REMOVE2,SKIP2,FLIST2,PROGRESS2,STATS2 	| Enables detailed logging in Rsync Pod.                                                   	|
| rsync_opt_extras    	| string 	| Empty                                            	| Reserved for any other arbitrary options.                                                	|
| migration_rsync_privileged 	|  bool  	|  false  	|                      Run Rsync Pods in `privileged` mode                       	|
|     rsync_backoff_limit    	|   int  	|    20   	| Maximum number of transfer attempts before data migration is considered failed 	|

See full doc [here](./RsyncConfiguration.md)