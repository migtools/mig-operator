# Compatible OCP versions

Refer to the guidelines below to select the correct mig-operator version for your OpenShift cluster version.

## Install version guidelines

 - OpenShift 3.7 - 4.5
  - Install MTC 1.5.1 or newer MTC 1.5.x

 - OpenShift 4.6+
  - Install MTC 1.6.x+
  - Use this as the control cluster (where mig-controller and mig-ui are installed)

_Note_ that MTC 1.6.x and MTC 1.5.1 are designed to be compatible when MTC 1.6.x is the control cluster (e.g. the cluster where mig-controller and mig-ui runs).

# Incompatibilities

Due to the switchover from v1beta1 to v1 CRD API in recent versions of OpenShift:

- MTC 1.5.1- is not compatible with OpenShift 4.9+
- MTC 1.6.0+ is not compatible with OpenShift 4.5-