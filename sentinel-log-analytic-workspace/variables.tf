variable "resource_group_name" {
  type        = string
  description = "Name of the Azure resource group"
}

variable "location" {
  type        = string
  description = "Azure region for the deployment"
  default     = "East US"

  validation {
    condition = contains([
      "East US",
      "West US",
      "Central US",
      "North Europe",
      "West Europe",
      "Southeast Asia",
      "Australia East",
      "Japan East"
    ], var.location)

    error_message = "The location must be one of the approved Azure regions."
  }
}

variable "log_analytics_workspace_name" {
  type        = string
  description = "Name of the Log Analytics workspace"
}

variable "management_group_name" {
  description = "The name of the management group."
  type        = string
}

variable "management_group_display_name" {
  description = "The display name of the management group."
  type        = string
}

variable "subscription_id" {
  description = "The subscription ID to associate with the management group."
  type        = string
}

variable "admin_password" {
  description = "Admin password for the Linux VM"
  type        = string
  sensitive   = true

  validation {
    condition = length(var.admin_password) >= 12
    error_message = "The admin password must be at least 12 characters long."
  }
}
