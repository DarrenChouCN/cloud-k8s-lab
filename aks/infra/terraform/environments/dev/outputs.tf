output "resource_group_name" {
  value = module.aks_infra.resource_group_name
}

output "aks_cluster_name" {
  value = module.aks_infra.aks_cluster_name
}

output "dns_zone_name" {
  value = module.aks_infra.dns_zone_name
}

output "dns_zone_name_servers" {
  value = module.aks_infra.dns_zone_name_servers
}

output "external_dns_client_id" {
  value = module.aks_infra.external_dns_client_id
}

output "external_dns_identity_name" {
  value = module.aks_infra.external_dns_identity_name
}

output "aks_get_credentials_command" {
  value = module.aks_infra.aks_get_credentials_command
}

output "acr_name" {
  value = module.aks_infra.acr_name
}

output "acr_login_server" {
  value = module.aks_infra.acr_login_server
}