#!/bin/bash
_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source $_dir/my_var
totalRetries=10
sleepInterval=5

echo "Patching image registry to expose a route..."
oc patch configs.imageregistry.operator.openshift.io/cluster -p='{"spec":{"defaultRoute":true}}' --type=merge

echo "Waiting for exposed registry route..."
externalRouteTries=0
defaultRegistryRoute=""
while true; do
  if [[ $externalRouteTries -eq $totalRetries ]]; then
    echo "ERROR: Timed out while waiting for external registry route to be exposed"
    exit 1
  fi
  echo "Attempt: $((externalRouteTries+1))"

  queryResult=$(oc get images.config.openshift.io -o yaml | egrep -o 'default-route.*$')
  if [[ "$queryResult" != "" ]]; then
    defaultRegistryRoute=$queryResult
    break
  fi

  externalRouteTries=$((externalRouteTries+1))
  sleep $sleepInterval
done

echo "Found default route:"
echo "-> $defaultRegistryRoute"

sleep 3
echo 'Creating ServiceAccount: "mig-registry" in openshift-marketplace for registry access...'
oc create -f $_dir/mig-registry.sa.yml
echo 'Writing mig-registry SA token to my_var...'
sed -i '/MIG_REGISTRY_SA_TOKEN/d' $_dir/my_var
echo "MIG_REGISTRY_SA_TOKEN=\"$(oc sa -n openshift-marketplace get-token mig-registry)\"" >> $_dir/my_var
sed -i '/CLUSTER_REGISTRY_ROUTE/d' $_dir/my_var
echo "CLUSTER_REGISTRY_ROUTE=\"$defaultRegistryRoute\"" >> $_dir/my_var

echo ""
echo "============================================================"
echo "Ensure both of the following registries are configured as"
echo "insecure registries in your docker config and you have reloaded"
echo "the service:"
echo ""
echo "$DOWNSTREAM_REGISTRY"
echo "$defaultRegistryRoute"
echo ""
echo "Login to your target cluster's exposed registry with the exported script:"
echo "$_dir/docker_login_exposed_registry.sh"
echo ""
echo "Once the above has completed, you should be ready to run"
echo "mirror_downstream_mig_images.sh to import images from brew into your"
echo "4.x cluster."
echo "============================================================"
