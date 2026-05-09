variable "cluster_name" {
  type        = string
  description = "Logical name of the Kubernetes cluster."
}

variable "namespace" {
  type        = string
  default     = "etcd-backup"
}

variable "kubeconfig_path" {
  type        = string
  default     = "~/.kube/config"
}

variable "kubeconfig_context" {
  type        = string
  default     = ""
}

variable "etcd_endpoints" {
  type        = list(string)
  description = "ETCD endpoints."
}

variable "etcd_cert_file" {
  type        = string
  default     = "/etc/etcd/pki/etcd-client.crt"
}

variable "etcd_key_file" {
  type        = string
  default     = "/etc/etcd/pki/etcd-client.key"
}

variable "etcd_ca_file" {
  type        = string
  default     = "/etc/etcd/pki/ca.crt"
}

variable "backup_schedule" {
  type        = string
  default     = "0 */6 * * *"
}

variable "backup_retention" {
  type        = number
  default     = 14
}

variable "backup_pvc_size" {
  type        = string
  default     = "10Gi"
}

variable "backup_storage_class" {
  type        = string
  default     = ""
}

variable "image" {
  type        = string
  default     = "bitnami/etcd:3.5.12"
}

variable "node_selector" {
  type = map(string)
  default = {
    "node-role.kubernetes.io/control-plane" = "true"
  }
}

variable "tolerations" {
  type = list(object({
    key      = string
    operator = string
    value    = string
    effect   = string
  }))
  default = [
    {
      key      = "node-role.kubernetes.io/control-plane"
      operator = "Exists"
      value    = ""
      effect   = "NoSchedule"
    }
  ]
}

variable "labels" {
  type    = map(string)
  default = {}
}

variable "annotations" {
  type    = map(string)
  default = {}
}

# -------------------------
# Azure‑only remote storage
# -------------------------

variable "enable_azure" {
  type        = bool
  default     = false
}

variable "azure_resource_group" {
  type        = string
  default     = "rg-etcd"
}

variable "location" {
  type        = string
  default     = "eastus"
  description = "Azure region for the resource group and storage account."
}


variable "azure_storage_account_name" {
  type        = string
  default     = ""
}

variable "azure_container_name" {
  type        = string
  default     = ""
}

# Slack alerting
variable "enable_slack_alerts" {
  type    = bool
  default = false
}

variable "slack_webhook_url" {
  type      = string
  default   = ""
  sensitive = true
}

variable "alert_channel" {
  type    = string
  default = "#etcd-backups"
}

