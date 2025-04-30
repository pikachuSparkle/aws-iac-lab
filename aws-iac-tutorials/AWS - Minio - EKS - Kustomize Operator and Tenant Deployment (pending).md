
>MinIO recommends using the same method of Tenant deployment and management used to install the Operator. Mixing Kustomize and Helm for Operator or Tenant management may increase operational complexity.

```
Important
If you use Kustomize to deploy a MinIO Tenant, you must use Kustomize to manage or upgrade that deployment. Do not use `kubectl krew`, a Helm Chart, or similar methods to manage or upgrade the MinIO Tenant.
```
## 1. Deploy EKS Cluster

[[AWS - EKSCTL - EKS Cluster Deployment]]
[[AWS - EKSCTL - EKS nodeGroup Scaling Out]] (Optional)

## 2. Deploy aws-ebs-csi-driver

[[AWS - EKS - StorageClass - aws-ebs-csi-driver Installation]]

## 3. Install the MinIO Operator using Kustomize[^r1]

https://min.io/docs/minio/kubernetes/eks/operations/installation.html

The following command installs the Operator to the `minio-operator` namespace:
```
kubectl apply -k "github.com/minio/operator?ref=v7.1.1"
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

## 4 Deploy a MinIO Tenant with Kustomize

You can deploy MinIO tenants using the [MinIO CRD and Kustomize.](https://min.io/docs/minio/kubernetes/eks/operations/install-deploy-manage/deploy-minio-tenant.html#minio-k8s-deploy-minio-tenant) MinIO also provides a [Helm chart for deploying Tenants](https://min.io/docs/minio/kubernetes/eks/operations/install-deploy-manage/deploy-minio-tenant-helm.html#deploy-tenant-helm).

MinIO recommends using the same method of Tenant deployment and management used to install the Operator. Mixing Kustomize and Helm for Operator or Tenant management may increase operational complexity.

https://min.io/docs/minio/kubernetes/eks/operations/install-deploy-manage/deploy-minio-tenant.html#minio-k8s-deploy-minio-tenant

#### 4.1 Create a YAML object for the Tenant
    
    Use the `kubectl kustomize` command to produce a YAML file containing all Kubernetes resources necessary to deploy the `base` Tenant:
    
    kubectl kustomize https://github.com/minio/operator/examples/kustomization/base/ > tenant-base.yaml
    
    The command creates a single YAML file with multiple objects separated by the `---` line. Open the file in your preferred editor.
    
    The following steps reference each object based on it’s `kind` and `metadata.name` fields:
    
#### 4.2 Configure the Tenant topology

The `kind: Tenant` object describes the MinIO Tenant.    
The following fields share the `spec.pools[0]` prefix and control the number of servers, volumes per server, and storage class of all pods deployed in the Tenant:

| Field                                                   | Description                                                                                                                                                                                                                                                                       | Value |
| ------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----- |
| servers                                                 | The number of MinIO pods to deploy in the Server Pool.                                                                                                                                                                                                                            | 4     |
| volumesPerServer                                        | The number of persistent volumes to attach to each MinIO pod (`servers`). The Operator generates `volumesPerServer x servers` Persistant Volume Claims for the Tenant.                                                                                                            | 1     |
| volumeClaimTemplate.<br>spec.storageClassName           | The Kubernetes storage class to associate with the generated Persistent Volume Claims.<br>If no storage class exists matching the specified value _or_ if the specified storage class cannot meet the requested number of PVCs or storage capacity, the Tenant may fail to start. | gp2   |
| volumeClaimTemplate.<br>spec.resources.requests.storage | The amount of storage to request for each generated PVC.                                                                                                                                                                                                                          | 1Gi   |
