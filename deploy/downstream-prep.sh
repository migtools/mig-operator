#!/bin/bash

#Remove latest and stable as options
sed -i 3,6d deploy/olm-catalog/mig-operator/mig-operator.package.yaml
sed -i s,mig-operator,cam-operator,g deploy/olm-catalog/mig-operator/mig-operator.package.yaml
rm -rf deploy/olm-catalog/mig-operator/stable deploy/olm-catalog/mig-operator/latest

# 1.0.0 Downstream CSV Changes
sed -i s,quay.io,image-registry.openshift-image-registry.svc:5000,g                              deploy/olm-catalog/mig-operator/v1.0.0/mig-operator.v1.0.0.clusterserviceversion.yaml
sed -i s,ocpmigrate,rhcam,g                                                                      deploy/olm-catalog/mig-operator/v1.0.0/mig-operator.v1.0.0.clusterserviceversion.yaml
sed -i s,mig-operator:,openshift-migration-rhel7-operator:,g                                     deploy/olm-catalog/mig-operator/v1.0.0/mig-operator.v1.0.0.clusterserviceversion.yaml
sed -i s,mig-operator:,openshift-migration-rhel7-operator:,g                                     deploy/olm-catalog/mig-operator/v1.0.0/mig-operator.v1.0.0.clusterserviceversion.yaml
sed -i s,mig-controller,openshift-migration-controller-rhel8,g                                   deploy/olm-catalog/mig-operator/v1.0.0/mig-operator.v1.0.0.clusterserviceversion.yaml
sed -i s,mig-ui,openshift-migration-ui-rhel8,g                                                   deploy/olm-catalog/mig-operator/v1.0.0/mig-operator.v1.0.0.clusterserviceversion.yaml
sed -i 's,velero-restic-restore-helper,openshift-migration-velero-restic-restore-helper-rhel8,g' deploy/olm-catalog/mig-operator/v1.0.0/mig-operator.v1.0.0.clusterserviceversion.yaml
sed -i 's,value: velero,value: openshift-migration-velero-rhel8,g'                               deploy/olm-catalog/mig-operator/v1.0.0/mig-operator.v1.0.0.clusterserviceversion.yaml
sed -i s,migration-plugin,openshift-migration-plugin-rhel8,g                                     deploy/olm-catalog/mig-operator/v1.0.0/mig-operator.v1.0.0.clusterserviceversion.yaml
sed -i s,release-1.0,v1.0,g                                                                      deploy/olm-catalog/mig-operator/v1.0.0/mig-operator.v1.0.0.clusterserviceversion.yaml
sed -i s,fusor-1.1,v1.0,g                                                                        deploy/olm-catalog/mig-operator/v1.0.0/mig-operator.v1.0.0.clusterserviceversion.yaml
sed -i s,mig-operator\.,cam-operator.,g                                                          deploy/olm-catalog/mig-operator/v1.0.0/mig-operator.v1.0.0.clusterserviceversion.yaml
sed -i 's,: mig-operator,: cam-operator,g'                                                       deploy/olm-catalog/mig-operator/v1.0.0/mig-operator.v1.0.0.clusterserviceversion.yaml
sed -i 's/Migration Operator/Cluster Application Migration Operator/g'                           deploy/olm-catalog/mig-operator/v1.0.0/mig-operator.v1.0.0.clusterserviceversion.yaml

