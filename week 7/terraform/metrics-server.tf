locals {
  values_metrics-server = <<VALUES
    apiService:
      create: ture
VALUES
}

resource "helm_release" "metrics-server" {
  depends_on = [module.eks]
  name       = "metrics-server"

  repository = "https://kubernetes-sigs.github.io/metrics-server/"
  chart      = "metrics-server"
  version     = "3.10.0"
  namespace = "metrics-server"
  create_namespace = true

  values = [
    local.values_metrics-server
  ]
}