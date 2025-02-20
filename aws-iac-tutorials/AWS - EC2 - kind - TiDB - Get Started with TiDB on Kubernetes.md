# Prerequisites:
- Amazon Linux 2023
- Linux account ec2-user
- t3a - 2C8G20G

# Reference:
https://docs.pingcap.com/tidb-in-kubernetes/stable/get-started?utm_source=github&utm_medium=tidb
https://github.com/pingcap/tidb-operator/tree/master/examples/basic

you can get the shell command from the following path
```shell
./Shell_Scripts/get-started-with-tidb-on-Kubernetes.sh
```

# 1. Prevision tools
## Install Kind
```
[ $(uname -m) = x86_64 ] && curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.27.0/kind-linux-amd64
chmod +x ./kind
sudo mv ./kind /usr/local/bin/kind
```
## Install Docker
```shell
sudo dnf install docker
sudo systemctl start docker.service
sudo systemctl enable docker.service
```
## Install kubectl
```shell
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x ./kubectl
sudo mv ./kubectl /usr/local/bin/kubectl
```
## Install helm
```shell
cd ~/
curl -Lo helm-v3.17.1-linux-amd64.tar.gz https://get.helm.sh/helm-v3.17.1-linux-amd64.tar.gz
tar -xvzf helm-v3.17.1-linux-amd64.tar.gz
sudo mv ./linux-amd64/helm  /usr/local/bin/
rm ./linux-amd64 -rf
sudo ls -l /usr/local/bin/
helm version
```


# 2. Create TiDB Cluster

## Create kind cluster
```shell
sudo kind create cluster # --config kind-config.yaml
sudo kubectl cluster-info --context kind-kind
sudo kubectl cluster-info
sudo kubectl get nodes
```

## Install TiDB-operator
```
sudo kubectl create -f https://raw.githubusercontent.com/pingcap/tidb-operator/v1.6.1/manifests/crd.yaml

sudo helm repo add pingcap https://charts.pingcap.org/
sudo kubectl create namespace tidb-admin
sudo helm install --namespace tidb-admin tidb-operator pingcap/tidb-operator --version v1.6.1

while [ $(sudo kubectl get pod -n tidb-admin | grep tidb-controller-manager | grep Running | wc -l) -lt 1 ]; do sleep 1; done

sudo kubectl get pods --namespace tidb-admin -l app.kubernetes.io/instance=tidb-operator
```

## Install TiDB cluster components

```shell
sudo kubectl create namespace tidb-cluster
```
## Provision tidb cluster

```shell
sudo kubectl -n tidb-cluster apply -f https://raw.githubusercontent.com/pingcap/tidb-operator/v1.6.1/examples/basic/tidb-cluster.yaml

sudo kubectl get po -n tidb-cluster
```
## Install tidb-monitor

```
sudo kubectl -n tidb-cluster apply -f https://raw.githubusercontent.com/pingcap/tidb-operator/v1.6.1/examples/basic/tidb-monitor.yaml

sudo kubectl get po -n tidb-cluster
```
## Install tidb-dashboard

```
sudo kubectl -n tidb-cluster apply -f https://raw.githubusercontent.com/pingcap/tidb-operator/v1.6.1/examples/basic/tidb-dashboard.yaml

sudo kubectl get po -n tidb-cluster
```

# 3. Validate the TiDB Cluster

```shell
sudo kubectl get svc -n tidb-cluster
```

## Test tidb-cluster

```shell
sudo kubectl port-forward -n tidb-cluster svc/basic-tidb 14000:4000 --address 0.0.0.0 > pf14000.out &

sudo dnf install meriadb105
mysql --comments -h 127.0.0.1 -P 14000 -u root
```

```sql
mysql> use test;

mysql> create table hello_world (id int unsigned not null auto_increment primary key, v varchar(32));

mysql> select tidb_version()\G

mysql> select * from information_schema.tikv_store_status\G

mysql> select * from information_schema.cluster_info\G
```

## Test tidb-monitor

```
sudo kubectl port-forward -n tidb-cluster svc/basic-grafana --address 0.0.0.0 3000 > pf3000.out &
```
> visit http://${remote-server-IP}:3000

## Test tidb-dashboard

```
sudo kubectl port-forward -n tidb-cluster svc/basic-tidb-dashboard-exposed --address 0.0.0.0 12333 > pf12333.out &
```
> visit http://${remote-server-IP}:12333

# 4. TiDB Upgrade

```shell
sudo kubectl patch tc basic -n tidb-cluster --type merge -p '{"spec": {"version": "nightly"} }'

mysql --comments -h 127.0.0.1 -P 14000 -u root -e 'select tidb_version()\G'
```

# 5. Clean the Resources

## Clean the port-forward processes
```shell
pgrep -lfa kubectl
```

```shell
vim ./clean.sh
```

```shell
#!/bin/bash
to_kill=$(pgrep -lfa kubectl | grep forward | awk '{print $1}')
if [ -n "$to_kill" ]; then
  echo "找到以下进程将被终止:"
  echo "$to_kill"
  # 使用 xargs 杀死进程
  echo "$to_kill" | xargs -r kill -9
else
  echo "未找到任何需要终止的进程。"
fi
```

```shell
chmod +x ./clean.sh
sudo ./clean.sh
```

```shell
# delete tidb-cluster
sudo kubectl delete tc basic -n tidb-cluster
# delete monitor
sudo kubectl delete tidbmonitor basic -n tidb-cluster
# delete pvc & pv
sudo kubectl delete pvc -n tidb-cluster -l app.kubernetes.io/instance=basic,app.kubernetes.io/managed-by=tidb-operator && \
sudo kubectl get pv -l app.kubernetes.io/namespace=tidb-cluster,app.kubernetes.io/managed-by=tidb-operator,app.kubernetes.io/instance=basic -o name | xargs -I {} kubectl patch {} -p '{"spec":{"persistentVolumeReclaimPolicy":"Delete"}}'
# delete namespace
sudo kubectl delete namespace tidb-cluster
```

```shell
# delete k8s cluster
sudo kind delete cluster
```

