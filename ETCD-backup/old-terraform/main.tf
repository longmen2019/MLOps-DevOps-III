locals {
  common_labels = merge(
    {
      "app.kubernetes.io/name"       = "etcd-backup"
      "app.kubernetes.io/component"  = "backup"
      "app.kubernetes.io/managed-by" = "terraform"
      "app.kubernetes.io/part-of"    = var.cluster_name
    },
    var.labels
  )
}


module "azure_backup_storage" {
  source = "./modules/azure-backup"

  enable_azure              = var.enable_azure
  azure_resource_group      =  var.azure_resource_group
  azure_storage_account_name = var.azure_storage_account_name
  azure_container_name       = var.azure_container_name
  cluster_name               = var.cluster_name
}

resource "kubernetes_namespace_v1" "backup" {
  metadata {
    name        = var.namespace
    labels      = local.common_labels
    annotations = var.annotations
  }
}

resource "kubernetes_service_account_v1" "backup" {
  metadata {
    name      = "etcd-backup-sa"
    namespace = var.namespace
    labels    = local.common_labels
  }
}

resource "kubernetes_cluster_role_v1" "backup" {
  metadata {
    name   = "etcd-backup-role"
    labels = local.common_labels
  }

  rule {
    api_groups = [""]
    resources  = ["pods", "pods/log", "nodes"]
    verbs      = ["get", "list", "watch"]
  }
}

resource "kubernetes_cluster_role_binding_v1" "backup" {
  metadata {
    name   = "etcd-backup-binding"
    labels = local.common_labels
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role_v1.backup.metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account_v1.backup.metadata[0].name
    namespace = var.namespace
  }
}

resource "kubernetes_persistent_volume_claim_v1" "backup" {
  metadata {
    name      = "etcd-backup-pvc"
    namespace = var.namespace
    labels    = local.common_labels
  }

  spec {
    access_modes = ["ReadWriteOnce"]

    resources {
      requests = {
        storage = var.backup_pvc_size
      }
    }

    # Only set storage_class_name if user provided one
    storage_class_name = var.backup_storage_class != "" ? var.backup_storage_class : null
  }
}


locals {
  pvc_name = kubernetes_persistent_volume_claim_v1.backup.metadata[0].name
}

resource "kubernetes_config_map_v1" "backup_script" {
  metadata {
    name      = "etcd-backup-script"
    namespace = var.namespace
    labels    = local.common_labels
  }

  data = {
    "etcd-backup.sh" = templatefile("${path.module}/templates/backup-script.sh.tpl", {
      cluster_name          = var.cluster_name
      etcd_endpoints        = join(",", var.etcd_endpoints)
      etcd_cert_file        = var.etcd_cert_file
      etcd_key_file         = var.etcd_key_file
      etcd_ca_file          = var.etcd_ca_file
      backup_retention      = var.backup_retention
      enable_azure          = var.enable_azure
      azure_storage_account = var.azure_storage_account_name
      azure_container_name  = var.azure_container_name
      enable_slack_alerts   = var.enable_slack_alerts
      slack_webhook_url     = var.slack_webhook_url
      alert_channel         = var.alert_channel
    })
  }
}

resource "kubernetes_cron_job_v1" "etcd_backup" {
  metadata {
    name      = "etcd-backup"
    namespace = var.namespace
    labels    = local.common_labels
  }

  spec {
    schedule                   = var.backup_schedule
    concurrency_policy         = "Forbid"
    successful_jobs_history_limit = 3
    failed_jobs_history_limit     = 3

    job_template {
      metadata {
        labels = local.common_labels
      }

      spec {
        backoff_limit = 1

        template {
          metadata {
            labels = local.common_labels
          }

          spec {
            service_account_name = kubernetes_service_account_v1.backup.metadata[0].name
            restart_policy       = "OnFailure"

            node_selector = var.node_selector

            dynamic "toleration" {
              for_each = var.tolerations
              content {
                key      = toleration.value.key
                operator = toleration.value.operator
                value    = toleration.value.value
                effect   = toleration.value.effect
              }
            }

            container {
              name  = "etcd-backup"
              image = var.image

              command = ["/bin/bash", "/scripts/etcd-backup.sh"]

              env {
                name  = "ETCD_ENDPOINTS"
                value = join(",", var.etcd_endpoints)
              }

              env {
                name  = "ENABLE_AZURE"
                value = var.enable_azure ? "true" : "false"
              }

              env {
                name  = "AZURE_STORAGE_ACCOUNT"
                value = var.azure_storage_account_name
              }

              env {
                name  = "AZURE_CONTAINER_NAME"
                value = var.azure_container_name
              }

              volume_mount {
                name       = "backup-storage"
                mount_path = "/var/backups/etcd"
              }

              volume_mount {
                name       = "backup-script"
                mount_path = "/scripts"
              }
            }

            volume {
              name = "backup-storage"

              persistent_volume_claim {
                claim_name = local.pvc_name
              }
            }

            volume {
              name = "backup-script"

              config_map {
                name = kubernetes_config_map_v1.backup_script.metadata[0].name

                items {
                  key  = "etcd-backup.sh"
                  path = "etcd-backup.sh"
                }
              }
            }
          }
        }
      }
    }
  }
}
