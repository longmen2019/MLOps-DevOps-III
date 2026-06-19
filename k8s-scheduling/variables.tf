variable "cluster_name" {
  type        = string
  description = "AKS cluster name"
  default     = "k8s-scheduling"
}

variable "location" {
  type        = string
  description = "Azure region"
  default     = "eastus2"
}

variable "resource_group_name" {
  type        = string
  description = "Resource group for AKS"
  default     = "rg-k8s-scheduling"
}

variable "k8s_version" {
  type        = string
  description = "Kubernetes version for AKS"
  default     = "1.35.4"
}
