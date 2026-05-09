variable "location" {
  type        = string
  description = "Azure region"
  default     = "eastus"
}

variable "azure_resource_group" {
  type        = string
  description = "Resource group for AKS"
  default     = "rg-etcd"
}

variable "aks_name" {
  type        = string
  description = "AKS cluster name"
  default     = "etcd-aks"
}
