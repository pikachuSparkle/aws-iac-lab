## 1. DOCS:

Istio Installing on AWS
https://aws-ia.github.io/terraform-aws-eks-blueprints/patterns/istio/
https://aws.amazon.com/cn/blogs/opensource/getting-started-with-istio-on-amazon-eks/

Source Code:
https://github.com/aws-ia/terraform-aws-eks-blueprints
https://github.com/aws-samples/istio-on-eks/tree/main/modules/01-getting-started

Istio Offical DOCS 
https://istio.io/latest/docs/setup/getting-started/

## 2. EKS Cluster setup

#### 2.1 Git clone the original source code
```
git clone https://github.com/aws-ia/terraform-aws-eks-blueprints.git 
cd terraform-aws-eks-blueprints/patterns/istio
```
#### 2.2 Obtain the main.tf as the following Section 4

#### 2.3 Apply the terraform codes 
```shell
terraform init 
terraform apply -auto-approve 

# configure kubeconfig
aws eks --region us-east-1 update-kubeconfig --name istio
```

Once the resources have been provisioned, you will need to replace the `istio-ingress` pods due to a `istiod` [dependency issue](https://github.com/istio/istio/issues/35789). Use the following command to perform a rolling restart of the `istio-ingress` pods:
```
kubectl rollout restart deployment istio-ingress -n istio-ingress
```

Use the following code snippet to add the Istio Observability Add-ons on the EKS cluster with deployed Istio.
```
for ADDON in kiali jaeger prometheus grafana
do
    ADDON_URL="https://raw.githubusercontent.com/istio/istio/release-1.20/samples/addons/$ADDON.yaml"
    kubectl apply -f $ADDON_URL
done
```

## 3. Cluster Destroy and Resource Recovery
https://aws-ia.github.io/terraform-aws-eks-blueprints/getting-started/#destroy
```shell
terraform destroy -target='module.eks_blueprints_addons.helm_release.this["istio-ingress"]' -auto-approve

terraform destroy -target="module.eks_blueprints_addons" -auto-approve
terraform destroy -target="module.eks" -auto-approve
terraform destroy -auto-approve
```

## 4. Source Obtaining & Explanation & Reconfiguration

#### 4.1 Obtaining Source

You have two approaches to obtain the terraform source code:

1. You can directly references to the refined terraform codes in this Github repo & apply it with terraform command.
```shell
git clone https://github.com/pikachuSparkle/aws-iac-lab.git
vim aws-iac-lab/Terraform_Codes/istio/main.tf
```

2. You can change the original code manually as follows `main.tf`

```yaml
provider "aws" {
  region = local.region
}

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    # This requires the awscli to be installed locally where Terraform is executed
    args = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
  }
}

provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      # This requires the awscli to be installed locally where Terraform is executed
      args = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
    }
  }
}

data "aws_availability_zones" "available" {
  # Do not include local zones
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

locals {
  name   = basename(path.cwd)
  region = "us-east-1"

  vpc_cidr = "10.0.0.0/16"
  azs      = slice(data.aws_availability_zones.available.names, 0, 3)

  istio_chart_url     = "https://istio-release.storage.googleapis.com/charts"
  istio_chart_version = "1.20.2"

  tags = {
    Blueprint  = local.name
    GithubRepo = "github.com/aws-ia/terraform-aws-eks-blueprints"
  }
}

##########################################################################
# Cluster
##########################################################################

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.11"

  cluster_name                   = local.name
  cluster_version                = "1.30"
  cluster_endpoint_public_access = true

  # Give the Terraform identity admin access to the cluster
  # which will allow resources to be deployed into the cluster
  enable_cluster_creator_admin_permissions = true

  cluster_addons = {
    coredns    = {}
    kube-proxy = {}
    vpc-cni    = {}
  }

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.public_subnets

  eks_managed_node_groups = {
    initial = {
      instance_types = ["t3a.medium"]

      min_size     = 1
      max_size     = 2
      desired_size = 1

      # Enable public IP assignment for the nodes
      associate_public_ip_address = true
    }
  }

  #  EKS K8s API cluster needs to be able to talk with the EKS worker nodes with port 15017/TCP and 15012/TCP which is used by Istio
  #  Istio in order to create sidecar needs to be able to communicate with webhook and for that network passage to EKS is needed.
  node_security_group_additional_rules = {
    ingress_15017 = {
      description                   = "Cluster API - Istio Webhook namespace.sidecar-injector.istio.io"
      protocol                      = "TCP"
      from_port                     = 15017
      to_port                       = 15017
      type                          = "ingress"
      source_cluster_security_group = true
    }
    ingress_15012 = {
      description                   = "Cluster API to nodes ports/protocols"
      protocol                      = "TCP"
      from_port                     = 15012
      to_port                       = 15012
      type                          = "ingress"
      source_cluster_security_group = true
    }
  }

  tags = local.tags
}

################################################################################
# Update aws-auth ConfigMap
################################################################################


################################################################################
# EKS Blueprints Addons
################################################################################

resource "kubernetes_namespace_v1" "istio_system" {
  metadata {
    name = "istio-system"
  }
}

module "eks_blueprints_addons" {
  source  = "aws-ia/eks-blueprints-addons/aws"
  version = "~> 1.16"

  cluster_name      = module.eks.cluster_name
  cluster_endpoint  = module.eks.cluster_endpoint
  cluster_version   = module.eks.cluster_version
  oidc_provider_arn = module.eks.oidc_provider_arn

  # This is required to expose Istio Ingress Gateway
  enable_aws_load_balancer_controller = true

  helm_releases = {
    istio-base = {
      chart         = "base"
      chart_version = local.istio_chart_version
      repository    = local.istio_chart_url
      name          = "istio-base"
      namespace     = kubernetes_namespace_v1.istio_system.metadata[0].name
    }

    istiod = {
      chart         = "istiod"
      chart_version = local.istio_chart_version
      repository    = local.istio_chart_url
      name          = "istiod"
      namespace     = kubernetes_namespace_v1.istio_system.metadata[0].name

      set = [
        {
          name  = "meshConfig.accessLogFile"
          value = "/dev/stdout"
        }
      ]
    }

    istio-ingress = {
      chart            = "gateway"
      chart_version    = local.istio_chart_version
      repository       = local.istio_chart_url
      name             = "istio-ingress"
      namespace        = "istio-ingress" # per https://github.com/istio/istio/blob/master/manifests/charts/gateways/istio-ingress/values.yaml#L2
      create_namespace = true

      values = [
        yamlencode(
          {
            labels = {
              istio = "ingressgateway"
            }
            service = {
              annotations = {
                "service.beta.kubernetes.io/aws-load-balancer-type"            = "external"
                "service.beta.kubernetes.io/aws-load-balancer-nlb-target-type" = "ip"
                "service.beta.kubernetes.io/aws-load-balancer-scheme"          = "internet-facing"
                "service.beta.kubernetes.io/aws-load-balancer-attributes"      = "load_balancing.cross_zone.enabled=true"
              }
            }
          }
        )
      ]
    }
  }

  tags = local.tags
}

################################################################################
# Supporting Resources
################################################################################

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = local.name
  cidr = local.vpc_cidr

  azs             = local.azs
  private_subnets = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 4, k)]
  public_subnets  = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k + 48)]

  enable_nat_gateway = false
  single_nat_gateway = false

  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
  }

  # Enable auto-assign public IP for public subnets
  map_public_ip_on_launch = true

  tags = local.tags
}

```

NOTES:
- In AWS best practices, node group should be deployed in private subnet. In this scenario, NAT gateway is needed, for NAT gateway allow instances in a private subnet to access the internet or other external services without exposing their private IP addresses. NAT gateways significantly enhance the security of instances in private subnets. 
- The original terraform codes used NAT gateway, which will incur costs.
- In an effort to reduce costs, the original code was modified. The node group is now deployed directly in a public subnet, eliminating the need for a NAT gateway. Furthermore, the node configuration has been optimized to use fewer resources. This has effectively created a more economical, or "bare-bones" version of the deployment.

#### 4.2 Explanation:
###### 4.2.1 Change local.region = "us-east-1"
###### 4.2.2 Change the instance_type & node group size
```
      # t3a.medium will cheaker 10% than t3a.medium
      # Intel CPU >> AMD CPU
      instance_types = ["t3a.medium"]

      min_size     = 1
      max_size     = 2
      desired_size = 1
```
###### 4.2.3 Use the public_subnet
```
# in EKS subnet configuration
subnet_ids = module.vpc.public_subnets
```

```
# in VPC
# Enable auto-assign public IP for public subnets
  map_public_ip_on_launch = true
```

```
# in node group
# Enable public IP assignment for the nodes
      associate_public_ip_address = true
```
###### 4.2.4 Delete NAT_gateway
```
# In this VPC
  enable_nat_gateway = false
  single_nat_gateway = false
```

###### 4.2.5 About IAM and aws-auth (no changing)
```
# Give the Terraform identity admin access to the cluster
# which will allow resources to be deployed into the cluster
  enable_cluster_creator_admin_permissions = true
```
https://repost.aws/knowledge-center/eks-kubernetes-object-access-error

###### 4.2.6 In this demo, 3 private subnets and 3 public subnets are created. 


