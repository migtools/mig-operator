# Using Self-signed Certificates

If a remote cluster or replication repository are secured by a self-signed certificate,
certificate verification may fail with the message `x509: certificate signed by unknown authority`.
In order to proceed, SSL verification can be disabled,
or a certificate bundle may be provided to the CAM tool which it will use to verify the
remote connection.

## Disabling SSL verification from the CAM UI

From the CAM UI, SSL verification can be turned off for a cluster or S3-compatible replication
repository by unchecking the `Require SSL verification` box on the respective
add/edit form.

## Disabling SSL verification from the OpenShift CLI

If you'd prefer to create the cluster or S3-compatible replication repository from the command
line, you may disable SSL verification by setting `insecure: true` on the
migcluster or migstorage.

```
# disable ssl verification on a migstorage

apiVersion: migration.openshift.io/v1alpha1
kind: MigStorage
...
spec:
  backupStorageProvider: aws
  volumeSnapshotProvider: aws

  backupStorageConfig:
    insecure: true
    awsBucketName: foo
    awsRegion: foo
    awsS3Url: <S3-compatible storage endpoint>
...
```

```
# disable ssl verification on a migcluster

apiVersion: migration.openshift.io/v1alpha1
kind: MigCluster
metadata:
  labels:
    controller-tools.k8s.io: "1.0"
  name: migcluster-remote
  namespace: openshift-migration
spec:
  isHostCluster: false
  url: "https://my-remote-cluster-ip.nip.io:8443"
  insecure: true
  serviceAccountSecretRef:
    name: sa-token-remote
    namespace: openshift-migration
```

## Downloading a certificate from a remote endpoint

You can download the certificate you want to trust from the remote endpoint by use
of the openssl client. Replace HOST and PORT in the below command with the host and port of the https
endpoint which you'd like to retrieve the certificate chain from.

```
echo -n | openssl s_client -connect HOST:PORT -showcerts \
| sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' > self-signed.cert

```

For instance, to download the certificate chain from an Openshift 4.x cluster:

```
echo -n | openssl s_client -connect api.my-cluster.example.com:6443 -showcerts \
| sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' > self-signed.cert
```

The resulting certificate file can then be provided to CAM via the following methods.

## Providing a trusted certificate bundle via the CAM UI

CAM can be configured to trust a self-signed certificate by uploading
a public certificate in the CAM UI which will be used to verify SSL connections to the
remote cluster or replication repository.

While adding or editing your cluster or replication repository, use the "CA Bundle file" field to select a PEM-encoded certificate bundle. This certificate will be used
to verify SSL connections to the remote system.

## Providing a trusted certificate bundle via the OpenShift CLI

You may also provide the certificate bundle on the migcluster or migstorage resource directly. First, base64 encode the PEM-encoded certificate bundle.

```
$ base64 -w 0 < self-signed.crt

LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSURhVENDQWxHZ0F3SUJBNGJkdnd3RF...
```

```
# Add a CA bundle to a migstorage

apiVersion: migration.openshift.io/v1alpha1
kind: MigStorage
...
spec:
  backupStorageProvider: aws
  volumeSnapshotProvider: aws

  backupStorageConfig:
    s3CustomCABundle: LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSURhVENDQWxHZ0F3SUJBNGJkdnd3RF...
    awsBucketName: foo
    awsRegion: foo
    awsS3Url: <S3-compatible storage endpoint>
...
```

```
# Add a CA bundle to a migcluster

apiVersion: migration.openshift.io/v1alpha1
kind: MigCluster
metadata:
  labels:
    controller-tools.k8s.io: "1.0"
  name: migcluster-remote
  namespace: openshift-migration
spec:
  caBundle: LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSURhVENDQWxHZ0F3SUJBNGJkdnd3RF...
  isHostCluster: false
  url: "https://my-remote-cluster-ip.nip.io:8443"
  serviceAccountSecretRef:
    name: sa-token-remote
    namespace: openshift-migration
```
