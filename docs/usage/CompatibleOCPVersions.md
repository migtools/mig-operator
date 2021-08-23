# Compatible OCP versions

Refer to the guidelines below to select the correct mig-operator version for your OpenShift cluster version.

## Install version guidelines

 - **OpenShift 3.7 - 4.5**
   - Crane 1.5.x is compatible
   - Install Crane using [mig-legacy-operator](https://github.com/konveyor/mig-legacy-operator) available from YAML manifests.
 - **OpenShift 4.6+**
   - Crane 1.6.x+ is compatible
   - Install Crane using [mig-operator](https://github.com/konveyor/mig-operator) available from OperatorHub.
   - Use this as the control cluster (where mig-controller and mig-ui are installed)

_Note_: Crane 1.6.x and Crane 1.5.1 are designed to be compatible when Crane 1.6.x is the control cluster (e.g. the cluster where mig-controller and mig-ui runs).

