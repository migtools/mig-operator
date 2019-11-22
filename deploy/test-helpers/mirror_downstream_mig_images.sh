#!/bin/bash
_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source $_dir/my_var

OCCMD=${DOCKERCMD:-oc}

echo "Mirroring downstream images..."
echo "Downstream registry: $DOWNSTREAM_REGISTRY"
echo "Target cluster registry: $CLUSTER_REGISTRY_ROUTE"
echo "Downstream repo name: $DOWNSTREAM_REPONAME"
echo "Target repo name: $TARGET_NAMESPACE"

echo "Creating namespaces:"
oc create namespace $TARGET_NAMESPACE > /dev/null 2>&1 ||:
oc create namespace openshift-migration > /dev/null 2>&1 ||:
oc policy add-role-to-group system:image-puller system:serviceaccounts:openshift-migration --namespace=$TARGET_NAMESPACE

function fullImgSrc() { echo "$DOWNSTREAM_REGISTRY/$DOWNSTREAM_ORG/$DOWNSTREAM_REPO_PREFIX${IMG_MAP[${img}_repo]}:${IMG_MAP[${img}_ds_tag]}"; }
function fullImgDest() { echo "$CLUSTER_REGISTRY_ROUTE/$TARGET_NAMESPACE/${IMG_MAP[${img}_tgt_name]}:${IMG_MAP[${img}_tgt_tag]}"; }

echo "Pulling images from:"
for img in "${IMAGES[@]}"; do
  echo "-> $(fullImgSrc)"
done

echo "Pushing images to:"
for img in "${IMAGES[@]}"; do
  echo "-> $(fullImgDest)"
done

for img in "${IMAGES[@]}"; do
  $OCCMD image mirror --insecure=true $(fullImgSrc)=$(fullImgDest)
done
