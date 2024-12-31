## 0. DOCS：
GitHub
https://github.com/kubernetes-sigs/aws-ebs-csi-driver/blob/master/docs/install.md
AWS Official Workshop 
https://www.eksworkshop.com/docs/fundamentals/storage/ebs/ebs-csi-driver
## 1. Set up driver permissions & Create an IAM role

```
export AWS_REGION=us-east-1 
eksctl utils associate-iam-oidc-provider --cluster=cluster-demo-1 --approve
```

>The Amazon EBS CSI plugin requires IAM permissions to make calls to AWS APIs on your behalf. If you don't do these steps, attempting to install the add-on and running `kubectl describe pvc` will show `failed to provision volume with StorageClass` along with a `could not create volume in EC2: UnauthorizedOperation` error.

https://docs.aws.amazon.com/eks/latest/userguide/ebs-csi.html#csi-iam-role

Create an IAM role and attach a policy. AWS maintains an AWS managed policy or you can create your own custom policy. You can create an IAM role and attach the AWS managed policy with the following command.
```
eksctl create iamserviceaccount \
        --name ebs-csi-controller-sa \
        --namespace kube-system \
        --cluster cluster-demo-1 \
        --role-name AmazonEKS_EBS_CSI_DriverRole \
        --role-only \
        --attach-policy-arn arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy \
        --approve
```

## 2. Deploy driver

You may deploy the EBS CSI driver via Kustomize, Helm, or as an [Amazon EKS managed add-on](https://docs.aws.amazon.com/eks/latest/userguide/managing-ebs-csi.html).

#### 2.1 使用add-on的方式
参考DOCS
https://navyadevops.hashnode.dev/setting-up-prometheus-and-grafana-on-amazon-eks-for-kubernetes-monitoring


To improve security and reduce the amount of work, you can manage the Amazon EBS CSI driver as an Amazon EKS add-on.

To see the required platform version, run the following command. 
```
aws eks describe-addon-versions --addon-name aws-ebs-csi-driver
```

To add the Amazon EBS CSI add-on using eksctl. Replace your cluster name and AWS account number.
```
eksctl create addon --name aws-ebs-csi-driver --cluster my-cluster --service-account-role-arn arn:aws:iam::111122223333:role/AmazonEKS_EBS_CSI_DriverRole --force
```

Check the current version of your Amazon EBS CSI add-on.
```
eksctl get addon --name aws-ebs-csi-driver --cluster my-cluster
```

Update the add-on to the version returned under UPDATE AVAILABLE in the output of the previous step. (no testing)
```
eksctl update addon --name aws-ebs-csi-driver --version v1.11.4-eksbuild.1 --cluster my-cluster \

  --service-account-role-arn arn:aws:iam::444444444444:role/AmazonEKS_EBS_CSI_DriverRole --force
```

#### 2.2 使用helm的方式
```
helm repo add aws-ebs-csi-driver https://kubernetes-sigs.github.io/aws-ebs-csi-driver
helm repo update
```

```
#其他都是default；注意Role那个参数的配置，这个可是血泪，否则没有权限
helm upgrade --install aws-ebs-csi-driver   aws-ebs-csi-driver/aws-ebs-csi-driver \
    --namespace kube-system \
    --set controller.serviceAccount.annotations."eks\.amazonaws\.com/role-arn"="arn:aws:iam::444444444444:role/AmazonEKS_EBS_CSI_DriverRole"
```

```
Configure value, 见下面的文件。重要，可以根据这个调整helm install的配置
https://github.com/kubernetes-sigs/aws-ebs-csi-driver/blob/master/charts/aws-ebs-csi-driver/values.yaml
```

## 3. Check

```
kubectl get pods -n kube-system -l app.kubernetes.io/name=aws-ebs-csi-driver
```

```
kubectl get storageclass -A
```

```
NAME PROVISIONER RECLAIMPOLICY VOLUMEBINDINGMODE ALLOWVOLUMEEXPANSION   AGE
gp2 kubernetes.io/aws-ebs Delete  WaitForFirstConsumer false            20m
```

## 4. Demo

>The Kubernetes project suggests that you use the [AWS EBS](https://github.com/kubernetes-sigs/aws-ebs-csi-driver) out-of-tree storage driver instead.

>This example shows you how to write to a dynamically provisioned EBS volume with a specified configuration in the `StorageClass` resource. https://github.com/kubernetes-sigs/aws-ebs-csi-driver/tree/master/examples/kubernetes/storageclass

#### 4.1 gp2 StorageClass Provisioner & demo StorageClass provisioner

```
kubectl edit storageclass gp2 -n kube-system
```
会发现provisioner是`kubernetes.io/****'
而Demo中的provisioner和官方案例(https://kubernetes.io/docs/concepts/storage/storage-classes/#aws-ebs)是相同的`provisioner: ebs.csi.aws.com`

Demo StorageClass yaml:
```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: ebs-sc
provisioner: ebs.csi.aws.com
volumeBindingMode: WaitForFirstConsumer
parameters:
  csi.storage.k8s.io/fstype: xfs
  type: io1
  iopsPerGB: "50"
  encrypted: "true"
allowedTopologies:
- matchLabelExpressions:
  - key: topology.kubernetes.io/zone
    values:
    - us-east-2c
```

`provisioner: ebs.csi.aws.com` is canonical, but the original is alse can be used. 

#### 4.2 gp2 StorageClass testing

使用上面连接中的pod.yaml 和 claim.yaml，claim.yaml把storageclass改成gp2
```
kubectl get pvc -A
```
并且可以看到PVC被创建，并且bound了。查看AWS Dashboard EBS，可以看到有新的Volume。

#### 4.3 demo StarageClass
1. Modify the `StorageClass` resource in [`storageclass.yaml`](https://github.com/kubernetes-sigs/aws-ebs-csi-driver/blob/master/examples/kubernetes/storageclass/manifests/storageclass.yaml) as desired. For a list of supported parameters consult the Kubernetes documentation on [Storage Classes](https://kubernetes.io/docs/concepts/storage/storage-classes/#aws-ebs).

2. Deploy the provided pod on your cluster along with the `StorageClass` and `PersistentVolumeClaim`:
```shell
$ kubectl apply -f manifests

persistentvolumeclaim/ebs-claim created
pod/app created
storageclass.storage.k8s.io/ebs-sc created
```

3. Validate the `PersistentVolumeClaim` is bound to your `PersistentVolume`.
```shell
$ kubectl get pvc ebs-claim

NAME       STATUS  VOLUME    CAPACITY   ACCESS MODES   STORAGECLASS   AGE
ebs-claim  Bound   pvc-1fb712f2-632d-4b63-92e4-3b773d698ae1  4Gi RWO  ebs-sc 17s
```

4. Validate the pod successfully wrote data to the dynamically provisioned volume:
```shell
$ kubectl exec app -- cat /data/out.txt

Wed Feb 23 19:56:12 UTC 2022
```

5. Cleanup resources:
```shell
$ kubectl delete -f manifests

persistentvolumeclaim "ebs-claim" deleted
pod "app" deleted
storageclass.storage.k8s.io "ebs-sc" deleted
```

## 5. Uninstall

```
helm uninstall aws-ebs-csi-driver --namespace kube-system
```
