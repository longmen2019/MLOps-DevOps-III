// Private IP of control-plane node
output "cp_private_ip" {
  description = "Private IP of control-plane node"
  value       = azurerm_linux_virtual_machine.cp.private_ip_address
}

// Private IPs of worker nodes
output "worker_private_ips" {
  description = "Private IPs of worker nodes"
  value = [
    azurerm_linux_virtual_machine.worker1.private_ip_address,
    azurerm_linux_virtual_machine.worker2.private_ip_address
  ]
}

// Public IP of control-plane node
output "cp_public_ip" {
  description = "Public IP of control-plane node"
  value       = azurerm_public_ip.cp_pip.ip_address
}

// Public IP of jump host
output "jump_public_ip" {
  description = "Public IP of the jump host"
  value       = azurerm_public_ip.jump_pip.ip_address
}

// Worker nodes have no public IPs anymore
output "worker_public_ips" {
  description = "Workers do not have public IPs"
  value       = []
}

// Rendered Ansible inventory content
output "inventory_ini" {
  description = "Kubespray-style Ansible inventory"
  value       = local.inventory
}
