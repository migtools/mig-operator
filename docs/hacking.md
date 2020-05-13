# Hacking.md
In order to test OLM metadata you will need to push your test metadata to Quay and tell your cluster where to look for it.

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
1. `export ORG=$organization`
1. `git clone https://github.com/konveyor/mig-operator`
1. `cd mig-operator`
1. `operator-courier --verbose push deploy/olm-catalog/konveyor-operator/ $ORG konveyor-operator 1.0.0 "$QUAY_TOKEN"`

Notes:
* The first time you push your metadata to quay.io you will need to browse to the [application](https://quay.io/application/) and make it public.
* The version refers only to the metadata version and must be incremented each time you push.

## Updating OLM to access your metadata
One of the methods use to tell OLM how to retrieve metadata is an OperatorSource.

To write the mig-operator-source.yaml and create the resource run the following:
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
