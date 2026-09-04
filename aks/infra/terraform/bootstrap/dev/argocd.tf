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

resource "helm_release" "argocd_bootstrap" {
  name       = "argocd-bootstrap"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argocd-apps"
  namespace  = "argocd"

  values = [
    file("${path.module}/argocd-apps-values.yaml")
  ]

  depends_on = [
    helm_release.argocd
  ]
}