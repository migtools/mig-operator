#!/bin/bash

MIG_OPERATOR_REPO=$(pwd)

if [[ "${ORG}" == "konveyor" ]]; then
  echo "ORG is set to konveyor. Change ORG to your personal quay org."
  exit 1
fi

if [[ $(basename ${MIG_OPERATOR_REPO}) != "mig-operator" ]]; then
  echo "Please run this script from the root directory of the mig-operator git repo."
  exit 1
fi

if [[ ! -d ${MIG_OPERATOR_REPO} ]]; then
  echo "Define MIG_OPERATOR_REPO var"
fi

pushd ${MIG_OPERATOR_REPO} &> /dev/null

trap "{ popd &> /dev/null; }" EXIT

echo "Build docker image? (Y/N)" 
read build_docker

if [[ -z "$ORG" ]]; then
  echo "Define ORG var"
  read ORG
fi

if [[ -z "$TAG" ]]; then
  echo "Define TAG var"
  read TAG
fi

if [[ ${build_docker} =~ ^[Yy]$ ]]; then
  IMG=quay.io/$ORG/mig-operator-container:$TAG
  docker build -t $IMG -f ./build/Dockerfile .
  find ./deploy/olm-catalog/bundle/manifests/ -name '*.clusterserviceversion.*' -exec sed -E -i -e "s,image: quay.io/(.*)/mig-operator-container:(.*),image: ${IMG},g" {} \;
else
  echo "Not building docker image"
fi

echo "Push docker image? (Y/N)"
read push_docker

if [[ ${push_docker} =~ ^[Yy]$ ]]; then
  if docker push $IMG; then
    echo "Image pushed"
  else
    echo "Please login to quay.io using 'docker login quay.io'"
    exit 1
  fi
fi

echo "Build bundle and index images? (Y/N)"
read build_bundle

if [[ ${build_bundle} =~ ^[Yy]$ ]]; then
  docker build -f ./build/Dockerfile.bundle -t quay.io/$ORG/mig-operator-bundle:$TAG .
  docker push quay.io/$ORG/mig-operator-bundle:$TAG

  opm index add -c docker --bundles quay.io/$ORG/mig-operator-bundle:$TAG --tag quay.io/$ORG/mig-operator-index:$TAG
  docker push quay.io/$ORG/mig-operator-index:$TAG
fi

echo "Disable default catalog sources? (Y/N)"
read disable_def_sources

if [[ ${disable_def_sources} =~ ^[Yy]$ ]]; then
    oc patch OperatorHub cluster --type json -p '[{"op": "add", "path": "/spec/disableAllDefaultSources", "value": true}]'
fi

echo "Create CatalogSource? (Y/N)"
read create_catalogsource

if [[ ${create_catalogsource} =~ ^[Yy]$ ]]; then
  cat << EOF > catalogsource.yml
apiVersion: operators.coreos.com/v1alpha1
kind: CatalogSource
metadata:
  name: migration-operator
  namespace: openshift-marketplace
spec:
  sourceType: grpc
  image: quay.io/$ORG/mig-operator-index:$TAG
EOF

  export BUNDLEDIGEST=$(oc image mirror --dry-run=true quay.io/$ORG/mig-operator-index:$TAG=quay.io/$ORG/mig-operator-index:dry 2>&1 | grep -A1 manifests | grep sha256 | awk -F' ' '{ print $1 }')
  sed "s/:latest/@$BUNDLEDIGEST/" catalogsource.yml | oc create -f -
  rm catalogsource.yml
fi

echo "Create OperatorGroup? (Y/N)"
read create_opg

if [[ ${create_opg} =~ ^[Yy]$ ]]; then
  oc create ns openshift-migration

  cat << EOF > opg.yaml
apiVersion: operators.coreos.com/v1
kind: OperatorGroup
metadata:
  namespace: openshift-migration
  labels:
    opg-for: mtc
  generateName: openshift-migration-
spec:
  targetNamespaces:
  - openshift-migration
EOF
  
  oc delete operatorgroup -l opg-for=mtc 
  oc create -f opg.yaml
  rm opg.yaml
fi

echo "Create Subscription? (Y/N)"
read create_sub

if [[ ${create_sub} =~ ^[Yy]$ ]]; then
  cat << EOF > sub.yaml
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: crane-operator
  namespace: openshift-migration
spec:
  channel: development
  installPlanApproval: Automatic
  name: crane-operator
  source: migration-operator
  sourceNamespace: openshift-marketplace
EOF
 
  oc create -f sub.yaml
  rm sub.yaml
fi
