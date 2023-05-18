locals {
  values_kube-prometheus-stack = <<VALUES
    prometheus:
      prometheusSpec:
        podMonitorSelectorNilUsesHelmValues: false
        serviceMonitorSelectorNilUsesHelmValues: false
        retention: 5d
        retentionSize: "10GiB"

      ingress:
        enabled: true
        ingressClassName: alb
        hosts: 
          - prometheus.${var.domain_name}
        paths: 
          - /*
        annotations:
          alb.ingress.kubernetes.io/scheme: internet-facing
          alb.ingress.kubernetes.io/target-type: ip
          alb.ingress.kubernetes.io/listen-ports: '[{"HTTPS":443}, {"HTTP":80}]'
          alb.ingress.kubernetes.io/certificate-arn: ${data.aws_acm_certificate.domain_acm.arn}
          alb.ingress.kubernetes.io/success-codes: 200-399
          alb.ingress.kubernetes.io/load-balancer-name: myeks-ingress-alb
          alb.ingress.kubernetes.io/group.name: study
          alb.ingress.kubernetes.io/ssl-redirect: '443'
          external-dns.alpha.kubernetes.io/hostname: prometheus.${var.domain_name}

    grafana:
      defaultDashboardsTimezone: Asia/Seoul
      adminPassword: prom-operator

      ingress:
        enabled: true
        ingressClassName: alb
        hosts: 
          - grafana.${var.domain_name}
        paths: 
          - /*
        annotations:
          alb.ingress.kubernetes.io/scheme: internet-facing
          alb.ingress.kubernetes.io/target-type: ip
          alb.ingress.kubernetes.io/listen-ports: '[{"HTTPS":443}, {"HTTP":80}]'
          alb.ingress.kubernetes.io/certificate-arn: ${data.aws_acm_certificate.domain_acm.arn}
          alb.ingress.kubernetes.io/success-codes: 200-399
          alb.ingress.kubernetes.io/load-balancer-name: myeks-ingress-alb
          alb.ingress.kubernetes.io/group.name: study
          alb.ingress.kubernetes.io/ssl-redirect: '443'
          external-dns.alpha.kubernetes.io/hostname: grafana.${var.domain_name}

    defaultRules:
      create: false
    kubeControllerManager:
      enabled: false
    kubeEtcd:
      enabled: false
    kubeScheduler:
      enabled: false
    alertmanager:
      enabled: false

    # alertmanager:
    #   ingress:
    #     enabled: true
    #     ingressClassName: alb
    #     hosts: 
    #       - alertmanager.${var.domain_name}
    #     paths: 
    #       - /*
    #     annotations:
    #       alb.ingress.kubernetes.io/scheme: internet-facing
    #       alb.ingress.kubernetes.io/target-type: ip
    #       alb.ingress.kubernetes.io/listen-ports: '[{"HTTPS":443}, {"HTTP":80}]'
    #       alb.ingress.kubernetes.io/certificate-arn: ${data.aws_acm_certificate.domain_acm.arn}
    #       alb.ingress.kubernetes.io/success-codes: 200-399
    #       alb.ingress.kubernetes.io/load-balancer-name: myeks-ingress-alb
    #       alb.ingress.kubernetes.io/group.name: study
    #       alb.ingress.kubernetes.io/ssl-redirect: '443'
VALUES
}

resource "helm_release" "kube-prometheus-stack" {
  count = var.kube-prometheus-stack && !var.kubecost ? 1 : 0
  depends_on = [module.eks]
  name       = "kube-prometheus-stack"

  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  version     = "45.27.2"
  namespace = "monitoring"
  create_namespace = true

  set {
    name  = "prometheus.prometheusSpec.scrapeInterval"
    value = "15s"
  }

  set {
    name  = "prometheus.prometheusSpec.evaluationInterval"
    value = "15s"
  }

  values = [
    local.values_kube-prometheus-stack  ]
}