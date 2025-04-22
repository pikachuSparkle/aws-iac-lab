## DOCS:
https://www.elastic.co/docs/deploy-manage/deploy/cloud-on-k8s/managing-deployments-using-helm-chart

Starting from ECK 2.4.0, a Helm chart is available for managing Elastic Stack resources using the ECK Operator. It is available from the Elastic Helm repository and can be added to your Helm repository list by running the following command:
```
helm repo add elastic https://helm.elastic.co 
helm repo update
```

The Elastic Stack (`eck-stack`) Helm chart is built on top of individual charts such as `eck-elasticsearch` and `eck-kibana`. For more details on its structure and dependencies, refer to the [chart repository](https://github.com/elastic/cloud-on-k8s/tree/main/deploy/eck-stack/).
## Prerequisites:

- AWS EKS 1.32
- aws-ebs-csi-driver
- ECK 3.0.0
- Elasticsearch 9.0

## Create EKS Cluster
[[AWS - EKSCTL - EKS Cluster Deployment]]

## aws-ebs-csi-driver Installation
[[AWS - EKS - StorageClass - aws-ebs-csi-driver Installation]]

## ECK Operator Deployment
[[AWS - Elasticsearch - EKS - ECK - Elasticsearch & Kibana deployment]]

```
kubectl create -f https://download.elastic.co/downloads/eck/3.0.0/crds.yaml
```

```
kubectl apply -f https://download.elastic.co/downloads/eck/3.0.0/operator.yaml
```
## Elastic-Stack Deployment
https://www.elastic.co/docs/deploy-manage/deploy/cloud-on-k8s/managing-deployments-using-helm-chart#k8s-install-logstash-elasticsearch-kibana-helm

```
# Install an eck-managed Elasticsearch, Kibana, Beats and Logstash using custom values. helm install eck-stack-with-logstash elastic/eck-stack \ --values https://raw.githubusercontent.com/elastic/cloud-on-k8s/{{eck_release_branch}}/deploy/eck-stack/examples/logstash/basic-eck.yaml -n elastic-stack
```

create ns 
```
kubectl create ns elastic-stack
```

install the elastic-stack
```
helm install eck-stack-with-logstash elastic/eck-stack \
    --values https://raw.githubusercontent.com/elastic/cloud-on-k8s/3.0/deploy/eck-stack/examples/logstash/basic-eck.yaml -n elastic-stack
```





```
Error: INSTALLATION FAILED: 1 error occurred:
        * admission webhook "elastic-beat-validation-v1beta1.k8s.elastic.co" denied the request: Beat.beat.k8s.elastic.co "eck-stack-with-logstash-eck-beats" is invalid: [spec.daemonSet: Forbidden: Specify either daemonSet or deployment, not both, spec.deployment: Forbidden: Specify either daemonSet or deployment, not both, spec: Invalid value: v1beta1.BeatSpec{Type:"filebeat", Version:"9.0.0", ElasticsearchRef:v1.ObjectSelector{Namespace:"", Name:"", ServiceName:"", SecretName:""}, KibanaRef:v1.ObjectSelector{Namespace:"", Name:"", ServiceName:"", SecretName:""}, Image:"", Config:(*v1.Config)(0xc0000ab880), ConfigRef:(*v1.ConfigSource)(nil), SecureSettings:[]v1.SecretSource(nil), ServiceAccountName:"", DaemonSet:(*v1beta1.DaemonSetSpec)(0xc00062d888), Deployment:(*v1beta1.DeploymentSpec)(0xc00062dc08), Monitoring:v1.Monitoring{Metrics:v1.MetricsMonitoring{ElasticsearchRefs:[]v1.ObjectSelector(nil)}, Logs:v1.LogsMonitoring{ElasticsearchRefs:[]v1.ObjectSelector(nil)}}, RevisionHistoryLimit:(*int32)(nil)}: either daemonset or deployment must be specified]
```