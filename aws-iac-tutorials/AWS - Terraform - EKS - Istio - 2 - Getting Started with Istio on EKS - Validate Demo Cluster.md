
------------------------

Following the [[AWS - Terraform - EKS - Istio - 1 - Getting Started with Istio on EKS - Cluster Deployment]]

-----------------

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
```shell
# Install all the microservices in one go
helm install mesh-basic . -n workshop
```

Confirm the installation of microservices in the workshop namespace by running this command:
```shell
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

In this article and the upcoming series, we will be gradually introducing all of the Istio core components. For this particular blog, we are focusing on two key Istio elements: 
**Istio Ingress Gateway** and **VirtualService** that are deployed via the Helm chart in the previous step.
```shell
kubectl get Gateway,VirtualService -n workshop
```

#### Istio Ingress Gateway
[Istio Ingress Gateway](https://istio.io/latest/docs/tasks/traffic-management/ingress/ingress-control/) describes a network load balancer operating at the edge of the mesh receiving incoming HTTP/TCP connections. The specification describes a set of ports that should be exposed, the type of protocol to use, and configuration for the load balancer.

In our example, the `productapp-gateway` Gateway is responsible for defining which hostnames the ingress traffic allows through this gateway, its kind (protocol), and the port at which it is accepted.

```shell
kubectl get gateway productapp-gateway -n workshop -o yaml
```

#### VirtualService

 [VirtualService](https://istio.io/latest/docs/concepts/traffic-management/#virtual-services) defines a set of traffic routing rules to apply when a hostname is addressed. Each routing rule defines matching criteria for traffic of a specific protocol. If the traffic is matched, then it is sent to a named destination service (or subset/version of it) defined in the registry. Without virtual services, Envoy distributes traffic using round-robin load balancing between all service instances mapped to the hostname. With a virtual service, you can specify routing rules that tell Envoy how to send the virtual service’s traffic to appropriate destinations.

```shell
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

```shell
kubectl port-forward svc/kiali 20001:20001 -n istio-system --address 0.0.0.0
```

#### Grafana

```shell
kubectl port-forward svc/grafana 3000:3000 -n istio-system --address 0.0.0.0
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

```shell
terraform destroy -target='module.eks_blueprints_addons.helm_release.this["istio-ingress"]' -auto-approve

terraform destroy -target="module.eks_blueprints_addons" -auto-approve 
terraform destroy -target="module.eks" -auto-approve 
terraform destroy -auto-approve
```