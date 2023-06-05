resource "helm_release" "valutoperator" {
  count = var.vault ? 1 : 0
  namespace        = "vault-secrets-operator"
  create_namespace = true
  name       = "vault-secrets-operator"
  repository = "https://helm.releases.hashicorp.com"
  chart      = "vault-secrets-operator"
  version    = "0.1.0-beta"
}