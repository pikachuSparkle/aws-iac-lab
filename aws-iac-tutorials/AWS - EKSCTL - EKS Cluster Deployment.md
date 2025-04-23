
## 1. Deployment Approaches：

There are three approaches to create EKS Cluster in AWS.
#### 1.1 Approach 1 - AWS dashboard 

> **Elastic Kubernetes Service | Deploy a sample application**
> https://www.youtube.com/watch?v=I6yqVBhNXxY
> **Elastic Kubernetes Service | Application Load Balancing on EKS**
> https://www.youtube.com/watch?v=ZGKaSboqKzk&list=PLLuj64lk0VU7v9TTWPLQ2EePdOQCJSL_D&index=32
#### 1.2 Approach 2 - EKSCTL Deployment
Following this article
#### 1.3 Approach 3 - Terraform Deployment
[[AWS - Terraform - EKS - Istio - 1. Getting Started with Istio on Amazon EKS]]

## 2. eksctl Tool Binary Installation

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

edit aws credentials config file：~/.aws/credentials
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

## 3. EKS Cluster Deployment

Edit `cluster.yaml` 
DOCS: https://eksctl.io/usage/schema/
```yaml
apiVersion: eksctl.io/v1alpha5
kind: ClusterConfig

metadata:
  name: cluster-demo-1
  region: us-east-1
  version: "1.32"

vpc:
  nat:
    gateway: Disable

nodeGroups:
  - name: demo-nodeGroup-1
    instanceType: t3a.medium
    minSize: 1
    maxSize: 3
    desiredCapacity: 1
    volumeSize: 20
```


Create EKS Cluster as follows
```shell
eksctl create cluster -f cluster.yaml
# Waiting for 10 min and cluster created.
# After cluster started, utilize 'kubectl' console, '~/.kube/config' have been configured automatically
```

NOTES:
- The Dafault Disk is 80G, tunning the disk size to 20G.
- `NAT GATEWAY` will be created by default, which will be charged. The "NAT GATEWAY" is utilized for helping `EC2 instances` in `private subnet` to visit the public internet (inbound direction is not allowed, whick is the best practise for EKS). [[AWS - Concepts - NAT Gateway]]
- eksctl will create EC2 instances in `public subnet`. Hence, opening `NAT GATEWAY` is not needed. Dev environment could tolerate less security for saving money.


## 4. Validate metrics-server addon

```shell
kubectl get pod -A
kubectl top nodes
```

## 5. Terminate EKS Cluster with eksctl

```shell
eksctl delete cluster --name=<name> --region=<region>
```

## 6. Troubleshooting

- Error
```
1 pods are unevictable from node ip-192-168-10-204.ec2.internal
```
- Solutions
```shell
kubectl get pdb -n kube-system
kubectl delete pdb coredns -n kube-system
eksctl delete cluster --name=<name> --region=<region>
```
