variable "cluster_name" {
  type        = string
  description = "Logical name of the cluster (used for naming and tagging)."
}

variable "enable_s3" {
  type        = bool
  description = "Whether to create an S3 bucket for ETCD backups."
  default     = false
}

variable "s3_bucket_name" {
  type        = string
  description = "Name of the S3 bucket to create/use for ETCD backups."
  default     = ""
}

variable "s3_bucket_region" {
  type        = string
  description = "Region for the S3 bucket."
  default     = "us-east-1"
}

variable "enable_azure" {
  type        = bool
  description = "Whether to create Azure storage resources for ETCD backups."
  default     = false
}

variable "azure_resource_group" {
  type        = string
  description = "Azure resource group for the storage account."
  default     = ""
}

variable "azure_storage_account_name" {
  type        = string
  description = "Azure storage account name for ETCD backups."
  default     = ""
}

variable "azure_container_name" {
  type        = string
  description = "Azure Blob container name for ETCD backups."
  default     = ""
}
