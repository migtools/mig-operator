# Disconnected CAM Deployments

Many enterprise OCP clusters run in an environment with limited external
communications (via proxy), or entirely disconnected from the internet.
CAM can still be used to migrate workloads between disconnected clusters,
provided the clusters have network connectivity to one another, and a private
registry is accesisble by both clusters that will serve as an internal image
mirror. CAM deployment will vary depending on whether you are intalling
on an OCP4 or OCP3 cluster.

## Prerequisites

* All clusters must have network connectivity with one another.
* All clusters must have network connectivity with their replication repository.
For a fully disconnected migration, this would require an internally hosted S3
like NooBaa or Minio. For limited connectivity environments via proxy, AWS, GCP,
or Azure object storage can be used provided they are whitelisted within the
proxy.
* All clusters must be configured and able to pull from a self-hosted image
registry. For the purposes of this document, we'll call this `$SHARED_REGISTRY`.
For example:

`export SHARED_REGISTRY=my-registry.example.com`

## OCP 4 deployment

On an OCP4 cluster CAM is installed via OLM and there is a generic procedure
using the oc tooling for mirroring all of the Red Hat operator metadata, their
associated images, and configures the cluster to use this as a content source:

https://docs.openshift.com/container-platform/4.4/operators/olm-restricted-networks.html

Once the above procedure is complete, CAM will be available for install as part
`redhat-operators` catalog.

## OCP 3 deployment

CAM is installed via a kubernetes manifest file on an OCP3 cluster that
is exported off of the operator image. To deploy CAM on a disconnected
cluster using the shared image registry, this manifest file must be
configured to point to the new registry.

On a connected machine, copy the operator and controller files off the
operator image as you normally would for a connected deployment:

> NOTE: These versions will be different depending on the X.Y version of CAM
you are using. Example: For CAM 1.1.2, the repo will be rhcam-1-1 and the tag v1.1.
For 1.2.0, the repo will be rhcam-1-2 and the tag v1.2, etc.

```
podman cp $(podman create registry.redhat.io/rhcam-1-1/openshift-migration-rhel7-operator:v1.1):/operator.yml ./
podman cp $(podman create registry.redhat.io/rhcam-1-1/openshift-migration-rhel7-operator:v1.1):/controller-3.yml ./
```

First you must to set the operator image value itself editing the image
fields on the deployment to the fully qualified image name in your self-hosted registry:

https://github.com/konveyor/mig-operator/blob/master/deploy/non-olm/latest/operator.yml#L290

To get the correct value, when you ran the `oc adm mirror` command for the OCP4
cluster, next to the imagecontentsourcepolicy file, there should be a mapping.txt file.
If you grep that for the operator, it will have the image sha you'll need to use, for example:

```
$ grep openshift-migration-rhel7-operator ./mapping.txt | grep rhcam-1-1
registry.redhat.io/rhcam-1-1/openshift-migration-rhel7-operator@sha256:468a6126f73b1ee12085ca53a312d1f96ef5a2ca03442bcb63724af5e2614e8a=registry-nsk-discon-test.apps.example.com/rhcam-1-1/openshift-migration-rhel7-operator
```

So the fully qualified operator image value to use is:
`registry-nsk-discon-test.apps.example.com/rhcam-1-1/openshift-migration-rhel7-operator@sha256:468a6126f73b1ee12085ca53a312d1f96ef5a2ca03442bcb63724af5e2614e8a`

After setting the two image fields in the operator.yml file to this value, the
last thing you need to do is to override the REGISTRY value in the environment variables.
This tells the operator to deploy all of its operands out of your shared registry
instead of the default `registry.redhat.io`:

https://github.com/konveyor/mig-operator/blob/master/deploy/non-olm/latest/operator.yml#L307

Continuing the above example, I would set this value to: `registry-nsk-discon-test.apps.example.com`

Now that the manifest file has been configured to use the shared internal registry,
the operator can be deployed running an `oc create -f operator.yml` on the edited
file, as you would do with a normal connected deployment. All images will be
pulled from the specified registry.
