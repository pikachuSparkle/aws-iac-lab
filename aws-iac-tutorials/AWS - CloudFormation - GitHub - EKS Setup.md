This demo is from the AWS templates GitHub [aws-cloudformation-templates](https://github.com/aws-cloudformation/aws-cloudformation-templates)

![Architecture](https://raw.githubusercontent.com/aws-cloudformation/aws-cloudformation-templates/refs/heads/main/EKS/eks_ec2_diagram.png)


## Obtain the source code

```
git clone https://github.com/aws-cloudformation/aws-cloudformation-templates.git
cd ./aws-cloudformation-templates/EKS/
ll ./template.yaml
```

## Set up Cluster with template

Apply the above template in AWS CloudFormation dashboard 

>NOTES:
>Amazon EKS will no longer publish EKS-optimized Amazon Linux 2 (AL2) AMIs after November 26th, 2025. Additionally, Kubernetes version 1.32 is the last version for which Amazon EKS will release AL2 AMIs. From version 1.33 onwards, Amazon EKS will continue to release AL2023 and Bottlerocket based AMIs.

## Validated

```
aws eks update-kubeconfig --region <region-code> --name <cluster-name>
```

Output:
```
Added new context arn:aws:eks:us-east-1:637423222719:cluster/demo11114444-cluster to /root/.kube/config
```



```
kubectl get po -A
```

Output:
```
NAMESPACE     NAME                       READY   STATUS    RESTARTS   AGE
kube-system   aws-node-jhrqq             2/2     Running   0          74s
kube-system   aws-node-v5wjd             2/2     Running   0          73s
kube-system   coredns-6b9575c64c-ghxkc   1/1     Running   0          3m1s
kube-system   coredns-6b9575c64c-t2x8d   1/1     Running   0          3m
kube-system   kube-proxy-dv6hd           1/1     Running   0          74s
kube-system   kube-proxy-pkf27           1/1     Running   0          73s
```
