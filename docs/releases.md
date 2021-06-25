# Upstream Release Procedures
# Requirements
1. podman (yum/dnf -y install podman)
1. operator-courier (yum/dnf -y install python3-operator-courier or follow [Installation Instructions](https://github.com/operator-framework/operator-courier/#installation) for other options) 
1. [opm](https://github.com/operator-framework/operator-registry)
1. Your QUAY token exported, `export QUAY_TOKEN="basic ..."`, see [operator-courier](https://github.com/operator-framework/operator-courier/blob/master/README.md#authentication) for instructions on how to get a basic auth token.

# Stable
1. Create the new release branch, for example `release-1.4.1`
1. Create a PR for the new release branch
   1. Run `ansible-playbook deploy/cut-release.yml`
   1. Answer the prompt for the version with a semver version string, for example `1.4.1`
   1. Answer the prompt for a channel. We currently use a convention of release-v$major.$minor, for example `release-v1.4`
   1. Review the changes, commit, and submit the PR for review
1. Create a PR for the master branch.
   1. Update the skips list in the master branch CSV [example](https://github.com/konveyor/mig-operator/pull/460)
1. Once the release is ready add it to the index image and push.
1. When the branch is ready for release move the channel tag, e.g. `release-v1.5` to this new(er) branch.
1. If this is a new channel update the SUPPORTED_CHANNELS env var in the publish github action.

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
  name: crane-for-containers-bundle
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
