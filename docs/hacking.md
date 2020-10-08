# hacking.md

## How do I test my mig-operator changes?

|Where is your change?|You changed|To test your changes|
|---|---|---|
|`./roles`| Playbook content |[Build and push a new mig-operator image](#building-and-pushing-the-mig-operator-container-image) |
|`./deploy/non-olm`| OpenShift 3 manifests | [Apply updated manifests directly](#using-a-new-mig-operator-container-image) |
|`./deploy/olm-catalog`| OpenShift 4 metadata | [Build and push a new OperatorHub metadata, update OperatorSource](#pushing-operator-metadata-openshift-4x)|

**Note**: if you build a new mig-operator image, you must reference it in `./deploy/non-olm/[...]` and `./deploy/olm-catalog/[...]`. 

## Building and pushing the mig-operator container image

1. Pull the latest `operator-sdk` base image before building.

```
docker pull quay.io/operator-framework/ansible-operator:latest
```

2. Set quay org and tag

```
export ORG=your-quay-org
export TAG=latest
```

2. Run the build from the root of the mig-operator repo:

```
docker build -f build/Dockerfile -t quay.io/$ORG/mig-operator-container:$TAG . 
docker push quay.io/$ORG/mig-operator-container:$TAG
```

### Using a new mig-operator container image

#### OpenShift 3

1. Update the deploy manifest in `./deploy/non-olm`

   ```
   # from ./deploy/non-olm/latest/operator.yml
   [...]
      containers:
      - name: operator
        image: quay.io/$ORG/mig-operator-container:$TAG
   ```
   
2. Apply the updated manifest to your cluster
   ```
   oc apply -f ./deploy/non-olm/latest/operator.yml
   ```

#### OpenShift 4

1. Update the ClusterServiceVersion in `./deploy/olm-catalog`

   ```
   # from ./deploy/olm-catalog/[...]/konveyor-operator.v99.0.0.clusterserviceversion.yaml
   [...]
      containers:
      - name: operator
        image: quay.io/$ORG/mig-operator-container:$TAG
   ```

2. Follow steps to [push operator metadata](#pushing-operator-metadata-openshift-4x)

3. Follow steps to [install mig-operator after pushing metadata](#installing-mig-operator-after-pushing-metadata)


## Pushing Operator Metadata (OpenShift 4.x)

The tooling and steps for pushing metadata depend on the OpenShift version.
|OpenShift Versions|Operator Metadata Tooling|
|---|---|
|4.5+|[opm](https://github.com/operator-framework/operator-registry)|
|4.1 - 4.5|[operator-courier](https://github.com/operator-framework/operator-courier)|
|3.x| n/a |


---

### Pushing operator metadata with `opm` (OpenShift 4.5+)

#### Prerequisities

- Install `opm` from [operator-registry](https://github.com/operator-framework/operator-registry)
- Install `podman` from your package manager

#### Build bundle and index images, update CatalogSource 


1. Set quay org and image tag

   ```
   export ORG=your-quay-org
   export TAG=latest
   ```

2. Build and push the _bundle image_

   ```
   docker build -f build/Dockerfile.bundle -t quay.io/$ORG/mig-operator-bundle:$TAG .
   docker push quay.io/$ORG/mig-operator-bundle:$TAG
   ```
   
3. Visit quay.io and make `mig-operator-bundle` public

4. Build and push the _index image_

   ```   
   opm index add -p docker --bundles quay.io/$ORG/mig-operator-bundle:$TAG --tag quay.io/$ORG/mig-operator-index:$TAG
   podman push quay.io/$ORG/mig-operator-index:$TAG
   ```
   
5. Visit quay.io and make `mig-operator-index` public

6. Create a new _CatalogSource_ referencing the _index image_
   ```
   cat << EOF > catalogsource.yml
   apiVersion: operators.coreos.com/v1alpha1
   kind: CatalogSource
   metadata:
     name: konveyor-for-containers-bundle
     namespace: openshift-marketplace
   spec:
     sourceType: grpc
     image: quay.io/$ORG/mig-operator-index:$TAG
   EOF
   
   oc create -f catalogsource.yml
   ```
   
   *Note*: CatalogSources will not pull updated images.
   https://github.com/operator-framework/operator-lifecycle-manager/issues/903

   As a workaround, use the commands below to modify your CatalogSource with the latest index image SHA
   ```bash
   export BUNDLEDIGEST=$(docker pull quay.io/$ORG/mig-operator-index:latest | grep Digest | awk '{ print $2 }')
   sed "s/:latest/@$BUNDLEDIGEST/" catalogsource.yml | oc create -f -
   ```

---

### Pushing operator metadata with `operator-courier` (OpenShift 4.1-4.5)

#### Prerequisities

 - Install `operator-courier`
 
    ```
    dnf -y install python3-operator-courier
    ```

 - Set the `QUAY_TOKEN` basic auth token
    - To interact with the quay API using operator courier you will need to obtain a  basic auth token. The example script below can be used to retrieve a token and then to more easily follow examples here it is suggested you export it in your .bashrc or somewhere else that makes sense for you, `export QUAY_TOKEN="basic ..."`.

   ```
   export QUAY_USERNAME
   export QUAY_PASSWORD
   echo $(curl -sH "Content-Type: application/json" -XPOST https://quay.io/cnr/api/v1/users/login -d '
   {
   "user": {
   "username": "'"${QUAY_USERNAME}"'",
   "password": "'"${QUAY_PASSWORD}"'"
   }
   }')
   ```

#### Pushing metadata and updating the CatalogSource

1. Set quay org

   ```
   export ORG=your-quay-org
   ```

2. Use `opm` to export metadata in appregistry format

   ```
   opm index export -c podman -i quay.io/$ORG/mig-operator-index:latest -o mtc-operator
   ```

   This will produce a directory called `downloaded` with appregistry format metadata.

3. Use `operator-courier` to push updated metadata, making sure to increment the version

    ```
    operator-courier --verbose push downloaded $ORG mtc-operator 2.0.0 "$QUAY_TOKEN"`
    ```

4. Visit quay.io and make the app `$ORG/mtc-operator` public

5. Create a new _CatalogSource_ referencing the pushed metadata
    ```
    cat << EOF > mig-operator-source.yaml
    apiVersion: operators.coreos.com/v1
    kind: OperatorSource
    metadata:
      name: migration-operator
      namespace: openshift-marketplace
    spec:
      type: appregistry
      endpoint: https://quay.io/cnr
      registryNamespace: $ORG
      displayName: "Migration Operator"
      publisher: "ocp-migrate-team@redhat.com"
    EOF

    oc create -f mig-operator-source.yaml
    ```

---

## Installing mig-operator after pushing metadata

### Disabling default OperatorSources

If you are working on an operator such as konveyor, that exists in community-operators or elsewhere you may see duplicate operators in the UI. It can be difficult to discern which copy comes from which source. To alleviate this problem you may disable the default operator sources.

```
oc patch OperatorHub cluster --type json -p '[{"op": "add", "path": "/spec/disableAllDefaultSources", "value": true}]'
```

To reverse this change simply update the value again.
```
oc patch OperatorHub cluster --type json -p '[{"op": "add", "path": "/spec/disableAllDefaultSources", "value": false}]'
```

### Creating the OperatorGroup
Before creating a subscription from the CLI, you must create an OperatorGroup.

```
cat << EOF > operatorgroup.yml
apiVersion: operators.coreos.com/v1
kind: OperatorGroup
metadata:
  namespace: openshift-migration
  generateName: openshift-migration-
spec:
  targetNamespaces:
  - openshift-migration
EOF

oc apply -f operatorgroup.yml
```

### Creating the Operator Subscription

You may _Subscribe_ to an Operator via OperatorHub or from the CLI.

To _Subscribe_ to an Operator from the CLI:

1. Ensure the namespace exists, 
2. Select an update channel
3. Write a subscription.yml, and create the resource.

```
oc create namespace openshift-migration ||:

export CHANNEL=latest

cat << EOF > subscription.yml
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: konveyor-operator
  namespace: openshift-migration
spec:
  channel: $CHANNEL
  installPlanApproval: Automatic
  name: konveyor-operator
  source: migration-operator
  sourceNamespace: openshift-marketplace
EOF

oc create -f subscription.yml
```

### Making iterative changes to mig-operator
If you have made a change, deployed the operator, spotted an error and need to test another update:

1. Update operator playbook and metadata
   1. Make changes to _playbook contents_
   1. Build and push updated _mig-operator image_
   1. Make changes to _operator metadata_
   1. Build and push updated _operator metadata_

1. Clean up 
   1. Delete the Operator Subscription `oc delete -f subscription.yml`
   1. Delete the OperatorSource `oc delete -f mig-operator-source.yaml`

1. Re-deploy
   1. Recreate the OperatorSource `oc create -f mig-operator-source.yaml`
   1. Recreate the Operator Subscription  `oc create -f subscription.yml`
