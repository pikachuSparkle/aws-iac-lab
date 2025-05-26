### Prerequisites
- AWS EC2 2C4G12G
- Ubuntu 22.04


### Server Node Installation

#### 1. Running the installer
```
curl -sfL https://get.rke2.io | sh -
```
This prosure will install the `rke2-server` service and the `rke2` binary onto your machine. 
Due to its nature, It will fail unless it runs as the root user or through `sudo`.

#### 2. Enable the rke2-server service 
```
systemctl enable rke2-server.service
```

#### 3. Start the service
```
systemctl start rke2-server.service
```

#### 4. Following the logs, if you like
```
journalctl -u rke2-server -f
```

After running this installation:
- The `rke2-server` service will be installed. The `rke2-server` service will be configured to automatically restart after node reboots or if the process crashes or is killed.
- Additional utilities will be installed at `/var/lib/rancher/rke2/bin/`. They include: `kubectl`, `crictl`, and `ctr`. Note that these are not on your path by default.
- Two cleanup scripts, `rke2-killall.sh` and `rke2-uninstall.sh`, will be installed to the path at:
    - `/usr/local/bin` for regular file systems
    - `/opt/rke2/bin` for read-only and brtfs file systems
    - `INSTALL_RKE2_TAR_PREFIX/bin` if `INSTALL_RKE2_TAR_PREFIX` is set
- A [kubeconfig](https://kubernetes.io/docs/concepts/configuration/organize-cluster-access-kubeconfig/) file will be written to `/etc/rancher/rke2/rke2.yaml`. `$KUBECONFIG` need to be configured.
- A token that can be used to register other server or agent nodes will be created at `/var/lib/rancher/rke2/server/node-token`
#### 5. Check the RKE2 Cluster
```
export KUBECONFIG=/etc/rancher/rke2/rke2.yaml
echo $KUBECONFIG

/var/lib/rancher/rke2/bin/kubectl get pods -A
/var/lib/rancher/rke2/bin/kubectl get nodes
```
