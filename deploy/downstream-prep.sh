#!/bin/bash

#Remove latest as option
if grep -q latest deploy/olm-catalog/mig-operator/mig-operator.package.yaml; then
  sed -i 3,4d deploy/olm-catalog/mig-operator/mig-operator.package.yaml
fi
sed -i s,mig-operator,cam-operator,g deploy/olm-catalog/mig-operator/mig-operator.package.yaml
rm -rf deploy/olm-catalog/mig-operator/stable deploy/olm-catalog/mig-operator/latest

if [ -d deploy/olm-catalog/mig-operator/v1.1.0 ]; then
  #Declare v1.1 image information
  V1_1_IMAGES=(
    "controller"
    "operator"
    "plugin"
    "ui"
    "velero"
    "helper"
    "gcpplugin"
    "awsplugin"
    "azureplugin"
  )

 declare -A V1_1_IMG_MAP
  V1_1_IMG_MAP[controller_repo]="openshift-migration-controller"
  V1_1_IMG_MAP[operator_repo]="openshift-migration-operator"
  V1_1_IMG_MAP[plugin_repo]="openshift-migration-plugin"
  V1_1_IMG_MAP[ui_repo]="openshift-migration-ui"
  V1_1_IMG_MAP[velero_repo]="openshift-migration-velero"
  V1_1_IMG_MAP[helper_repo]="openshift-migration-velero-restic-restore-helper"
  V1_1_IMG_MAP[gcpplugin_repo]="openshift-migration-velero-plugin-for-gcp"
  V1_1_IMG_MAP[awsplugin_repo]="openshift-migration-velero-plugin-for-aws"
  V1_1_IMG_MAP[azureplugin_repo]="openshift-migration-velero-plugin-for-microsoft-azure"

  #Get latest 1.1 images
  for i in ${V1_1_IMAGES[@]}; do
    docker pull registry-proxy.engineering.redhat.com/rh-osbs/rhcam-${V1_1_IMG_MAP[${i}_repo]}:v1.1 > /dev/null
  done

  #oc mirror 1.1 images to get correct shas
  for i in ${V1_1_IMAGES[@]}; do
    V1_1_IMG_MAP[${i}_sha]=$(oc image mirror --dry-run=true registry-proxy.engineering.redhat.com/rh-osbs/rhcam-${V1_1_IMG_MAP[${i}_repo]}:v1.1=quay.io/ocpmigrate/rhcam-${V1_1_IMG_MAP[${i}_repo]}:v1.1 2>&1 | grep -A1 manifests | grep sha256 | awk -F'[: ]' '{ print $8 }')
  done

  # Make 1.1.0 Downstream CSV Changes
  sed -i s,quay.io,image-registry.openshift-image-registry.svc:5000,g                                                             deploy/olm-catalog/mig-operator/v1.1.0/mig-operator.v1.1.0.clusterserviceversion.yaml
  sed -i s,ocpmigrate,rhcam-1-1,g                                                                                                 deploy/olm-catalog/mig-operator/v1.1.0/mig-operator.v1.1.0.clusterserviceversion.yaml
  sed -i "s,mig-operator:.*,openshift-migration-rhel7-operator@sha256:${V1_1_IMG_MAP[operator_sha]},g"                            deploy/olm-catalog/mig-operator/v1.1.0/mig-operator.v1.1.0.clusterserviceversion.yaml
  sed -i "s,rhel7-operator@sha256:.*,rhel7-operator@sha256:${V1_1_IMG_MAP[operator_sha]},g"                                       deploy/olm-catalog/mig-operator/v1.1.0/mig-operator.v1.1.0.clusterserviceversion.yaml
  sed -i s,mig-controller,openshift-migration-controller-rhel8@sha256,g                                                           deploy/olm-catalog/mig-operator/v1.1.0/mig-operator.v1.1.0.clusterserviceversion.yaml
  sed -i s,mig-ui,openshift-migration-ui-rhel8@sha256,g                                                                           deploy/olm-catalog/mig-operator/v1.1.0/mig-operator.v1.1.0.clusterserviceversion.yaml
  sed -i 's,value: velero-restic-restore-helper,value: openshift-migration-velero-restic-restore-helper-rhel8@sha256,g'           deploy/olm-catalog/mig-operator/v1.1.0/mig-operator.v1.1.0.clusterserviceversion.yaml
  sed -i 's,value: velero,value: openshift-migration-velero-rhel8@sha256,g'                                                       deploy/olm-catalog/mig-operator/v1.1.0/mig-operator.v1.1.0.clusterserviceversion.yaml
  sed -i 's,value: migration-plugin,value: openshift-migration-plugin-rhel8@sha256,g'                                             deploy/olm-catalog/mig-operator/v1.1.0/mig-operator.v1.1.0.clusterserviceversion.yaml
  sed -i 's,value: velero-plugin-for-gcp,value: openshift-migration-velero-plugin-for-gcp-rhel8@sha256,g'                         deploy/olm-catalog/mig-operator/v1.1.0/mig-operator.v1.1.0.clusterserviceversion.yaml
  sed -i 's,value: velero-plugin-for-aws,value: openshift-migration-velero-plugin-for-aws-rhel8@sha256,g'                         deploy/olm-catalog/mig-operator/v1.1.0/mig-operator.v1.1.0.clusterserviceversion.yaml
  sed -i 's,value: velero-plugin-for-microsoft-azure,value: openshift-migration-velero-plugin-for-microsoft-azure-rhel8@sha256,g' deploy/olm-catalog/mig-operator/v1.1.0/mig-operator.v1.1.0.clusterserviceversion.yaml
  sed -i s,mig-operator\.,cam-operator.,g                                                                                         deploy/olm-catalog/mig-operator/v1.1.0/mig-operator.v1.1.0.clusterserviceversion.yaml
  sed -i 's,: mig-operator,: cam-operator,g'                                                                                      deploy/olm-catalog/mig-operator/v1.1.0/mig-operator.v1.1.0.clusterserviceversion.yaml
  sed -i 's/displayName: Migration Operator/displayName: Cluster Application Migration Operator/g'                                deploy/olm-catalog/mig-operator/v1.1.0/mig-operator.v1.1.0.clusterserviceversion.yaml
  sed -i 's/The Migration Operator/The Cluster Application Migration Operator/g'                                                  deploy/olm-catalog/mig-operator/v1.1.0/mig-operator.v1.1.0.clusterserviceversion.yaml
  sed -i "/MIG_CONTROLLER_TAG/,/^ *[^:]*:/s/value: .*/value: ${V1_1_IMG_MAP[controller_sha]}/"                                    deploy/olm-catalog/mig-operator/v1.1.0/mig-operator.v1.1.0.clusterserviceversion.yaml
  sed -i "/MIG_UI_TAG/,/^ *[^:]*:/s/value: .*/value: ${V1_1_IMG_MAP[ui_sha]}/"                                                    deploy/olm-catalog/mig-operator/v1.1.0/mig-operator.v1.1.0.clusterserviceversion.yaml
  sed -i "/VELERO_PLUGIN_TAG/,/^ *[^:]*:/s/value: .*/value: ${V1_1_IMG_MAP[plugin_sha]}/"                                         deploy/olm-catalog/mig-operator/v1.1.0/mig-operator.v1.1.0.clusterserviceversion.yaml
  sed -i "/VELERO_TAG/,/^ *[^:]*:/s/value: .*/value: ${V1_1_IMG_MAP[velero_sha]}/"                                                deploy/olm-catalog/mig-operator/v1.1.0/mig-operator.v1.1.0.clusterserviceversion.yaml
  sed -i "/VELERO_RESTIC_RESTORE_HELPER_TAG/,/^ *[^:]*:/s/value: .*/value: ${V1_1_IMG_MAP[helper_sha]}/"                          deploy/olm-catalog/mig-operator/v1.1.0/mig-operator.v1.1.0.clusterserviceversion.yaml
  sed -i "/VELERO_GCP_PLUGIN_TAG/,/^ *[^:]*:/s/value: .*/value: ${V1_1_IMG_MAP[gcpplugin_sha]}/"                                  deploy/olm-catalog/mig-operator/v1.1.0/mig-operator.v1.1.0.clusterserviceversion.yaml
  sed -i "/VELERO_AWS_PLUGIN_TAG/,/^ *[^:]*:/s/value: .*/value: ${V1_1_IMG_MAP[awsplugin_sha]}/"                                  deploy/olm-catalog/mig-operator/v1.1.0/mig-operator.v1.1.0.clusterserviceversion.yaml
  sed -i "/VELERO_AZURE_PLUGIN_TAG/,/^ *[^:]*:/s/value: .*/value: ${V1_1_IMG_MAP[azureplugin_sha]}/"                              deploy/olm-catalog/mig-operator/v1.1.0/mig-operator.v1.1.0.clusterserviceversion.yaml

  # Make 1.1.0 Downstream non-OLM changes
  sed -i s,quay.io,registry.redhat.io,g                                                                                           deploy/non-olm/v1.1.0/operator.yml
  sed -i s,ocpmigrate,rhcam-1-1,g                                                                                                 deploy/non-olm/v1.1.0/operator.yml
  sed -i s,mig-operator:latest,openshift-migration-rhel7-operator:v1.1,g                                                          deploy/non-olm/v1.1.0/operator.yml
  sed -i s,mig-controller,openshift-migration-controller-rhel8@sha256,g                                                           deploy/non-olm/v1.1.0/operator.yml
  sed -i s,mig-ui,openshift-migration-ui-rhel8@sha256,g                                                                           deploy/non-olm/v1.1.0/operator.yml
  sed -i 's,value: velero-restic-restore-helper,value: openshift-migration-velero-restic-restore-helper-rhel8@sha256,g'           deploy/non-olm/v1.1.0/operator.yml
  sed -i 's,value: velero,value: openshift-migration-velero-rhel8@sha256,g'                                                       deploy/non-olm/v1.1.0/operator.yml
  sed -i 's,value: migration-plugin,value: openshift-migration-plugin-rhel8@sha256,g'                                             deploy/non-olm/v1.1.0/operator.yml
  sed -i 's,value: velero-plugin-for-gcp,value: openshift-migration-velero-plugin-for-gcp-rhel8@sha256,g'                         deploy/non-olm/v1.1.0/operator.yml
  sed -i 's,value: velero-plugin-for-aws,value: openshift-migration-velero-plugin-for-aws-rhel8@sha256,g'                         deploy/non-olm/v1.1.0/operator.yml
  sed -i 's,value: velero-plugin-for-microsoft-azure,value: openshift-migration-velero-plugin-for-microsoft-azure-rhel8@sha256,g' deploy/non-olm/v1.1.0/operator.yml
  sed -i "/MIG_CONTROLLER_TAG/,/^ *[^:]*:/s/value: .*/value: ${V1_1_IMG_MAP[controller_sha]}/"                                    deploy/non-olm/v1.1.0/operator.yml
  sed -i "/MIG_UI_TAG/,/^ *[^:]*:/s/value: .*/value: ${V1_1_IMG_MAP[ui_sha]}/"                                                    deploy/non-olm/v1.1.0/operator.yml
  sed -i "/VELERO_PLUGIN_TAG/,/^ *[^:]*:/s/value: .*/value: ${V1_1_IMG_MAP[plugin_sha]}/"                                         deploy/non-olm/v1.1.0/operator.yml
  sed -i "/VELERO_TAG/,/^ *[^:]*:/s/value: .*/value: ${V1_1_IMG_MAP[velero_sha]}/"                                                deploy/non-olm/v1.1.0/operator.yml
  sed -i "/VELERO_RESTIC_RESTORE_HELPER_TAG/,/^ *[^:]*:/s/value: .*/value: ${V1_1_IMG_MAP[helper_sha]}/"                          deploy/non-olm/v1.1.0/operator.yml
  sed -i "/VELERO_GCP_PLUGIN_TAG/,/^ *[^:]*:/s/value: .*/value: ${V1_1_IMG_MAP[gcpplugin_sha]}/"                                  deploy/non-olm/v1.1.0/operator.yml
  sed -i "/VELERO_AWS_PLUGIN_TAG/,/^ *[^:]*:/s/value: .*/value: ${V1_1_IMG_MAP[awsplugin_sha]}/"                                  deploy/non-olm/v1.1.0/operator.yml
  sed -i "/VELERO_AZURE_PLUGIN_TAG/,/^ *[^:]*:/s/value: .*/value: ${V1_1_IMG_MAP[azureplugin_sha]}/"                              deploy/non-olm/v1.1.0/operator.yml
fi

if [ -d deploy/olm-catalog/mig-operator/v1.0.0 ]; then
  #Declare v1.0 image information
  V1_0_IMAGES=(
    "controller"
    "operator"
    "plugin"
    "ui"
    "velero"
    "helper"
  )

 declare -A V1_0_IMG_MAP
  V1_0_IMG_MAP[controller_repo]="openshift-migration-controller"
  V1_0_IMG_MAP[operator_repo]="openshift-migration-operator"
  V1_0_IMG_MAP[plugin_repo]="openshift-migration-plugin"
  V1_0_IMG_MAP[ui_repo]="openshift-migration-ui"
  V1_0_IMG_MAP[velero_repo]="openshift-migration-velero"
  V1_0_IMG_MAP[helper_repo]="openshift-migration-velero-restic-restore-helper"

  #Get latest 1.0 images
  for i in ${V1_0_IMAGES[@]}; do
    docker pull registry-proxy.engineering.redhat.com/rh-osbs/rhcam-${V1_0_IMG_MAP[${i}_repo]}:v1.0 > /dev/null
  done

  #oc mirror 1.0 images to get correct shas
  for i in ${V1_0_IMAGES[@]}; do
    V1_0_IMG_MAP[${i}_sha]=$(oc image mirror --dry-run=true registry-proxy.engineering.redhat.com/rh-osbs/rhcam-${V1_0_IMG_MAP[${i}_repo]}:v1.0=quay.io/ocpmigrate/rhcam-${V1_0_IMG_MAP[${i}_repo]}:v1.0 2>&1 | grep -A1 manifests | grep sha256 | awk -F'[: ]' '{ print $8 }')
  done

  # Make 1.0.0 Downstream CSV Changes
  sed -i s,quay.io,image-registry.openshift-image-registry.svc:5000,g                                                   deploy/olm-catalog/mig-operator/v1.0.0/mig-operator.v1.0.0.clusterserviceversion.yaml
  sed -i s,ocpmigrate,rhcam,g                                                                                           deploy/olm-catalog/mig-operator/v1.0.0/mig-operator.v1.0.0.clusterserviceversion.yaml
  sed -i s,mig-operator:,openshift-migration-rhel7-operator:,g                                                          deploy/olm-catalog/mig-operator/v1.0.0/mig-operator.v1.0.0.clusterserviceversion.yaml
  sed -i s,mig-controller,openshift-migration-controller-rhel8,g                                                        deploy/olm-catalog/mig-operator/v1.0.0/mig-operator.v1.0.0.clusterserviceversion.yaml
  sed -i s,mig-ui,openshift-migration-ui-rhel8,g                                                                        deploy/olm-catalog/mig-operator/v1.0.0/mig-operator.v1.0.0.clusterserviceversion.yaml
  sed -i 's,value: velero-restic-restore-helper,value: openshift-migration-velero-restic-restore-helper-rhel8,g'        deploy/olm-catalog/mig-operator/v1.0.0/mig-operator.v1.0.0.clusterserviceversion.yaml
  sed -i 's,value: velero,value: openshift-migration-velero-rhel8,g'                                                    deploy/olm-catalog/mig-operator/v1.0.0/mig-operator.v1.0.0.clusterserviceversion.yaml
  sed -i 's,value: migration-plugin,value: openshift-migration-plugin-rhel8,g'                                          deploy/olm-catalog/mig-operator/v1.0.0/mig-operator.v1.0.0.clusterserviceversion.yaml
  sed -i s,release-1.0,v1.0,g                                                                                           deploy/olm-catalog/mig-operator/v1.0.0/mig-operator.v1.0.0.clusterserviceversion.yaml
  sed -i s,fusor-1.1,v1.0,g                                                                                             deploy/olm-catalog/mig-operator/v1.0.0/mig-operator.v1.0.0.clusterserviceversion.yaml
  sed -i s,mig-operator\.,cam-operator.,g                                                                               deploy/olm-catalog/mig-operator/v1.0.0/mig-operator.v1.0.0.clusterserviceversion.yaml
  sed -i 's,: mig-operator,: cam-operator,g'                                                                            deploy/olm-catalog/mig-operator/v1.0.0/mig-operator.v1.0.0.clusterserviceversion.yaml
  sed -i 's/displayName: Migration Operator/displayName: Cluster Application Migration Operator/g'                      deploy/olm-catalog/mig-operator/v1.0.0/mig-operator.v1.0.0.clusterserviceversion.yaml
  sed -i 's/The Migration Operator/The Cluster Application Migration Operator/g'                                        deploy/olm-catalog/mig-operator/v1.0.0/mig-operator.v1.0.0.clusterserviceversion.yaml

  # Make 1.0.0 Downstream non-OLM changes
  sed -i s,quay.io,registry.redhat.io,g                                                                                 deploy/non-olm/v1.0.0/operator.yml
  sed -i s,ocpmigrate,rhcam-1-0,g                                                                                       deploy/non-olm/v1.0.0/operator.yml
  sed -i s,mig-operator:,openshift-migration-rhel7-operator:,g                                                          deploy/non-olm/v1.0.0/operator.yml
  sed -i s,mig-controller,openshift-migration-controller-rhel8,g                                                        deploy/non-olm/v1.0.0/operator.yml
  sed -i s,mig-ui,openshift-migration-ui-rhel8,g                                                                        deploy/non-olm/v1.0.0/operator.yml
  sed -i 's,value: velero-restic-restore-helper,value: openshift-migration-velero-restic-restore-helper-rhel8,g'        deploy/non-olm/v1.0.0/operator.yml
  sed -i 's,value: velero,value: openshift-migration-velero-rhel8,g'                                                    deploy/non-olm/v1.0.0/operator.yml
  sed -i 's,value: migration-plugin,value: openshift-migration-plugin-rhel8,g'                                          deploy/non-olm/v1.0.0/operator.yml
  sed -i s,release-1.0,v1.0,g                                                                                           deploy/non-olm/v1.0.0/operator.yml
  sed -i s,fusor-1.1,v1.0,g                                                                                             deploy/non-olm/v1.0.0/operator.yml

  # Make 1.0.1 Downstream CSV Changes
  sed -i s,quay.io,image-registry.openshift-image-registry.svc:5000,g                                                   deploy/olm-catalog/mig-operator/v1.0.1/mig-operator.v1.0.1.clusterserviceversion.yaml
  sed -i s,ocpmigrate,rhcam-1-0,g                                                                                       deploy/olm-catalog/mig-operator/v1.0.1/mig-operator.v1.0.1.clusterserviceversion.yaml
  sed -i "s,mig-operator:.*,openshift-migration-rhel7-operator@sha256:${V1_0_IMG_MAP[operator_sha]},g"                  deploy/olm-catalog/mig-operator/v1.0.1/mig-operator.v1.0.1.clusterserviceversion.yaml
  sed -i "s,rhel7-operator@sha256:.*,rhel7-operator@sha256:${V1_0_IMG_MAP[operator_sha]},g"                             deploy/olm-catalog/mig-operator/v1.0.1/mig-operator.v1.0.1.clusterserviceversion.yaml
  sed -i s,mig-controller,openshift-migration-controller-rhel8@sha256,g                                                 deploy/olm-catalog/mig-operator/v1.0.1/mig-operator.v1.0.1.clusterserviceversion.yaml
  sed -i s,mig-ui,openshift-migration-ui-rhel8@sha256,g                                                                 deploy/olm-catalog/mig-operator/v1.0.1/mig-operator.v1.0.1.clusterserviceversion.yaml
  sed -i 's,value: velero-restic-restore-helper,value: openshift-migration-velero-restic-restore-helper-rhel8@sha256,g' deploy/olm-catalog/mig-operator/v1.0.1/mig-operator.v1.0.1.clusterserviceversion.yaml
  sed -i 's,value: velero,value: openshift-migration-velero-rhel8@sha256,g'                                             deploy/olm-catalog/mig-operator/v1.0.1/mig-operator.v1.0.1.clusterserviceversion.yaml
  sed -i 's,value: migration-plugin,value: openshift-migration-plugin-rhel8@sha256,g'                                   deploy/olm-catalog/mig-operator/v1.0.1/mig-operator.v1.0.1.clusterserviceversion.yaml
  sed -i s,mig-operator\.,cam-operator.,g                                                                               deploy/olm-catalog/mig-operator/v1.0.1/mig-operator.v1.0.1.clusterserviceversion.yaml
  sed -i 's,: mig-operator,: cam-operator,g'                                                                            deploy/olm-catalog/mig-operator/v1.0.1/mig-operator.v1.0.1.clusterserviceversion.yaml
  sed -i 's/displayName: Migration Operator/displayName: Cluster Application Migration Operator/g'                      deploy/olm-catalog/mig-operator/v1.0.1/mig-operator.v1.0.1.clusterserviceversion.yaml
  sed -i 's/The Migration Operator/The Cluster Application Migration Operator/g'                                        deploy/olm-catalog/mig-operator/v1.0.1/mig-operator.v1.0.1.clusterserviceversion.yaml
  sed -i "/MIG_CONTROLLER_TAG/,/^ *[^:]*:/s/value: .*/value: ${V1_0_IMG_MAP[controller_sha]}/"                          deploy/olm-catalog/mig-operator/v1.0.1/mig-operator.v1.0.1.clusterserviceversion.yaml
  sed -i "/MIG_UI_TAG/,/^ *[^:]*:/s/value: .*/value: ${V1_0_IMG_MAP[ui_sha]}/"                                          deploy/olm-catalog/mig-operator/v1.0.1/mig-operator.v1.0.1.clusterserviceversion.yaml
  sed -i "/VELERO_PLUGIN_TAG/,/^ *[^:]*:/s/value: .*/value: ${V1_0_IMG_MAP[plugin_sha]}/"                               deploy/olm-catalog/mig-operator/v1.0.1/mig-operator.v1.0.1.clusterserviceversion.yaml
  sed -i "/VELERO_TAG/,/^ *[^:]*:/s/value: .*/value: ${V1_0_IMG_MAP[velero_sha]}/"                                      deploy/olm-catalog/mig-operator/v1.0.1/mig-operator.v1.0.1.clusterserviceversion.yaml
  sed -i "/VELERO_RESTIC_RESTORE_HELPER_TAG/,/^ *[^:]*:/s/value: .*/value: ${V1_0_IMG_MAP[helper_sha]}/"                deploy/olm-catalog/mig-operator/v1.0.1/mig-operator.v1.0.1.clusterserviceversion.yaml

  # Make 1.0.1 Downstream non-OLM changes
  sed -i s,quay.io,registry.redhat.io,g                                                                                 deploy/non-olm/v1.0.1/operator.yml
  sed -i s,ocpmigrate,rhcam-1-0,g                                                                                       deploy/non-olm/v1.0.1/operator.yml
  sed -i s,mig-operator:release-1\.0,openshift-migration-rhel7-operator:v1.0,g                                          deploy/non-olm/v1.0.1/operator.yml
  sed -i s,mig-controller,openshift-migration-controller-rhel8@sha256,g                                                 deploy/non-olm/v1.0.1/operator.yml
  sed -i s,mig-ui,openshift-migration-ui-rhel8@sha256,g                                                                 deploy/non-olm/v1.0.1/operator.yml
  sed -i 's,value: velero-restic-restore-helper,value: openshift-migration-velero-restic-restore-helper-rhel8@sha256,g' deploy/non-olm/v1.0.1/operator.yml
  sed -i 's,value: velero,value: openshift-migration-velero-rhel8@sha256,g'                                             deploy/non-olm/v1.0.1/operator.yml
  sed -i 's,value: migration-plugin,value: openshift-migration-plugin-rhel8@sha256,g'                                   deploy/non-olm/v1.0.1/operator.yml
  sed -i "/MIG_CONTROLLER_TAG/,/^ *[^:]*:/s/value: .*/value: ${V1_0_IMG_MAP[controller_sha]}/"                          deploy/non-olm/v1.0.1/operator.yml
  sed -i "/MIG_UI_TAG/,/^ *[^:]*:/s/value: .*/value: ${V1_0_IMG_MAP[ui_sha]}/"                                          deploy/non-olm/v1.0.1/operator.yml
  sed -i "/VELERO_PLUGIN_TAG/,/^ *[^:]*:/s/value: .*/value: ${V1_0_IMG_MAP[plugin_sha]}/"                               deploy/non-olm/v1.0.1/operator.yml
  sed -i "/VELERO_TAG/,/^ *[^:]*:/s/value: .*/value: ${V1_0_IMG_MAP[velero_sha]}/"                                      deploy/non-olm/v1.0.1/operator.yml
  sed -i "/VELERO_RESTIC_RESTORE_HELPER_TAG/,/^ *[^:]*:/s/value: .*/value: ${V1_0_IMG_MAP[helper_sha]}/"                deploy/non-olm/v1.0.1/operator.yml
fi
