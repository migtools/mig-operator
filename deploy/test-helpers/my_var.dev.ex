# vim: set ft=sh:
# DEV SETTINGS
# NOTE: YOU MUST SET THIS REGISTRY LOCATION
DOWNSTREAM_REGISTRY="downstream.registry"

# THESE SETTINGS SHOULD NOT REQUIRE EDITING
DOWNSTREAM_ORG="rhcam-1-0"
DOWNSTREAM_REPO_PREFIX="rhcam-"
TARGET_NAMESPACE="rhcam-1-0"
IMAGES=(
  "controller"
  "operator"
  "plugin"
  "ui"
  "velero"
  "helper"
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
