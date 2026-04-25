# Enable this after you create a Terraform backend storage account.
#
# terraform {
#   backend "azurerm" {
#     resource_group_name  = "rg-tfstate-cloud-k8s-lab-aus-01"
#     storage_account_name = "REPLACE_WITH_STORAGE_ACCOUNT_NAME"
#     container_name       = "tfstate"
#     key                  = "aks/dev/terraform.tfstate"
#     use_azuread_auth     = true
#   }
# }