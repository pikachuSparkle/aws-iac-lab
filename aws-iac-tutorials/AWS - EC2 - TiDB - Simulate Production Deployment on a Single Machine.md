
This article describes how to set up the smallest TiDB cluster with a full topology, and simulate production deployment steps on a single Linux server.
The following describes how to deploy a TiDB cluster using a YAML file of the smallest topology in TiUP.

the reference shell commands are as follows: 
```shell
./Shell_Scripts/tidb-simulate-production-deployment-on-a-single-machine
```
# Prerequisites:
- Amazon Linux 2023
- t3a.xlarge, 4 vCPU, 16 GB RAM, 40 GB SSD
- Linux account root
- The smallest TiDB cluster topology consists of the following instances:

| Instance | Count | IP       | Configuration                                   |
| :------- | :---- | :------- | :---------------------------------------------- |
| TiKV     | 3     | 10.0.1.1 | Use incremental port numbers to avoid conflicts |
| TiDB     | 1     | 10.0.1.1 | Use default port and other configurations       |
| PD       | 1     | 10.0.1.1 | Use default port and other configurations       |
| TiFlash  | 1     | 10.0.1.1 | Use default port and other configurations       |
| Monitor  | 1     | 10.0.1.1 | Use default port and other configurations       |
# References:
https://docs.pingcap.com/tidb/dev/quick-start-with-tidb#simulate-production-deployment-on-a-single-machine


The following steps use the `root` user as an example.
```shell
sudo -i
```
## 1 Download and install TiUP:

```shell
cd ~/
curl --proto '=https' --tlsv1.2 -sSf https://tiup-mirrors.pingcap.com/install.sh | sh
```

```shell
#Output:
#===============================================
#Successfully set mirror to https://tiup-mirrors.pingcap.com
#Detected shell: bash
#Shell profile:  /root/.bash_profile
#/root/.bash_profile has been modified to add tiup to PATH
#open a new terminal or source /root/.bash_profile to use it
#Installed path: /root/.tiup/bin/tiup
#===============================================
#Have a try:     tiup playground
#=============================================== 
```

## 2 Declare the global environment variable.

After the above command, `tiup` is installed into `/root/.tiup/bin/tiup`
```shell
source /root/.bash_profile
```

## 3 Install the cluster component of TiUP:
```shell
tiup cluster
```

## 4 If the TiUP cluster is already installed on the machine, update the software version:
```shell
tiup update --self && tiup update cluster
```

## 5 Increase the connection limit of the sshd service using the root user privilege. This is because TiUP needs to simulate deployment on multiple machines.
```
# Modify /etc/ssh/sshd_config, and set MaxSessions to 20.
vim /etc/ssh/sshd_config
# Restart the sshd service:
systemctl restart sshd
```

## 6 Create and start the cluster:
Create and edit the [topology configuration file](https://docs.pingcap.com/tidb/dev/tiup-cluster-topology-reference) according to the following template, and name it as `topo.yaml`:
```shell
cat > topo.yaml << EOF
# # Global variables are applied to all deployments and used as the default value of
# # the deployments if a specific deployment value is missing.
global:
 user: "tidb"
 ssh_port: 22
 deploy_dir: "/tidb-deploy"
 data_dir: "/tidb-data"
# # Monitored variables are applied to all the machines.
monitored:
 node_exporter_port: 9100
 blackbox_exporter_port: 9115
server_configs:
 tidb:
   instance.tidb_slow_log_threshold: 300
 tikv:
   readpool.storage.use-unified-pool: false
   readpool.coprocessor.use-unified-pool: true
 pd:
   replication.enable-placement-rules: true
   replication.location-labels: ["host"]
 tiflash:
   logger.level: "info"
pd_servers:
 - host: 10.0.1.1
tidb_servers:
 - host: 10.0.1.1
tikv_servers:
 - host: 10.0.1.1
   port: 20160
   status_port: 20180
   config:
     server.labels: { host: "logic-host-1" }
 - host: 10.0.1.1
   port: 20161
   status_port: 20181
   config:
     server.labels: { host: "logic-host-2" }
 - host: 10.0.1.1
   port: 20162
   status_port: 20182
   config:
     server.labels: { host: "logic-host-3" }
tiflash_servers:
 - host: 10.0.1.1
monitoring_servers:
 - host: 10.0.1.1
grafana_servers:
 - host: 10.0.1.1
EOF
```
- `user: "tidb"`: Use the `tidb` system user (automatically created during deployment) to perform the internal management of the cluster. By default, use port 22 to log in to the target machine via SSH.
- `replication.enable-placement-rules`: This PD parameter is set to ensure that TiFlash runs normally.
- `host`: The IP of the target machine.

Modify the IP address of the machine in the topology file:
```shell
sed 's/10.0.1.1/172.31.82.56/g' -i topo.yaml
```

## 7 Execute the cluster deployment command:

```
#Deploy the cluster:
#tiup cluster deploy <cluster-name> <version> ./topo.yaml --user root -p
#tiup cluster deploy <cluster-name> <version> ./topo.yaml --user root -i key.pem
```
- `<cluster-name>`: sets the cluster name.
- `<version>`: sets the TiDB cluster version, such as `v8.5.0`. You can see all the supported TiDB versions by running the `tiup list tidb` command.
- `--user`: specifies the user to initialize the environment.
- `-p`: specifies the password used to connect to the target machine.
- `-i`: specifies the key file used to connect to the target machine.

Here，we use the key file as authentication  method
Copy the public key to the root home path:
```
cp /home/ec2-user/.ssh/authorized_keys ./.ssh/
```

Prepare the private key for your machine: `key.pem`

```
tiup cluster deploy tidb-demo v8.5.0  ./topo.yaml --user root -i key.pem
```
## 8 Start the cluster:
```
tiup cluster start tidb-demo
tiup cluster list
tiup cluster display tidb-demo
```

## 9 Access the cluster endpoints:
```shell
# Install the MySQL. If it is already installed, skip this step.
yum -y install mariadb105

# Connect to the TiDB database using the MySQL client. The password is empty:
mysql -h 10.0.1.1 -P 4000 -u root

# Grafana: http://{grafana-ip}:3000
# The default username and password are both admin.
# TiDB Dashboard: http://{pd-ip}:2379/dashboard
# The default username is root, and the password is empty.
```

## 10 View the cluster list and topology.
- To view the cluster list:
```shell
tiup cluster list
```    
- To view the cluster topology and status:
```shll
tiup cluster display <cluster-name>
```

## 11 Clean up the cluster:

```shell
tiup clean --all
```
