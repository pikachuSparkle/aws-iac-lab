Like `kind`, [`minikube`](https://minikube.sigs.k8s.io/) is a tool that lets you run Kubernetes locally. `minikube` runs an all-in-one or a multi-node local Kubernetes cluster on your personal computer (including Windows, macOS and Linux PCs) so that you can try out Kubernetes, or for daily development work.

Minikube deploys a cluster on a single machine, using a single container as a node. This is particularly suitable for testing on a PC and serves as the official demo platform for Kubernetes. However, there can be some strange phenomena, such as discovering that the IP address of the NodePort is that of a Docker container.

## References：
https://minikube.sigs.k8s.io/docs/start/
https://kubernetes.io/docs/tutorials/hello-minikube/

## 0. Prerequisites

- 2 CPUs or more
- 2GB of free memory
- 20GB of free disk space
- Internet connection
- Container or virtual machine manager, such as: [Docker](https://minikube.sigs.k8s.io/docs/drivers/docker/), [QEMU](https://minikube.sigs.k8s.io/docs/drivers/qemu/), [Hyperkit](https://minikube.sigs.k8s.io/docs/drivers/hyperkit/), [Hyper-V](https://minikube.sigs.k8s.io/docs/drivers/hyperv/), [KVM](https://minikube.sigs.k8s.io/docs/drivers/kvm2/), [Parallels](https://minikube.sigs.k8s.io/docs/drivers/parallels/), [Podman](https://minikube.sigs.k8s.io/docs/drivers/podman/), [VirtualBox](https://minikube.sigs.k8s.io/docs/drivers/virtualbox/), or [VMware Fusion/Workstation](https://minikube.sigs.k8s.io/docs/drivers/vmware/)

## 1. Installation

Linux->x86-64->Stable->Binary download
To install the latest minikube **stable** release on **x86-64** **Linux** using **binary download**:
```shell
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube && rm minikube-linux-amd64
```
## 2. Start your cluster

From a terminal with administrator access (but not logged in as root), run:
```
minikube start --driver=docker
```
If minikube fails to start, see the [drivers page](https://minikube.sigs.k8s.io/docs/drivers/) for help setting up a compatible container or virtual-machine manager.
## 3. Interact with your cluster

If you already have kubectl installed (see [documentation](https://kubernetes.io/docs/tasks/tools/install-kubectl/)), you can now use it to access your shiny new cluster:
```
#install kubectl, then
kubectl get po -A
```

Alternatively, minikube can download the appropriate version of kubectl and you should be able to use it like this:
```
minikube kubectl -- get po -A
```

You can also make your life easier by adding the following to your shell config: (for more details see: [kubectl](https://minikube.sigs.k8s.io/docs/handbook/kubectl/))
```shell
alias kubectl="minikube kubectl --"
```

Initially, some services such as the storage-provisioner, may not yet be in a Running state. This is a normal condition during cluster bring-up, and will resolve itself momentarily. For additional insight into your cluster state, minikube bundles the Kubernetes Dashboard, allowing you to get easily acclimated to your new environment:
```shell
minikube dashboard
```



## 4. Deploy applications

#### 4.1 Service

https://kubernetes.io/docs/tutorials/kubernetes-basics/expose/expose-intro/
Create a sample deployment and expose it on port 8080:
```shell
kubectl create deployment hello-minikube --image=kicbase/echo-server:1.0
kubectl expose deployment hello-minikube --type=NodePort --port=8080
```

It may take a moment, but your deployment will soon show up when you run:
```shell
kubectl get services hello-minikube
```

The easiest way to access this service is to let minikube launch a web browser for you:
```shell
minikube service hello-minikube
```

Alternatively, use kubectl to forward the port:
```shell
kubectl port-forward service/hello-minikube 7080:8080
```

Your application is now available at [http://localhost:7080/](http://localhost:7080/).

You should be able to see the request metadata in the application output. Try changing the path of the request and observe the changes. Similarly, you can do a POST request and observe the body show up in the output.

#### 4.2 LoadBalancer

https://minikube.sigs.k8s.io/docs/handbook/accessing/#loadbalancer-access
To access a LoadBalancer deployment, use the “minikube tunnel” command. Here is an example deployment:

```shell
kubectl create deployment balanced --image=kicbase/echo-server:1.0
kubectl expose deployment balanced --type=LoadBalancer --port=8080
```

In another window, start the tunnel to create a routable IP for the ‘balanced’ deployment:
```shell
minikube tunnel
```

To find the routable IP, run this command and examine the `EXTERNAL-IP` column:
```shell
kubectl get services balanced
```

Your deployment is now available at `<EXTERNAL-IP>:8080`

#### 4.3 Ingress
https://kubernetes.io/docs/tasks/access-application-cluster/ingress-minikube/
Enable ingress addon:
```shell
minikube addons enable ingress
```

he following example creates simple echo-server services and an Ingress object to route to these services.
```yaml
kind: Pod
apiVersion: v1
metadata:
  name: foo-app
  labels:
    app: foo
spec:
  containers:
    - name: foo-app
      image: 'kicbase/echo-server:1.0'
---
kind: Service
apiVersion: v1
metadata:
  name: foo-service
spec:
  selector:
    app: foo
  ports:
    - port: 8080
---
kind: Pod
apiVersion: v1
metadata:
  name: bar-app
  labels:
    app: bar
spec:
  containers:
    - name: bar-app
      image: 'kicbase/echo-server:1.0'
---
kind: Service
apiVersion: v1
metadata:
  name: bar-service
spec:
  selector:
    app: bar
  ports:
    - port: 8080
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: example-ingress
spec:
  rules:
    - http:
        paths:
          - pathType: Prefix
            path: /foo
            backend:
              service:
                name: foo-service
                port:
                  number: 8080
          - pathType: Prefix
            path: /bar
            backend:
              service:
                name: bar-service
                port:
                  number: 8080
---
```

Apply the contents
```shell
kubectl apply -f https://storage.googleapis.com/minikube-site-examples/ingress-example.yaml
```

Wait for ingress address

```shell
kubectl get ingress
NAME              CLASS   HOSTS   ADDRESS          PORTS   AGE
example-ingress   nginx   *       <your_ip_here>   80      5m45s
```

**Note for Docker Desktop Users:**
To get ingress to work you’ll need to open a new terminal window and run `minikube tunnel` and in the following step use `127.0.0.1` in place of `<ip_from_above>`.

Now verify that the ingress works
```shell
$ curl <ip_from_above>/foo
Request served by foo-app
...

$ curl <ip_from_above>/bar
Request served by bar-app
...
```


## 5. Manage your cluster

Pause Kubernetes without impacting deployed applications:
```shell
minikube pause
```

Unpause a paused instance:
```shell
minikube unpause
```

Halt the cluster:
```shell
minikube stop
```

Change the default memory limit (requires a restart):
```shell
minikube config set memory 9001
```

Browse the catalog of easily installed Kubernetes services:
```shell
minikube addons list
```

Create a second cluster running an older Kubernetes release:
```shell
minikube start -p aged --kubernetes-version=v1.16.1
```

Delete all of the minikube clusters:
```shell
minikube delete --all
```









