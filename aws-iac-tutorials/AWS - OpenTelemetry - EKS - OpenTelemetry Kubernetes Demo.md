
## DOCS
[Kubernetes deployment | OpenTelemetry](https://opentelemetry.io/docs/demo/kubernetes-deployment/)
[OpenTelemetry Demo Chart](https://opentelemetry.io/docs/platforms/kubernetes/helm/demo/)

## Prerequisites

- Kubernetes 1.24+
- 6 GB of free RAM for the application
- Helm 3.14+ (for Helm installation method only)

## Kubernetes Cluster Deployment

[[AWS - EKSCTL - EKS Cluster Deployment]]

[[AWS - EKSCTL - EKS nodeGroup Scaling Out]] (Optional)

## Demo Deployment


Add OpenTelemetry Helm repository:
```
helm repo add open-telemetry https://open-telemetry.github.io/opentelemetry-helm-charts
```

To install the chart with the release name `my-otel-demo`, run the following command:
```
helm install my-otel-demo open-telemetry/opentelemetry-demo
```

Once installed, all services are made available via the Frontend proxy ([http://localhost:8080](http://localhost:8080/)) by running these commands:
```
kubectl port-forward svc/my-otel-demo-frontendproxy 8080:8080 --address 0.0.0.0
```


```
- All services are available via the Frontend proxy: http://localhost:8080
  by running these commands:
     kubectl --namespace default port-forward svc/frontend-proxy 8080:8080

  The following services are available at these paths after the frontend-proxy service is exposed with port forwarding:
  Webstore             http://localhost:8080/
  Jaeger UI            http://localhost:8080/jaeger/ui/
  Grafana              http://localhost:8080/grafana/
  Load Generator UI    http://localhost:8080/loadgen/
  Feature Flags UI     http://localhost:8080/feature/
```

In order for spans from the Web store to be collected you must expose the OpenTelemetry Collector OTLP/HTTP receiver:

```
kubectl port-forward svc/my-otel-demo-otelcol 4318:4318
```







