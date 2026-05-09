output "remote_storage_summary" {
  description = "Human-readable summary of remote storage configuration for ETCD backups."

  value = trimspace(join(" ", [
    local.s3_enabled ? "S3 bucket ${aws_s3_bucket.etcd_backups[0].bucket} in ${var.s3_bucket_region} with 30-day lifecycle." : "",
    local.azure_enabled ? "Azure container ${var.azure_container_name} in storage account ${var.azure_storage_account_name} (resource group ${var.azure_resource_group})." : "",
    (!local.s3_enabled && !local.azure_enabled) ? "No remote storage configured." : ""
  ]))
}
