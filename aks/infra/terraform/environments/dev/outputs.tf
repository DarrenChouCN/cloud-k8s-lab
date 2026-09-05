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

output "external_dns_gitops_config" {
  description = "Configuration consumed by the ExternalDNS GitOps deployment."

  value = {
    tenant_id = data.azurerm_client_config.current.tenant_id

    subscription_id = data.azurerm_client_config.current.subscription_id

    dns_resource_group_name = module.aks_infra.resource_group_name

    client_id = module.aks_infra.external_dns_client_id

    oidc_issuer_url = module.aks_infra.oidc_issuer_url

    service_account_subject = module.aks_infra.external_dns_service_account_subject
  }
}