## 0. References:

Percona Operator for MySQL based on Percona XtraDB Cluster
- DOCS: https://docs.percona.com/percona-operator-for-mysql/pxc/eks.html
- Source Code: https://github.com/percona/percona-xtradb-cluster-operator

Pencona Operator for MySQL based on Percona Server for MySQL
- DOCS: https://docs.percona.com/percona-operator-for-mysql/ps/eks.html
- Source Code: https://github.com/percona/percona-server-mysql-operator

NOTES:
>`Pencona Operator for MySQL based on Percona Server for MySQL` is in the tech preview state right now. Don't use it on production.
>
>Version 0.8.0 of the [Percona Operator for MySQL](https://github.com/percona/percona-server-mysql-operator) is **a tech preview release** and it is **not recommended for production environments**. **As of today, we recommend using** [Percona Operator for MySQL based on Percona XtraDB Cluster](https://www.percona.com/doc/kubernetes-operator-for-pxc/index.html), which is production-ready and contains everything you need to quickly and consistently deploy and scale MySQL clusters in a Kubernetes-based environment, on-premises or in the cloud.

In this artical, we use  `Percona Operator for MySQL based on Percona XtraDB Cluster`.

## 1.  Create the EKS cluster

[[AWS - EKSCTL - Deployment EKS Cluster]]

In this Demo, we will need 4 working nodes (node type: t3a.medium).
## 2.  install the Amazon EBS CSI driver

[[AWS - EKS - StorageClass - aws-ebs-csi-driver Installation]]

```
export AWS_REGION=us-east-1 
eksctl utils associate-iam-oidc-provider --cluster=cluster-demo-1 --region=us-east-1 --approve

eksctl create iamserviceaccount         
--name ebs-csi-controller-sa                      \         
--namespace kube-system                           \
--cluster cluster-demo-1                          \
--role-name AmazonEKS_EBS_CSI_DriverRole          \
--role-only                                       \
--attach-policy-arn arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy                     \
--region=us-east-1                                \
--approve

helm upgrade --install aws-ebs-csi-driver              \  
aws-ebs-csi-driver/aws-ebs-csi-driver                  \
--namespace kube-system                                \
--set controller.serviceAccount.annotations."eks\.amazonaws\.com/role-arn"="arn:aws:iam::444444444444:role/AmazonEKS_EBS_CSI_DriverRole"
```

## 3. Install the Operator

This deploys default Percona XtraDB Cluster configuration with three HAProxy and three XtraDB Cluster instances. Please see [deploy/cr.yaml](https://raw.githubusercontent.com/percona/percona-xtradb-cluster-operator/v1.15.0/deploy/cr.yaml)  and [Custom Resource Options](https://docs.percona.com/percona-operator-for-mysql/pxc/operator.html) for the configuration options. You can clone the repository with all manifests and source code by executing the following command:
```
# git clone the source codes 
git clone -b v1.15.0 https://github.com/percona/percona-xtradb-cluster-operator.git
cd percona-xtradb-cluster-operator
# configure the cluster parameters as your wish
vim ./deploy/cr.yaml
# change the S3 zone: west -> east
# comment the antiAffinity with #
```

Create a namespace and set the context for the namespace.
```
kubectl create namespace mysql
kubectl config set-context $(kubectl config current-context) --namespace=mysql
```

Deploy the Operator using the following command:
```
kubectl apply --server-side -f /data/codes/percona-xtradb-cluster-operator/deploy/bundle.yaml
```

The operator has been started, and you can deploy Percona XtraDB Cluster:
```
kubectl apply -f /data/codes/percona-xtradb-cluster-operator/deploy/cr.yaml
```

NOTES:
Re-configurate the PVC storageClassName with your own sc, for examle `gp2`.
## 4. Validate the Cluster

The creation process may take some time. When the process is over your cluster will obtain the `ready` status. You can check it with the following command:
```
kubectl get pxc
```

```
NAME ENDPOINT STATUS PXC PROXYSQL HAPROXY AGE cluster1 cluster1-haproxy.default ready 3 3 5m51s
```

pod:
```
kubectl get pods
NAME                                    READY   STATUS    RESTARTS      AGE
cluster1-haproxy-0                      2/2     Running   2 (16m ago)   22m
cluster1-haproxy-1                      2/2     Running   0             2m34s
cluster1-haproxy-2                      2/2     Running   0             2m13s
cluster1-pxc-0                          3/3     Running   0             21m
cluster1-pxc-1                          3/3     Running   0             13m
cluster1-pxc-2                          3/3     Running   0             4m4s
percona-xtradb-cluster-operator-6d-4g   1/1     Running   0             24m
```

svc:
```
root@ip-172-31-45-201:/data/eksctl/sbin# kubectl get svc
NAME            TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)         AGE
cluster1-haproxy                  ClusterIP   10.100.75.199    <none>        3306/TCP,3309/TCP,33062/TCP,33060/TCP   23m
cluster1-haproxy-replicas         ClusterIP   10.100.110.162   <none>        3306/TCP                                23m
cluster1-pxc                      ClusterIP   None             <none>        3306/TCP,33062/TCP,33060/TCP            23m
cluster1-pxc-unready              ClusterIP   None             <none>        3306/TCP,33062/TCP,33060/TCP            23m
percona-xtradb-cluster-operator   ClusterIP   10.100.53.38     <none>        443/TCP                                 24m
```

sts:
```
root@ip-172-31-45-201:/data/eksctl/sbin# kubectl get sts
NAME               READY   AGE
cluster1-haproxy   3/3     23m
cluster1-pxc       3/3     23m
```

endpoint:
```
root@ip-172-31-45-201:/data/eksctl/sbin# kubectl get endpoints
NAME         ENDPOINTS                                                     AGE
cluster1-haproxy                  192.168.0.128:33062,192.168.3.100:33062,192.168.54.49:33062 + 9 more...    24m
cluster1-haproxy-replicas         192.168.0.128:3307,192.168.3.100:3307,192.168.54.49:3307                   24m
cluster1-pxc                      192.168.31.101:33062,192.168.33.80:33062,192.168.50.78:33062 + 6 more...   24m
cluster1-pxc-unready              192.168.31.101:33062,192.168.33.80:33062,192.168.50.78:33062 + 6 more...   24m
percona-xtradb-cluster-operator   192.168.26.111:9443                            
```

secret:
```
kubectl get secrets
NAME                    TYPE                DATA   AGE
cluster1-secrets        Opaque              6      21m
cluster1-ssl            kubernetes.io/tls   3      20m
cluster1-ssl-internal   kubernetes.io/tls   3      20m
internal-cluster1       Opaque              6      21m
```

Use the following command to get the password of the `root` user.
```
kubectl get secret cluster1-secrets -n <namespace> --template='{{.data.root | base64decode}}{{"\n"}}'
```

```
+Hqb)]N7k&jQ997MeV
```

Run a container with `mysql` tool and connect its console output to your terminal. The following command does this, naming the new Pod `percona-client`:
```
kubectl run -n <namespace> -i --rm --tty percona-client --image=percona:8.0 --restart=Never -- bash -il
```

Now run the `mysql` tool in the `percona-client` command shell using the password obtained from the Secret instead of the `<root_password>` placeholder.
```
# HA Proxy (default)
mysql -h cluster1-haproxy -uroot -p
```

## 5. Release the resources & Destroy the Cluster

```
kubectl delete -f /data/codes/percona-xtradb-cluster-operator/deploy/cr.yaml

kubectl delete -f /data/codes/percona-xtradb-cluster-operator/deploy/bundle.yaml

kubectl delete ns mysql

helm uninstall aws-ebs-csi-driver    --namespace kube-system

kubectl delete pdb coredns -n kube-system

stop the eksctl cluster 
```



