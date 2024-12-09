
## 0. References
https://docs.rke2.io/install/quickstart

## 1. Server Node Installation

[[AWS - EC2 - RKE2 - 1 - Server Node Installation]]

---
NOTES-1：
kubectl 默认$HOME/.kube/config，建议软连接
- 可以直接创建软连接`ln -s /etc/rancher/rke2/rke2.yaml $HOME/.kube/config`
- 也可以创建环境变量`export KUBECONFIG=/etc/rancher/rke2/rke2.yaml` 

---
NPTES-2：
在~/.profile里面增加
```
PATH=/var/lib/rancher/rke2/bin:$PATH
source .profile
```
也可以在~/.bashrc里面
```
PATH=/var/lib/rancher/rke2/bin:$PATH
source .profile
```
建议前者，vim一下文件就知道了 .profile调用了.bashrc，并且文件内容简单

---

## 2. Linux Agent Node Installation

[[AWS - EC2 - RKE2 - 2 - Agent (Worker) Node Installation]]

## 3. Tunning the RKE Cluster

#### Helm
- RKE2天生兼容helm（https://docs.rke2.io/helm），二进制装helm就好
- RKE2 is inherently compatible with Helm; you just need to install the Helm binary.
```
wget https://get.helm.sh/helm-v3.13.2-linux-amd64.tar.gz
tar -zxvf helm-v3.13.2-linux-amd64.tar.gz
mv linux-amd64/helm /usr/local/bin/helm
```
- `/var/lib/rancher/rke2/server/manifests` 是自动启动项，查看`kubectl get addon -A`

#### StorageClass
- 没有安装StorageClass，应用创建PVC时候报错，需要安装local-path-provision
- 官方参考资料：https://github.com/rancher/local-path-provisioner
```shell
kubectl create namespace local-path-storage
wget https://raw.githubusercontent.com/rancher/local-path-provisioner/v0.0.26/deploy/local-path-storage.yaml
kubectl apply -f local-path-storage.yaml
kubectl get pods -n local-path-storage
kubectl get storageclass
```

## 4. Prometheus deployment for testing

#### Prometheus
```
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm install my-prometheus prometheus-community/prometheus
```

#### Grafana
```
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update
helm install my-grafana grafana/grafana
#ingress还需要研究
```

## 5. Middleware deployment

#### bitnami（redis, postgresql）
```
helm repo add bitnami https://charts.bitnami.com/bitnami
helm list
helm repo list

helm install my-redis bitnami/redis 
# configure pvc yaml "storageClassName: local-path"
# kubectl delete pod redis-**

helm install my-postgresql bitnami/postgresql --set postgresqlPassword=my-passwd
# configure pvc yaml "storageClassName: local-path"
# kubectl delete pod my-postgresql-**
