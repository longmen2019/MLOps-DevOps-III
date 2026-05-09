output "backup_namespace" {
  value = var.namespace
}

output "backup_pvc_name" {
  value = local.pvc_name
}

output "backup_cronjob_name" {
  value = kubernetes_cron_job_v1.etcd_backup.metadata[0].name
}

output "backup_schedule" {
  value = kubernetes_cron_job_v1.etcd_backup.spec[0].schedule
}

output "remote_storage_summary" {
  value = module.azure_backup_storage.remote_storage_summary
}
