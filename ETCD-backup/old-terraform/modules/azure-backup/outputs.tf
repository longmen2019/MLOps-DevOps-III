output "remote_storage_summary" {
  value = (
    local.azure_enabled ?
    "Azure Blob container ${var.azure_container_name} in storage account ${var.azure_storage_account_name} (RG: ${var.azure_resource_group})" :
    "No Azure remote storage configured."
  )
}

