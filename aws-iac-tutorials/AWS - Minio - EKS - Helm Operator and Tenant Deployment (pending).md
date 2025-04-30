
>MinIO recommends using the same method of Tenant deployment and management used to install the Operator. Mixing Kustomize and Helm for Operator or Tenant management may increase operational complexity.

## 1. Deploy EKS Cluster

[[AWS - EKSCTL - EKS Cluster Deployment]]
[[AWS - EKSCTL - EKS nodeGroup Scaling Out]] (Optional)
## 2. Deploy aws-ebs-csi-driver

[[AWS - EKS - StorageClass - aws-ebs-csi-driver Installation]]

## 3. Install the MinIO Operator using Helm


## 4. Deploy a MinIO Tenant with Helm

```
helm repo add minio-operator https://operator.min.io
```

You can validate the repo contents using `helm search`:
```
helm search repo minio-operator
```

The response should resemble the following:
```
NAME                    CHART VERSION   APP VERSION     DESCRIPTION
minio-operator/minio-operator   4.3.7     v4.3.7  A Helm chart for MinIO Operator
minio-operator/operator         6.0.3     v6.0.3  A Helm chart for MinIO Operator
minio-operator/tenant           6.0.3     v6.0.3  A Helm chart for MinIO Operator
```

Create a local copy of the Helm `values.yaml` for modification
```
curl -sLo values.yaml https://raw.githubusercontent.com/minio/operator/master/helm/tenant/values.yaml
```

Open the `values.yaml` object in your preferred text editor.

The following fields share the `tenant.pools[0]` prefix and control the number of servers, volumes per server, and storage class of all pods deployed in the Tenant:

| Field              | Description                                                                                                                                                                                                                                                                           | value |
| ------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----- |
| `servers`          | The number of MinIO pods to deploy in the Server Pool.                                                                                                                                                                                                                                | 1     |
| `volumesPerServer` | The number of persistent volumes to attach to each MinIO pod (`servers`). The Operator generates `volumesPerServer x servers` Persistant Volume Claims for the Tenant.                                                                                                                | 2     |
| `storageClassName` | The Kubernetes storage class to associate with the generated Persistent Volume Claims.<br><br>If no storage class exists matching the specified value _or_ if the specified storage class cannot meet the requested number of PVCs or storage capacity, the Tenant may fail to start. | gp2   |
| `size`             | The amount of storage to request for each generated PVC.                                                                                                                                                                                                                              | 10G   |

Use `helm` to install the Tenant Chart using your `values.yaml` as an override:
```
helm install \
--namespace TENANT-NAMESPACE \
--create-namespace \
--values values.yaml \
TENANT-NAME minio-operator/tenant
```

You can monitor the progress using the following command:
```
watch kubectl get all -n TENANT-NAMESPACE
```

**Validate - Expose the Tenant MinIO S3 API port**

To test the MinIO Client [`mc`](https://min.io/docs/minio/linux/reference/minio-mc.html#command-mc "(in MinIO Documentation for Linux)") from your local machine, forward the MinIO port and create an alias.
Forward the Tenant’s MinIO port:

```
kubectl port-forward svc/TENANT-NAME-hl 9000 -n TENANT-NAMESPACE
```

Create an alias for the Tenant service:

```
mc alias set myminio https://localhost:9000 minio minio123 --insecure
```

You can use [`mc mb`](https://min.io/docs/minio/linux/reference/minio-mc/mc-mb.html#command-mc.mb "(in MinIO Documentation for Linux)") to create a bucket on the Tenant:

```
mc mb myminio/mybucket --insecure
```

**Validate - Expose the Tenant Dashboard**[^r3]

```
kubectl port-forward svc/TENANT-NAME-console 9443 -n TENANT-NAMESPACE
```





