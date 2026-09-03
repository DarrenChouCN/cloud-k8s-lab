data "azurerm_kubernetes_cluster" "main" {
  name                = "aks-cloud-k8s-lab-dev-ause-01"
  resource_group_name = "rg-cloud-k8s-lab-dev-ause-01"
}