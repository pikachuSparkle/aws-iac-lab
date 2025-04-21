## DOCS:
https://www.elastic.co/docs/deploy-manage/deploy/cloud-on-k8s/deploy-an-orchestrator
https://www.elastic.co/docs/deploy-manage/deploy/cloud-on-k8s/manage-deployments

## Platform:
in this scenario, using the most simple tools locap-path provisioner and ingress-nginx
- AWS EKS Cluster
- no less than 8G memory
- storageClassName local-path
- [[AWS - EKS - Ingress Controller - NLB & Ingress-nginx]]

## Testbed Provisioning

1. Setup Cluster
[[AWS - EKSCTL - EKS Cluster Deployment]]

2. Install [local-path-provisioner](https://github.com/rancher/local-path-provisioner)
```
kubectl apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/v0.0.28/deploy/local-path-storage.yaml
```

3. Scaling out EKS nodeGroup 
[[AWS - EKSCTL - EKS nodeGroup Scaling Out]]

## Deploy ECK in your Kubernetes cluster
https://www.elastic.co/guide/en/cloud-on-k8s/current/k8s-deploy-eck.html

```
kubectl create -f https://download.elastic.co/downloads/eck/2.14.0/crds.yaml
```

```
customresourcedefinition.apiextensions.k8s.io/agents.agent.k8s.elastic.co created
customresourcedefinition.apiextensions.k8s.io/apmservers.apm.k8s.elastic.co created
customresourcedefinition.apiextensions.k8s.io/beats.beat.k8s.elastic.co created
customresourcedefinition.apiextensions.k8s.io/elasticmapsservers.maps.k8s.elastic.co created
customresourcedefinition.apiextensions.k8s.io/elasticsearches.elasticsearch.k8s.elastic.co created
customresourcedefinition.apiextensions.k8s.io/enterprisesearches.enterprisesearch.k8s.elastic.co created
customresourcedefinition.apiextensions.k8s.io/kibanas.kibana.k8s.elastic.co created
customresourcedefinition.apiextensions.k8s.io/logstashes.logstash.k8s.elastic.co created
```

```
kubectl apply -f https://download.elastic.co/downloads/eck/2.14.0/operator.yaml
```

```
kubectl -n elastic-system logs -f statefulset.apps/elastic-operator
```
## Deploy an Elasticsearch cluster
https://www.elastic.co/guide/en/cloud-on-k8s/current/k8s-deploy-elasticsearch.html

```
cat <<EOF | kubectl apply -f -
apiVersion: elasticsearch.k8s.elastic.co/v1
kind: Elasticsearch
metadata:
  name: quickstart
spec:
  version: 8.15.0
  nodeSets:
  - name: default
    count: 1
    config:
      node.store.allow_mmap: false
EOF
```

```
kubectl edit pvc quickstart-es-default-0 -n default
# edit the pvc & change the storageClassName: local-path
```

```
kubectl get elasticsearch
```

```
NAME          HEALTH    NODES     VERSION   PHASE         AGE
quickstart    green     1         8.15.0     Ready         1m
```

```
kubectl get pods --selector='elasticsearch.k8s.elastic.co/cluster-name=quickstart'
```

```
NAME                      READY   STATUS    RESTARTS   AGE
quickstart-es-default-0   1/1     Running   0          79s
```

```
kubectl logs -f quickstart-es-default-0
```

```
kubectl get service quickstart-es-http
```

```
NAME                 TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)    AGE
quickstart-es-http   ClusterIP   10.15.251.145   <none>        9200/TCP   34m
```

```
PASSWORD=$(kubectl get secret quickstart-es-elastic-user -o go-template='{{.data.elastic | base64decode}}')
```

```
curl -u "elastic:$PASSWORD" -k "https://quickstart-es-http:9200"
```

```
kubectl port-forward service/quickstart-es-http 9200
```

```
curl -u "elastic:$PASSWORD" -k "https://localhost:9200"
```

```
{
  "name" : "quickstart-es-default-0",
  "cluster_name" : "quickstart",
  "cluster_uuid" : "XqWg0xIiRmmEBg4NMhnYPg",
  "version" : {...},
  "tagline" : "You Know, for Search"
}
```

## Deploy a Kibana instance
https://www.elastic.co/guide/en/cloud-on-k8s/current/k8s-deploy-kibana.html

```
cat <<EOF | kubectl apply -f -
apiVersion: kibana.k8s.elastic.co/v1
kind: Kibana
metadata:
  name: quickstart
spec:
  version: 8.15.0
  count: 1
  elasticsearchRef:
    name: quickstart
EOF
```

```
kubectl get kibana
```

```
kubectl get pod --selector='kibana.k8s.elastic.co/name=quickstart'
```

```
kubectl get service quickstart-kb-http
```

```
kubectl port-forward service/quickstart-kb-http 5601
```

```
kubectl get secret quickstart-es-elastic-user -o=jsonpath='{.data.elastic}' | base64 --decode; echo
```

## Next 
https://www.elastic.co/guide/en/cloud-on-k8s/current/k8s-orchestrating-elastic-stack-applications.html
