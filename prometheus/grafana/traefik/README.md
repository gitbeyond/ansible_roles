# Traefik-kubernetes-281-custom

这个`dashboard`在是官方提供的`Traefik-kubernetes`的基础上增加了一些变量。如
* group
* instance
* namespace
* pod
* datasource


其需要使用如下形式的`podmonitor`为各组`traefik`添加监控信息。在`7.1.0`和`8.1.1`上均测试正常。

```bash
# cat podmonitor/traefik-outer_podmonitor.yml 
apiVersion: monitoring.coreos.com/v1
kind: PodMonitor
metadata:
  name: traefik-outer-podmonitors
  namespace: traefik-outer
spec:
  jobLabel: traefik-outer
  namespaceSelector:
    matchNames:
    - traefik-outer
  podMetricsEndpoints:
  - interval: 15s
    path: /metrics
    port: "metrics"
  selector:
    matchLabels:
      app.kubernetes.io/instance: ingress-traefik-outer
      app.kubernetes.io/name: traefik

# k -n traefik-outer get podmonitor
NAME                      AGE
traefik-outer-podmonitors   140d


```

# Traefik-kubernetes-service

这个实际的名字叫“traefik kubernetes service”。是针对各个`service`指标的查看，

主要是
* traefik_service_open_connections
* traefik_service_request_duration_seconds_bucket
* traefik_service_requests_total

在测试环境当中，由于使用了`servicemonitor`来监控`traefik`, 导致service的label变成了`exported_service`。

```yaml
# cat traefik_monitor_service.yml 
apiVersion: v1
kind: Service
metadata:
  labels:
    app.kubernetes.io/instance: ingress-traefik-t1
    app.kubernetes.io/managed-by: Helm
    app.kubernetes.io/name: traefik
    helm.sh/chart: traefik-9.18.0
  name: traefik-monitor
  namespace: t1
spec:
  ports:
  - name: monitor
    port: 9000
    protocol: TCP
    targetPort: traefik
  selector:
    app.kubernetes.io/instance: ingress-traefik-t1
    app.kubernetes.io/name: traefik
  sessionAffinity: None
  type: ClusterIP
# cat traefik_servicemonitor.yml 
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  labels:
    app.kubernetes.io/name: traefik-t1
  name: traefik
  namespace: t1
spec:
  endpoints:
  - interval: 15s
    port: monitor
    scheme: http
  #jobLabel: app.kubernetes.io/name
  jobLabel: app.kubernetes.io/instance
  selector:
    matchLabels:
      app.kubernetes.io/instance: ingress-traefik-t1
      app.kubernetes.io/name: traefik

```


```
traefik_service_requests_total{code="200", container="traefik", endpoint="monitor", exported_service="t1-app1-custom-outer-8c38a88994868fa75160@kubernetescrd", instance="192.168.1.1:9000", job="ingress-traefik-hongyuan-bim", method="GET", namespace="t1", pod="ingress-traefik-t1-5645b49c54-hxgh4", protocol="websocket", service="traefik-monitor"}
```

