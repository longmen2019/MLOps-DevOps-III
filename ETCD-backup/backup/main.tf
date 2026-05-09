resource "kubernetes_namespace_v1" "backup" {
  metadata {
    name = var.namespace
  }
}

resource "kubernetes_persistent_volume_claim_v1" "backup" {
  metadata {
    name      = var.pvc_name
    namespace = kubernetes_namespace_v1.backup.metadata[0].name
  }

  spec {
    access_modes = ["ReadWriteOnce"]

    resources {
      requests = {
        storage = var.storage_size
      }
    }

    storage_class_name = var.storage_class_name
  }
}

# resource "kubernetes_config_map_v1" "backup_script" {
#   metadata {
#     name      = "etcd-backup-script"
#     namespace = kubernetes_namespace_v1.backup.metadata[0].name
#   }

#   data = {
#     "backup.sh" = <<-EOT
#       #!/bin/sh
#       set -e

#       echo "Running etcd backup..."
#       # TODO: Replace with your etcdctl snapshot command
#       echo "Backup complete."
#     EOT
#   }
# }

resource "kubernetes_cron_job_v1" "etcd_backup" {
  metadata {
    name      = "etcd-backup-cron"
    namespace = kubernetes_namespace_v1.backup.metadata[0].name
  }

  spec {
    schedule = "0 * * * *" # every hour

    job_template {
      metadata {
        name = "etcd-backup-job"
      }

      spec {
        template {
          metadata {
            labels = {
              app = "etcd-backup"
            }
          }

          spec {
            restart_policy = "OnFailure"

            container {
              name  = "etcd-backup"
              image = "bitnami/etcd:latest"

              command = ["/bin/sh", "-c", "chmod +x /scripts/backup.sh && /scripts/backup.sh"]

              env {
                name  = "ETCD_ENDPOINTS"
                value = "https://etcd:2379"
              }

              env {
                name  = "MINIO_ENDPOINT"
                value = "https://minio.example.com"
              }

              env {
                name = "MINIO_BUCKET"
                value = "etcd-backups"
              }

              env {
                name = "RETENTION_DAYS"
                value = "7"
              }

              env_from {
                secret_ref {
                  name = "minio-credentials"
                }
              }

              volume_mount {
                name       = "backup-storage"
                mount_path = "/backup"
              }

              volume_mount {
                name       = "backup-script"
                mount_path = "/scripts"
              }

              volume_mount {
                name       = "etcd-certs"
                mount_path = "/certs"
                read_only  = true
              }
            }

            volume {
              name = "backup-storage"

              persistent_volume_claim {
                claim_name = kubernetes_persistent_volume_claim_v1.backup.metadata[0].name
              }
            }

            volume {
              name = "backup-script"

              config_map {
                name         = kubernetes_config_map_v1.backup_script.metadata[0].name
                default_mode = "0700"
              }
            }

            volume {
              name = "etcd-certs"

              secret {
                secret_name = "etcd-tls"
              }
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_config_map_v1" "backup_script" {
  metadata {
    name      = "etcd-backup-script"
    namespace = kubernetes_namespace_v1.backup.metadata[0].name
  }

  data = {
    "backup.sh" = <<-EOT
      #!/bin/sh
      set -euo pipefail

      echo "[etcd-backup] Starting backup at $(date -Iseconds)"

      # ---------- Config & sanity checks ----------
      : "$${ETCD_ENDPOINTS:?ETCD_ENDPOINTS is required}"
      : "$${MINIO_ENDPOINT:?MINIO_ENDPOINT is required}"
      : "$${MINIO_BUCKET:?MINIO_BUCKET is required}"
      : "$${RETENTION_DAYS:?RETENTION_DAYS is required}"
      : "$${MINIO_ACCESS_KEY:?MINIO_ACCESS_KEY is required}"
      : "$${MINIO_SECRET_KEY:?MINIO_SECRET_KEY is required}"

      BACKUP_DIR="/backup"
      CERT_DIR="/certs"
      ETCDCTL_API=3
      export ETCDCTL_API

      CA_CERT="$${CERT_DIR}/ca.crt"
      CLIENT_CERT="$${CERT_DIR}/etcd-client.crt"
      CLIENT_KEY="$${CERT_DIR}/etcd-client.key"

      TS="$(date +%Y%m%d-%H%M%S)"
      SNAPSHOT_FILE="$${BACKUP_DIR}/etcd-snapshot-$${TS}.db"
      ARCHIVE_FILE="$${BACKUP_DIR}/etcd-snapshot-$${TS}.tar.gz"

      echo "[etcd-backup] Snapshot file: $${SNAPSHOT_FILE}"

      etcdctl \
        --endpoints="$${ETCD_ENDPOINTS}" \
        --cacert="$${CA_CERT}" \
        --cert="$${CLIENT_CERT}" \
        --key="$${CLIENT_KEY}" \
        snapshot save "$${SNAPSHOT_FILE}"

      etcdctl snapshot status "$${SNAPSHOT_FILE}"

      tar -czf "$${ARCHIVE_FILE}" -C "$${BACKUP_DIR}" "$(basename "$${SNAPSHOT_FILE}")"

      mc alias set etcd-minio "$${MINIO_ENDPOINT}" "$${MINIO_ACCESS_KEY}" "$${MINIO_SECRET_KEY}"

      REMOTE_PATH="etcd-minio/$${MINIO_BUCKET}/etcd/$${TS}/$(basename "$${ARCHIVE_FILE}")"

      mc cp "$${ARCHIVE_FILE}" "$${REMOTE_PATH}"

      find "$${BACKUP_DIR}" -type f -name "etcd-snapshot-*.tar.gz" -mtime +"$${RETENTION_DAYS}" -print -delete

      mc find "etcd-minio/$${MINIO_BUCKET}/etcd" \
        --older-than "$${RETENTION_DAYS}d" \
        --exec "mc rm {}"

      echo "[etcd-backup] Backup finished successfully at $(date -Iseconds)"
    EOT
  }
}

resource "kubernetes_secret_v1" "etcd_tls" {
  metadata {
    name      = "etcd-tls"
    namespace = kubernetes_namespace_v1.backup.metadata[0].name
  }

  data = {
    "ca.crt"           = filebase64("${path.module}/certs/ca.crt")
    "etcd-client.crt"  = filebase64("${path.module}/certs/etcd-client.crt")
    "etcd-client.key"  = filebase64("${path.module}/certs/etcd-client.key")
  }

  type = "Opaque"
}
