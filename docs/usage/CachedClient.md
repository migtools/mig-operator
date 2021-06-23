# Cached Client

Crane/MTC 1.5.0 introduced the ability to turn on _cached Kubernetes clients_ for communicating with all clusters involved in migrations. 

## Turning on Cached Clients in Crane/MTC 1.5.0+

Cached clients are turned off by default in MTC 1.5.0 since they consume additional memory. To enable them, use the command below.

### Enable cached client

```bash
oc --namespace openshift-migration patch MigrationController migration-controller --type=json \
 --patch '[{ "op": "replace", "path": "/spec/mig_controller_enable_cache", "value": true}]'
```

### Disable cached client
```bash
oc --namespace openshift-migration patch MigrationController migration-controller --type=json \
 --patch '[{ "op": "replace", "path": "/spec/mig_controller_enable_cache", "value": false}]'
```

### MigrationController Options

| MigrationController Option              | Explanation                                             |
|-----------------------------------------|---------------------------------------------------------|
| mig_controller_enable_cache: false      | Set to 'true' to enable cached client                   |
| mig_controller_limits_memory: "10Gi"    | Increase if encountering OOMKilled after enabling cache |
| mig_controller_requests_memory: "350Mi" | Increase if encountering OOMKilled after enabling cache |

## Considerations for Turning on Cached Clients

### Performance Benefits

Turning on cached clients can speed up migrations and make Crane/MTC more responsive in general, *especially if there is significant network latency* between clusters you are migrating  apps between. 

Certain tasks performed by mig-controller are read heavy, those will benefit from cache reads being ~1000x or more faster than APIserver reads. Delegated tasks (rsync of PV data, Velero Backup and Restore) will *not* increase in speed from mig-controller cached clients.

To get an idea of the performance you may gain by enabling cached clients, check out this [cached client demo](https://www.youtube.com/watch?v=NuAqTJwq_ao).


| Scenario                                | Estimated Speed Boost from Cached Client |
|-----------------------------------------|------------------------------------------|
| PV discovery                            | 5-10x                                    |
| Migration across regions, small PV data | 2-5x                                     |
| Migration across regions, large PV data | Not significant                          |
| Migration in same region, small PV data | 1x-1.5x                                  |
| Migration in same region, large PV data | Not significant                          |

### Additional Memory Requirements of Cached Clients

By turning on cached clients, mig-controller will consume more memory since it will be caching all API resources for kinds that it interacts with on all connected MigClusters. 

The cache will be kept up to date with an informer/watch mechanism, with data being pushed into the cache by the APIserver as it is updated.

If you find mig-controller is getting OOMKilled errors after enabling the cached client, you can bump the memory requests and limits for mig-controller with MigrationController CR fields mentioned in [turning on cached clients.](#turning-on-cached-clients)

### APIserver load and Memory Usage of Cached Clients

| Cache Turned On? | Reads go to | Writes go to | Memory Usage | APIserver load from Reads | APIserver load from informer |
|------------------|-------------|--------------|--------------|---------------------------|------------------------------|
| Yes              | Cache       | APIserver    | High         | Low                       | High                         |
| No               | APIserver   | APIserver    | Low          | High                      | Low                          |

Without cached clients, all APIserver reads go straight to the host or remote APIserver. With cache, reads go straight to the cache, but the cache has to be fed by the APIserver. You may want to experiment with turning cache on or off if you are experiencing high APIserver load. Depending on cluster conditions, the optimal setting may differ.
