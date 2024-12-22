## 1. Prerequisites:

1. Launch 2 EC2 instances running Ubuntu 22.04 with the following configuration: 
```
Instance Type: t3a.medium 
Configuration: 2 vCPUs, 4 GiB of memory
```
2. Install Docker on both instances
3. Install kubeadm, kubelet, and kubectl on both instances
4. Disable swap on both instances
```
# disable swap
sudo swapoff -a
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
```

The overall instruction is base on official reference.[^5]
## 2. Install Containerd on Ubuntu

#### 2.1 DOCS:

The following step is based on official method [Install using the `apt` repository](https://docs.docker.com/engine/install/ubuntu/#install-using-the-repository)

Also you can find other methods from the references.[^1][^2][^3][^4]

#### 2.2 Install Docker Engine on Ubuntu

Run the following command to uninstall all conflicting packages:
```
for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do sudo apt-get remove $pkg; done
```

Set up Docker's `apt` repository
```
# Add Docker's official GPG key:
sudo apt-get update
sudo apt-get install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
```

Install the Docker packages
```
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

Verify that the Docker Engine installation is successful by running the `hello-world` image
```
sudo docker run hello-world
```

## 3. Install Kubernetes Components

#### 3.1 DOCS:

This part is following the instructions step by step. 
[Installing kubeadm, kubelet and kubectl](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/#installing-kubeadm-kubelet-and-kubectl)

#### 3.2 Installing kubeadm, kubelet and kubectl

>You will install these packages on all of your machines:
>- `kubeadm`: the command to bootstrap the cluster.
>- `kubelet`: the component that runs on all of the machines in your cluster and does things like starting pods and containers.
>- `kubectl`: the command line util to talk to your cluster.

These instructions are for Kubernetes v1.31.

1. Update the `apt` package index and install packages needed to use the Kubernetes `apt` repository:
    ```shell
    sudo apt-get update
    # apt-transport-https may be a dummy package; if so, you can skip that package
    sudo apt-get install -y apt-transport-https ca-certificates curl gpg
    ```
2. Download the public signing key for the Kubernetes package repositories. The same signing key is used for all repositories so you can disregard the version in the URL:
    ```shell
    # If the directory `/etc/apt/keyrings` does not exist, it should be created before the curl command, read the note below.
    # sudo mkdir -p -m 755 /etc/apt/keyrings
    curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.31/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
    ```
3. Add the appropriate Kubernetes `apt` repository. Please note that this repository have packages only for Kubernetes 1.31; for other Kubernetes minor versions, you need to change the Kubernetes minor version in the URL to match your desired minor version (you should also check that you are reading the documentation for the version of Kubernetes that you plan to install).
    ```shell
    # This overwrites any existing configuration in /etc/apt/sources.list.d/kubernetes.list
    echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.31/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
    ```
4. Update the `apt` package index, install kubelet, kubeadm and kubectl, and pin their version:
    ```shell
    sudo apt-get update
    sudo apt-get install -y kubelet kubeadm kubectl
    sudo apt-mark hold kubelet kubeadm kubectl
    ```
5. (Optional) Enable the kubelet service before running kubeadm:
    ```shell
    sudo systemctl enable --now kubelet
    ```

The kubelet is now restarting every few seconds, as it waits in a crashloop for kubeadm to tell it what to do.

## 4. Troubleshooting

#### 4.1 Configuring the `systemd` cgroup driver [](https://kubernetes.io/docs/setup/production-environment/container-runtimes/#containerd-systemd)

```
# Check your /etc/containerd/config.toml, it should be hundreds of configuration.
# if not, exec the following
containerd config default > /etc/containerd/config.toml
```

```
[plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc]
  ...
  [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc.options]
    SystemdCgroup = true
```

>Note:
>
>If you installed containerd from a package (for example, RPM or `.deb`), you may find that the CRI integration plugin is disabled by default.
>
>You need CRI support enabled to use containerd with Kubernetes. Make sure that `cri` is not included in the`disabled_plugins` list within `/etc/containerd/config.toml`; if you made changes to that file, also restart `containerd`.
>
>If you experience container crash loops after the initial cluster installation or after installing a CNI, the containerd configuration provided with the package might contain incompatible configuration parameters. Consider resetting the containerd configuration with `containerd config default > /etc/containerd/config.toml` as specified in [getting-started.md](https://github.com/containerd/containerd/blob/main/docs/getting-started.md#advanced-topics) and then set the configuration parameters specified above accordingly.

```
sudo systemctl restart containerd
```

## 5. Creating a cluster with kubeadm (master)

```
# initialize control plain 
kubeadm init --pod-network-cidr=10.244.0.0/16
# example
# kubeadm init --pod-network-cidr=10.244.0.0/16 --service-cidr=10.96.0.0/12 --apiserver-advertise-address=<YOUR_API_SERVER_IP>
```

output:
```
[kubelet-finalize] Updating "/etc/kubernetes/kubelet.conf" to point to a rotatable kubelet client certificate and key
[addons] Applied essential addon: CoreDNS
[addons] Applied essential addon: kube-proxy

Your Kubernetes control-plane has initialized successfully!

To start using your cluster, you need to run the following as a regular user:

  mkdir -p $HOME/.kube
  sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  sudo chown $(id -u):$(id -g) $HOME/.kube/config

Alternatively, if you are the root user, you can run:

  export KUBECONFIG=/etc/kubernetes/admin.conf

You should now deploy a pod network to the cluster.
Run "kubectl apply -f [podnetwork].yaml" with one of the options listed at:
  https://kubernetes.io/docs/concepts/cluster-administration/addons/

Then you can join any number of worker nodes by running the following on each as root:

kubeadm join 10.20.64.12:6443 --token xknwjw.ihv8d7srfk80ms3p \
        --discovery-token-ca-cert-hash sha256:5901c509eaaefd7853951913e99f8e42ece0b98f1eb2a4a30032b7d843af0fb2 
```


```
# Install the Flannel pod network add-on:
kubectl apply -f https://raw.githubusercontent.com/flannel-io/flannel/master/Documentation/kube-flannel.yml
```
or
```
# Install Calico CNI plugin 
kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml
```

## 6. Join the Kubernetes nodes to Cluster

Following the output instruction.
```
kubeadm join 10.20.64.12:6443 --token xknwjw.ihv8d7srfk80ms3p \
        --discovery-token-ca-cert-hash sha256:5901c509eaaefd7853951913e99f8e42ece0b98f1eb2a4a30032b7d843af0fb2
```

## 7. Deploying ArgoCD as Demo

Install ArgoCD in the default namespace:
```shell
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

Expose the ArgoCD server using a NodePort service:

```shell
kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "NodePort"}}'
```

Get the ArgoCD server URL and initial admin password:
```shell
export ARGOCD_SERVER=$(kubectl get service argocd-server -n argocd -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
export ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
```

Log in ArgoCD dashboard with the admin username and the password obtained in previous steps.

## References:
[^5]: https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/
[^1]: https://docs.docker.com/engine/install/ubuntu/
[^2]: https://github.com/containerd/containerd/blob/main/docs/getting-started.md
[^3]: https://kubernetes.io/docs/setup/production-environment/container-runtimes/#containerd
[^4]: https://kubernetes.io/docs/setup/production-environment/container-runtimes/