output "vm_public_ip" {
  value = azurerm_public_ip.vm_pip.ip_address
}

output "sentinel_workspace_id" {
  value = azurerm_log_analytics_workspace.law.id
}

output "vm_private_ip" {
  value = azurerm_network_interface.nic.private_ip_address
}
