variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "location" {
  type = string
}

variable "location_short" {
  type = string
}

variable "owner" {
  type = string
}

variable "dns_zone_name" {
  type = string
}

variable "node_vm_size" {
  type = string
}

variable "node_count" {
  type = number
}

variable "os_disk_size_gb" {
  type = number
}

variable "kubernetes_version" {
  type    = string
  default = null
}

variable "external_dns_namespace" {
  type    = string
  default = "external-dns"
}

variable "external_dns_service_account_name" {
  type    = string
  default = "external-dns"
}

variable "acr_name" {
  type = string
}