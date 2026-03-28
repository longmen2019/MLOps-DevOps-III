output "resource_group_name" {
  value = azurerm_resource_group.demo_rg.name
}

output "log_analytics_workspace_id" {
  value = azurerm_log_analytics_workspace.demo_law.id
}

output "key_vault_name" {
  value = azurerm_key_vault.demo_kv.name
}

output "storage_account_name" {
  value = azurerm_storage_account.demo_sa.name
}