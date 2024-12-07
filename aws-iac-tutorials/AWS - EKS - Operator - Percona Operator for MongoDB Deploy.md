## 0. DOCS:

The specific procures of deploying with Percona Operator for MongoDB
https://docs.percona.com/percona-operator-for-mongodb/eks.html
The overall intrduction of production deployment of mongodb on K8S
https://www.cncf.io/blog/2024/03/14/production-deployment-of-mongodb-on-kubernetes/
The survey blog about mongodb opeator solutions
https://www.percona.com/blog/run-mongodb-in-kubernetes-solutions-pros-and-cons/


Even though MongoDB is one of the most popular databases in the world, there are not a lot of solutions available to run it in Kubernetes. Please looked into available options in [this blog post](https://www.percona.com/blog/run-mongodb-in-kubernetes-solutions-pros-and-cons/).

Solutions that we have reviewed are:
- Bitnami Helm chart
- KubeDB
- MongoDB Community Operator
- Percona Operator for MongoDB

>Designed with both efficiency and simplicity in mind, the Percona Operator for MongoDB not only streamlines the deployment of MongoDB on Kubernetes but also automates the entire lifecycle of cloud-native MongoDB database operations. It offers a range of functionalities like installation, configuration, high availability, and expanded clustering. With our operator, you gain enterprise-grade features, unrestricted portability, and compatibility with popular Kubernetes flavors. Choose the Percona Operator for MongoDB for a seamless, automated, and efficient MongoDB management experience on Kubernetes.

## 1. Create EKS with Terraform

[[AWS - Terraform - EKS - Istio - 1. Getting Started with Istio on Amazon EKS]]

## 2. Install aws-ebs-csi-driver

[[AWS - EKS - aws-ebs-csi-driver Installation]]

```
export AWS_REGION=us-east-1
eksctl utils associate-iam-oidc-provider --cluster=istio --region=us-east-1 --approve

```

```
eksctl create iamserviceaccount \
        --name ebs-csi-controller-sa \
        --namespace kube-system \
        --cluster istio \
        --role-name AmazonEKS_EBS_CSI_DriverRole \
        --role-only \
        --attach-policy-arn arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy \
        --approve
```

```
helm upgrade --install aws-ebs-csi-driver   aws-ebs-csi-driver/aws-ebs-csi-driver \
    --namespace kube-system \
    --set controller.serviceAccount.annotations."eks\.amazonaws\.com/role-arn"="arn:aws:iam::444444444444:role/AmazonEKS_EBS_CSI_DriverRole"
```

## 3. Install Percona Server for MongoDB on Amazon Elastic Kubernetes Service (EKS)

Deploy the Operator. By default deployment will be done in the `default` namespace. If that’s not the desired one, you can create a new namespace and/or set the context for the namespace as follows
```
kubectl create namespace mongodb
kubectl config set-context $(kubectl config current-context) --namespace=mongodb
```

Deploy the Operator [using](https://kubernetes.io/docs/reference/using-api/server-side-apply/)  the following command:
```
kubectl apply --server-side -f https://raw.githubusercontent.com/percona/percona-server-mongodb-operator/v1.16.2/deploy/bundle.yaml
```

The operator has been started, and you can deploy your MongoDB cluster:
```
kubectl apply -f https://raw.githubusercontent.com/percona/percona-server-mongodb-operator/v1.16.2/deploy/cr.yaml
```

The creation process may take some time. When the process is over your cluster will obtain the `ready` status. You can check it with the following command:
```
kubectl get psmdb
```

Notes:

>This deploys default MongoDB cluster configuration, three mongod, three mongos, and three config server instances. Please see [deploy/cr.yaml](https://raw.githubusercontent.com/percona/percona-server-mongodb-operator/v1.16.2/deploy/cr.yaml)  and [Custom Resource Options](https://docs.percona.com/percona-operator-for-mongodb/operator.html) for the configuration options. You can clone the repository with all manifests and source code by executing the following command:
`$ git clone -b v1.16.2 https://github.com/percona/percona-server-mongodb-operator`

>In this deployment, 4 nodes are needed because of the affinity.


## 4. Verifying the cluster operation

It may take ten minutes to get the cluster started. When `kubectl get psmdb` command finally shows you the cluster status as `ready`, you can try to connect to the cluster.

```
root@ip-172-31-45-201:~# kubectl get po 
NAME                                        READY   STATUS    RESTARTS        AGE
my-cluster-name-cfg-0                       2/2     Running   0               20m
my-cluster-name-cfg-1                       2/2     Running   0               16m
my-cluster-name-cfg-2                       2/2     Running   0               10m
my-cluster-name-mongos-0                    1/1     Running   0               14m
my-cluster-name-mongos-1                    1/1     Running   0               13m
my-cluster-name-mongos-2                    1/1     Running   0               6m
my-cluster-name-rs0-0                       2/2     Running   3 (8m13s ago)   17m
my-cluster-name-rs0-1                       2/2     Running   0               12m
my-cluster-name-rs0-2                       2/2     Running   0               4m
percona-server-mongodb-operator-5bd99d      1/1     Running   0               24m
```

```
root@ip-172-31-45-201:~# kubectl get pvc
NAME           STATUS   VOLUME    CAPACITY   ACCESS MODES   STORAGECLASS   VOLUMEATTRIBUTESCLASS   AGE
mongod-data-my-cluster-name-cfg-0   Bound    pvc-32fdb11f-3eaa-4171-b461-7c800e334ddf   3Gi        RWO            gp2            <unset>                 24m
mongod-data-my-cluster-name-cfg-1   Bound    pvc-cc2e0842-0618-44af-897a-559160e7074a   3Gi        RWO            gp2            <unset>                 17m
mongod-data-my-cluster-name-cfg-2   Bound    pvc-bc25127a-3bf7-4e39-bb42-8cf01d463600   3Gi        RWO            gp2            <unset>                 15m
mongod-data-my-cluster-name-rs0-0   Bound    pvc-266b2f2d-bdd4-4e05-88f5-fd730fa57caf   3Gi        RWO            gp2            <unset>                 24m
mongod-data-my-cluster-name-rs0-1   Bound    pvc-264591aa-eedc-43f2-9480-31c825e9dade   3Gi        RWO            gp2            <unset>                 17m
mongod-data-my-cluster-name-rs0-2   Bound    pvc-6d5e4777-06a5-4438-a73a-a355f6339726   3Gi        RWO            gp2            <unset>                 6m37s
```

```
NAME                    TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)     AGE
my-cluster-name-cfg     ClusterIP   None            <none>        27017/TCP   24m
my-cluster-name-mongos  ClusterIP   172.20.108.97   <none>        27017/TCP   14m
my-cluster-name-rs0     ClusterIP   None            <none>        27017/TCP   24m
```

```
root@ip-172-31-45-201:~#  kubectl get psmdb
NAME              ENDPOINT                                           STATUS   AGE
my-cluster-name   my-cluster-name-mongos.mongodb.svc.cluster.local   ready    25m
```


```
root@ip-172-31-45-201:~# kubectl get secrets 
NAME                                     TYPE                DATA   AGE
internal-my-cluster-name-users           Opaque              10     26m
my-cluster-name-mongodb-encryption-key   Opaque              1      26m
my-cluster-name-mongodb-keyfile          Opaque              1      26m
my-cluster-name-secrets                  Opaque              10     26m
my-cluster-name-ssl                      kubernetes.io/tls   3      26m
my-cluster-name-ssl-internal             kubernetes.io/tls   3      26m
```


```
root@ip-172-31-45-201:~# kubectl get secret my-cluster-name-secrets -o yaml
apiVersion: v1
data:
  MONGODB_BACKUP_PASSWORD: S1pjcFl2N2V2Z1N6d2pDbU1sUg==
  MONGODB_BACKUP_USER: YmFja3Vw
  MONGODB_CLUSTER_ADMIN_PASSWORD: R0JoU3VvTVE4amRPRWhCR3dvag==
  MONGODB_CLUSTER_ADMIN_USER: Y2x1c3RlckFkbWlu
  MONGODB_CLUSTER_MONITOR_PASSWORD: ZFpjMjNyZkZheGlGNWM4NA==
  MONGODB_CLUSTER_MONITOR_USER: Y2x1c3Rlck1vbml0b3I=
  MONGODB_DATABASE_ADMIN_PASSWORD: RlEzcjFZNkVxU1NsenVaeg==
  MONGODB_DATABASE_ADMIN_USER: ZGF0YWJhc2VBZG1pbg==
  MONGODB_USER_ADMIN_PASSWORD: dHJ5TTZ2V1V2cEVHMXR6QkxKeg==
  MONGODB_USER_ADMIN_USER: dXNlckFkbWlu
kind: Secret
metadata:
  creationTimestamp: "2024-09-07T23:53:58Z"
  name: my-cluster-name-secrets
  namespace: mongodb
  resourceVersion: "6410"
  uid: 53384cf8-7a72-45aa-82d8-283cfbdb215f
type: Opaque
```

The actual login name and password on the output are base64-encoded. To bring it back to a human-readable form, run:
```
echo 'MONGODB_DATABASE_ADMIN_USER' | base64 --decode 
echo 'MONGODB_DATABASE_ADMIN_PASSWORD' | base64 --decode
```

```
#Output
userAdmin
tryM6vWUvpEG1tzBLJz
```

Run a container with a MongoDB client and connect its console output to your terminal. The following command does this, naming the new Pod `percona-client`:

```
kubectl run -i --rm --tty percona-client --image=percona/percona-server-mongodb:7.0.8-5 --restart=Never -- bash -il
```

Now run `mongosh` tool inside the `percona-client` command shell using the admin user credentialds you obtained from the Secret, and a proper namespace name instead of the `<namespace name>` placeholder. The command will look different depending on whether sharding is on (the default behavior) or off:

if sharding is on
```
mongosh "mongodb://userAdmin:tryM6vWUvpEG1tzBLJz@my-cluster-name-mongos.mongodb.svc.cluster.local/admin?ssl=false"
```

if sharding is off
```
$ mongosh "mongodb+srv://dXNlckFkbWlu:dHJ5TTZ2V1V2cEVHMXR6QkxKeg==@my-cluster-name-rs0.mongodb.svc.cluster.local/admin?replicaSet=rs0&ssl=false"
```



