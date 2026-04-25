resource "azurerm_resource_group" "main" {
  name     = local.resource_group_name
  location = var.location

  tags = local.tags
}

resource "azurerm_dns_zone" "aks" {
  name                = var.dns_zone_name
  resource_group_name = azurerm_resource_group.main.name

  tags = local.tags
}

resource "azurerm_user_assigned_identity" "external_dns" {
  name                = local.external_dns_identity_name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  tags = local.tags
}

resource "azurerm_role_assignment" "external_dns_zone_contributor" {
  scope                = azurerm_dns_zone.aks.id
  role_definition_name = "DNS Zone Contributor"
  principal_id         = azurerm_user_assigned_identity.external_dns.principal_id
}

resource "azurerm_kubernetes_cluster" "main" {
  name                = local.aks_cluster_name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  dns_prefix          = local.aks_dns_prefix
  kubernetes_version  = var.kubernetes_version
  sku_tier            = "Free"

  oidc_issuer_enabled       = true
  workload_identity_enabled = true

  role_based_access_control_enabled = true

  default_node_pool {
    name            = "sysnp"
    node_count      = var.node_count
    vm_size         = var.node_vm_size
    os_disk_size_gb = var.os_disk_size_gb
    type            = "VirtualMachineScaleSets"

    upgrade_settings {
      max_surge = "10%"
    }
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin    = "kubenet"
    load_balancer_sku = "standard"
    outbound_type     = "loadBalancer"
  }

  tags = local.tags
}

resource "azurerm_federated_identity_credential" "external_dns" {
  name                      = local.federated_identity_name
  user_assigned_identity_id = azurerm_user_assigned_identity.external_dns.id

  audience = [
    "api://AzureADTokenExchange"
  ]

  issuer  = azurerm_kubernetes_cluster.main.oidc_issuer_url
  subject = "system:serviceaccount:${var.external_dns_namespace}:${var.external_dns_service_account_name}"
}