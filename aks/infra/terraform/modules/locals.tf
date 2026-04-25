locals {
  name_suffix = "${var.project_name}-${var.environment}-${var.location_short}-01"

  resource_group_name        = "rg-${local.name_suffix}"
  aks_cluster_name           = "aks-${local.name_suffix}"
  aks_dns_prefix             = "aks-${var.project_name}-${var.environment}-${var.location_short}"
  external_dns_identity_name = "id-externaldns-${var.environment}-${var.location_short}-01"
  federated_identity_name    = "fic-externaldns-${var.environment}-${var.location_short}-01"

  tags = {
    project     = var.project_name
    environment = var.environment
    owner       = var.owner
    managed_by  = "terraform"
    workload    = "aks-lab"
  }
}