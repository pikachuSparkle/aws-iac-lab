# Prerequisites:
# ec2-user on Amazon Linux 2003
# 2C8G20G
# Reference:
# https://docs.pingcap.com/tidb-in-kubernetes/stable/get-started?utm_source=github&utm_medium=tidb
# https://github.com/pingcap/tidb-operator/tree/master/examples/basic

# install kind
cd ~/
[ $(uname -m) = x86_64 ] && curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.27.0/kind-linux-amd64
chmod +x ./kind
sudo mv ./kind /usr/local/bin/kind

# install docker
cd ~/
sudo dnf install docker
sudo systemctl start docker.service
sudo systemctl enable docker.service

# install kubectl
cd ~/
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x ./kubectl
sudo mv ./kubectl /usr/local/bin/kubectl

#install helm
cd ~/
curl -Lo helm-v3.17.1-linux-amd64.tar.gz https://get.helm.sh/helm-v3.17.1-linux-amd64.tar.gz
tar -xvzf helm-v3.17.1-linux-amd64.tar.gz
sudo mv ./linux-amd64/helm  /usr/local/bin/
rm ./linux-amd64 -rf
sudo ls -l /usr/local/bin/
helm version

# create kind cluster
cd ~/
sudo kind create cluster # --config kind-config.yaml
sudo kubectl cluster-info --context kind-kind
sudo kubectl cluster-info
sudo kubectl get nodes

# pull images
#sudo docker pull pingcap/pd:v5.3.0
#sudo docker pull pingcap/tikv:v5.3.0
#sudo docker pull pingcap/tidb:v5.3.0

#sudo docker pull prom/prometheus:v2.27.1
#sudo docker pull grafana/grafana:7.5.11
#sudo docker pull pingcap/tidb-monitor-initializer:v5.3.0
#sudo docker pull pingcap/tidb-monitor-reloader:v1.0.1 

#sudo docker pull pingcap/pd:nightly
#sudo docker pull pingcap/tidb:nightly
#sudo docker pull pingcap/tikv:nightly

# load images
#sudo kind load docker-image pingcap/pd:v5.3.0 pingcap/tikv:v5.3.0 pingcap/tidb:v5.3.0  prom/prometheus:v2.27.1  grafana/grafana:7.5.11  pingcap/tidb-monitor-initializer:v5.3.0  pingcap/tidb-monitor-reloader:v1.0.1
#sudo kind load docker-image pingcap/pd:nightly pingcap/tidb:nightly pingcap/tikv:nightly

# install tidb-operator
sudo kubectl create -f https://raw.githubusercontent.com/pingcap/tidb-operator/v1.6.1/manifests/crd.yaml
sudo helm repo add pingcap https://charts.pingcap.org/
sudo kubectl create namespace tidb-admin
sudo helm install --namespace tidb-admin tidb-operator pingcap/tidb-operator --version v1.6.1

while [ $(sudo kubectl get pod -n tidb-admin | grep tidb-controller-manager | grep Running | wc -l) -lt 1 ]; do sleep 1; done
sudo kubectl get pods --namespace tidb-admin -l app.kubernetes.io/instance=tidb-operator

# install tidb-cluster components
sudo kubectl create namespace tidb-cluster
# install tidb-cluster
sudo kubectl -n tidb-cluster apply -f https://raw.githubusercontent.com/pingcap/tidb-operator/v1.6.1/examples/basic/tidb-cluster.yaml
sudo kubectl get po -n tidb-cluster
# install tidb-monitor
sudo kubectl -n tidb-cluster apply -f https://raw.githubusercontent.com/pingcap/tidb-operator/v1.6.1/examples/basic/tidb-monitor.yaml
sudo kubectl get po -n tidb-cluster
# install tidb-dashboard
sudo kubectl -n tidb-cluster apply -f https://raw.githubusercontent.com/pingcap/tidb-operator/v1.6.1/examples/basic/tidb-dashboard.yaml
sudo kubectl get po -n tidb-cluster

# validate tidb-cluster
sudo kubectl get svc -n tidb-cluster

# test tidb-cluster
cd ~/
sudo kubectl port-forward -n tidb-cluster svc/basic-tidb 14000:4000 --address 0.0.0.0 > pf14000.out &
sudo dnf install mariadb105
mysql --comments -h 127.0.0.1 -P 14000 -u root 

# mysql client testing
mysql> use test;
mysql> create table hello_world (id int unsigned not null auto_increment primary key, v varchar(32));

mysql> select tidb_version()\G

mysql> select * from information_schema.tikv_store_status\G

mysql> select * from information_schema.cluster_info\G

mysql> exit


# test tidb-monitor
sudo kubectl port-forward -n tidb-cluster svc/basic-grafana --address 0.0.0.0 3000 > pf3000.out &
# visit http://${remote-server-IP}:3000

# test tidb-dashboard
sudo kubectl port-forward -n tidb-cluster svc/basic-tidb-dashboard-exposed --address 0.0.0.0 12333 > pf12333.out &
# visit http://${remote-server-IP}:12333

# tidb upgrade 
sudo kubectl patch tc basic -n tidb-cluster --type merge -p '{"spec": {"version": "nightly"} }'
mysql --comments -h 127.0.0.1 -P 14000 -u root -e 'select tidb_version()\G'


# clean the resources
# clean port-forward processes
pgrep -lfa kubectl

# clean.sh
cd ~/
vim clean.sh
```
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
chmod +x ./clean.sh
sudo ./clean.sh

# delete tidb-cluster
sudo kubectl delete tc basic -n tidb-cluster
sudo kubectl delete tidbmonitor basic -n tidb-cluster
sudo kubectl delete tidbdashboard basic -n tidb-cluster
# delete tidb-cluster pv pvc
sudo kubectl delete pvc -n tidb-cluster -l app.kubernetes.io/instance=basic,app.kubernetes.io/managed-by=tidb-operator && \
sudo kubectl get pv -l app.kubernetes.io/namespace=tidb-cluster,app.kubernetes.io/managed-by=tidb-operator,app.kubernetes.io/instance=basic -o name | xargs -I {} sudo kubectl patch {} -p '{"spec":{"persistentVolumeReclaimPolicy":"Delete"}}'
# delete tidb-cluster namespace
sudo kubectl delete namespace tidb-cluster

# delete tidb-cluster
sudo kind delete cluster
