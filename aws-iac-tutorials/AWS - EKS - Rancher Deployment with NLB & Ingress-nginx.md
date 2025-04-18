
本案例主要加深对于Ingress-nginx controller的理解，是基于NLB构建的ingress controller，TLS terminate通过ingress来处理。
## DOCS:
https://ranchermanager.docs.rancher.com/getting-started/installation-and-upgrade/install-upgrade-on-a-kubernetes-cluster#install-the-rancher-helm-chart

## 1. Create [EKS Cluster](https://docs.aws.amazon.com/eks/latest/userguide/create-cluster.html)

[[AWS - EKSCTL - EKS Cluster Deployment with EKSCTL]]

## 2. Install Ingress-nginx

[[AWS - EKS - Ingress Controller - NLB & Ingress-nginx]]

## 3. Install Rancher

这里使用了自有的证书，所以不用安装cert-manager

```
helm repo add rancher-latest https://releases.rancher.com/server-charts/latest
#or
helm repo add rancher-stable https://releases.rancher.com/server-charts/stable
```

```
helm install rancher rancher-<CHART_REPO>/rancher \
  --namespace cattle-system \
  --set hostname=rancher.XXXX.com \
  --set bootstrapPassword=admin \
  --set ingress.tls.source=secret  \
  --set ingress.ingressClassName=nginx
```


Output：

>NOTES:
>Rancher Server has been installed.
>
>NOTE: Rancher may take several minutes to fully initialize. Please standby while Certificates are being issued, Containers are started and the Ingress rule comes up.
>
>Check out our docs at https://rancher.com/docs/
>
>If you provided your own bootstrap password during installation, browse to https://rancher.XXXX.com to get started.
>
>If this is the first time you installed Rancher, get started by running this command and clicking the URL it generates:
>
```
echo https://rancher.zambiaelephantbaby.uk/dashboard/?setup=$(kubectl get secret --namespace cattle-system bootstrap-secret -o go-template='{{.data.bootstrapPassword|base64decode}}')
```
>
>To get just the bootstrap password on its own, run:
>
```
kubectl get secret --namespace cattle-system bootstrap-secret -o go-template='{{.data.bootstrapPassword|base64decode}}{{ "\n" }}'
```
>Happy Containering!

## 4. Visit

这时候就可以访问了，配置上DNS，直接访问就可以，不过这时候会给一个连接不安全的报错，但是可以使用。

要修复这个问题，是需要把tls证书添加上。
证书的准备参考
看一下ingress rancher的内容，会发现一个secret的名字是tls-rancher-ingress，这个secret需要创建出来：
```
kubectl create secret tls tls-rancher-ingress --cert=./certificate.pem --key=./private.pem -n cattle-system
```
清理缓存，之后就可以正常的访问了。



