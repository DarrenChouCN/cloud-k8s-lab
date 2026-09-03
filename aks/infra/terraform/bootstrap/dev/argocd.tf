resource "helm_release" "argocd" {
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = "10.4.1"

  namespace        = "argocd"
  create_namespace = true

  wait    = true
  timeout = 600
}