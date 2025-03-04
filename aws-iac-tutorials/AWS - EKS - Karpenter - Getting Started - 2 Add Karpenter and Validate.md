
## References

https://karpenter.sh/docs/getting-started/getting-started-with-karpenter/#4-install-karpenter

## Prerequisites:

- Set up the EKS Cluster with eksctl
[[AWS - EKS - Karpenter - Getting Started - 1 Set Up a Cluster]]
- Print out and verify current environment variables
```shell
echo -e "KARPENTER_NAMESPACE: ${KARPENTER_NAMESPACE}"
echo -e "KARPENTER_VERSION: ${KARPENTER_VERSION}"
echo -e "K8S_VERSION: ${K8S_VERSION}"
echo -e "CLUSTER_NAME: ${CLUSTER_NAME}"
echo -e "AWS_DEFAULT_REGION: ${AWS_DEFAULT_REGION}"
echo -e "AWS_ACCOUNT_ID: ${AWS_ACCOUNT_ID}"
echo -e "TEMPOUT: ${TEMPOUT}"
echo -e "ARM_AMI_ID:${ARM_AMI_ID}"
echo -e "AMD_AMI_ID: ${AMD_AMI_ID}"
echo -e "GPU_AMI_ID: ${GPU_AMI_ID}"
```

## 4. Install Karpenter

```shell
# Logout of helm registry to perform an unauthenticated pull against the public ECR
helm registry logout public.ecr.aws

helm upgrade --install karpenter oci://public.ecr.aws/karpenter/karpenter --version "${KARPENTER_VERSION}" --namespace "${KARPENTER_NAMESPACE}" --create-namespace \
  --set "settings.clusterName=${CLUSTER_NAME}" \
  --set "settings.interruptionQueue=${CLUSTER_NAME}" \
  --set controller.resources.requests.cpu=1 \
  --set controller.resources.requests.memory=1Gi \
  --set controller.resources.limits.cpu=1 \
  --set controller.resources.limits.memory=1Gi \
  --wait
```

## 5. Create NodePool

```shell
cat <<EOF | envsubst | kubectl apply -f -
apiVersion: karpenter.sh/v1
kind: NodePool
metadata:
  name: default
spec:
  template:
    spec:
      requirements:
        - key: kubernetes.io/arch
          operator: In
          values: ["amd64"]
        - key: kubernetes.io/os
          operator: In
          values: ["linux"]
        - key: karpenter.sh/capacity-type
          operator: In
          values: ["on-demand"]
        - key: karpenter.k8s.aws/instance-category
          operator: In
          values: ["c", "m", "r"]
        - key: karpenter.k8s.aws/instance-generation
          operator: Gt
          values: ["2"]
      nodeClassRef:
        group: karpenter.k8s.aws
        kind: EC2NodeClass
        name: default
      expireAfter: 720h # 30 * 24h = 720h
  limits:
    cpu: 1000
  disruption:
    consolidationPolicy: WhenEmptyOrUnderutilized
    consolidateAfter: 1m
---
apiVersion: karpenter.k8s.aws/v1
kind: EC2NodeClass
metadata:
  name: default
spec:
  role: "KarpenterNodeRole-${CLUSTER_NAME}" # replace with your cluster name
  amiSelectorTerms:
    - alias: "al2023@${ALIAS_VERSION}"
  subnetSelectorTerms:
    - tags:
        karpenter.sh/discovery: "${CLUSTER_NAME}" # replace with your cluster name
  securityGroupSelectorTerms:
    - tags:
        karpenter.sh/discovery: "${CLUSTER_NAME}" # replace with your cluster name
EOF

```

## 6. Scale up deployment

```shell
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: inflate
spec:
  replicas: 0
  selector:
    matchLabels:
      app: inflate
  template:
    metadata:
      labels:
        app: inflate
    spec:
      terminationGracePeriodSeconds: 0
      securityContext:
        runAsUser: 1000
        runAsGroup: 3000
        fsGroup: 2000
      containers:
      - name: inflate
        image: public.ecr.aws/eks-distro/kubernetes/pause:3.7
        resources:
          requests:
            cpu: 1
        securityContext:
          allowPrivilegeEscalation: false
EOF

kubectl scale deployment inflate --replicas 5
kubectl logs -f -n "${KARPENTER_NAMESPACE}" -l app.kubernetes.io/name=karpenter -c controller

```


```bash
kubectl scale deployment inflate --replicas 5
kubectl logs -f -n "${KARPENTER_NAMESPACE}" -l app.kubernetes.io/name=karpenter -c controller
```

## 7. Scale down deployment
```bash
kubectl delete deployment inflate
kubectl logs -f -n "${KARPENTER_NAMESPACE}" -l app.kubernetes.io/name=karpenter -c controller
```

## 8. Delete Karpenter nodes manually

If you delete a node with kubectl, Karpenter will gracefully cordon, drain, and shutdown the corresponding instance. Under the hood, Karpenter adds a finalizer to the node object, which blocks deletion until all pods are drained and the instance is terminated. Keep in mind, this only works for nodes provisioned by Karpenter.
```bash
kubectl delete node "${NODE_NAME}"
```

## 9. Delete the cluster

To avoid additional charges, remove the demo infrastructure from your AWS account.
```shell
helm uninstall karpenter --namespace "${KARPENTER_NAMESPACE}"
aws cloudformation delete-stack --stack-name "Karpenter-${CLUSTER_NAME}"
aws ec2 describe-launch-templates --filters "Name=tag:karpenter.k8s.aws/cluster,Values=${CLUSTER_NAME}" |
    jq -r ".LaunchTemplates[].LaunchTemplateName" |
    xargs -I{} aws ec2 delete-launch-template --launch-template-name {}
eksctl delete cluster --name "${CLUSTER_NAME}"

```