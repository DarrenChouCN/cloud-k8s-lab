output "resource_group_name" {
  value = azurerm_resource_group.main.name
}

output "aks_cluster_name" {
  value = azurerm_kubernetes_cluster.main.name
}

output "dns_zone_name" {
  value = azurerm_dns_zone.aks.name
}

output "dns_zone_name_servers" {
  value = azurerm_dns_zone.aks.name_servers
}

output "external_dns_identity_name" {
  value = azurerm_user_assigned_identity.external_dns.name
}

output "external_dns_client_id" {
  value = azurerm_user_assigned_identity.external_dns.client_id
}

output "external_dns_principal_id" {
  value = azurerm_user_assigned_identity.external_dns.principal_id
}

output "oidc_issuer_url" {
  value = azurerm_kubernetes_cluster.main.oidc_issuer_url
}

output "aks_get_credentials_command" {
  value = "az aks get-credentials --resource-group ${azurerm_resource_group.main.name} --name ${azurerm_kubernetes_cluster.main.name}"
}