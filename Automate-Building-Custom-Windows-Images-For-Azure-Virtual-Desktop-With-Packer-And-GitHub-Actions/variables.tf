variable "location" {
  description = "Azure region where all resources will be deployed."
  type        = string
  default     = "northeurope"
}

variable "resource_group_name" {
  description = "Optional name for the resource group. If null, a random name will be generated."
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags to apply to all resources."
  type        = map(string)
  default     = {
    environment = "dev"
    owner       = "long"
  }
}

variable "admin_user" {
  description = "Admin username for the VMSS and jumpbox."
  type        = string
  default     = "azureuser"
}

variable "admin_password" {
  description = "Optional admin password. If null, a random password will be generated."
  type        = string
  default     = null
}

variable "application_port" {
  description = "Port used for the load balancer probe and rule."
  type        = number
  default     = 80
}

variable "packer_resource_group_name" {
  description = "Resource group where the Packer-built image is stored."
  type        = string
  default = "myPackerImages"
}

variable "packer_image_name" {
  description = "Name of the Packer-built managed image."
  type        = string
  default = "myPackerImage"
}
