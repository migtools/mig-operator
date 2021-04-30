# MigCluster Configuration

For every _MigCluster_ resource created in MTC, a _ConfigMap_ named `migration-cluster-config` is created in Migration Operator's namespace on the cluster which _MigCluster_ resource represents. It allows configuring _MigCluster_ specific values and is managed by the Migration Operator. Every value in the _ConfigMap_ can be configured using the variables exposed in _MigrationController_ CR.

## Usage

Following table summarizes the _MigrationController_ variables:

| Variable                             	| Type   	| Required 	| Description                                                              	|
|--------------------------------------	|--------	|----------	|--------------------------------------------------------------------------	|
| migration_stage_image_fqin           	| string 	| No       	| Image to use for Stage Pods (only applicable to IndirectVolumeMigration) 	|
| migration_registry_image_fqin        	| string 	| No       	| Image to use for Migration Registry                                      	|
| rsync_transfer_image_fqin            	| string 	| No       	| Image to use for Rsync Pods (only applicable to DirectVolumeMigration)   	|
| migration_rsync_privileged           	| bool   	| No       	| Whether to run Rsync Pods as privileged or not                           	|
| cluster_subdomain                    	| string 	| No       	| Cluster's subdomain                                                      	|
| migration_registry_readiness_timeout 	| int    	| No       	| Readiness timeout (in seconds) for Migration Registry Deployment         	|
| migration_registry_liveness_timeout  	| int    	| No       	| Liveness timeout (in seconds) for Migration Registry Deployment          	|

> Note that the values are specific to MigCluster resource. Therefore, the variables need to be updated in the MigrationController resource present on the respective cluster you wish to update. The values that are *not required* will be automatically set by the Migration Operator or the Migration Controller.
