#!/bin/bash

#Find most recent version
export MTCVERSION=$(ls deploy/olm-catalog/bundle/manifests/konveyor-operator.v* | awk -F '.' '{out=""; for(i=2;i<4;i++){out=out$i"."}{out=out$4}; print out}')
#Checkout all the old operator.ymls and CSVs
git checkout origin/$(git branch --show-current) -- Dockerfile
git checkout origin/$(git branch --show-current) -- .gitignore
git checkout origin/$(git branch --show-current) -- content_sets.yml
git checkout origin/$(git branch --show-current) -- container.yaml
for i in $(ls -1d deploy/non-olm/v* | grep -v $MTCVERSION); do git checkout origin/$(git branch --show-current) $i; done

#deal with k8s_status change upstream/downstream
sed -i "s,ansible_operator_meta,meta,g" roles/migrationcontroller/tasks/main.yml
sed -i "s,ansible_operator_meta,meta,g" roles/migrationcontroller/templates/migration-controller.yml.j2

#Fix differing entrypoint
sed -i 's,.tini.*,exec ${OPERATOR} exec-entrypoint ansible --watches-file=/opt/ansible/watches.yaml $@,g' build/entrypoint

#Declare image information
IMAGES=(
  "controller"
  "operator"
  "plugin"
  "ui"
  "velero"
  "helper"
  "gcpplugin"
  "awsplugin"
  "azureplugin"
  "registry"
  "mustgather"
  "hookrunner"
  "logreader"
)

declare -A IMG_MAP
IMG_MAP[controller_repo]="openshift-migration-controller"
IMG_MAP[operator_repo]="openshift-migration-operator"
IMG_MAP[plugin_repo]="openshift-velero-plugin"
IMG_MAP[ui_repo]="openshift-migration-ui"
IMG_MAP[velero_repo]="openshift-migration-velero"
IMG_MAP[helper_repo]="openshift-migration-velero-restic-restore-helper"
IMG_MAP[gcpplugin_repo]="openshift-migration-velero-plugin-for-gcp"
IMG_MAP[awsplugin_repo]="openshift-migration-velero-plugin-for-aws"
IMG_MAP[azureplugin_repo]="openshift-migration-velero-plugin-for-microsoft-azure"
IMG_MAP[registry_repo]="openshift-migration-registry"
IMG_MAP[mustgather_repo]="openshift-migration-must-gather"
IMG_MAP[hookrunner_repo]="openshift-migration-hook-runner"
IMG_MAP[logreader_repo]="openshift-migration-log-reader"

#Get latest images
for i in ${IMAGES[@]}; do
  docker pull registry-proxy.engineering.redhat.com/rh-osbs/rhmtc-${IMG_MAP[${i}_repo]}:${MTCVERSION} >/dev/null 2>&1
  DOCKER_STAT=$?
  RETRIES=10
  while [ "$DOCKER_STAT" -ne 0 ] && [ $RETRIES -gt 0 ]; do
    docker pull registry-proxy.engineering.redhat.com/rh-osbs/rhmtc-${IMG_MAP[${i}_repo]}:${MTCVERSION} >/dev/null 2>&1
    DOCKER_STAT=$?
    let RETRIES=RETRIES-1
  done

  if [ $RETRIES -le 0 ]; then
    echo "Failed to pull new images"
    exit 1
  fi
done

#oc mirror images to get correct shas
for i in ${IMAGES[@]}; do
  RETRIES=10
  while [ -z "${IMG_MAP[${i}_sha]}" ] && [ $RETRIES -gt 0 ]; do
    IMG_MAP[${i}_sha]=$(oc image mirror --dry-run=true registry-proxy.engineering.redhat.com/rh-osbs/rhmtc-${IMG_MAP[${i}_repo]}:${MTCVERSION}=quay.io/ocpmigrate/rhmtc-${IMG_MAP[${i}_repo]}:${MTCVERSION} 2>&1 | grep -A1 manifests | grep sha256 | awk -F'[: ]' '{ print $8 }')
    let RETRIES=RETRIES-1
  done

  if [ $RETRIES -le 0 ]; then
    echo "Failed to mirror images to obtain SHAs"
    exit 1
  fi
done

# Make Downstream CSV Changes
for f in deploy/olm-catalog/bundle/manifests/konveyor-operator.${MTCVERSION}.clusterserviceversion.yaml \
         deploy/non-olm/${MTCVERSION}/operator.yml
  do
  if [[ "$f" =~ .*clusterserviceversion.* ]]; then
    sed -i "s,mig-operator-container:.*,openshift-migration-rhel7-operator@sha256:${IMG_MAP[operator_sha]},g"                                                        ${f}
  else
    sed -i "s,mig-operator-container:.*,openshift-migration-rhel7-operator:${MTCVERSION},g"                                                                          ${f}
  fi
  sed -i 's,quay.io,registry.redhat.io,g'                                                                                                                            ${f}
  sed -i "s,registry.redhat.io\/konveyor,registry.redhat.io/rhmtc,g"                                                                                                 ${f}
  sed -i "s,value: konveyor,value: rhmtc,g"                                                                                                                          ${f}
  sed -i "s,/mig-controller:.*,/openshift-migration-controller-rhel8@sha256:${IMG_MAP[controller_sha]},g"                                                            ${f}
  sed -i "s,/mig-ui:.*,/openshift-migration-ui-rhel8@sha256:${IMG_MAP[ui_sha]},g"                                                                                    ${f}
  sed -i "s,/velero:.*,/openshift-migration-velero-rhel8@sha256:${IMG_MAP[velero_sha]},g"                                                                            ${f}
  sed -i "s,/velero-restic-restore-helper:.*,/openshift-migration-velero-restic-restore-helper-rhel8@sha256:${IMG_MAP[helper_sha]},g"                                ${f}
  sed -i "s,/openshift-velero-plugin:.*,/openshift-velero-plugin-rhel8@sha256:${IMG_MAP[plugin_sha]},g"                                                              ${f}
  sed -i "s,/velero-plugin-for-aws:.*,/openshift-migration-velero-plugin-for-aws-rhel8@sha256:${IMG_MAP[awsplugin_sha]},g"                                           ${f}
  sed -i "s,/velero-plugin-for-microsoft-azure:.*,/openshift-migration-velero-plugin-for-microsoft-azure-rhel8@sha256:${IMG_MAP[azureplugin_sha]},g"                 ${f}
  sed -i "s,/velero-plugin-for-gcp:.*,/openshift-migration-velero-plugin-for-gcp-rhel8@sha256:${IMG_MAP[gcpplugin_sha]},g"                                           ${f}
  sed -i "s,/registry:.*,/openshift-migration-registry-rhel8@sha256:${IMG_MAP[registry_sha]},g"                                                                      ${f}
  sed -i "s,/hook-runner:.*,/openshift-migration-hook-runner-rhel7@sha256:${IMG_MAP[hookrunner_sha]},g"                                                              ${f}
  sed -i "s,/mig-log-reader:.*,/openshift-migration-log-reader-rhel8@sha256:${IMG_MAP[logreader_sha]},g"                                                             ${f}
  sed -i "s,rhel7-operator@sha256:.*,rhel7-operator@sha256:${IMG_MAP[operator_sha]},g"                                                                               ${f}
  sed -i "s,controller-rhel8@sha256:.*,controller-rhel8@sha256:${IMG_MAP[controller_sha]},g"                                                                         ${f}
  sed -i "s,ui-rhel8@sha256:.*,ui-rhel8@sha256:${IMG_MAP[ui_sha]},g"                                                                                                 ${f}
  sed -i "s,velero-rhel8@sha256:.*,velero-rhel8@sha256:${IMG_MAP[velero_sha]},g"                                                                                     ${f}
  sed -i "s,velero-restic-restore-helper-rhel8@sha256:.*,velero-restic-restore-helper-rhel8@sha256:${IMG_MAP[helper_sha]},g"                                         ${f}
  sed -i "s,plugin-rhel8@sha256:.*,plugin-rhel8@sha256:${IMG_MAP[plugin_sha]},g"                                                                                     ${f}
  sed -i "s,aws-rhel8@sha256:.*,aws-rhel8@sha256:${IMG_MAP[awsplugin_sha]},g"                                                                                        ${f}
  sed -i "s,azure-rhel8@sha256:.*,azure-rhel8@sha256:${IMG_MAP[azureplugin_sha]},g"                                                                                  ${f}
  sed -i "s,gcp-rhel8@sha256:.*,gcp-rhel8@sha256:${IMG_MAP[gcpplugin_sha]},g"                                                                                        ${f}
  sed -i "s,registry-rhel8@sha256:.*,registry-rhel8@sha256:${IMG_MAP[registry_sha]},g"                                                                               ${f}
  sed -i "s,hook-runner-rhel7@sha256:.*,hook-runner-rhel7@sha256:${IMG_MAP[hookrunner_sha]},g"                                                                       ${f}
  sed -i 's,value: hook-runner,value: openshift-migration-hook-runner-rhel7@sha256,g'                                                                                ${f}
  sed -i "s,log-reader-rhel8@sha256:.*,log-reader-rhel8@sha256:${IMG_MAP[logreader_sha]},g"                                                                          ${f}
  sed -i 's,value: mig-log-reader,value: openshift-migration-log-reader-rhel8@sha256,g'                                                                              ${f}
  sed -i 's,value: mig-controller,value: openshift-migration-controller-rhel8@sha256,g'                                                                              ${f}
  sed -i 's,value: mig-ui,value: openshift-migration-ui-rhel8@sha256,g'                                                                                              ${f}
  sed -i 's,value: velero-restic-restore-helper,value: openshift-migration-velero-restic-restore-helper-rhel8@sha256,g'                                              ${f}
  sed -i 's,value: velero-plugin-for-gcp,value: openshift-migration-velero-plugin-for-gcp-rhel8@sha256,g'                                                            ${f}
  sed -i 's,value: velero-plugin-for-aws,value: openshift-migration-velero-plugin-for-aws-rhel8@sha256,g'                                                            ${f}
  sed -i 's,value: velero-plugin-for-microsoft-azure,value: openshift-migration-velero-plugin-for-microsoft-azure-rhel8@sha256,g'                                    ${f}
  sed -i 's,value: velero,value: openshift-migration-velero-rhel8@sha256,g'                                                                                          ${f}
  sed -i 's,value: openshift-velero-plugin$,value: openshift-velero-plugin-rhel8@sha256,g'                                                                           ${f}
  sed -i 's,value: registry$,value: openshift-migration-registry-rhel8@sha256,g'                                                                                     ${f}
  sed -i 's,konveyor-operator\.,mtc-operator.,g'                                                                                                                     ${f}
  sed -i 's,:\ konveyor-operator,: mtc-operator,g'                                                                                                                   ${f}
  sed -i 's/displayName: Konveyor Operator for Containers/displayName: Migration Toolkit for Containers Operator/g'                                                  ${f}
  sed -i 's/The Konveyor Operator/The Migration Toolkit for Containers Operator/g'                                                                                   ${f}
  sed -i "/MIG_CONTROLLER_TAG/,/^ *[^:]*:/s/value: .*/value: ${IMG_MAP[controller_sha]}/"                                                                            ${f}
  sed -i "/MIG_UI_TAG/,/^ *[^:]*:/s/value: .*/value: ${IMG_MAP[ui_sha]}/"                                                                                            ${f}
  sed -i "/VELERO_PLUGIN_TAG/,/^ *[^:]*:/s/value: .*/value: ${IMG_MAP[plugin_sha]}/"                                                                                 ${f}
  sed -i "/VELERO_TAG/,/^ *[^:]*:/s/value: .*/value: ${IMG_MAP[velero_sha]}/"                                                                                        ${f}
  sed -i "/VELERO_RESTIC_RESTORE_HELPER_TAG/,/^ *[^:]*:/s/value: .*/value: ${IMG_MAP[helper_sha]}/"                                                                  ${f}
  sed -i "/VELERO_GCP_PLUGIN_TAG/,/^ *[^:]*:/s/value: .*/value: ${IMG_MAP[gcpplugin_sha]}/"                                                                          ${f}
  sed -i "/VELERO_AWS_PLUGIN_TAG/,/^ *[^:]*:/s/value: .*/value: ${IMG_MAP[awsplugin_sha]}/"                                                                          ${f}
  sed -i "/VELERO_AZURE_PLUGIN_TAG/,/^ *[^:]*:/s/value: .*/value: ${IMG_MAP[azureplugin_sha]}/"                                                                      ${f}
  sed -i "/MIGRATION_REGISTRY_TAG/,/^ *[^:]*:/s/value: .*/value: ${IMG_MAP[registry_sha]}/"                                                                          ${f}
  sed -i "/HOOK_RUNNER_TAG/,/^ *[^:]*:/s/value: .*/value: ${IMG_MAP[hookrunner_sha]}/"                                                                               ${f}
  sed -i "/MIG_LOG_READER_TAG/,/^ *[^:]*:/s/value: .*/value: ${IMG_MAP[logreader_sha]}/"                                                                             ${f}
  sed -i "/name: Documentation/,/^ *[^:]*:/s/url: .*/url: https:\/\/docs.openshift.com\/container-platform\/latest\/migration\/migrating_3_4\/about-migration.html/" ${f}
if [[ "$f" =~ .*clusterserviceversion.* ]] && ! grep -q infrastructure-features ${f}; then
  sed -i '/^spec:/i\ \ \ \ operators.openshift.io/infrastructure-features: \x27[\"Disconnected\"]\x27'                                                               ${f}
fi
if [[ "$f" =~ .*clusterserviceversion.* ]] && ! grep -q cluster-monitoring ${f}; then
  sed -i '/^spec:/i\ \ \ \ operatorframework.io/cluster-monitoring: "true"'                                                                                          ${f}
fi
done

#replace base64 encoded image:
for i in $(find ./ -name *clusterserviceversion*); do
  sed -i 's/base64data.*/base64data: PHN2ZyBpZD0iTGF5ZXJfMSIgZGF0YS1uYW1lPSJMYXllciAxIiB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCAxOTIgMTQ1Ij48ZGVmcz48c3R5bGU+LmNscy0xe2ZpbGw6I2UwMDt9PC9zdHlsZT48L2RlZnM+PHRpdGxlPlJlZEhhdC1Mb2dvLUhhdC1Db2xvcjwvdGl0bGU+PHBhdGggZD0iTTE1Ny43Nyw2Mi42MWExNCwxNCwwLDAsMSwuMzEsMy40MmMwLDE0Ljg4LTE4LjEsMTcuNDYtMzAuNjEsMTcuNDZDNzguODMsODMuNDksNDIuNTMsNTMuMjYsNDIuNTMsNDRhNi40Myw2LjQzLDAsMCwxLC4yMi0xLjk0bC0zLjY2LDkuMDZhMTguNDUsMTguNDUsMCwwLDAtMS41MSw3LjMzYzAsMTguMTEsNDEsNDUuNDgsODcuNzQsNDUuNDgsMjAuNjksMCwzNi40My03Ljc2LDM2LjQzLTIxLjc3LDAtMS4wOCwwLTEuOTQtMS43My0xMC4xM1oiLz48cGF0aCBjbGFzcz0iY2xzLTEiIGQ9Ik0xMjcuNDcsODMuNDljMTIuNTEsMCwzMC42MS0yLjU4LDMwLjYxLTE3LjQ2YTE0LDE0LDAsMCwwLS4zMS0zLjQybC03LjQ1LTMyLjM2Yy0xLjcyLTcuMTItMy4yMy0xMC4zNS0xNS43My0xNi42QzEyNC44OSw4LjY5LDEwMy43Ni41LDk3LjUxLjUsOTEuNjkuNSw5MCw4LDgzLjA2LDhjLTYuNjgsMC0xMS42NC01LjYtMTcuODktNS42LTYsMC05LjkxLDQuMDktMTIuOTMsMTIuNSwwLDAtOC40MSwyMy43Mi05LjQ5LDI3LjE2QTYuNDMsNi40MywwLDAsMCw0Mi41Myw0NGMwLDkuMjIsMzYuMywzOS40NSw4NC45NCwzOS40NU0xNjAsNzIuMDdjMS43Myw4LjE5LDEuNzMsOS4wNSwxLjczLDEwLjEzLDAsMTQtMTUuNzQsMjEuNzctMzYuNDMsMjEuNzdDNzguNTQsMTA0LDM3LjU4LDc2LjYsMzcuNTgsNTguNDlhMTguNDUsMTguNDUsMCwwLDEsMS41MS03LjMzQzIyLjI3LDUyLC41LDU1LC41LDc0LjIyYzAsMzEuNDgsNzQuNTksNzAuMjgsMTMzLjY1LDcwLjI4LDQ1LjI4LDAsNTYuNy0yMC40OCw1Ni43LTM2LjY1LDAtMTIuNzItMTEtMjcuMTYtMzAuODMtMzUuNzgiLz48L3N2Zz4=/g' $i
  sed -i 's,image/png,image/svg+xml,g' $i
done
