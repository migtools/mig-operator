# Upstream Release Procedures
# Development
1. Add the development bundle to the latest release index image and push
  1. `opm index add -p docker -f quay.io/konveyor/mig-operator-index:1.3.1 --bundles quay.io/konveyor/mig-operator-bundle:latest --tag quay.io/konveyor/mig-operator-index:latest`
  1. `podman push quay.io/konveyor/mig-operator-index:latest`

# Stable
1. Create a release branch, for example `release-1.3.1)
1. Update the skips list in the master branch CSV [example](https://github.com/konveyor/mig-operator/pull/460)
1. Create a PR for the new release branch [example](https://github.com/konveyor/mig-operator/pull/461)
  1. Update the CSV with the correct version and new image labels
  1. Copy the latest non-olm files and update the image labels with the operator.yml
  1. Update the stable link to point to the new version
  1. Update channel information in annotations.yml [example](https://github.com/konveyor/mig-operator/pull/463)
1. Once the release is ready add it to the index image
  1. `opm index add -p docker -f quay.io/konveyor/mig-operator-index:1.3.0 --bundles quay.io/konveyor/mig-operator-bundle:release-1.3.0 --tag quay.io/konveyor/mig-operator-index:1.3.1`
  1. `podman push quay.io/konveyor/mig-operator-index:1.3.1`
  1. `opm index add -p docker -f quay.io/konveyor/mig-operator-index:1.3.1 --bundles quay.io/konveyor/mig-operator-bundle:latest --tag quay.io/konveyor/mig-operator-index:latest`
  1. `podman push quay.io/konveyor/mig-operator-index:latest`

# Sprint
1. Determine the sprint you'd like to release for and what attempt this is. The easiest way to do this is look at one of the quay repos for `sprint-xxx.y` [tags](https://quay.io/repository/konveyor/mig-operator-container?tab=tags)
1. You can only run a sprint/attempt combination once. Attempting to recreate branches will fail.
1. Run `ansible-playbook deploy/sprint-build.yml`
1. When prompted enter the sprint number
1. When prompted enter the release attempt number.

Once the playbook finishes you will have a sprint index image ready for testing. To test create a catalog source definition using the example below and replacing xxx.y with the values corresponding to the release you wish to use.
```
apiVersion: operators.coreos.com/v1alpha1
kind: CatalogSource
metadata:
  name: konveyor-for-containers-bundle
  namespace: openshift-migration
spec:
  sourceType: grpc
  image: quay.io/konveyor/mig-operator-index:sprint-xxx.y

```
