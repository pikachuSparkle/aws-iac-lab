## 0. DOCS:

Deployment on AWS
主参考
https://aws.amazon.com/cn/blogs/opensource/getting-started-with-istio-on-amazon-eks/
辅参考
https://aws-ia.github.io/terraform-aws-eks-blueprints/patterns/istio/

Source Code:
https://github.com/aws-ia/terraform-aws-eks-blueprints
https://github.com/aws-samples/istio-on-eks/tree/main/modules/01-getting-started

Conanical K8S deployment
https://istio.io/latest/docs/setup/getting-started/

## 1. EKS Cluster setup

Git clone the souece code
```
git clone https://github.com/aws-ia/terraform-aws-eks-blueprints.git 
cd terraform-aws-eks-blueprints/patterns/istio
```

Change the main.tf as the following Section 4

Apply the terraform codes 
```
terraform init 
terraform apply -auto-approve 
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

## 2. Cluster Destroy and Resource Recovery
https://aws-ia.github.io/terraform-aws-eks-blueprints/getting-started/#destroy
```yaml
terraform destroy -target="module.eks_blueprints_addons" -auto-approve
terraform destroy -target="module.eks" -auto-approve
terraform destroy -auto-approve
```

## 3. Source Reading & Explanation

```
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

################################################################################
# Cluster
################################################################################

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
      instance_types = ["t3.medium"]

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

- AWS best practices 是 node group部署在private_subnet中，为了访问公网，需要增加一个nat gateway，既保证安全，又可以访问公网。原版的terraform代码就是这样的。
- 为了省钱，对原有代码进行了修改，node group直接部署在public_subnet中，删除nat gateway。另外压缩node的配置。形成了穷人版代码。

#### 4.1 Change local.region = "us-east-1"
#### 4.2 Change the instance_type & node group size
```
      # 调整成t3a.medium会更便宜10%,CPU换成稍弱的AMD处理器
      instance_types = ["t3a.medium"]

      min_size     = 1
      max_size     = 2
      desired_size = 1
```
#### 4.3 use the public_subnet
```
# in EKS subnet configurate
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
#### 4.4 nat_gateway delete
```
# in VPC
  enable_nat_gateway = false
  single_nat_gateway = false
```


#### 4.5 About IAM and aws-auth (no changing)
```
# Give the Terraform identity admin access to the cluster
# which will allow resources to be deployed into the cluster
  enable_cluster_creator_admin_permissions = true
```
https://repost.aws/zh-Hans/knowledge-center/eks-kubernetes-object-access-error
授予权限问题

#### 4.6 关于子网，demo中建立了3个privatesubnet, 3个public subnet


## 5. Deploying the microservices to Istio Service Mesh

We will be following the steps from the  [01-getting-started module](https://github.com/aws-samples/istio-on-eks/tree/main/modules/01-getting-started) of the istio-on-eks Git repository
```
git clone https://github.com/aws-samples/istio-on-eks.git 
cd istio-on-eks/modules/01-getting-started
```

To be able to deploy the microservices to the Istio Service Mesh automatically, the chosen namespace must be labeled with the label `istio-injection=enabled`. This will [inject the sidecar envoy proxy](https://istio.io/latest/docs/setup/additional-setup/sidecar-injection/#automatic-sidecar-injection) into the microservices that are part of the “workshop” namespace.

```
# Create workshop namespace and label it for use with Istio Service Mesh
kubectl create namespace workshop 
kubectl label namespace workshop istio-injection=enabled
```

Now deploy the provided [mesh-basic](https://github.com/aws-samples/istio-on-eks/blob/main/modules/01-getting-started/Chart.yaml) Helm Chart. This helm chart is packaged with a deployment manifest for:
- All the three microservices (`frontend`,`prodcatalog`, and `catalogdetail`)
- Istio Gateway and a VirtualService.
```yaml
# Install all the microservices in one go
helm install mesh-basic . -n workshop
```

Confirm the installation of microservices in the workshop namespace by running this command:
```
kubectl get pods -n workshop
```

The application’s (user interface) URL can be retrieved using the following command:
```
ISTIO_INGRESS_URL=$(kubectl get svc istio-ingress -n istio-ingress -o jsonpath='{.status.loadBalancer.ingress[*].hostname}') 
echo "http://$ISTIO_INGRESS_URL"
```

Accessing this URL in the browser will lead you to the **Product Catalog** application as shown here:
```
K8S**************************.us-east-1-amazonaws.com
```

```
v1----> `Vendors`: `ABC.com`
v2----> `Vendors`: `ABC.com, XYZ.com`
```

## 6. Key Istio Components

In this blog and the upcoming series, we will be gradually introducing all of the Istio core components. For this particular blog, we are focusing on two key Istio elements: **Istio Ingress Gateway** and **VirtualService** that are deployed via the Helm chart in the previous step.
```
kubectl get Gateway,VirtualService -n workshop
```

#### Istio Ingress Gateway
[Istio Ingress Gateway](https://istio.io/latest/docs/tasks/traffic-management/ingress/ingress-control/) describes a network load balancer operating at the edge of the mesh receiving incoming HTTP/TCP connections. The specification describes a set of ports that should be exposed, the type of protocol to use, and configuration for the load balancer.

In our example, the `productapp-gateway` Gateway is responsible for defining which hostnames the ingress traffic allows through this gateway, its kind (protocol), and the port at which it is accepted.

```
kubectl get gateway productapp-gateway -n workshop -o yaml
```

#### VirtualService

A [VirtualService](https://istio.io/latest/docs/concepts/traffic-management/#virtual-services) defines a set of traffic routing rules to apply when a hostname is addressed. Each routing rule defines matching criteria for traffic of a specific protocol. If the traffic is matched, then it is sent to a named destination service (or subset/version of it) defined in the registry. Without virtual services, Envoy distributes traffic using round-robin load balancing between all service instances mapped to the hostname. With a virtual service, you can specify routing rules that tell Envoy how to send the virtual service’s traffic to appropriate destinations.

```
kubectl get VirtualService productapp -n workshop -o yaml
```


Based on this YAML definition of the Gateway, we can conclude that the `productapp` VirtualService :

- Is associated specifically with `productapp-gateway` Gateway and any ingress traffic through it
- Matches any host name `(*)` of the `HTTP` traffic
- When matched with no specific context path `(/)` in the request URI, routes the traffic to the `frontend` destination service.

## 7. Visualization

Now that we have demonstrated how to deploy services into Istio Service Mesh, let’s get into how you can visualize the service mesh with Kiali and its metrics in Grafana.

#### Kiali
[Kiali](https://kiali.io/) is a console for Istio service mesh and we will be using Kiali to validate our setup. Kiali should already be available as a deployment in the `istio-system` namespace if you have setup Istio using the [EKS Istio blueprint](https://aws-ia.github.io/terraform-aws-eks-blueprints/patterns/istio/) we shared before.

```
kubectl port-forward svc/kiali 20001:20001 -n istio-system
```

#### Grafana

```
kubectl port-forward svc/grafana 3000:3000 -n istio-system
```

Use your browser to navigate to `http://localhost:3000/dashboards`

## 8. Testing

- Traffic rate
- Traffic distribution
- Throughput
- Response time
- Traffic animation between services

Generating Traffic
```
ISTIO_INGRESS_URL=$(kubectl get svc istio-ingress -n istio-ingress -o jsonpath='{.status.loadBalancer.ingress[*].hostname}') 

# Generate load for 2 minute, with 5 concurrent threads and with a delay of 10s between successive requests 
siege http://$ISTIO_INGRESS_URL -c 5 -d 10 -t 2M
```

Observations
Based on traffic animation captured in Kiali as a result of our load test, we can conclude that:
- The Ingress traffic directed towards the `istio-ingress` is captured by the Gateway `productapp-gateway` as it handles traffic for all hosts `(*)`
- Traffic is then directed towards `productapp` VirtualService as its host definition matches all hosts `(*)`
- From `productapp` VirtualService, the traffic reaches `frontend` microservice as the context-path matches `/`, from there moves to `productcatalog` and then finally to `catalogdetail`.
- The `catalogdetail` service, as expected, randomly splits the traffic between `v1` and `v2` versions.

## 9. Cleanup

```
helm uninstall mesh-basic -n workshop kubectl delete namespace workshop
```

To further remove the EKS cluster with deployed Istio that you might have created in the prerequisite step, run the commands provided [here](https://aws-ia.github.io/terraform-aws-eks-blueprints/patterns/istio/#destroy).

```
terraform destroy -target='module.eks_blueprints_addons.helm_release.this["istio-ingress"]' -auto-approve

terraform destroy -target="module.eks_blueprints_addons" -auto-approve 
terraform destroy -target="module.eks" -auto-approve 
terraform destroy -auto-approve
```