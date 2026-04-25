module "aks_infra" {
  source = "../../modules"

  project_name       = var.project_name
  environment        = var.environment
  location           = var.location
  location_short     = var.location_short
  owner              = var.owner
  dns_zone_name      = var.dns_zone_name
  node_vm_size       = var.node_vm_size
  node_count         = var.node_count
  os_disk_size_gb    = var.os_disk_size_gb
  kubernetes_version = var.kubernetes_version
}