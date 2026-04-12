// Prefix for all resource names
variable "prefix" {
  type        = string
  description = "Prefix for Azure resources"
  default     = "mini-kubespray"
}

// Azure region (West Europe)
variable "location" {
  type        = string
  description = "Azure region"
  default     = "westeurope"
}

// Admin username for SSH
variable "admin_username" {
  type        = string
  description = "Admin username for VMs"
  default     = "azureuser"
}

// SSH public key for VM access
variable "ssh_public_key" {
  type        = string
  description = "SSH public key for admin user"
}

// VM size for control-plane node
variable "vm_size_cp" {
  type        = string
  description = "VM size for control-plane node"
  default     = "Standard_B2s"   // 2 vCPUs
}

// VM size for worker node 1
variable "vm_size_worker1" {
  type        = string
  description = "VM size for worker node 1"
  default     = "Standard_B1ms"  // 1 vCPU
}

// VM size for worker node 2
variable "vm_size_worker2" {
  default = "Standard_F1s"
}


// VM size for jump host
variable "vm_size_jump" {
  type        = string
  description = "VM size for jump host"
  default     = "Standard_B1s"   // 1 vCPU
}

// Resource group for main cluster
variable "resource_group" {
  type        = string
  description = "Name of the resource group"
  default     = "mult-node-kube-clustter-kubeadm"
}

// Tags
variable "tags" {
  type        = map(string)
  description = "Tags to apply to all resources"
  default = {
    environment = "dev"
    project     = "mini-kubespray"
  }
}

// VNET name
variable "vnet_name" {
  type        = string
  description = "Name of the virtual network"
  default     = "mini-kubespray-vnet"
}

// VNET address space
variable "vnet_address_space" {
  type        = list(string)
  description = "Address space for the virtual network"
  default     = ["10.10.0.0/16"]
}

// Subnet name
variable "subnet_name" {
  type        = string
  description = "Name of the subnet"
  default     = "mini-kubespray-subnet"
}

// Subnet CIDR
variable "subnet_prefix" {
  type        = string
  description = "Subnet CIDR prefix"
  default     = "10.10.1.0/24"
}
