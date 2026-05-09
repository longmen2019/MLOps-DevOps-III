variable "enable_azure" {
  type    = bool
  default = false
}

variable "azure_resource_group" {
  type    = string
  default = ""
}

variable "azure_storage_account_name" {
  type    = string
  default = ""
}

variable "azure_container_name" {
  type    = string
  default = ""
}

variable "cluster_name" {
  type = string
}
