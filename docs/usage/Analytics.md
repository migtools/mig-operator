# Analytics
Starting with MTC 1.3.0 it is possible to run an analysis that will show the number of Kubernetes resources, images, and pv capacity. A break down will be provided per namespace, with a break down of individual kubernetes resources in each namespace.

# Running an analysis
To run a report create a MigAnalytic CR referencing the plan you have created.
```
apiVersion: migration.openshift.io/v1alpha1
kind: MigAnalytic
metadata:
  annotations:
  name: test
  namespace: openshift-migration
spec:
  migPlanRef:
    name: test
    namespace: openshift-migration
  analyzeK8SResources: true
  analyzeImageCount: true
  analyzePVCapacity: true
```

## Listing Images
By default individual images per namespace are not listed to prevent the output from becoming excessively long.

To list images add the following parameters to the CR. The default ListImagesLimit value is 0 and needs to be adjusted to see any images.
```
spec:
  listImages: true
  ListImagesLimit: 50
```


Analysis can be expected to take several seconds per namespace.

# Retrieving Analysis
To retrieve the results from a miganalytic CR with the name test as in the example above run `oc get -o yaml miganalytic test`.

The results will be populated under the `status.analytics` parameter.

This is a partial example output:
```
status:
  analytics:
    imageCount: 19
    k8sResourceTotal: 824
    namespaces:
    - k8sResourceTotal: 386
      k8sResources:
      - count: 2
        kind: endpoints
        version: v1
      - count: 2
        kind: persistentvolumeclaims
        version: v1
      ...
      - count: 2
        group: metrics.k8s.io
        kind: pods
        version: v1beta1
      namespace: mediawiki
      pvCapacity: 2Gi
    - imageCount: 19
      k8sResourceTotal: 438
      k8sResources:
      - count: 1
        kind: pods
        version: v1
      ...
      - count: 1
        group: metrics.k8s.io
        kind: pods
        version: v1beta1
      namespace: registry-images
      pvCapacity: "0"
    plan: test
    pvCapacity: 2Gi
```

# Rerunning analysis
In the event you need to rerun analysis delete the miganalytic CR and recreate it.

# UI Analytics
Analytics will be run automatically and presented to the user when ready any time a plan is created in the UI.
