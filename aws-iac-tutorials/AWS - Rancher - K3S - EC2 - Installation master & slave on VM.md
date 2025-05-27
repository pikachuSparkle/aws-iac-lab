
## 参考
https://docs.k3s.io/zh/quick-start

## 安装server

```shell
k3s-uninstall.sh

curl -sfL https://rancher-mirror.rancher.cn/k3s/k3s-install.sh | INSTALL_K3S_MIRROR=cn INSTALL_K3S_VERSION=v1.28.6+k3s1 sh -

export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
sudo chown ubuntu:ubuntu /etc/rancher/k3s/k3s.yaml
```

## 安装agent 

```
`K3S_URL` 参数会导致安装程序将 K3s 配置为 Agent 而不是 Server。K3s Agent 将注册到在 URL 上监听的 K3s Server。`K3S_TOKEN` 使用的值存储在 Server 节点上的 `/var/lib/rancher/k3s/server/node-token` 中
```

```shell
curl -sfL https://rancher-mirror.rancher.cn/k3s/k3s-install.sh | INSTALL_K3S_MIRROR=cn K3S_URL=https://192.168.126.31:6443 K3S_TOKEN=mynodetoken INSTALL_K3S_VERSION=v1.28.6+k3s1 sh -
```

## 卸载
```
https://docs.k3s.io/zh/installation/uninstall
```
