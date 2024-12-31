## 0. DOCS

这俩包含了prometheus和grafana
https://archive.eksworkshop.com/intermediate/240_monitoring/deploy-prometheus/
https://navyadevops.hashnode.dev/setting-up-prometheus-and-grafana-on-amazon-eks-for-kubernetes-monitoring
这个资料有点老了，整体流程是对的
https://dev.to/aws-builders/monitoring-eks-cluster-with-prometheus-and-grafana-1kpb

## 1. EKS Cluster & aws-ebs-driver-driver Deployment

[[AWS - EKS - StorageClass - aws-ebs-csi-driver Installation]]

## 2. Deploy Prometheus 

```
kubectl create ns prometheus

helm repo add kube-state-metrics https://kubernetes.github.io/kube-state-metrics
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
```

```
helm upgrade -install prometheus prometheus-community/prometheus \
  --namespace prometheus \
  --set server.persistentVolume.storageClass="gp2"  \
  --set alertmanager.persistentVolume.storageClass="gp2"
```

NOTES：
1. `alertmanager.persistentVolume.storageClass="gp2"`这个在helm install阶段好像配置不上，没找到helm chart里面的value，后续在pvc里面配置
```
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 8Gi
  storageClassName: gp2
  volumeMode: Filesystem
  volumeName: pvc-84148cbf-ad77-4e1c-9c5e-9f045d9f50cf
```
2. Prometheus参考的文档
```
https://github.com/prometheus-community/helm-charts/tree/main/charts/prometheus
https://github.com/prometheus-community/helm-charts/blob/main/charts/prometheus/values.yaml
```
3. 卸载关注
```
helm uninstall prometheus -n prometheus
额外删除ns prometheus（以删除alertmanager的pvc）
```

## 3. Expose Prometheus Service

```text
#The Prometheus server can be accessed via port 80 on the following DNS name #from within your cluster:
#prometheus-server.prometheus.svc.cluster.local
#注意service端口是80，对应的pod端口是9090
```

把prometheus-server的svc进行edit，设置为NodePort
1、可以在Security Policy直接开放NodePort的端口，暴露服务。
2、方便后续通过ingress暴露出来（看需求）

```
kubectl get all -n prometheus
```
理论这样暴露也是可以的
```
kubectl port-forward -n prometheus deploy/prometheus-server 8081:9090 &
```

## 4. Deploy Grafana

```
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update
helm repo list

kubectl create namespace grafana
```


```yaml
datasources:
datasources.yaml:
  apiVersion: 1
  datasources:
  - name: Prometheus
    type: prometheus
    url: http://prometheus-server.prometheus.svc.cluster.local
    access: proxy
    isDefault: true
```

Config Data Sources。结果后来发现datasource没有成功加上，手动加没有问题
`http://prometheus-server.prometheus.svc.cluster.local`

```shell
helm install grafana grafana/grafana \
    --namespace grafana \
    --set persistence.storageClassName="gp2" \
    --set persistence.enabled=true \
    --set adminPassword='EKS!sAWSome' \
    --values /data/eksctl/grafana.yaml \
    --set service.type=NodePort
```

Output
```
NAME: grafana
LAST DEPLOYED: Sun Aug 25 03:24:44 2024
NAMESPACE: grafana
STATUS: deployed
REVISION: 1
NOTES:
1. Get your 'admin' user password by running:

   kubectl get secret --namespace grafana grafana -o jsonpath="{.data.admin-password}" | base64 --decode ; echo


2. The Grafana server can be accessed via port 80 on the following DNS name from within your cluster:

   grafana.grafana.svc.cluster.local

   Get the Grafana URL to visit by running these commands in the same shell:
     export NODE_PORT=$(kubectl get --namespace grafana -o jsonpath="{.spec.ports[0].nodePort}" services grafana)
     export NODE_IP=$(kubectl get nodes --namespace grafana -o jsonpath="{.items[0].status.addresses[0].address}")
     echo http://$NODE_IP:$NODE_PORT

3. Login with the password from step 1 and the username: admin
```


Delete the deployment
```
helm delete grafana -n grafana
```

## 5. Expose Grafana Service

#### 5.1 直接使用grafana服务的NodePort端口就可以访问

#### 5.2 创建ingress访问

Ingress的yaml文件
```yaml
apiVersion: networking.k8s.io/v1
  kind: Ingress
  metadata:
    annotations:
      alb.ingress.kubernetes.io/scheme: internet-facing
      alb.ingress.kubernetes.io/backend-protocol: HTTP
      alb.ingress.kubernetes.io/listen-ports: '[{"HTTPS":443}]'
      alb.ingress.kubernetes.io/healthcheck-path: /api/health
      alb.ingress.kubernetes.io/healthcheck-interval-seconds: '30'
      alb.ingress.kubernetes.io/healthcheck-timeout-seconds: '5'
      alb.ingress.kubernetes.io/healthy-threshold-count: '2'
      alb.ingress.kubernetes.io/unhealthy-threshold-count: '2'
    name: grafana
    namespace: grafana
  spec:
    ingressClassName: alb
    rules:
    - host: grafana.zambiaelephantbaby.uk
      http:
        paths:
        - path: /
          backend:
            service:
              name: grafana
              port:
                number: 80
          pathType: Prefix
    tls:
    - hosts:
      - grafana.zambiaelephantbaby.uk
```


- 注意后端是HTTP
- 注意增加healthy那5句annotations才能check healthy状态
- 注意不能/*
- 注意创建需要时间，等待2分钟，ALB - provision 和 target group - initializing 

根据ingress的信息，修改DNS的record之后可以登录访问