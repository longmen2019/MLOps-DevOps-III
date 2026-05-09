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
      : "${ETCD_ENDPOINTS:?ETCD_ENDPOINTS is required}"
      : "${MINIO_ENDPOINT:?MINIO_ENDPOINT is required}"
      : "${MINIO_BUCKET:?MINIO_BUCKET is required}"
      : "${RETENTION_DAYS:?RETENTION_DAYS is required}"
      : "${MINIO_ACCESS_KEY:?MINIO_ACCESS_KEY is required}"
      : "${MINIO_SECRET_KEY:?MINIO_SECRET_KEY is required}"

      BACKUP_DIR="/backup"
      CERT_DIR="/certs"
      ETCDCTL_API=3
      export ETCDCTL_API

      CA_CERT="${CERT_DIR}/ca.crt"
      CLIENT_CERT="${CERT_DIR}/etcd-client.crt"
      CLIENT_KEY="${CERT_DIR}/etcd-client.key"

      TS="$(date +%Y%m%d-%H%M%S)"
      SNAPSHOT_FILE="${BACKUP_DIR}/etcd-snapshot-${TS}.db"
      ARCHIVE_FILE="${BACKUP_DIR}/etcd-snapshot-${TS}.tar.gz"

      echo "[etcd-backup] Snapshot file: ${SNAPSHOT_FILE}"

      etcdctl \
        --endpoints="${ETCD_ENDPOINTS}" \
        --cacert="${CA_CERT}" \
        --cert="${CLIENT_CERT}" \
        --key="${CLIENT_KEY}" \
        snapshot save "${SNAPSHOT_FILE}"

      etcdctl snapshot status "${SNAPSHOT_FILE}"

      tar -czf "${ARCHIVE_FILE}" -C "${BACKUP_DIR}" "$(basename "${SNAPSHOT_FILE}")"

      mc alias set etcd-minio "${MINIO_ENDPOINT}" "${MINIO_ACCESS_KEY}" "${MINIO_SECRET_KEY}"

      REMOTE_PATH="etcd-minio/${MINIO_BUCKET}/etcd/${TS}/$(basename "${ARCHIVE_FILE}")"

      mc cp "${ARCHIVE_FILE}" "${REMOTE_PATH}"

      find "${BACKUP_DIR}" -type f -name "etcd-snapshot-*.tar.gz" -mtime +"${RETENTION_DAYS}" -print -delete

      mc find "etcd-minio/${MINIO_BUCKET}/etcd" \
        --older-than "${RETENTION_DAYS}d" \
        --exec "mc rm {}"

      echo "[etcd-backup] Backup finished successfully at $(date -Iseconds)"
    EOT
  }
}
