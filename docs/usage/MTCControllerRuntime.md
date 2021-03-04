# MTC with Kubernetes Controller-Runtime Package

This document provides a short preview on how to use [Kubernetes Controller-Runtime Package](https://pkg.go.dev/sigs.k8s.io/controller-runtime) with the MTC custom resources. We will go through a small example in order to do so.

## Prequisite
- Golang
- Kubernetes Controller-Runtime
- OpenShift/Kubernetes Cluster

## Example

1. Make sure that all the pre-requisites are appropriately fullfilled before proceeding further.
2. Our example consists of 2 files, namely `go.mod` and `main.go` . We will take a look at them one by one.
3. For creation of the `go.mod` file, just run the command `go mod init <module_path>` (in our example it is `test-controller-runtime/main`). This will create a `go.mod` file.
4. Now add the dependency details (refer the snippet below) to the `go.mod` file and run the command `go mod tidy` in order to resolve all the dependencies specified in the files. The `go.mod` file should look somewhat like the following snippet:
```
module test-controller-runtime/main

go 1.14

// Use fork
replace bitbucket.org/ww/goautoneg v0.0.0-20120707110453-75cd24fc2f2c => github.com/markusthoemmes/goautoneg v0.0.0-20190713162725-c6008fefa5b1

replace github.com/vmware-tanzu/velero => github.com/konveyor/velero v0.0.0-20201026230312-8bd8ce8744d5

//k8s deps pinning
replace k8s.io/apimachinery => k8s.io/apimachinery v0.0.0-20181127025237-2b1284ed4c93

replace k8s.io/client-go => k8s.io/client-go v0.0.0-20181213151034-8d9ed539ba31

replace k8s.io/api => k8s.io/api v0.0.0-20181213150558-05914d821849

replace k8s.io/apiextensions-apiserver => k8s.io/apiextensions-apiserver v0.0.0-20181213153335-0fe22c71c476

//openshift deps pinning
replace github.com/openshift/api => github.com/openshift/api v0.0.0-20190716152234-9ea19f9dd578

require (
	cloud.google.com/go/storage v1.12.0 // indirect
	github.com/Azure/azure-sdk-for-go v49.0.0+incompatible // indirect
	github.com/Azure/go-autorest/autorest v0.11.13 // indirect
	github.com/Azure/go-autorest/autorest/adal v0.9.8 // indirect
	github.com/aws/aws-sdk-go v1.36.2 // indirect
	github.com/evanphx/json-patch v4.9.0+incompatible // indirect
	github.com/google/gofuzz v1.2.0 // indirect
	github.com/konveyor/mig-controller v0.0.0-20210302184306-85208090e6aa
	github.com/matttproud/golang_protobuf_extensions v1.0.2-0.20181231171920-c182affec369 // indirect
	github.com/onsi/gomega v1.10.3 // indirect
	github.com/openshift/api v0.0.0-20201019163320-c6a5ec25f267 // indirect
	github.com/prometheus/client_golang v1.8.0 // indirect
	golang.org/x/crypto v0.0.0-20201203163018-be400aefbc4c // indirect
	golang.org/x/net v0.0.0-20201202161906-c7110b5ffcbb // indirect
	golang.org/x/oauth2 v0.0.0-20201203001011-0b49973bad19 // indirect
	golang.org/x/time v0.0.0-20200630173020-3af7569d3a1e // indirect
	google.golang.org/api v0.36.0 // indirect
	k8s.io/api v0.17.4
	k8s.io/apimachinery v0.17.4
	k8s.io/utils v0.0.0-20201110183641-67b214c5f920 // indirect
	sigs.k8s.io/controller-runtime v0.1.11
)
```
4. Now let's create a `main.go` source file. This file will contain the code to communicate and interact with the Kubernetes/OpenShift cluster to perform operations on MTC resources. The following sample code snippet imports the MTC custom resources and the client sends a create `MigCluster` request to the cluster configured.
```
package main

import (
	"context"
	"fmt"
	"os"

	"github.com/konveyor/mig-controller/pkg/apis/migration/v1alpha1"
	"github.com/konveyor/mig-controller/pkg/apis"
	kapi "k8s.io/api/core/v1"
	"sigs.k8s.io/controller-runtime/pkg/client/config"
	"sigs.k8s.io/controller-runtime/pkg/manager"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
)

func main() {

	cluster := &v1alpha1.MigCluster{
		ObjectMeta: metav1.ObjectMeta{
			Name: "sample-migcluster",
			Namespace: "openshift-migration",
		},
		Spec: v1alpha1.MigClusterSpec{
			URL: "https://master.sample-url.com",
			IsHostCluster: false,
			ServiceAccountSecretRef: &kapi.ObjectReference{
				Name: "sample-sa",
				Namespace: "openshift-config",
			},
			Insecure: true,
		},
	}

	cfg, err := config.GetConfig()
	if err != nil {
		fmt.Printf("\nerror: %v\n", err)
		os.Exit(1)
	}

	mgr, err := manager.New(cfg, manager.Options{})
	if err != nil {
		fmt.Printf("\nerror: %v\n", err)
		os.Exit(2)
	}

	if err := apis.AddToScheme(mgr.GetScheme()); err != nil {
		fmt.Printf("\nerror: %v\n", err)
		os.Exit(1)
	}

	client := mgr.GetClient()

	err = client.Create(context.TODO(), cluster)
	if err != nil {
		fmt.Printf("\nerror: %v\n", err)
		os.Exit(2)
	}

}
```
5. Finally, let's run the code, in order to do so, run the command `go run main.go` . The code should be successfully executed and a `MigCluster` instance named `sample-migcluster` should be created, you can check that by executing the command `oc get migclusters`.  
6. Just like the above example, you can use the Controller-Runtime package to interact with the cluster, perform CRUD operations and much more on the MTC custom resources.

**Note:** 
- For more details and examples please refer [Kubernetes Controller-Runtime Package examples](https://pkg.go.dev/sigs.k8s.io/controller-runtime@v0.8.2/pkg/client#pkg-examples).
- Also, please ensure that you specify appropriate metadata and spec values for the MTC resources to be operated on. For more details please refer the [MTC API documentation](MTCAPIDoc.md). You can also run the `oc explain <MTC Resource>` to obtain spec details of a particular MTC resource.