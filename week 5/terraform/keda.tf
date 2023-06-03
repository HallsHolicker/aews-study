locals {
  values_keda = <<VALUES
  metricsServer:
    useHostNetwork: true
  prometheus:
    metricServer:
      enabled: true
      port: 9022
      portName: metrics
      path: /metrics
      serviceMonitor:
        # Enables ServiceMonitor creation for the Prometheus Operator
        enabled: true
      podMonitor:
        # Enables PodMonitor creation for the Prometheus Operator
        enabled: true
    operator:
      enabled: true
      port: 8080
      serviceMonitor:
        # Enables ServiceMonitor creation for the Prometheus Operator
        enabled: true
      podMonitor:
        # Enables PodMonitor creation for the Prometheus Operator
        enabled: true
  webhooks:
    enabled: true
    port: 8080
    serviceMonitor:
      # Enables ServiceMonitor creation for the Prometheus webhooks
      enabled: true
VALUES
}

resource "helm_release" "keda" {
  count = var.keda ? 1 : 0
  namespace        = "keda"
  create_namespace = true
  name       = "keda"
  repository = "https://kedacore.github.io/charts"
  chart      = "keda"
  version    = "2.10.2"
}