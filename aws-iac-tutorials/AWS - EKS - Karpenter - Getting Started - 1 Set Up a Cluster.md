
Karpenter automatically provisions new nodes in response to unschedulable pods. Karpenter does this by observing events within the Kubernetes cluster, and then sending commands to the underlying cloud provider.

This guide shows how to get started with Karpenter by creating a Kubernetes cluster and installing Karpenter. To use Karpenter, you must be running a supported Kubernetes cluster on a supported cloud provider.

The guide below explains how to utilize the [Karpenter provider for AWS](https://github.com/aws/karpenter-provider-aws) with EKS.

This guide uses `eksctl` to create the cluster. It should take less than 1 hour to complete, and cost less than $0.25. Follow the clean-up instructions to reduce any charges.

References:
https://karpenter.sh/docs/getting-started/getting-started-with-karpenter/


NOTES:
All-in-one scripts, please follow the following shell commands, and you can obtain the shell scripts.
```shell
git clone https://github.com/pikachuSparkle/aws-iac-lab.git
cd aws-iac-lab/EKSCTL_Codes/karpenter/
vim karpenter-set-up-cluster.sh
# To keep the environment variables, source command should be used
source karpenter-set-up-cluster.sh
```
And you can also go through the article step by step  as floows.


## 1. Install utilities [](https://karpenter.sh/docs/getting-started/getting-started-with-karpenter/#1-install-utilities)
Karpenter is installed in clusters with a Helm chart.

Karpenter requires cloud provider permissions to provision nodes, for AWS IAM Roles for Service Accounts (IRSA) should be used. IRSA permits Karpenter (within the cluster) to make privileged requests to AWS (as the cloud provider) via a ServiceAccount.

Install these tools before proceeding (the newest version):

1. [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2-linux.html)
2. `kubectl` - [the Kubernetes CLI](https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/)
3. `eksctl` (>= v0.202.0) - [the CLI for AWS EKS](https://eksctl.io/installation)
4. `helm` - [the package manager for Kubernetes](https://helm.sh/docs/intro/install/)

[Configure the AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-quickstart.html) with a user that has sufficient privileges to create an EKS cluster. Verify that the CLI can authenticate properly by running `aws sts get-caller-identity`.

## 2. Set environment variables

After setting up the tools, set the Karpenter and Kubernetes version:
```shell
export KARPENTER_NAMESPACE="kube-system"
export KARPENTER_VERSION="1.2.1"
export K8S_VERSION="1.32"
```

Then set the following environment variable:
```shell
export AWS_PARTITION="aws" # if you are not using standard partitions, you may need to configure to aws-cn / aws-us-gov
export CLUSTER_NAME="${USER}-karpenter-demo"
export AWS_DEFAULT_REGION="us-west-2"
export AWS_ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text)"
export TEMPOUT="$(mktemp)"
export ALIAS_VERSION="$(aws ssm get-parameter --name "/aws/service/eks/optimized-ami/${K8S_VERSION}/amazon-linux-2023/x86_64/standard/recommended/image_id" --query Parameter.Value | xargs aws ec2 describe-images --query 'Images[0].Name' --image-ids | sed -r 's/^.*(v[[:digit:]]+).*$/\1/')"
```

If you open a new shell to run steps in this procedure, you need to set some or all of the environment variables again. To remind yourself of these values, type:
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

## 3. Create a Cluster

Create a basic cluster with `eksctl`. The following cluster configuration will:

- Use CloudFormation to set up the infrastructure needed by the EKS cluster. See [CloudFormation](https://karpenter.sh/docs/reference/cloudformation/) for a complete description of what `cloudformation.yaml` does for Karpenter.
- Create a Kubernetes service account and AWS IAM Role, and associate them using IRSA to let Karpenter launch instances.
- Add the Karpenter node role to the aws-auth configmap to allow nodes to connect.
- Use [AWS EKS managed node groups](https://docs.aws.amazon.com/eks/latest/userguide/managed-node-groups.html) for the kube-system and karpenter namespaces. Uncomment fargateProfiles settings (and comment out managedNodeGroups settings) to use Fargate for both namespaces instead.
- Set KARPENTER_IAM_ROLE_ARN variables.
- Create a role to allow spot instances.
- Run Helm to install Karpenter

```shell
curl -fsSL https://raw.githubusercontent.com/aws/karpenter-provider-aws/v"${KARPENTER_VERSION}"/website/content/en/preview/getting-started/getting-started-with-karpenter/cloudformation.yaml  > "${TEMPOUT}" \
&& aws cloudformation deploy \
  --stack-name "Karpenter-${CLUSTER_NAME}" \
  --template-file "${TEMPOUT}" \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameter-overrides "ClusterName=${CLUSTER_NAME}"
```


```shell
eksctl create cluster -f - <<EOF
---
apiVersion: eksctl.io/v1alpha5
kind: ClusterConfig
metadata:
  name: ${CLUSTER_NAME}
  region: ${AWS_DEFAULT_REGION}
  version: "${K8S_VERSION}"
  tags:
    karpenter.sh/discovery: ${CLUSTER_NAME}

iam:
  withOIDC: true
  podIdentityAssociations:
  - namespace: "${KARPENTER_NAMESPACE}"
    serviceAccountName: karpenter
    roleName: ${CLUSTER_NAME}-karpenter
    permissionPolicyARNs:
    - arn:${AWS_PARTITION}:iam::${AWS_ACCOUNT_ID}:policy/KarpenterControllerPolicy-${CLUSTER_NAME}

iamIdentityMappings:
- arn: "arn:${AWS_PARTITION}:iam::${AWS_ACCOUNT_ID}:role/KarpenterNodeRole-${CLUSTER_NAME}"
  username: system:node:{{EC2PrivateDNSName}}
  groups:
  - system:bootstrappers
  - system:nodes
  ## If you intend to run Windows workloads, the kube-proxy group should be specified.
  # For more information, see https://github.com/aws/karpenter/issues/5099.
  # - eks:kube-proxy-windows

managedNodeGroups:
- instanceType: m5.large
  amiFamily: AmazonLinux2023
  name: ${CLUSTER_NAME}-ng
  desiredCapacity: 2
  minSize: 1
  maxSize: 10

addons:
- name: eks-pod-identity-agent
EOF
```


```shell
export CLUSTER_ENDPOINT="$(aws eks describe-cluster --name "${CLUSTER_NAME}" --query "cluster.endpoint" --output text)"
export KARPENTER_IAM_ROLE_ARN="arn:${AWS_PARTITION}:iam::${AWS_ACCOUNT_ID}:role/${CLUSTER_NAME}-karpenter"

echo -e "CLUSTER_ENDPOINT: ${CLUSTER_ENDPOINT}"
echo -e "KARPENTER_IAM_ROLE_ARN: ${KARPENTER_IAM_ROLE_ARN}"
```


```shell
# Delete the cluster
eksctl delete cluster --name "${CLUSTER_NAME}" --region us-east-1
```
