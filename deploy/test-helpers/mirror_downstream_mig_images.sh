#!/bin/bash
_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source $_dir/my_var

DOCKERCMD=${DOCKERCMD:-docker}

echo "Mirroring downstream images..."
echo "Downstream registry: $DOWNSTREAM_REGISTRY"
echo "Target cluster registry: $CLUSTER_REGISTRY_ROUTE"
echo "Downstream repo name: $DOWNSTREAM_REPONAME"
echo "Target repo name: $TARGET_NAMESPACE"

echo "Creating namespaces:"
oc create namespace $TARGET_NAMESPACE > /dev/null 2>&1 ||:
oc create namespace openshift-migration > /dev/null 2>&1 ||:
oc policy add-role-to-group system:image-puller system:serviceaccounts:openshift-migration --namespace=$TARGET_NAMESPACE

echo "Pulling images from:"
for img in "${IMAGES[@]}"; do
  echo "-> $DOWNSTREAM_REGISTRY/$DOWNSTREAM_ORG/$DOWNSTREAM_REPO_PREFIX${IMG_MAP[${img}_repo]}:${IMG_MAP[${img}_ds_tag]}"
done

echo "Pushing images to:"
for img in "${IMAGES[@]}"; do
  echo "-> $CLUSTER_REGISTRY_ROUTE/$TARGET_NAMESPACE/${IMG_MAP[${img}_repo]}:${IMG_MAP[${img}_tgt_tag]}"
done

for img in "${IMAGES[@]}"; do
  fullImgSrc="$DOWNSTREAM_REGISTRY/$DOWNSTREAM_ORG/$DOWNSTREAM_REPO_PREFIX${IMG_MAP[${img}_repo]}:${IMG_MAP[${img}_ds_tag]}"
  fullImgDest="$CLUSTER_REGISTRY_ROUTE/$TARGET_NAMESPACE/${IMG_MAP[${img}_repo]}:${IMG_MAP[${img}_tgt_tag]}"

  $DOCKERCMD pull $fullImgSrc
  $DOCKERCMD tag $fullImgSrc $fullImgDest
  $DOCKERCMD push $fullImgDest
done
