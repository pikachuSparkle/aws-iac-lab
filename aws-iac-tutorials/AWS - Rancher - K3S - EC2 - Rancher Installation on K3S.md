## Introduction
K3S是一个可以使用于生产环境的K8S发行版本，本文通过单点K3S（只有master）部署Rancher使用，当然使用多节点集群也是一样的。202407
## Prerequisites
使用网络比较好的公有云
至少要2C4G10G
ubuntu22.04
K3S版本1.28.6
## Deployment

#### 1. Folder Preparation
```
mkdir -p /data
chown ubuntu:ubuntu /dara -R
cd /data
```

#### 2. Install K3S
选择版本1.28.6，为了与cert-manager兼容
https://docs.k3s.io/quick-start
```
curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION=v1.28.6+k3s1 sh -
kubectl get nodes #发现不能显示，需要配置
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml #可以配置/etc/rancher/k3s/k3s.yaml，也可以配置~/.kube/config/k3s.yaml
echo $KUBECONFIG
chown ubuntu:ubuntu /etc/rancher/k3s/k3s.yaml #可以读写
kubectl get nodes
```

#### 3. Install helm binaries
```
cd /data
wget https://get.helm.sh/helm-v3.12.0-linux-amd64.tar.gz
tar -zxvf helm-v3.12.0-linux-amd64.tar.gz
sudo mv linux-amd64/helm /usr/local/bin/
rm 残留的文件
```

#### 4. Install cert-manager && rancher
Install Rancher with Helm
https://ranchermanager.docs.rancher.com/getting-started/quick-start-guides/deploy-rancher-manager/helm-cli

```
helm repo add rancher-latest https://releases.rancher.com/server-charts/latest
kubectl create namespace cattle-system
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.15.1/cert-manager.crds.yaml
helm repo add jetstack https://charts.jetstack.io
helm repo update
helm install cert-manager jetstack/cert-manager   --namespace cert-manager   --create-namespace

#安装Rancher需要和K3S的版本匹配，需要cert-manager版本匹配
helm install rancher rancher-latest/rancher \
  --namespace cattle-system \
  --set hostname=184.72.120.207.sslip.io \
  --set replicas=1 \
  --set bootstrapPassword=bootstrap@Password
```

#### 5. Validate
根据提示访问Rancher就可以了，首次登录的密码会有提示
https://PublicIp.sslip.io/dashboard
