## DOCS:

https://dev.to/aws-builders/setup-rancher-on-eks-alb-50
>Rancher documentation is using [nginx-ingress-controller](https://kubernetes.github.io/ingress-nginx/) and only creates Classic Load Balancer or Network Load Balancer.  
>We will use [AWS Load Balancer Controller](https://kubernetes-sigs.github.io/aws-load-balancer-controller/) to create ALB for our Rancher.

## 1. Create [EKS Cluster](https://docs.aws.amazon.com/eks/latest/userguide/create-cluster.html)

[[AWS - EKS - EKS Cluster Deployment with eksctl]]

## 2. Install [AWS Load Balancer Controller](https://docs.aws.amazon.com/eks/latest/userguide/aws-load-balancer-controller.html#lbc-install-controller)

[[AWS - EKS - Ingress Controller - ALB & Load Balancer Controller & ArgoCD]]

## 3. Deploy Rancher with ALB Ingress

Add the Helm Chart Repository

```
helm repo add rancher-stable https://releases.rancher.com/server-charts/stable
```

安装rancher，这里对参考文档中的配置进行了简化。
- 证书资源使用的ACM，EKS可以通过arn自己寻找
- subnet这块没有配置，感觉EKS会自己找
```
helm install rancher rancher-latest/rancher  \ 
--namespace cattle-system \ 
--set hostname=rancher.example.com \
--set 'ingress.extraAnnotations.alb\.ingress\.kubernetes\.io/scheme=internet-facing' \
--set 'ingress.extraAnnotations.alb\.ingress\.kubernetes\.io/success-codes=200\,404\,301\,302'  \
--set 'ingress.extraAnnotations.alb\.ingress\.kubernetes\.io/listen-ports=[{\"HTTP\": 80}\, {\"HTTPS\": 443}]' \
--set 'ingress.extraAnnotations.kubernetes\.io/ingress\.class=alb'  \
--set replicas=1 \
--set tls=external \
--create-namespace
```

必须要修改，因为ALB的instance网络传输type依赖NodePort
（只有做了这一步，才能获得ALB的创建和外部地址）

```
kubectl -n cattle-system patch svc rancher -p '{"spec": {"type": "NodePort"}}'

kubetctl get ingress -A
```

备注：
- 修改ingress，把路径改成/* ，要不然首页访问不通。
- 或者说，应该修改set the path as `pathType: Prefix` with "/", it will match all requests, including `/dashboard/`

## 4. 修改DNS的record，使用CNAME

访问上面的域名即可