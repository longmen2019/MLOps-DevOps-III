variable "location" {
  type        = string
  default     = "eastus"
  description = "Azure region"
}

variable "kubernetes_version" {
  type        = string
  default     = "1.35.4"
  description = "AKS Kubernetes version (pick one available in your region)"
}

variable "node_vm_size" {
  type        = string
  default     = "Standard_B2s" # cheap enough for student subscription
  description = "VM size for AKS nodes"
}

variable "node_count" {
  type        = number
  default     = 1
  description = "Node count for AKS"
}
