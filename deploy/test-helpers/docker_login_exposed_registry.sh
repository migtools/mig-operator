#!/bin/bash
_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source $_dir/my_var
docker login $CLUSTER_REGISTRY_ROUTE \
  -u mig-registry -p $MIG_REGISTRY_SA_TOKEN
