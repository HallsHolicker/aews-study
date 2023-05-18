locals {
  values_kubecost = <<VALUES
    global:
      grafana:
        enabled: false
        proxy: false

    imageVersion: prod-1.103.3
    kubecostFrontend:
      image: public.ecr.aws/kubecost/frontend

    kubecostModel:
      image: public.ecr.aws/kubecost/cost-model

    kubecostMetrics:
      emitPodAnnotations: true
      emitNamespaceAnnotations: true

    persistentVolume:
        storageClass: "gp3"

    prometheus:
      server:
        image:
          repository: public.ecr.aws/kubecost/prometheus
          tag: v2.35.0

      configmapReload:
        prometheus:
          image:
            repository: public.ecr.aws/bitnami/configmap-reload
            tag: 0.7.1

    reporting:
      productAnalytics: false
VALUES
}


resource "helm_release" "kubecost" {
  count = var.kubecost && !var.kube-prometheus-stack ? 1 : 0
  depends_on = [module.eks]
  name       = "kubecost"

  repository = "oci://public.ecr.aws/kubecost"
  chart      = "cost-analyzer"
  version     = "1.103.2"
  namespace = "kubecost"
  create_namespace = true

  values = [
    local.values_kubecost
  ]
}

resource "kubernetes_ingress_v1" "kubecost-ingress" {
  count = var.kubecost && !var.kube-prometheus-stack ? 1 : 0
  depends_on = [helm_release.kubecost]

  metadata {
    name = "kubecost-ingress"
    namespace = "kubecost"
    annotations = {
      "alb.ingress.kubernetes.io/scheme" = "internet-facing"
      "alb.ingress.kubernetes.io/target-type" = "ip"
      "external-dns.alpha.kubernetes.io/hostname" = "kubecost.${var.domain_name}"
    }
  }

  spec {
    ingress_class_name = "alb"
    rule {
      host = "kubecost.${var.domain_name}" 
      http {
        path {
          path = "/*"
          backend {
            service {
              name = "kubecost-cost-analyzer"
              port {
                number = 9090
              }
            }
          }
        }
      }
    }
  }
}