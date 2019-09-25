# vim: set ft=sh:
DOWNSTREAM_REGISTRY="downstream.registry"
REPONAME=rhcam
IMAGES=(
  "openshift-migration-controller:v1.0-0.6"
  "openshift-migration-operator:v1.0-0.6"
  "openshift-migration-plugin:v1.0-0.1"
  "openshift-migration-ui:v1.0-0.13"
  "openshift-migration-velero:v1.0-0.9"
  "openshift-migration-velero-restic-restore-helper:v1.0-0.1"
)
