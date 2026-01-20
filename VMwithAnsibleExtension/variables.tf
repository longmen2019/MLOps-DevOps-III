#########################################################
#RESOURCE GROUP
#########################################################

variable "resource_group_name" {
  description = "Name of the Azure Resource Group"
  type        = string
}

variable "location" {
  description = "Azure region where the Resource Group will be created"
  type        = string
  default     = "East US"  # Optional: set a default
}

variable "environment_tag" {
  description = "Tag to specify the environment (e.g., dev, prod)"
  type        = string
  default     = "dev"  # Optional: set a default
}

#########################################################
#VIRTUAL NETWORK
#########################################################

variable "virtual_network_name" {
  description = "Name of the Azure Virtual Network"
  type        = string
}

variable "address_space" {
  description = "Address space for the Virtual Network (e.g., [\"10.0.0.0/16\"])"
  type        = list(string)
}

#########################################################
#SUBNET 
#########################################################

variable "subnet_name" {
  description = "Name of the Azure Subnet"
  type        = string
}

variable "address_prefixes" {
  description = "List of address prefixes for the subnet (e.g., [\"10.0.1.0/24\"])"
  type        = list(string)
}

#########################################################
#NETWORK SECURITY GROUP 
#########################################################

variable "network_security_group_name" {
  description = "Name of the Azure Network Security Group"
  type        = string
}

#########################################################
#KEY VAULT
#########################################################

variable "key_vault_name" {
  description = "Name of the Azure Key Vault"
  type        = string
}
#########################################################
#KEY VAULT SECRET 
#########################################################

variable "key_vault_secret_name" {
  description = "Name of the secret to store in Key Vault"
  type        = string
}

#########################################################
#PUBLIC IP
#########################################################

variable "public_ip_name" {
  description = "Name of the public IP resource"
  type        = string
}

#########################################################
#NETWORK INTERFACE 
#########################################################

variable "network_interface_name" {
  description = "Name of the network interface"
  type        = string
}

#########################################################
#VIRTUAL MACHINE
#########################################################

variable "virtual_machine_name" {
  description = "Name of the Linux virtual machine"
  type        = string
}

variable "vm_size" {
  description = "Size of the virtual machine"
  type        = string
  default     = "Standard_DS1_v2"
}

variable "admin_username" {
  description = "Admin username for the virtual machine"
  type        = string
}