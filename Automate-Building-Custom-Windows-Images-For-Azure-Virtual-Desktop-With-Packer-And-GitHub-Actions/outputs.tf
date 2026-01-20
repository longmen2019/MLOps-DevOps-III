# output "resource_group_name" {
#   description = "Name of the resource group created for the VMSS deployment."
#   value       = data.azurerm_resource_group.vmss.name
# }

# output "vmss_name" {
#   description = "Name of the Virtual Machine Scale Set."
#   value       = azurerm_virtual_machine_scale_set.vmss.name
# }

# output "vmss_lb_public_ip" {
#   description = "Public IP address of the VMSS load balancer."
#   value       = azurerm_public_ip.vmss.ip_address
# }

# output "jumpbox_public_ip" {
#   description = "Public IP address of the jumpbox VM."
#   value       = azurerm_public_ip.jumpbox.ip_address
# }

# output "ssh_public_key" {
#   description = "Generated SSH public key used for VMSS and jumpbox."
#   value       = azapi_resource_action.ssh_public_key_gen.output.publicKey
# }

# output "ssh_private_key" {
#   description = "Generated SSH private key (sensitive)."
#   value       = azapi_resource_action.ssh_public_key_gen.output.privateKey
#   sensitive   = true
# }

# output "packer_image_id" {
#   description = "ID of the Packer-built managed image used by the VMSS."
#   value       = data.azurerm_image.image.id
# }
