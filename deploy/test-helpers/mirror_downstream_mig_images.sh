#!/bin/bash
_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source $_dir/my_var

DOCKERCMD=${DOCKERCMD:-docker}

echo "Mirroring downstream images..."
echo "Downstream registry: $DOWNSTREAM_REGISTRY"
echo "Target cluster registry: $CLUSTER_REGISTRY_ROUTE"
echo "Downstream repo name: $DOWNSTREAM_REPONAME"
echo "Target repo name: $TARGET_REPONAME"

echo "Pulling images from:"
for img in "${IMAGES_TO_MIRROR[@]}"; do
  echo "-> $DOWNSTREAM_REGISTRY/$DOWNSTREAM_REPONAME/$img"
done

echo "Pushing images to:"
for img in "${IMAGES_TO_MIRROR[@]}"; do
  echo "-> $CLUSTER_REGISTRY_ROUTE/$TARGET_REPONAME/$img"
done

for img in "${IMAGES_TO_MIRROR[@]}"; do
  fullImgSrc="$DOWNSTREAM_REGISTRY/$DOWNSTREAM_REPONAME/$img"
  fullImgDest="$CLUSTER_REGISTRY_ROUTE/$TARGET_REPONAME/$img"

  $DOCKERCMD pull $fullImgSrc
  $DOCKERCMD tag $fullImgSrc $fullImgDest
  $DOCKERCMD push $fullImgDest
done
