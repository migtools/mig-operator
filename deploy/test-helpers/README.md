# Downstream operator testing helper scripts

## Mirroring images to the internal openshift registry

1. `oc login` to your target cluster where you are going to mirror your images.
1. `cp my_var.dev.ex my_var` OR `cp my_var.stage.ex my_var` depending on the environment
you are pulling your images from. The purpose of these two separate var files is that
the different environments use different naming conventions for their repos and image names.
1. Set the downstream registry to the brew registry in `my_var`
1. If you need to test a specific downstream image (for example v1.0-7) replace the `IMG_MAP[${img}_ds_tag]` value with the desired image tag to test, otherwise the latest v1.0 tagged builds will be pulled.
1. Run `expose_cluster_registry.sh` to expose the target cluster's docker registry.
It will also create and permission a ServiceAccount for you to use to push.
Ensure that you have added the resulting exposed registry route to your docker
daemon's insecure registries and reloaded your docker daemon.
1. Docker login to the newly exposed route using the `docker_login_exposed_registry.sh` script.
1. Run `mirror_downstream_mig_images.sh` to mirror the images. This script will also create the
rhcam and openshift-migration namespaces and allow pulling rhcam images from openshift-migration.

## Configuring the Operator Source
1. `cp marketplace-secret.operatorsource.yml.template marketplace-secret.operatorsource.yml`
1. Replace `${QUAY_TOKEN}` with your Quay token in `marketplace-secret.operatorsource.yml`
1. oc create -f `marketplace-secret.operatorsource.yml`
1. oc create -f `rh-verified-operators.operatorsource.yml`

Note: We also have `rh-osbs-operators.operatorsource.yml` which will give access to unverified
operators allowing access sooner, but being unverified broken operator CSV's can exist here
causing failures.

After a moment `Cluster Application Migration Operator` should appear in OperatorHub in the UI.

## Installing the operator from OLM
1. The scripts should create the `openshift-migration` namespace for you. It is required that the
operator and operands be installed in this namespace. Manual creation can be accomplished by
navigating to `Administration>Namespaces` in the Web UI. The `Dashboard>Projects` page will refuse
to create the namespace.
1. Navigate to the OperatorHub page
1. Search for the Cluster Application Migration Operator
1. Install to the `openshift-migration` namespace
1. When installation completes create a `MigrationController` CR. The default values will install
the UI, controller, restic, and velero.

## Installing the operator without OLM
This is primarily intended as a means of installing for OpenShift 3.
1. `oc create -f ./non-olm/v1.0.0/operator.yml`
1. `oc create -f ./non-olm/v1.0.0/controller-3.yml`

There is also a `controller-4.yml` but for proper installation testing OLM should be used for OpenShift 4.
