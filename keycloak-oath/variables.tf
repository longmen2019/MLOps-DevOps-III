variable "project_name" {
  type    = string
  default = "keycloak-aks"
}

variable "location" {
  type    = string
  default = "eastus2"
}

variable "node_count" {
  type    = number
  default = 1
}

variable "node_vm_size" {
  type    = string
  default = "Standard_B4ms" # fallback to B2ms/B2s if quota is low
}
