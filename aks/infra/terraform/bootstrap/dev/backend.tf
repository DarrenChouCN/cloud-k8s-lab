terraform {
  backend "azurerm" {
    resource_group_name  = "rg-tfstate-cloud-k8s-lab-ause-01"
    storage_account_name = "tfstatek8s074074"
    container_name       = "tfstate"
    key                  = "aks/bootstrap/dev/terraform.tfstate"
    use_azuread_auth     = true
  }
}