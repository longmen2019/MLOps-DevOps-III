# variable "subscription_id" {
#   description = "Azure Subscription ID to deploy resources into"
#   type        = string
# }

variable "location" {
  description = "Azure region to deploy resources into"
  type        = string
  default     = "UK South"
}