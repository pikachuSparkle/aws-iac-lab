## 0. References: 
https://docs.percona.com/percona-operator-for-postgresql/2.0/eks.html

This guide shows you how to deploy Percona Operator for PostgreSQL on Amazon Elastic Kubernetes Service (EKS). The document assumes some experience with the platform. For more information on the EKS, see the [Amazon EKS official documentation](https://aws.amazon.com/eks/) .

## Creating the EKS cluster

## 1.  Create the EKS cluster

[[AWS - EKS - EKS Cluster Deployment with eksctl]]

In this Demo, we will need 1 working nodes (node type: t3a.medium).
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
--approve

helm upgrade --install aws-ebs-csi-driver              \  
aws-ebs-csi-driver/aws-ebs-csi-driver                  \
--namespace kube-system                                \
--set controller.serviceAccount.annotations."eks\.amazonaws\.com/role-arn"="arn:aws:iam::444444444444:role/AmazonEKS_EBS_CSI_DriverRole"
```

## 3. Install the Operator and Percona Distribution for PostgreSQL

Create the Kubernetes namespace for your cluster if needed
```
kubectl create namespace postgres-operator
```

Deploy the Operator [using](https://kubernetes.io/docs/reference/using-api/server-side-apply/)  the following command:
```
kubectl apply --server-side -f https://raw.githubusercontent.com/percona/percona-postgresql-operator/v2.4.1/deploy/bundle.yaml -n postgres-operator
```
As the result you will have the Operator Pod up and running.

The operator has been started, and you can deploy your Percona Distribution for PostgreSQL cluster:
```
kubectl apply -f https://raw.githubusercontent.com/percona/percona-postgresql-operator/v2.4.1/deploy/cr.yaml -n postgres-operator

# or

git clone -b v2.4.1 https://github.com/percona/percona-postgresql-operator
kubectl apply -f deploy/cr.yaml -n postgres-operator

```

The creation process may take some time. When the process is over your cluster will obtain the `ready` status. You can check it with the following command:
```
kubectl get pg
```

## 4. Verifying the cluster operation

```
kubectl get pg -A
NAMESPACE           NAME       ENDPOINT                                   STATUS   POSTGRES   PGBOUNCER   AGE
postgres-operator   cluster1   cluster1-pgbouncer.postgres-operator.svc   ready    3          3           9m12s
```


```
kubectl get po -n postgres-operator
NAME                                          READY   STATUS      RESTARTS   AGE
cluster1-backup-2tzq-v4lzb                    0/1     Completed   0          4m
cluster1-instance1-958s-0                     4/4     Running     0          6m
cluster1-instance1-mkx2-0                     4/4     Running     0          10m
cluster1-instance1-vqx5-0                     4/4     Running     0          10m
cluster1-pgbouncer-98957c597-7hhh9            2/2     Running     0          10m
cluster1-pgbouncer-98957c597-l2mcf            2/2     Running     0          10m
cluster1-pgbouncer-98957c597-znqgt            2/2     Running     0          10m
cluster1-repo-host-0                          2/2     Running     0          10m
percona-postgresql-operator-55684fc7f-x4vnj   1/1     Running     0          16m
```


```
kubectl get pvc -A
NAMESPACE           NAME                             STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   VOLUMEATTRIBUTESCLASS   AGE
postgres-operator   cluster1-instance1-958s-pgdata   Bound    pvc-1358e918-d606-4f31-87e1-ba2be24f3564   1Gi        RWO            gp2            <unset>                 7m30s
postgres-operator   cluster1-instance1-mkx2-pgdata   Bound    pvc-9f4b7bd6-8f2b-4b37-8e99-c3d6e0827ed6   1Gi        RWO            gp2            <unset>                 7m30s
postgres-operator   cluster1-instance1-vqx5-pgdata   Bound    pvc-3da1f29e-f82f-4463-a86e-fa18de0da751   1Gi        RWO            gp2            <unset>                 7m29s
postgres-operator   cluster1-repo1                   Bound    pvc-0b6e6cd3-e3ba-4bbf-8927-301044570509   1Gi        RWO            gp2            <unset>                 7m29s
```

```
kubectl get sts,deploy -n postgres-operator
NAME                                       READY   AGE
statefulset.apps/cluster1-instance1-958s   1/1     7m23s
statefulset.apps/cluster1-instance1-mkx2   0/1     7m23s
statefulset.apps/cluster1-instance1-vqx5   0/1     7m22s
statefulset.apps/cluster1-repo-host        1/1     7m22s

NAME                                          READY   UP-TO-DATE   AVAILABLE  AGE
deployment.apps/cluster1-pgbouncer            3/3     3            3          7m
deployment.apps/percona-postgresql-operator   1/1     1            1          13m
```


Verifying the cluster operation

Use `kubectl get secrets` command to see the list of Secrets objects. The Secrets object you are interested in is named as `<cluster_name>-pguser-<cluster_name>`
```
kubectl get secrets -n postgres-operator
NAME                            TYPE     DATA   AGE
cluster1-cluster-cert           Opaque   3      14m
cluster1-instance1-958s-certs   Opaque   6      14m
cluster1-instance1-mkx2-certs   Opaque   6      14m
cluster1-instance1-vqx5-certs   Opaque   6      14m
cluster1-pgbackrest             Opaque   5      14m
cluster1-pgbouncer              Opaque   6      14m
cluster1-pguser-cluster1        Opaque   12     14m
cluster1-replication-cert       Opaque   3      14m
pgo-root-cacert                 Opaque   2      14m
```

Use the following command to get the password of this user. Replace the `<cluster_name>` and `<namespace>` placeholders with your values:
```
kubectl get secret cluster1-pguser-cluster1 -n postgres-operator
 --template='{{.data.password | base64decode}}{{"\n"}}'
```

```
ir******************ip
```

Create a pod and start Percona Distribution for PostgreSQL inside. The following command will do this, naming the new Pod `pg-client`:
```
kubectl run -i --rm --tty pg-client --image=perconalab/percona-distribution-postgresql:16.3 --restart=Never -- bash -il
```

Run a container with `psql` tool and connect its console output to your terminal. The following command will connect you as a `cluster1` user to a `cluster1` database via the PostgreSQL interactive terminal.
```
PGPASSWORD='pguser_password' psql -h cluster1-pgbouncer.postgres-operator.svc -p 5432 -U cluster1 cluster1
```

Output:
```
psql (16.3) SSL connection (protocol: TLSv1.3, cipher: TLS_AES_256_GCM_SHA384, bits: 256, compression: off) Type "help" for help. pgdb=>
```


## 5. # Insert sample data 
https://docs.percona.com/percona-operator-for-postgresql/2.0/data-insert.html

#### Create a schema

```
CREATE SCHEMA demo;
```

```
SET schema 'demo';
```

#### Create a table
```
CREATE TABLE LIBRARY(
   ID INTEGER NOT NULL,
   NAME TEXT,
   SHORT_DESCRIPTION TEXT,
   AUTHOR TEXT,
   DESCRIPTION TEXT,
   CONTENT TEXT,
   LAST_UPDATED DATE,
   CREATED DATE
);
```

#### Insert the data
```
INSERT INTO LIBRARY(id, name, short_description, author,
                              description,content, last_updated, created)
SELECT id, 'name', md5(random()::text), 'name2'
      ,md5(random()::text),md5(random()::text)
      ,NOW() - '1 day'::INTERVAL * (RANDOM()::int * 100)
      ,NOW() - '1 day'::INTERVAL * (RANDOM()::int * 100 + 100)
FROM generate_series(1,100) id;
```
## 6. Make a backup (pending)
https://docs.percona.com/percona-operator-for-postgresql/2.0/backup-tutorial.html
