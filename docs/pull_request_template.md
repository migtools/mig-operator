**Description**


**Check each of the following when appropriate to help reviewers verify work is complete.**

**Modifying an existing version**
* [ ] I modified operator permissions in the OLM CSV **and** operator.yml
* [ ] I modified the operator deployment in the OLM CSV **and** operator.yml
* [ ] I modified operand permissions in the OLM CSV **and** ansible role
* [ ] I modified CRDS in the OLM CSV **and** ansible role

**Adding a new release version**
* [ ] I created a new z release directory in `deploy/olm-catalog/crane-operator`
* [ ] I updated channels in the `crane-operator.package.yaml`
* [ ] I created a new release directory in `deploy/non-olm`
* [ ] I created or updated the major.minor link in `deploy/non-olm`
* [ ] I updated the spec.skips parameter in the CSV
