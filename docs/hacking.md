# Hacking.md
To test changes to the operator ansible playbook you will need to build and push an updated container.

To test OLM metadata you will need to push your test metadata to Quay and tell your cluster where to look for it.

# Building and pushing the container
Ensure you have the latest operator-sdk base image before building.

`docker pull quay.io/operator-framework/ansible-operator:latest`

The build is done with a standard docker build command, for example in the root of the mig-operator repo run:

`docker build -f build/Dockerfile -t quay.io/foo/mig-operator-container:latest . && docker push quay.io/foo/mig-operator-container:latest`

To test this image you may manually edit the CSV to use it instead of the default after installing the operator, or you can update the CSV and push it using the instructions below.

# Pushing metadata

## One time setup
The tool used for pushing metadata to Quay is called operator-courier. In recent Fedora releases it has been packaged. To install it run `dnf -y install python3-operator-courier`.

To interact with the quay API using operator courier you will need to obtain a  basic auth token. The example script below can be used to retrieve a token and then to more easily follow examples here it is suggested you export it in your .bashrc or somewhere else that makes sense for you, `export QUAY_TOKEN="basic ..."`.

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

Finally, determine which Quay organization you will push the metadata to in order to test. This can be your personal Quay organization, or any other you have access to push to.

## Pushing OLM metadata to Quay
Notes:
* Pushing an index file requires the `opm` utility which can be obtained from `https://github.com/operator-framework/operator-registry`.
* `opm` requires `podman`.
* The first time you push your bundle to quay.io you will need to browse to the repo make it public before trying to build the index.
* After pushing your index image for the first time you will also need to make the repo public

1. `export ORG=$organization`
1. `git clone https://github.com/konveyor/mig-operator`
1. `cd mig-operator`
1. `docker build -f build/Dockerfile.bundle . -t quay.io/$ORG/mig-operator-bundle:latest && docker push quay.io/$ORG/mig-operator-bundle:latest`
1. `opm index add --bundles docker push quay.io/$ORG/mig-operator-bundle:latest --tag quay.io/$ORG/mig-operator-index:latest`
1. `podman push quay.io/konveyor/mig-operator-index:latest`

## Updating OLM to access your metadata
This requires creating a CatalogSource to point at your new index image.

To write the mig-operator-source.yaml and create the resource run the following:
```
cat << EOF > mig-operator-bundle.yaml
apiVersion: operators.coreos.com/v1alpha1
kind: CatalogSource
metadata:
  name: konveyor-for-containers-bundle
  namespace: openshift-migration
spec:
  sourceType: grpc
  image: quay.io/$ORG/mig-operator-index:latest

EOF

oc create -f mig-operator-bundle.yaml
```

Note that CatalogSources will not ever pull updated images.
https://github.com/operator-framework/operator-lifecycle-manager/issues/903

To get around this you can script the creation of mig-operator-bundle.yaml to always use the latest SHA.
```
#!/bin/bash
export BUNDLEDIGEST=$(docker pull quay.io/$ORG/mig-operator-index:latest | grep Digest | awk '{ print $2 }')

sed "s/:latest/@$BUNDLEDIGEST/" mig-operator-bundle.yaml | oc create -f -
```

## Disabling default OperatorSources
If you are working on an operator such as konveyor, that exists in community-operators or elsewhere you may see duplicate operators in the UI. It can be difficult to discern which copy comes from which source. To alleviate this problem you may disable the default operator sources.
```
oc patch OperatorHub cluster --type json -p '[{"op": "add", "path": "/spec/disableAllDefaultSources", "value": true}]'
```

To reverse this change simply update the value again.
```
oc patch OperatorHub cluster --type json -p '[{"op": "add", "path": "/spec/disableAllDefaultSources", "value": false}]'
```

## Creating the OperatorGroup
Before creating a subscription from the CLI, you must create an OperatorGroup.

```
cat << EOF > operatorgroup.yml
apiVersion: operators.coreos.com/v1
kind: OperatorGroup
metadata:
  generateName: openshift-migration-
spec:
  targetNamespaces:
  - openshift-migration
EOF
```

## Creating the Subscription
You may either create the subscription via the UI console or from the CLI.

To do so from the CLI, ensure the namespace exists, select a channel, write a subscription.yml, and create the resource.

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

## Iterating changes
If you have made a change, deployed the operator, spotted an error and need to test another update:

1. Make your changes and push your metadata again, incrementing the version, for example: `operator-courier --verbose push deploy/olm-catalog/konveyor-operator/ $ORG konveyor-operator 2.0.0 "$QUAY_TOKEN"`.
1. Delete the operator subscription `oc delete -f subscription.yml`
1. Delete the operator source `oc delete -f mig-operator-source.yaml`
1. Recreate the operator source `oc create -f mig-operator-source.yaml`
1. Redploy the operator `oc create -f subscription.yml`
