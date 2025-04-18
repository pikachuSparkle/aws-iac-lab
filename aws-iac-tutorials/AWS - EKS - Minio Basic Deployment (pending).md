## 1. Deploy EKS Cluster

[[AWS - EKSCTL - Deployment EKS Cluster]]

## 2. Deploy aws-ebs-csi-driver

[[AWS - EKS - StorageClass - aws-ebs-csi-driver Installation]]

## 3. Install the MinIO Operator using Kustomize[^r1]

The following command installs the Operator to the `minio-operator` namespace:
```
kubectl apply -k "github.com/minio/operator?ref=v6.0.3"
```

Verify the Operator pods are running:
```
kubectl get pods -n minio-operator
```

```
NAME                              READY   STATUS    RESTARTS   AGE
minio-operator-6c758b8c45-nkhlx   1/1     Running   0          2m42s
minio-operator-6c758b8c45-dgd8n   1/1     Running   0          2m42s
```

In this example, the `minio-operator` pod is MinIO Operator and the `console` pod is the Operator Console.

You can modify your Operator deployment by applying kubectl patches. You can find examples for common configurations in the [Operator GitHub repository](https://github.com/minio/operator/tree/master/examples/kustomization).

Verify the Operator installation
```
Check the contents of the specified namespace (`minio-operator`) to ensure all pods and services have started successfully.
```

The response should resemble the following:
```
NAME                                  READY   STATUS    RESTARTS   AGE
pod/minio-operator-6c758b8c45-nkhlx   1/1     Running   0          5m20s
pod/minio-operator-6c758b8c45-dgd8n   1/1     Running   0          5m20s

NAME    TYPE    CLUSTER-IP      EXTERNAL-IP   PORT(S)         AGE
service/operator   ClusterIP   10.43.135.241   <none>   4221/TCP       5m20s
service/sts        ClusterIP   10.43.117.251   <none>   4223/TCP       5m20s

NAME                             READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/minio-operator   2/2     2            2           5m20s

NAME                                        DESIRED   CURRENT   READY   AGE
replicaset.apps/minio-operator-6c758b8c45   2         2         2       5m20s
```

## 4. Deploy MinIO tenants

You can deploy MinIO tenants using the [MinIO CRD and Kustomize.](https://min.io/docs/minio/kubernetes/eks/operations/install-deploy-manage/deploy-minio-tenant.html#minio-k8s-deploy-minio-tenant) MinIO also provides a [Helm chart for deploying Tenants](https://min.io/docs/minio/kubernetes/eks/operations/install-deploy-manage/deploy-minio-tenant-helm.html#deploy-tenant-helm).

MinIO recommends using the same method of Tenant deployment and management used to install the Operator. Mixing Kustomize and Helm for Operator or Tenant management may increase operational complexity.

#### 4.1 Deploy a MinIO Tenant with Kustomize

https://min.io/docs/minio/kubernetes/eks/operations/install-deploy-manage/deploy-minio-tenant.html#minio-k8s-deploy-minio-tenant


#### 4.2 Deploy a MinIO Tenant with Helm Charts[^r2]

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


References:

[^R1]: https://min.io/docs/minio/kubernetes/eks/operations/installation.html
[^R2]: https://min.io/docs/minio/kubernetes/eks/operations/install-deploy-manage/deploy-minio-tenant-helm.html#deploy-tenant-helm
[^R3]: https://min.io/docs/minio/kubernetes/eks/operations/install-deploy-manage/deploy-minio-tenant.html#create-tenant-connect-tenant
