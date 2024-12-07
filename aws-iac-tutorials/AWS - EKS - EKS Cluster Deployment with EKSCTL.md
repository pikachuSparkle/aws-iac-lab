
## 1. 部署方式：

EKS共有三种部署方式
#### 1.1 AWS dashboard 部署
参考资料如下：
> **Elastic Kubernetes Service | Deploy a sample application**
> https://www.youtube.com/watch?v=I6yqVBhNXxY
> **Elastic Kubernetes Service | Application Load Balancing on EKS**
> https://www.youtube.com/watch?v=ZGKaSboqKzk&list=PLLuj64lk0VU7v9TTWPLQ2EePdOQCJSL_D&index=32
#### 1.2 EKSCTL部署
详见第二节
#### 1.3 Terraform部署
暂未了解

## 2. EKSCTL部署

#### 2.1 EKSCTL Installation

DOCS: https://eksctl.io/installation/

```shell
# for ARM systems, set ARCH to: `arm64`, `armv6` or `armv7`
ARCH=amd64
PLATFORM=$(uname -s)_$ARCH

curl -sLO "https://github.com/eksctl-io/eksctl/releases/latest/download/eksctl_$PLATFORM.tar.gz"

# (Optional) Verify checksum
curl -sL "https://github.com/eksctl-io/eksctl/releases/latest/download/eksctl_checksums.txt" | grep $PLATFORM | sha256sum --check

tar -xzf eksctl_$PLATFORM.tar.gz -C /tmp && rm eksctl_$PLATFORM.tar.gz

sudo mv /tmp/eksctl /usr/local/bin
```


AWS credentials配置文件：~/.aws/credentials

```
[default]
aws_access_key_id = 
aws_secret_access_key = 

[dev]
aws_access_key_id = 
aws_secret_access_key = 

[prod]
aws_access_key_id = 
aws_secret_access_key = 
```

#### 2.2 EKS Cluster Deployment

`cluster.yaml` 
```yaml
apiVersion: eksctl.io/v1alpha5
kind: ClusterConfig

metadata:
  name: cluster-demo-1
  region: us-east-1
  version: "1.30"

vpc:
  nat:
    gateway: Disable

nodeGroups:
  - name: demo-nodeGroup-1
    instanceType: t3.medium
    minSize: 1
    maxSize: 2
    desiredCapacity: 1
    volumeSize: 20
```
DOCS:https://eksctl.io/usage/schema/

启动EKS Cluster

```shell
eksctl create cluster -f cluster.yaml
#等待10分钟启动完毕
#启动后可以使用kubectl了，~/.kube/config已经自动配置好了
```

注意：
```
- 磁盘默认80G，调整为20G。
- NAT GATEWAY默认是会被创建，这个是收费的。作用是帮助private subnet的instances出向访问互联网，入向不可以（EKS安全最佳实践）。由于eksctl默认创建的EC2 instances是在public subnet，这个的话就没必要开启这个NAT GATEWAY，省一点是一点，测试环境不必考虑安全性。
```


#### 2.3 测试安装Application

安装个metrices-server测试一下
DOCS：https://docs.aws.amazon.com/eks/latest/userguide/metrics-server.html
```shell
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
kubectl get deployment metrics-server -n kube-system
kubectl top nodes
```

#### 2.4 关闭EKS集群

```shell
eksctl delete cluster --name=<name> --region=<region>
```

Error: `1 pods are unevictable from node ip-192-168-10-204.ec2.internal`
Solutions: 
```shell
kubectl get pdb -n kube-system
kubectl delete pdb coredns -n kube-system
eksctl delete cluster --name=<name> --region=<region>
```

