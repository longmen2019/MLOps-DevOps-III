variable "namespace" {
  type        = string
  default     = "etcd-backup"
}

variable "pvc_name" {
  type        = string
  default     = "etcd-backup-pvc"
}

variable "storage_size" {
  type        = string
  default     = "10Gi"
}

variable "storage_class_name" {
  type    = string
  default = "azurefile-csi"
}

