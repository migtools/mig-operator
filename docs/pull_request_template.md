
**For each of the following check the box when you have verified either:**
* **the changes have been made for each applicable version**
* **no changes are required for the item**
* **PR's that are submitted without running through the list below will be CLOSED**

Affected versions:
* [ ] Latest
* [ ] 1.1
* [ ] 1.0

The CSV is responsible in OLM installs for
* [ ] Operator permissions
* [ ] Operator deployment
* [ ] Operand permissions
* [ ] CRDs

The operator.yml is responsible in non-OLM installs for
* [ ] Operator permissions
* [ ] Operator deployment

The ansible role is responsible in non-OLM installs for:
* [ ] Operand permissions
* [ ] CRDs

The ansible role is always responsible for:
* [ ] Operand deployment

If this PR updates a release or replaces channel 
* [ ] I created a new z release directory in `deploy/olm-catalog/konveyor-operator`
* [ ] I updated channels in the `konveyor-operator.package.yaml`
* [ ] I created a new release directory in `deploy/non-olm`
* [ ] I created or updated the major.minor link in `deploy/non-olm`
* [ ] Updated the `.github/pull_request_template.md` Affected versions list
