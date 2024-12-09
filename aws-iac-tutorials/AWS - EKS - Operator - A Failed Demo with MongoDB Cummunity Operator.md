## 1. Failed demo
I used to set up replica set successfully with mongodb community operator on canonical K8S:
- 提前在K8S环境部署storageclass local-path
- MongDB Community Operator (https://github.com/mongodb/mongodb-kubernetes-operator)
But failed on AWS EKS build by eksctl (aws-ebs-csi-driver)

For MongoDB offical operators, there are two subset:
- mongodb community operator - only have replicaset, and no backup features (https://github.com/mongodb/mongodb-kubernetes-operator)
- mongodb enterprise kubertetes operator - includeing mongodb-manager
## 2. Demo details

MongDB Community Operator (https://github.com/mongodb/mongodb-kubernetes-operator)
See the documentation to learn how to:

1. Install and upgrade the Operator.
2. Deploy and configure MongoDB resources.
3. Configure Logging of the MongoDB resource components.
4. Create a database user with SCRAM authentication.
5. Secure MongoDB resource connections using TLS.

NOTE: MongoDB Enterprise Kubernetes Operator docs are for the enterprise operator use case and NOT for the community operator. In addition to the docs mentioned above, you can refer to this blog post as well to learn more about community operator deployment


#### 2.1 Install and upgrade the Operator

Install and Upgrade the Community Kubernetes Operator (https://github.com/mongodb/mongodb-kubernetes-operator/blob/master/docs/install-upgrade.md)

The MongoDB Community Kubernetes Operator is a Custom Resource Definition and a controller.
- Operator in Same Namespace as Resources 
- Operator in Different Namespace Than Resources
NOTES: Resources means MongoDB Cluster

Install the Operator using Helm or using kubectl (having not tried)
```
helm repo add mongodb https://mongodb.github.io/helm-charts
```

Install in the Default Namespace using Helm
```
helm install community-operator mongodb/community-operator
```

Install in a Specific Namespace using Helm
```
helm install community-operator mongodb/community-operator --namespace mongodb [--create-namespace]
```

To configure the Operator to watch resources in another namespace, run the following command from the terminal. Replace `example` with the namespace the Operator should watch:
```
#watch specific ns
helm install community-operator mongodb/community-operator --set operator.watchNamespace="example"
#or watch all ns
helm install community-operator mongodb/community-operator --set operator.watchNamespace="*"
```

#### 2.2 Deploy and configure MongoDB resources (Cluster)

Deploy and Configure a MongoDBCommunity Resource (https://github.com/mongodb/mongodb-kubernetes-operator/blob/master/docs/deploy-configure.md)

1. Replace `<your-password-here>` in [mongodb.com_v1_mongodbcommunity_cr.yaml](https://github.com/mongodb/mongodb-kubernetes-operator/blob/master/config/samples/mongodb.com_v1_mongodbcommunity_cr.yaml) to the password you wish to use
2. kubectl apply
```
kubectl apply -f config/samples/mongodb.com_v1_mongodbcommunity_cr.yaml --namespace <my-namespace>
```

then failed!


NOTES：
1、operator namespace parameter
2、operator watch namespace paramater，一般设定为`*`就好，可以部署多套的replicaset
3、When you deploy mongodb cluster in a different namespace from mongodb-operator，需要增加sa、role、rolebinding的设定，名字是mongodb-database，否则pod不能schedualed
4、issue: pvc不能自动创建pv，导致创建pod不成功。经过搜索，看起来是AWS EKS eksctl aws-ebs-csi-driver这套组合下的bug(https://stackoverflow.com/questions/73871493/error-while-installing-mongodb-in-aws-eks-cluster-running-prebind-plugin-volu)

后面使用terraform+另外一个mongodb operator的方式实现了cluster的deployment
[[AWS - EKS - Operator - Percona Operator for MongoDB Deploy]]
