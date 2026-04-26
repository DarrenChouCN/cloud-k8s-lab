variable "subscription_id" {
  description = "Azure subscription ID used by Terraform."
  type        = string
}

variable "project_name" {
  description = "Project name used in resource naming."
  type        = string
}

variable "environment" {
  description = "Environment name, such as dev, test, or prod."
  type        = string
}

variable "location" {
  description = "Azure region."
  type        = string
}

variable "location_short" {
  description = "Short region code used in resource names."
  type        = string
}

variable "owner" {
  description = "Resource owner tag."
  type        = string
}

variable "dns_zone_name" {
  description = "Azure DNS zone name for AKS apps."
  type        = string
}

variable "node_vm_size" {
  description = "VM size for the default AKS node pool."
  type        = string
}

variable "node_count" {
  description = "Initial node count."
  type        = number
}

variable "os_disk_size_gb" {
  description = "OS disk size for AKS nodes."
  type        = number
}

variable "kubernetes_version" {
  description = "AKS Kubernetes version. Leave null to use Azure default."
  type        = string
  default     = null
}

variable "acr_name" {
  description = "Azure Container Registry name. Must be globally unique and contain only lowercase letters and numbers."
  type        = string
}