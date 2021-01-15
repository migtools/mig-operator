# Upstream Release Procedures
# Requirements
1. podman (yum/dnf -y install podman)
1. [opm](https://github.com/operator-framework/operator-registry)

# Development
1. Add the development bundle to the latest release index image and push
  1. `opm index add -p docker -f quay.io/konveyor/mig-operator-index:1.4.1 --bundles quay.io/konveyor/mig-operator-bundle:latest --tag quay.io/konveyor/mig-operator-index:latest`
  1. `podman push quay.io/konveyor/mig-operator-index:latest`

# Stable
1. Create a PR for the master branch.
   1. Update the skips list in the master branch CSV [example](https://github.com/konveyor/mig-operator/pull/460)
1. Create the new release branch, for example `release-1.4.1`
1. Create a PR for the new release branch
   1. Update channel information in annotations.yml and Dockerfile.bundle [example](https://github.com/konveyor/mig-operator/pull/463) / [example](https://github.com/konveyor/mig-operator/pull/461)
   1. Update the CSV  and non-olm operator.yml with the correct version and new image labels [example](https://github.com/konveyor/mig-operator/pull/461)
1. Once the release is ready add it to the index image and push. In these steps you are appending the new bundle to the old index and pushing it to a new location. The steps are repeated to add development to this new index and push it to latest. This is the index image used when creating the catalogsource. In the examples below `1.4.0` is the prior version, `1.4.1` is the new version, and you will need to adjust accordingly. It is OK to overwrite the current version if an error needs to be corrected.
   1. `opm index add -p docker -f quay.io/konveyor/mig-operator-index:1.4.0 --bundles quay.io/konveyor/mig-operator-bundle:release-1.4.1 --tag quay.io/konveyor/mig-operator-index:1.4.1`
   1. `podman push quay.io/konveyor/mig-operator-index:1.4.1`
   1. `opm index add -p docker -f quay.io/konveyor/mig-operator-index:1.4.1 --bundles quay.io/konveyor/mig-operator-bundle:latest --tag quay.io/konveyor/mig-operator-index:latest`
   1. `podman push quay.io/konveyor/mig-operator-index:latest`
1. Push the appregistry metadata
   1. `mkdir tmp && cd tmp`
   1. `opm index export -c podman -i quay.io/konveyor/mig-operator-index:latest -o mtc-operator -f .`
   1. `cd mtc-operator`
   1. `sed -i 's/mtc-operator/konveyor-operator/g' package.yaml`
   1. `operator-courier --verbose push . konveyor konveyor-operator 47.0.0 "$QUAY_TOKEN"`. Ensure you increment the [app version](https://quay.io/application/konveyor/konveyor-operator)

# Sprint
1. Export GH_TOKEN with your Github Token, as an example `export GH_TOKEN=1234567890abcdef1234567890abcdef01234567`.
1. Ensure you can log in to quay, build, and push containers with podman.
1. Determine the sprint you'd like to release for and what attempt this is. The easiest way to do this is look at one of the quay repos for `sprint-xxx.y` [tags](https://quay.io/repository/konveyor/mig-operator-container?tab=tags)
1. You can only run a sprint/attempt combination once. Attempting to recreate branches will fail.
1. Run `ansible-playbook deploy/sprint-build.yml`
1. When prompted enter the sprint number
1. When prompted enter the release attempt number.
1. Note that there is a 5 minute pause built into the branch creation process. This is because quay will ignore build triggers if too many are sent at once.

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

Starting with sprint 195 to use OCP 3.x you can run the commands below. Ensure you replace xxx.y with the values corresponding to the release you wish to use.
```
export SPRINT=sprint-xxx.y
podman cp $(podman create quay.io/konveyor/mig-operator-container:$SPRINT):/operator.yml ./
podman cp $(podman create quay.io/konveyor/mig-operator-container:$SPRINT):/controller-3.yml ./
sed -i "s/value: latest/value: $SPRINT/g" operator.yml
oc create -f operator.yml
```

Modify settings in the controller-3.yml as desired and `oc create -f controller-3.yml` as you normally would.
