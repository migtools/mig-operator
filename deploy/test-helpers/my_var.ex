# vim: set ft=sh:
DOWNSTREAM_REGISTRY="downstream.registry"
DOWNSTREAM_REPONAME=rhcam
# NOTE: TARGET_REPONAME *MUST* BE AN EXISTING NAMESPACE IN THE TARGET CLUSTER
# IN THE CASE OF rhcam, YOU WILL LIKELY NEED TO MANUALLY CREATE THAT ON A NEW
# CLUSTER
TARGET_REPONAME=rhcam
IMAGES=(
  "openshift-migration-controller:v1.0"
  "openshift-migration-operator:v1.0"
  "openshift-migration-plugin:v1.0"
  "openshift-migration-ui:v1.0"
  "openshift-migration-velero:v1.0"
  "openshift-migration-velero-restic-restore-helper:v1.0"
  "openshift-migration-cpma:v1.0"
)
