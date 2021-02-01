# Resources Migrated By Konveyor Operator

- **Migration via the configured Migration Plan:** The Konveyor operator allows you to select the namespaces to be migrated 
during the creation and configuration of a MigPlan, this implies that the **namespace** is the most basic resource that a 
user can specify for a particular migration and nothing more granular than that.

- **Namespace scoped resources vs Cluster scoped resources:** When a particular namespace is selected for migration, then all the 
objects/resources (services, pods etc.) pertaining to that namespace are also selected for the migration. But, there might be a case 
when a namespaced scoped resource depends on a cluster scoped resource, in such a scenario the cluster scoped resource also gets
migrated by the Konveyor operator. For instance, a Security Context Constraint (SCC) is a cluster scoped resource , and a service account (SA) 
is a namespace scoped resource, consider that the SA exists in the namespace which is selected for migration by the user then the operator 
will automatically go and find any SCCs that are applied to this SA and include those in the migration as well. Similarly, the relationship
of Persistent Volume Claims (PVC) and Persistent Volumes (PV) is handled by the operator. 

- **Custom Resources(CR) and Custom Resource Definitions(CRD):** Any namespace scoped CRs will automatically be included in the migration
if the namespace is selected by the user for migration. Consequently, the Konveyor operator will also migrate the CRDs associated with the CRs for migration.

- **Excluded Resources:** Some objects/resources are excluded by default from the migration by the Konveyor operator. These resources are 
service catalog resources or OLM resources, OLM migration is not handled by Konveyor operator. The excluded resources are (Please refer to the
[Excluded Resources](usage/ExcludeResources.md) document for more details) :

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
```

**Note:** For more granular information on this topic please refer the [Velero docs.](https://velero.io/docs/v1.4/how-velero-works/)
