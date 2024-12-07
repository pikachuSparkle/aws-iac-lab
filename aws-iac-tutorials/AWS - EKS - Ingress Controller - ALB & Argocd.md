## 1. DOCS：

关键参考案例和HTTP Demo: https://blog.bitipcman.com/eks-workshop-101-part2/
https://aws.amazon.com/blogs/opensource/kubernetes-ingress-aws-alb-ingress-controller/
https://kubernetes-sigs.github.io/aws-load-balancer-controller/v2.2/

>AWS Load Balancer Controller is a controller to help manage Elastic Load Balancers for a Kubernetes cluster.
>- It satisfies Kubernetes [Ingress resources](https://kubernetes.io/docs/concepts/services-networking/ingress/) by provisioning [Application Load Balancers](https://docs.aws.amazon.com/elasticloadbalancing/latest/application/introduction.html).
>- It satisfies Kubernetes [Service resources](https://kubernetes.io/docs/concepts/services-networking/service/) by provisioning [Network Load Balancers](https://docs.aws.amazon.com/elasticloadbalancing/latest/network/introduction.html).

## 2. Deployment

```shell
#设置env
export AWS_REGION=us-east-1 

#开启provider
eksctl utils associate-iam-oidc-provider --cluster=<your-cluster-name> --approve

#下载policy
curl -o iam-policy.json https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/main/docs/install/iam_policy.json
#创建policy
aws iam create-policy --policy-name AWSLoadBalancerControllerIAMPolicy --policy-document file://iam-policy.json


#注意那个连接资源arn必须到IAM的policy里面去找
eksctl create iamserviceaccount \
  --cluster=<your-cluster-name> \
  --namespace=kube-system \
  --name=aws-load-balancer-controller \
  --attach-policy-arn=arn:aws:iam::637423222719:policy/AWSLoadBalancerControllerIAMPolicy \
  --approve

#安装ALB Ingress Controllert
helm repo add eks https://aws.github.io/eks-charts
helm repo update
helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=<your-cluster-name> \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller

#删除安装的Controller，如果需要的话
helm delete aws-load-balancer-controller -n kube-system   
```

## 3. HTTP 验证 Demo

关键参考案例和HTTP Demo: https://blog.bitipcman.com/eks-workshop-101-part2/
这里面有nginx的例子，这个例子是完成一个80端口的http的alb的demo

## 4. HTTPS 验证 Demo

- 必须要有自己的域名，证书可以到ACM里面创建免费签发的public certificate
- 完成基于TLS的https的demo
- 使用argocd的UI作为界面
- 技术实践涉及证书创建验证、DNS配置
- 知识点涉及eks与alb ingress controller的网络实现（type：instance & IP）

#### 4.1 DOCS

Certificate Discovery
https://kubernetes-sigs.github.io/aws-load-balancer-controller/v2.2/guide/ingress/cert_discovery/

https://medium.com/@imhamoro/install-argo-cd-to-deploy-services-on-aws-eks-2d47b5bb8f91

#### 4.2 TLS证书创建与验证

创建环节：证书通过ACM创建
验证环节：通过给定的NAME 和 CNAME VALUE进行验证（在自己的DNS配置平台上），**验证完毕就可以删除！**

#### 4.3 argocd安装

```
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

备注：
- **先把argocd-server的那个svc的ClusterIP给改为NodePort**（知识点：AWS alb有instance和ip两种type，其中instance是默认的，必须开启NodePort）
- argocd其实还有一个grpc的服务，这次只做UI的服务暴露，把tls的ingress流程跑通，所以和官方的配置文件会不一样，把grpc的去掉（关键官方的配置也不大对）

#### 4.4 ingress部署

```yaml
apiVersion: networking.k8s.io/v1
  kind: Ingress
  metadata:
    annotations:
      alb.ingress.kubernetes.io/scheme: internet-facing
      alb.ingress.kubernetes.io/backend-protocol: HTTPS
      # Use this annotation (which must match a service name) to route traffic to HTTP2 backends.
      alb.ingress.kubernetes.io/conditions.argogrpc: |
        [{"field":"http-header","httpHeaderConfig":{"httpHeaderName": "Content-Type", "values":["application/grpc"]}}]
      alb.ingress.kubernetes.io/listen-ports: '[{"HTTPS":443}]'
    name: argocd
    namespace: argocd
  spec:
    ingressClassName: alb
    rules:
    - host: argocd.example.com
      http:
        paths:
        - path: /
          backend:
            service:
              name: argocd-server
              port:
                number: 443
          pathType: Prefix
    tls:
    - hosts:
      - argocd.example.com
```

注意，argocd官网配置的例子不太对，做了如下修正：

```
#添加
alb.ingress.kubernetes.io/scheme: internet-facing
ingressClassName: alb
```

```
#得有自己的域名
host: argocd.example.com
```

```
#tls会根据你配置的域名和证书（需要在ACM里面配置好），自动寻找
```

```
#暂时不需要grpc功能，删除RPC那一段
#其实annotation里面的alb.ingress.kubernetes.io/conditions.argogrpc也可以删除
- path: /grpc
          backend:
            service:
              name: argogrpc
              port:
                number: 443
          pathType: Prefix
```

部署这个调整好的yaml文件
```
kubectl apply -f argocd-ingress.yaml
```

#### 4.5 验证

```
kubectl get ingress -n argocd
```
optput:
```
NAME     CLASS   HOSTS                       ADDRESS          PORTS     AGE
argocd   alb     argocd.example.com   k8s-argocd-argocd-68ee239fcb-701787668.us-east-1.elb.amazonaws.com   80, 443   78m
```

等待一段时间，等ALB完成创建
- provision->active
- targetgroup状态healthy

#### 4.6 DNS配置
在DNS配置环境，需要做CNAME配置
```
NAME: hostname.example.com   
CNAME VALUE:  k8s-argocd-argocd-68ee239fcb-701787668.us-east-1.elb.amazonaws.com
```

#### 4.7 访问

URL：
https://argocd.example.com

Login：
```
username: admin
password: BBBBBBBBBBBBBB

#password 获取方式
kubectl -n argocd get secret argocd-initial-admin-secret \
          -o jsonpath="{.data.password}" | base64 -d; echo
```

argocd的UI界面访问成功！完成！