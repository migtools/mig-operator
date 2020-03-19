## Testing Changes to the mig-operator CSV with OperatorHub + OLM
1. Edit [mig-operator CSV](https://github.com/konveyor/mig-operator/blob/master/deploy/olm-catalog/mig-operator/v1.0.0/mig-operator.v1.0.0.clusterserviceversion.yaml) making desired changes.
2. Edit [mig-operator-source.yaml](https://github.com/konveyor/mig-operator/blob/master/mig-operator-source.yaml) setting 'registryNamespace' to an unused repo name under your quay.io org.
```
apiVersion: operators.coreos.com/v1
kind: OperatorSource
[...]
spec:
  [...]
  # set to an unused quay.io repo name under your user or organization
  registryNamespace: mig-operator
  [...]
```
3. Get [auth token](https://github.com/operator-framework/operator-courier#authentication) from quay.io
4. Use [operator-courier](https://github.com/operator-framework/operator-courier) to push the packaged CSV as an 'app' to your quay.io org.
```
# Before doing this, ensure the quay.io org you're pushing to doesn't have any existing 'repo' or 'app' by the same name.
# Visit https://quay.io/application/ and check to see if the 'app' you're trying to push already exists.
# Remove any existing 'app' or 'repo' by the same name if one is found.

operator-courier --verbose push ./deploy/olm-catalog/mig-operator/0.0.1/ your-quay-org mig-operator 0.0.1 "$AUTH_TOKEN"

# After a successful push, visit https://quay.io/application/your-quay-org/mig-operator?tab=settings and set the app to public
```

5. On an OpenShift 4 cluster, create the mig-operator OperatorSource.
```
oc create -f mig-operator-source.yaml
```

6. Navigate to 'Catalog -> OperatorHub' in the Web Console. Search for 'Migration Controller' and click 'Install' to create an OLM subscription and start mig-operator.

7. Navigate to 'Catalog -> Installed Operators' tab in the Web Console. Open the 'Migration Operator' item and create a 'MigrationController' CR to exercise mig-operator and test your changes.
