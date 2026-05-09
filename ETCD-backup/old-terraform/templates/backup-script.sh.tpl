#!/usr/bin/env bash
set -euo pipefail

CLUSTER_NAME="${cluster_name}"

ETCD_ENDPOINTS="${etcd_endpoints}"
ETCD_CERT_FILE="${etcd_cert_file}"
ETCD_KEY_FILE="${etcd_key_file}"
ETCD_CA_FILE="${etcd_ca_file}"

BACKUP_DIR="/var/backups/etcd"
BACKUP_RETENTION="${backup_retention}"

ENABLE_AZURE="${enable_azure}"
AZURE_STORAGE_ACCOUNT="${azure_storage_account}"
AZURE_CONTAINER_NAME="${azure_container_name}"

ENABLE_SLACK_ALERTS="${enable_slack_alerts}"
SLACK_WEBHOOK_URL="${slack_webhook_url}"
ALERT_CHANNEL="${alert_channel}"

timestamp() { date -u +"%Y-%m-%dT%H:%M:%SZ"; }

log() { echo "$(timestamp) [etcd-backup] $*"; }

notify_slack() {
  [[ "$ENABLE_SLACK_ALERTS" != "true" ]] && return 0
  curl -sS -X POST -H 'Content-type: application/json' \
    --data "{\"text\": \"[${cluster_name}] $1\"}" \
    "$SLACK_WEBHOOK_URL" >/dev/null || true
}

preflight() {
  command -v etcdctl >/dev/null || { log "etcdctl missing"; exit 1; }
  mkdir -p "$BACKUP_DIR"
}

take_snapshot() {
  ts="$(date -u +%Y%m%d-%H%M%S)"
  file="$BACKUP_DIR/etcd-snapshot-$ts.db"
  ETCDCTL_API=3 etcdctl \
    --endpoints="$ETCD_ENDPOINTS" \
    --cert="$ETCD_CERT_FILE" \
    --key="$ETCD_KEY_FILE" \
    --cacert="$ETCD_CA_FILE" \
    snapshot save "$file"
  gzip -f "$file"
  echo "$file.gz"
}

upload_azure() {
  [[ "$ENABLE_AZURE" != "true" ]] && return 0
  az storage blob upload \
    --account-name "$AZURE_STORAGE_ACCOUNT" \
    --container-name "$AZURE_CONTAINER_NAME" \
    --file "$1" \
    --name "$(basename "$1")" \
    --only-show-errors
}

prune_local() {
  mapfile -t files < <(ls -1t "$BACKUP_DIR"/etcd-snapshot-*.gz 2>/dev/null || true)
  for ((i=BACKUP_RETENTION; i< $${#files[@]}; i++)); do
    rm -f "$${files[$i]}"
  done
}

main() {
  preflight
  file="$(take_snapshot)"
  upload_azure "$file"
  prune_local
  log "Backup complete"
}

main "$@"
