## Object Storage Setup

CAM components use S3 object storage as temporary scratch space when performing migrations.  This storage can be any object storage that presents an `S3 like` interface.  Currently, we have tested AWS S3, Noobaa, and Minio.  

### Object Storage Setup with NooBaa

NooBaa can run on an OpenShift cluster to provide an S3 compatible store for migration scratch space. We recommend loading NooBaa onto the destination cluster.

1. Download the noobaa v1.1.0 CLI from https://github.com/noobaa-operator/releases. 
2. Ensure you have available PVs with capacities of 10 Gi, 50Gi. The NooBaa installer will create PVCs to consume these PVs.
```
# NooBaa PV usage requirements
NAME                          CAPACITY   ACCESS MODES                           
logdir-noobaa-core-0          10Gi       RWO                                    
mongo-datadir-noobaa-core-0   50Gi       RWO,RWX
```

3. Using the `noobaa` CLI tool, install NooBaa to the _destination cluster_. Take note of the output values for 'AWS_ACCESS_KEY_ID' and 'AWS_SECRET_ACCESS_KEY' that will be produced for a later step. Also note that an initial bucket has been created called 'first.bucket'
```
$ noobaa install --namespace noobaa

[...]
INFO[0002] System Status:                               
INFO[0003] ✅ Exists: NooBaa "noobaa"                    
INFO[0003] ✅ System Phase is "Ready"                    
[...]
INFO[0003] AWS_ACCESS_KEY_ID: ygeJ5GzAwbBJiSukw8Lv      
INFO[0003] AWS_SECRET_ACCESS_KEY: so2C5X/ttRhiX00DZrOnv0MxV0r5VlOkYmptTU91 
```

4. Expose the NooBaa S3 service to hosts outside the cluster. This is necessary so that both the _source_ and _destination_ cluster will be able to connect to S3 scratch space.
```
$ oc expose svc s3 -n noobaa
```

5. Take note of the NooBaa S3 route URL for a later step.
```
$ oc get route s3 -n noobaa -o jsonpath='http://{.spec.host}'
http://s3-noobaa.apps.destcluster.com
```

6. If you have the [`aws` CLI](https://aws.amazon.com/cli/) installed, you can use it to test that NooBaa is serving the S3 bucket 'first.bucket' from the route obtained in the previous step using the S3 credentials generated during NooBaa install.
```
$ AWS_ACCESS_KEY_ID="ygeJ5GzAwbBJiSukw8Lv" \
AWS_SECRET_ACCESS_KEY="so2C5X/ttRhiX00DZrOnv0MxV0r5VlOkYmptTU91" \
aws s3 ls --endpoint http://s3-noobaa.apps.destcluster.com

2019-09-04 13:21:20 first.bucket
```

### Object Storage Setup with AWS S3

AWS S3 can serve as migration scratch space as long as both clusters involved in a migration have connectivity to AWS.


#### Create S3 bucket

```bash
aws s3api create-bucket \
    --bucket <YOUR_BUCKET_NAME> \
    --region us-east-1
```

#### Create IAM user

1. Create the IAM user:

    ```bash
    aws iam create-user --user-name velero
    ```

2. Attach policies to give `velero` the necessary permissions:

    ```bash
    # Use this policy to grant access to ec2 volumes for PV snapshot purposes
    cat > velero-ec2-snapshot-policy.json <<EOF
    {
        "Version": "2012-10-17",
        "Statement": [
            {
                "Effect": "Allow",
                "Action": [
                    "ec2:DescribeVolumes",
                    "ec2:DescribeSnapshots",
                    "ec2:CreateTags",
                    "ec2:CreateVolume",
                    "ec2:CreateSnapshot",
                    "ec2:DeleteSnapshot"
                ],
                "Resource": "*"
            }
        ]
    }
    EOF
    ```

    ```bash
    # [Option 1] Grant access to a single S3 bucket. Fill in value for `${BUCKET}`.

    BUCKET=<YOUR_BUCKET_NAME>
    cat > velero-s3-policy.json <<EOF
    {
        "Version": "2012-10-17",
        "Statement": [
            {
                "Effect": "Allow",
                "Action": [
                    "s3:GetObject",
                    "s3:DeleteObject",
                    "s3:PutObject",
                    "s3:AbortMultipartUpload",
                    "s3:ListMultipartUploadParts"
                ],
                "Resource": [
                    "arn:aws:s3:::${BUCKET}/*"
                ]
            },
            {
                "Effect": "Allow",
                "Action": [
                    "s3:ListBucket"
                ],
                "Resource": [
                    "arn:aws:s3:::${BUCKET}"
                ]
            }
        ]
    }
    EOF
    ```

    ```bash
    # [Option 2] Grant access to all S3 buckets.

    cat > velero-s3-policy.json <<EOF
    {
        "Version": "2012-10-17",
        "Statement": [
            {
                "Effect": "Allow",
                "Action": [
                    "s3:GetObject",
                    "s3:DeleteObject",
                    "s3:PutObject",
                    "s3:AbortMultipartUpload",
                    "s3:ListMultipartUploadParts"
                ],
                "Resource": [
                    "arn:aws:s3:::*"
                ]
            },
            {
                "Effect": "Allow",
                "Action": [
                    "s3:ListBucket"
                ],
                "Resource": [
                    "arn:aws:s3:::*"
                ]
            }
        ]
    }
    EOF
    ```

    ```bash
    # Attach policy granting IAM access to EC2 EBS
    aws iam put-user-policy \
      --user-name velero \
      --policy-name velero-ebs \
      --policy-document file://velero-ec2-snapshot-policy.json
    ```

    ```bash
    # Attach policy granting IAM access to AWS S3
    aws iam put-user-policy \
      --user-name velero \
      --policy-name velero-s3 \
      --policy-document file://velero-s3-policy.json
    ```


3. Create an access key for the user:

    ```bash
    aws iam create-access-key --user-name velero
    ```

    The result should look like:

    ```json
     {
        "AccessKey": {
              "UserName": "velero",
              "Status": "Active",
              "CreateDate": "2017-07-31T22:24:41.576Z",
              "SecretAccessKey": <AWS_SECRET_ACCESS_KEY>,
              "AccessKeyId": <AWS_ACCESS_KEY_ID>
          }
     }
    ```

---
[Home](./README.md)
