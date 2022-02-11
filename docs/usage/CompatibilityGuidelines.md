# MTC Compatibility Guidelines

## Context

The typical support policy for MTC is current feature release, and
the current feature release - 1. We try to do minor level releases
every 3 months, so that means that about every quarter we issue a new minor
release, and drop support for the oldest minor release.

The introduction of v1 CRD APIs and deprecation / removal of v1beta1 CRDs depending
upon the platform version has made uniform support a challenge, since our
controller is tightly coupled to the CRD version that we use to express our API.

For more information about how we arrived at these guidelines, please reference
our [CRD deprecation enhancement](https://github.com/konveyor/enhancements/tree/master/enhancements/crane-1.x/crd-v1beta1-removal/crd-v1beta1-removal-dual-stream)
where several options were evaluated by the team.

## Definitions

* **Control Cluster:** The cluster that runs the MTC controller & UI.
* **Remote Cluster:** A source or destination cluster for a migration that runs
Velero. The Control Cluster communicates with Remote clusters via the Velero API
to drive migrations.

* **Legacy Platform:** OCP <= 4.5. Although the v1 CRD API was introduced with
OCP 4.3, OLM had its metadata repositories frozen with 4.5 and below, meaning we
have been unable to release any new content and are forced to use the legacy
operator and its manual install method for these platforms.
* **Modern Platform:** OCP >= 4.6. These are platforms with OLM support, as well
as v1 CRD APIs.

## Supported Channels and Platform Compatibility

As of 1.6, we made a decision to commit to v1 CRD compatibility, since dual
comaptibility with a controller would likely result in indeterminate and unsupportable
behavior. To ensure that customers have an answer for legacy platforms, we designed
the 1.5 legacy operator to interop as a remote (or control) cluster with 1.6.

With 1.7, **we are dropping support for running controllers on legacy platforms**.

> NOTE: There is a corner use-case where you have a legacy platform (ex: 3.11)
> that is on-prem or otherwise unreachable by a modern destination cluster.
> In the past, the recommendation here was to designate your source legacy
> cluster as the control cluster so that it could "push" the workloads to the
> modern target. Because we are deprecating controllers on legacy platforms with
> 1.7, this will not be possible. Instead, we have implemented a "holepunch"
> tool that will provide users the ability to bridge the two clusters so that
> the modern control cluster may access the legacy remote cluster's API server.
> See [crane tunnel-api](https://crane-docs.konveyor.io/content/usage/tunnel-api/).

There are effectively two supported channels:

* **Latest** - (1.7)
  - For legacy platforms, you must install manually via the legacy operator
  - For modern platforms, install via the typical OLM install process
  - The controller and UI are **not** supported on legacy platforms.
* **Stable** - (1.5 legacy + 1.6 modern)
  - If you have a legacy platform, you must use the 1.5 legacy install.
  - If you have a modern platform, you must use the 1.6 install.
  - 1.6 and 1.5 are designed to interop.
  - Corner case: we continue to support 1.5 controllers on legacy platforms
  as an alternative to using 1.7 and the `crane tunnel-api` command. It is
  recommended that you only use this topology if no other alternative suffices.

> NOTE: As of 1.8's release, we plan to deprecate 1.5 and 1.6 together. The
> supported channels will be 1.7 and 1.8.
