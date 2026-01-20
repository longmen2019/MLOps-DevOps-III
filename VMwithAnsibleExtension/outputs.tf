output "resource_group_name" {
  value = azurerm_resource_group.rg.name
}

output "virtual_network_name" {
  value = azurerm_virtual_network.vnet.name
}

output "subnet_id" {
  value = azurerm_subnet.snet.id
}

output "public_ip_address" {
  value = azurerm_public_ip.pip.ip_address
}

output "virtual_machine_id" {
  value = azurerm_linux_virtual_machine.vm.id
}

output "admin_password" {
  value     = azurerm_key_vault_secret.key_vault_secret.value
  sensitive = true
}
