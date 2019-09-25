#!/bin/bash
_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source $_dir/my_var

echo "Mirroring downstream images..."
echo "Downstream registry: $DOWNSTREAM_REGISTRY"
echo "Target cluster registry: $CLUSTER_REGISTRY_ROUTE"
echo "Repo name: $REPONAME"

echo "Pulling images from:"
for img in "${IMAGES_TO_MIRROR[@]}"; do
  echo "-> $DOWNSTREAM_REGISTRY/$REPONAME/$img"
done

echo "Pushing images to:"
for img in "${IMAGES_TO_MIRROR[@]}"; do
  echo "-> $CLUSTER_REGISTRY_ROUTE/$REPONAME/$img"
done

for img in "${IMAGES_TO_MIRROR[@]}"; do
  fullImgSrc="$DOWNSTREAM_REGISTRY/$REPONAME/$img"
  fullImgDest="$CLUSTER_REGISTRY_ROUTE/$REPONAME/$img"

  docker pull $fullImgSrc
  docker tag $fullImgSrc $fullImgDest
  docker push $fullImgDest
done
