
AWS's Elastic Kubernetes Service (EKS) is a managed service that lets you deploy, manage, and scale containerized applications on Kubernetes.

In this tutorial, you will deploy an EKS cluster using Terraform. Then, you will configure `kubectl` using Terraform output and verify that your cluster is ready to use.
## References
https://developer.hashicorp.com/terraform/tutorials/aws/eks

## Set up Terraform workspace



```shell
git clone https://github.com/hashicorp-education/learn-terraform-provision-eks-cluster
```

```shell
cd learn-terraform-provision-eks-cluster
```

This example repository contains configuration to provision a VPC, security groups, and an EKS cluster with the following architecture:
![](https://developer.hashicorp.com/_next/image?url=https%3A%2F%2Fcontent.hashicorp.com%2Fapi%2Fassets%3Fproduct%3Dtutorials%26version%3Dmain%26asset%3Dpublic%252Fimg%252Fterraform%252Feks%252Foverview.png%26width%3D1522%26height%3D1054&w=1920&q=75&dpl=dpl_3QtQRS8SEVCFvrALmzGP7iSu7QCW)

The configuration defines a new VPC in which to provision the cluster, and uses the public EKS module to create the required resources, including Auto Scaling Groups, security groups, and IAM Roles and Policies.

Open the `main.tf` file to review the module configuration. The `eks_managed_node_groups` parameter configures the cluster with three nodes across two node groups.

main.tf
```
eks_managed_node_groups = {
one = {
    name = "node-group-1"

    instance_types = ["t3.small"]

    min_size     = 1
    max_size     = 3
    desired_size = 2
}

two = {
    name = "node-group-2"

    instance_types = ["t3.small"]

    min_size     = 1
    max_size     = 2
    desired_size = 1
}
}
```

## Provision the EKS cluster

```shell
terraform init
terraform apply
```


## Configure kubectl

After provisioning your cluster, you need to configure `kubectl` to interact with it.

First, open the `outputs.tf` file to review the output values. You will use the `region` and `cluster_name` outputs to configure `kubectl`.

outputs.tf
```
output "cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = module.eks.cluster_endpoint
}

output "cluster_security_group_id" {
  description = "Security group ids attached to the cluster control plane"
  value       = module.eks.cluster_security_group_id
}

output "region" {
  description = "AWS region"
  value       = var.region
}

output "cluster_name" {
  description = "Kubernetes Cluster Name"
  value       = module.eks.cluster_name
}
```

Run the following command to retrieve the access credentials for your cluster and configure `kubectl`.

```
$ aws eks --region $(terraform output -raw region) update-kubeconfig \
    --name $(terraform output -raw cluster_name)
```

You can now use `kubectl` to manage your cluster and deploy Kubernetes configurations to it.

## Verify the Cluster

```
kubectl cluster-info

kubectl get nodes
```

[Deploy metrices server](https://github.com/kubernetes-sigs/metrics-server) for validate
```shell
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

kubectl get po -A -w
kubectl top nodes
```


## Clean up your workspace

```
terraform destroy
```