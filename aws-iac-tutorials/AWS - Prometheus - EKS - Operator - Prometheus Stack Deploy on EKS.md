## 0. Reference

https://spacelift.io/blog/prometheus-kubernetes

>What is kube-prometheus-stack?
>The kube-prometheus-stack Helm chart is the simplest way to bring up a complete Prometheus stack inside your Kubernetes cluster. It bundles several different components in one automated deployment:
>- Prometheus – Prometheus is the time series database that scrapes, stores, and exposes the metrics from your Kubernetes environment and its applications.
>- Node-Exporter – Prometheus works by scraping data from a variety of configurable sources called exporters. Node-Exporter is an exporter which collects resource utilization data from the Nodes in your Kubernetes cluster. The kube-prometheus-stack chart automatically deploys this exporter and configures your Prometheus instance to scrape it.
>- Kube-State-Metrics – Kube-State-Metrics is another exporter that supplies data to Prometheus. It exposes information about the API objects in your Kubernetes cluster, such as Pods and containers.
>- Grafana – Although you can directly query Prometheus, this is often tedious and repetitive. Grafana is an observability platform that works with several data sources, including Prometheus databases. You can use it to create dashboards that surface your Prometheus data.
>- Alertmanager – Alertmanager is a standalone Prometheus component that provides notifications when metrics change. You can use it to get an email when CPU utilization spikes or a Slack notification if a Pod is evicted, for example.
>Deploying, configuring, and maintaining all these components individually can be burdensome for administrators. Kube-Prometheus-Stack provides an automated solution that performs all the hard work for you.

https://github.com/prometheus-operator/kube-prometheus

>This repository collects Kubernetes manifests, [Grafana](http://grafana.com/) dashboards, and [Prometheus rules](https://prometheus.io/docs/prometheus/latest/configuration/recording_rules/) combined with documentation and scripts to provide easy to operate end-to-end Kubernetes cluster monitoring with [Prometheus](https://prometheus.io/) using the Prometheus Operator.

https://github.com/prometheus-operator/prometheus-operator
>Prometheus Operator vs. kube-prometheus vs. community helm chart
>Prometheus Operator
>The Prometheus Operator uses Kubernetes custom resources to simplify the deployment and configuration of Prometheus, Alertmanager, and related monitoring components.
>kube-prometheus
>kube-prometheus provides example configurations for a complete cluster monitoring stack based on Prometheus and the Prometheus Operator. This includes deployment of multiple Prometheus and Alertmanager instances, metrics exporters such as the node_exporter for gathering node metrics, scrape target configuration linking Prometheus to various metrics endpoints, and example alerting rules for notification of potential issues in the cluster.
>helm chart
>The prometheus-community/kube-prometheus-stack helm chart provides a similar feature set to kube-prometheus. This chart is maintained by the Prometheus community. For more information, please see the chart's readme

## 1. Setup Prometheus monitoring on EKS

```
# Helm Chart Readme
# https://github.com/prometheus-community/helm-charts/blob/main/charts/kube-prometheus-stack/README.md
```

```
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
```

Now you can run the following command to deploy the chart into a new namespace in your cluster:

```bash
helm install kube-prometheus-stack \
  --create-namespace \
  --namespace kube-prometheus-stack \
  prometheus-community/kube-prometheus-stack
```

```
# helm install [RELEASE_NAME] prometheus-community/kube-prometheus-stack
```

By default this chart installs additional, dependent charts:
- [prometheus-community/kube-state-metrics](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-state-metrics)
- [prometheus-community/prometheus-node-exporter](https://github.com/prometheus-community/helm-charts/tree/main/charts/prometheus-node-exporter)
- [grafana/grafana](https://github.com/grafana/helm-charts/tree/main/charts/grafana)
To disable dependencies during installation, see [multiple releases](https://github.com/prometheus-community/helm-charts/blob/main/charts/kube-prometheus-stack/README.md#multiple-releases) below.
_See [helm dependency](https://helm.sh/docs/helm/helm_dependency/) for command documentation._

```bash
kubectl -n kube-prometheus-stack get pods
NAME                                               READY STATUS  RESTARTS AGE
alertmanager-kube-prometheus-stack-alertmanager-0      2/2   Running 1    83s
kube-prometheus-stack-grafana-5cd658f9b4-cln2c         3/3   Running 0    99s
kube-prometheus-stack-kube-state-metrics-b64cf5876-j8  1/1   Running 0    99s
kube-prometheus-stack-operator-754ff78899-669k6        1/1   Running 0    99s
kube-prometheus-stack-prometheus-node-exporter-vdgrg   1/1   Running 0    99s
prometheus-kube-prometheus-stack-prometheus-0          2/2   Running 0    83s
```

uninstall the release 
```
helm uninstall kube-prometheus-stack -n kube-prometheus-stack  
```

## 2. Validate

#### Prometheus

```
kubectl port-forward -n kube-prometheus-stack svc/kube-prometheus-stack-prometheus 9090:9090
```

Visiting this URL in your web browser will reveal the Prometheus UI:
```
public-ip:9090
```
#### Grafana

```
kubectl port-forward -n svc/kube-prometheus-stack-grafana 8080:80
```

Next visit `http://public-ip:8080` in your browser. You’ll see the Grafana login page. The default user account is admin with a password of `prom-operator`.

#### Explore the Grafana pre-built dashboards

#### Configure alerts with Alertmanager (pending)