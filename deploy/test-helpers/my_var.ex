# vim: set ft=sh:
DOWNSTREAM_REGISTRY="downstream.registry"
DOWNSTREAM_ORG=""
DOWNSTREAM_REPO_PREFIX=""
TARGET_NAMESPACE=rhcam
IMAGES=(
  "controller"
  "operator"
  "plugin"
  "ui"
  "velero"
  "helper"
  "cpma"
)
declare -A IMG_MAP
IMG_MAP[controller_repo]="openshift-migration-controller"
IMG_MAP[controller_ds_tag]="v1.0"
IMG_MAP[controller_tgt_name]="openshift-migration-controller-rhel8"
IMG_MAP[controller_tgt_tag]="v1.0"
IMG_MAP[operator_repo]="openshift-migration-operator"
IMG_MAP[operator_ds_tag]="v1.0"
IMG_MAP[operator_tgt_name]="openshift-migration-rhel7-operator"
IMG_MAP[operator_tgt_tag]="v1.0"
IMG_MAP[plugin_repo]="openshift-migration-plugin"
IMG_MAP[plugin_ds_tag]="v1.0"
IMG_MAP[plugin_tgt_name]="openshift-migration-plugin-rhel8"
IMG_MAP[plugin_tgt_tag]="v1.0"
IMG_MAP[ui_repo]="openshift-migration-ui"
IMG_MAP[ui_ds_tag]="v1.0"
IMG_MAP[ui_tgt_name]="openshift-migration-ui-rhel8"
IMG_MAP[ui_tgt_tag]="v1.0"
IMG_MAP[velero_repo]="openshift-migration-velero"
IMG_MAP[velero_ds_tag]="v1.0"
IMG_MAP[velero_tgt_name]="openshift-migration-velero-rhel8"
IMG_MAP[velero_tgt_tag]="v1.0"
IMG_MAP[helper_repo]="openshift-migration-velero-restic-restore-helper"
IMG_MAP[helper_ds_tag]="v1.0"
IMG_MAP[helper_tgt_name]="openshift-migration-velero-restic-restore-helper-rhel8"
IMG_MAP[helper_tgt_tag]="v1.0"
IMG_MAP[cpma_repo]="openshift-migration-cpma"
IMG_MAP[cpma_ds_tag]="v1.0"
IMG_MAP[cpma_tgt_name]="openshift-migration-cpma-rhel8"
IMG_MAP[cpma_tgt_tag]="v1.0"
