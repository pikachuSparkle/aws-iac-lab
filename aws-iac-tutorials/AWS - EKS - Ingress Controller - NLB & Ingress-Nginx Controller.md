## DOCS:
There are two solutions to deploy ingress-nginx in AWS EKS using NLB.
1. yaml Approach
https://kubernetes.github.io/ingress-nginx/deploy/#aws
2. helm Approach
https://ranchermanager.docs.rancher.com/getting-started/installation-and-upgrade/install-upgrade-on-a-kubernetes-cluster/rancher-on-amazon-eks

>In AWS, we use a Network load balancer (NLB) to expose the Ingress-Nginx Controller behind a Service of Type=LoadBalancer.


## Installation with yaml

注意正常情况下这样就够了，官方为了使用NLB进行tls证书的卸载（terminate），增加了1234步骤
```shell
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.11.2/deploy/static/provider/aws/deploy.yaml
```

Validation:
```
kubectl get service ingress-nginx-controller --namespace=ingress-nginx
```

Output:
```
NAME      TYPE      CLUSTER-IP     EXTERNAL-IP               PORT(S)          AGE
ingress-nginx-controller   LoadBalancer   10.100.90.18   a904a952c73bf4f668a17c46ac7c56ab-962521486.us-west-2.elb.amazonaws.com   80:31229/TCP,443:31050/TCP 27m
```

注意：
- Ingress-Nginx Controller 必须使用secret的方式使用tls证书，不能使用alb那种引用AWS的arn的方式。
- https://letsencrypt.org/ 通过这个可以申请3个月的免费证书，详见[[Let's Encrypt Certificate Application]]

## Installation with helm

```
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx  
helm repo update  
helm search repo ingress-nginx -l
```

```
helm upgrade --install \  
ingress-nginx ingress-nginx/ingress-nginx \  
--namespace ingress-nginx \  
--set controller.service.type=LoadBalancer \  
--version 4.11.2 \  
--create-namespace
```

Output
```
NAME: ingress-nginx
LAST DEPLOYED: Wed Aug 28 02:04:09 2024
NAMESPACE: ingress-nginx
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
The ingress-nginx controller has been installed.
It may take a few minutes for the load balancer IP to be available.
You can watch the status by running 'kubectl get service --namespace ingress-nginx ingress-nginx-controller --output wide --watch'

An example Ingress that makes use of the controller:
  apiVersion: networking.k8s.io/v1
  kind: Ingress
  metadata:
    name: example
    namespace: foo
  spec:
    ingressClassName: nginx
    rules:
      - host: www.example.com
        http:
          paths:
            - pathType: Prefix
              backend:
                service:
                  name: exampleService
                  port:
                    number: 80
              path: /
    # This section is only required if TLS is to be enabled for the Ingress
    tls:
      - hosts:
        - www.example.com
        secretName: example-tls

If TLS is enabled for the Ingress, a Secret containing the certificate and key must also be provided:

  apiVersion: v1
  kind: Secret
  metadata:
    name: example-tls
    namespace: foo
  data:
    tls.crt: <base64 encoded cert>
    tls.key: <base64 encoded key>
  type: kubernetes.io/tls
```

Get the balance IP
```
kubectl get service ingress-nginx-controller --namespace=ingress-nginx
```

The result should look similar to the following:
```
NAME      TYPE     CLUSTER-IP     EXTERNAL-IP     PORT(S)         AGE
ingress-nginx-controller   LoadBalancer   10.100.90.18   a904a952c73bf4f668a17c46ac7c56ab-962521486.us-west-2.elb.amazonaws.com   80:31229/TCP,443:31050/TCP    27m
```

这个就是部署好了，后面可以通过安装rancher来验证
这个ingress controller比较简单，一个NLB起来之后，剩下的都交给配置ingress来做了

>When installing Rancher on top of this setup, you will also need to pass the value below into the Rancher Helm install command in order to set the name of the ingress controller to be used with Rancher's ingress resource:
>--set ingress.ingressClassName=nginx