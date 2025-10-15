#---------------------------
# Local declarations
#---------------------------
locals {
  nsg_inbound_rules = { for idx, security_rule in var.nsg_inbound_rules : security_rule.name => {
    idx : idx,
    security_rule : security_rule,
    }
  }
}

resource "random_pet" "rg_name" {
  prefix = var.resource_group_name_prefix
}

resource "random_string" "azurerm_analysis_services_server_name" {
  length  = 15
  upper   = false
  numeric = false
  special = false
}

locals {
  should_generate_password = (
    (var.os_flavor == "linux" && var.disable_password_authentication == false && var.admin_password == null) ||
    (var.os_flavor == "windows" && var.admin_password == null)
  )
}

#---------------------------------------------------------------
# Generates SSH2 key Pair for Linux VM's (Dev Environment only)
#---------------------------------------------------------------
resource "tls_private_key" "rsa" {
  count     = var.generate_admin_ssh_key ? 1 : 0
  algorithm = "RSA"
  rsa_bits  = 4096
}

#----------------------------------------------------------
# Resource Group, VNet, Subnet selection & Random Resources
#----------------------------------------------------------

resource "azurerm_resource_group" "rg" {
  name     = "${random_pet.rg_name.id }-rg"
  location = var.resource_group_location
}

resource "azurerm_virtual_network" "vnet" {
  name                = "${random_string.azurerm_analysis_services_server_name.result}-vnet"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["10.0.0.0/16"]
  dns_servers         = ["10.0.0.4", "10.0.0.5"]
}

resource "azurerm_subnet" "snet" {  
  name                 = "${random_string.azurerm_analysis_services_server_name.result}-snet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
  
}

#----------------------------------------------------------
# Storage Account
#----------------------------------------------------------

resource "azurerm_storage_account" "storeacc" {
  name                     = "${random_string.azurerm_analysis_services_server_name.result}"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "GRS"

  tags = var.resource_tags 
}

resource "random_password" "passwd" {
  count       = (var.os_flavor == "linux" && var.disable_password_authentication == false && var.admin_password == null ? 1 : (var.os_flavor == "windows" && var.admin_password == null ? 1 : 0))
  length      = var.random_password_length
  min_upper   = 4
  min_lower   = 2
  min_numeric = 4
  special     = false

  keepers = {
    admin_password = var.vmscaleset_name
  }
}

#-----------------------------------
# Public IP for Load Balancer
#-----------------------------------
resource "azurerm_public_ip" "pip" {
  count               = var.enable_load_balancer == true && var.load_balancer_type == "public" ? 1 : 0
  name                = lower("pip-vm-${var.vmscaleset_name}-${azurerm_resource_group.rg.location}-0${count.index + 1}")
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = var.public_ip_allocation_method
  sku                 = var.public_ip_sku
  sku_tier            = var.public_ip_sku_tier
  domain_name_label   = var.domain_name_label
  tags                = merge({ "resourcename" = lower("pip-vm-${var.vmscaleset_name}-${azurerm_resource_group.rg.location}-0${count.index + 1}") }, var.resource_tags )

  lifecycle {
    ignore_changes = [
      tags,
      ip_tags,
    ]
  }
}

#---------------------------------------
# External Load Balancer with Public IP
#---------------------------------------
resource "azurerm_lb" "vmsslb" {
  count               = var.enable_load_balancer ? 1 : 0
  name                = var.load_balancer_type == "public" ? lower("lbext-${var.vmscaleset_name}-${azurerm_resource_group.rg.location}") : lower("lbint-${var.vmscaleset_name}-${azurerm_resource_group.rg.location}")
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = var.load_balancer_sku
  tags                = merge({ "resourcename" = var.load_balancer_type == "public" ? lower("lbext-${var.vmscaleset_name}-${azurerm_resource_group.rg.location}") : lower("lbint-${var.vmscaleset_name}-${azurerm_resource_group.rg.location}") }, var.resource_tags)

  frontend_ip_configuration {
    name                          = var.load_balancer_type == "public" ? lower("lbext-frontend-${var.vmscaleset_name}") : lower("lbint-frontend-${var.vmscaleset_name}")
    public_ip_address_id          = var.enable_load_balancer == true && var.load_balancer_type == "public" ? azurerm_public_ip.pip[count.index].id : null
    private_ip_address_allocation = var.load_balancer_type == "private" ? var.private_ip_address_allocation_type : null
    private_ip_address            = var.load_balancer_type == "private" && var.private_ip_address_allocation_type == "Static" ? var.lb_private_ip_address : null
    subnet_id                     = var.load_balancer_type == "private" ? azurerm_subnet.snet.id : null
  }

  lifecycle {
    ignore_changes = [
      tags,
    ]
  }
}

#---------------------------------------
# Backend address pool for Load Balancer
#---------------------------------------
resource "azurerm_lb_backend_address_pool" "bepool" {
  count           = var.enable_load_balancer ? 1 : 0
  name            = lower("lbe-backend-pool-${var.vmscaleset_name}")
  loadbalancer_id = azurerm_lb.vmsslb[count.index].id
}

#---------------------------------------
# Load Balancer NAT pool
#---------------------------------------
resource "azurerm_lb_nat_pool" "natpol" {
  count                          = var.enable_load_balancer && var.enable_lb_nat_pool ? 1 : 0
  name                           = lower("lbe-nat-pool-${var.vmscaleset_name}-${azurerm_resource_group.rg.location}")
  resource_group_name            = azurerm_resource_group.rg.name
  loadbalancer_id                = azurerm_lb.vmsslb.0.id
  protocol                       = "Tcp"
  frontend_port_start            = var.nat_pool_frontend_ports[0]
  frontend_port_end              = var.nat_pool_frontend_ports[1]
  backend_port                   = var.os_flavor == "linux" ? 22 : 3389
  frontend_ip_configuration_name = azurerm_lb.vmsslb.0.frontend_ip_configuration.0.name
}

#---------------------------------------
# Health Probe for resources
#---------------------------------------
resource "azurerm_lb_probe" "lbp" {
  count               = var.enable_load_balancer ? 1 : 0
  name                = lower("lb-probe-port-${var.load_balancer_health_probe_port}-${var.vmscaleset_name}")  
  loadbalancer_id     = azurerm_lb.vmsslb[count.index].id
  port                = var.load_balancer_health_probe_port
  protocol            = var.lb_probe_protocol
  request_path        = var.lb_probe_protocol != "Tcp" ? var.lb_probe_request_path : null
  number_of_probes    = var.number_of_probes
}

#--------------------------
# Load Balancer Rules
#--------------------------
resource "azurerm_lb_rule" "lbrule" {
  count                          = var.enable_load_balancer ? length(var.load_balanced_port_list) : 0
  name                           = format("%s-%02d-rule", var.vmscaleset_name, count.index + 1)  
  loadbalancer_id                = azurerm_lb.vmsslb[0].id
  probe_id                       = azurerm_lb_probe.lbp[0].id
  protocol                       = "Tcp"
  frontend_port                  = tostring(var.load_balanced_port_list[count.index])
  backend_port                   = tostring(var.load_balanced_port_list[count.index])
  frontend_ip_configuration_name = azurerm_lb.vmsslb[0].frontend_ip_configuration.0.name
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.bepool[0].id]
}

#----------------------------------------------------------------------------------------------------
# Proximity placement group for virtual machines, virtual machine scale sets and availability sets.
#----------------------------------------------------------------------------------------------------
resource "azurerm_proximity_placement_group" "appgrp" {
  count               = var.enable_proximity_placement_group ? 1 : 0
  name                = lower("proxigrp-${var.vmscaleset_name}-${azurerm_resource_group.rg.location}")
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  tags                = merge({ "resourcename" = lower("proxigrp-${var.vmscaleset_name}-${azurerm_resource_group.rg.location}") }, var.resource_tags)

  lifecycle {
    ignore_changes = [
      tags,
    ]
  }
}

#---------------------------------------------------------------
# Network security group for Virtual Machine Network Interface
#---------------------------------------------------------------
resource "azurerm_network_security_group" "nsg" {
  count               = var.existing_network_security_group_id == null ? 1 : 0
  name                = lower("nsg_${var.vmscaleset_name}_${azurerm_resource_group.rg.location}_in")
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  tags                = merge({ "resourcename" = lower("nsg_${var.vmscaleset_name}_${azurerm_resource_group.rg.location}_in") }, var.resource_tags )

  lifecycle {
    ignore_changes = [
      tags,
    ]
  }
}

resource "azurerm_network_security_rule" "nsg_rule" {
  for_each                    = { for k, v in local.nsg_inbound_rules : k => v if k != null }
  name                        = each.key
  priority                    = 100 * (each.value.idx + 1)
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = each.value.security_rule.destination_port_range
  source_address_prefix       = each.value.security_rule.source_address_prefix
  destination_address_prefix  = element(concat(azurerm_subnet.snet.address_prefixes, [""]), 0)
  description                 = "Inbound_Port_${each.value.security_rule.destination_port_range}"
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.nsg.0.name
  depends_on                  = [azurerm_network_security_group.nsg]
}

#---------------------------------------
# Linux Virutal machine scale set
#---------------------------------------
resource "azurerm_linux_virtual_machine_scale_set" "linux_vmss" {
  count                                             = var.os_flavor == "linux" ? 1 : 0
  name                                              = format("vm%s%s", lower(replace(var.vmscaleset_name, "/[[:^alnum:]]/", "")), count.index + 1)
  computer_name_prefix                              = var.computer_name_prefix == null && var.instances_count == 1 ? substr(var.vmscaleset_name, 0, 9) : substr(format("%s%s", lower(replace(var.vmscaleset_name, "/[[:^alnum:]]/", "")), count.index + 1), 0, 9)
  resource_group_name                               = azurerm_resource_group.rg.name
  location                                          = azurerm_resource_group.rg.location
  sku                                               = var.virtual_machine_size
  instances                                         = var.instances_count
  admin_username                                    = var.admin_username
  admin_password                                    = var.disable_password_authentication == false && var.admin_password == null ? element(concat(random_password.passwd.*.result, [""]), 0) : var.admin_password
  custom_data                                       = var.custom_data
  disable_password_authentication                   = var.disable_password_authentication
  overprovision                                     = var.overprovision
  do_not_run_extensions_on_overprovisioned_machines = var.do_not_run_extensions_on_overprovisioned_machines
  encryption_at_host_enabled                        = var.enable_encryption_at_host
  health_probe_id                                   = var.enable_load_balancer ? azurerm_lb_probe.lbp[0].id : null
  platform_fault_domain_count                       = var.platform_fault_domain_count
  provision_vm_agent                                = true
  proximity_placement_group_id                      = var.enable_proximity_placement_group ? azurerm_proximity_placement_group.appgrp.0.id : null  
  single_placement_group                            = var.single_placement_group
  source_image_id                                   = var.source_image_id != null ? var.source_image_id : null
  upgrade_mode                                      = var.os_upgrade_mode
  zones                                             = var.availability_zones
  zone_balance                                      = var.availability_zone_balance
  tags                                              = merge({ "resourcename" = format("vm%s%s", lower(replace(var.vmscaleset_name, "/[[:^alnum:]]/", "")), count.index + 1) }, var.resource_tags)

  dynamic "admin_ssh_key" {
    for_each = var.disable_password_authentication ? [1] : []
    content {
      username   = var.admin_username
      public_key = var.admin_ssh_key_data == null ? tls_private_key.rsa[0].public_key_openssh : file(var.admin_ssh_key_data)
    }
  }

  dynamic "source_image_reference" {
    for_each = var.source_image_id != null ? [] : [1]
    content {
      publisher = var.custom_image != null ? var.custom_image["publisher"] : var.linux_distribution_list[lower(var.linux_distribution_name)]["publisher"]
      offer     = var.custom_image != null ? var.custom_image["offer"] : var.linux_distribution_list[lower(var.linux_distribution_name)]["offer"]
      sku       = var.custom_image != null ? var.custom_image["sku"] : var.linux_distribution_list[lower(var.linux_distribution_name)]["sku"]
      version   = var.custom_image != null ? var.custom_image["version"] : var.linux_distribution_list[lower(var.linux_distribution_name)]["version"]
    }
  }

  os_disk {
    storage_account_type      = var.os_disk_storage_account_type
    caching                   = var.os_disk_caching
    disk_encryption_set_id    = var.disk_encryption_set_id
    disk_size_gb              = var.disk_size_gb
    write_accelerator_enabled = var.enable_os_disk_write_accelerator
  }

  dynamic "additional_capabilities" {
    for_each = var.enable_ultra_ssd_data_disk_storage_support ? [1] : []
    content {
      ultra_ssd_enabled = var.enable_ultra_ssd_data_disk_storage_support
    }
  }

  dynamic "data_disk" {
    for_each = var.additional_data_disks
    content {
      lun                  = data_disk.key
      disk_size_gb         = data_disk.value
      caching              = "ReadWrite"
      create_option        = "Empty"
      storage_account_type = var.additional_data_disks_storage_account_type
    }
  }

  network_interface {
    name                          = lower("nic-${format("vm%s%s", lower(replace(var.vmscaleset_name, "/[[:^alnum:]]/", "")), count.index + 1)}")
    primary                       = true
    dns_servers                   = var.dns_servers
    enable_ip_forwarding          = var.enable_ip_forwarding
    enable_accelerated_networking = var.enable_accelerated_networking
    network_security_group_id     = var.existing_network_security_group_id == null ? azurerm_network_security_group.nsg.0.id : var.existing_network_security_group_id

    ip_configuration {
      name                                   = lower("ipconig-${format("vm%s%s", lower(replace(var.vmscaleset_name, "/[[:^alnum:]]/", "")), count.index + 1)}")
      primary                                = true
      subnet_id                              = azurerm_subnet.snet.id
      load_balancer_backend_address_pool_ids = var.enable_load_balancer ? [azurerm_lb_backend_address_pool.bepool[0].id] : null
      load_balancer_inbound_nat_rules_ids    = var.enable_load_balancer && var.enable_lb_nat_pool ? [azurerm_lb_nat_pool.natpol[0].id] : null

      dynamic "public_ip_address" {
        for_each = var.assign_public_ip_to_each_vm_in_vmss ? [1] : []
        content {
          name                = lower("pip-${format("vm%s%s", lower(replace(var.vmscaleset_name, "/[[:^alnum:]]/", "")), "0${count.index + 1}")}")
          public_ip_prefix_id = var.public_ip_prefix_id
        }
      }
    }
  }

  dynamic "automatic_os_upgrade_policy" {
    for_each = var.os_upgrade_mode == "Automatic" ? [1] : []
    content {
      disable_automatic_rollback  = true
      enable_automatic_os_upgrade = true
    }
  }

  dynamic "rolling_upgrade_policy" {
    for_each = var.os_upgrade_mode != "Manual" ? [1] : []
    content {
      max_batch_instance_percent              = var.rolling_upgrade_policy.max_batch_instance_percent
      max_unhealthy_instance_percent          = var.rolling_upgrade_policy.max_unhealthy_instance_percent
      max_unhealthy_upgraded_instance_percent = var.rolling_upgrade_policy.max_unhealthy_upgraded_instance_percent
      pause_time_between_batches              = var.rolling_upgrade_policy.pause_time_between_batches
    }
  }

  dynamic "automatic_instance_repair" {
    for_each = var.enable_automatic_instance_repair ? [1] : []
    content {
      enabled      = var.enable_automatic_instance_repair
      grace_period = var.grace_period
    }
  }

  dynamic "identity" {
    for_each = var.managed_identity_type != null ? [1] : []
    content {
      type         = var.managed_identity_type
      identity_ids = var.managed_identity_type == "UserAssigned" || var.managed_identity_type == "SystemAssigned, UserAssigned" ? var.managed_identity_ids : null
    }
  }

  dynamic "boot_diagnostics" {
    for_each = var.enable_boot_diagnostics ? [1] : []
    content {
      storage_account_uri = var.storage_account_name != null ? azurerm_storage_account.storeacc.0.primary_blob_endpoint : var.storage_account_uri
    }
  }

  lifecycle {
    ignore_changes = [
      tags,
      automatic_instance_repair,
      automatic_os_upgrade_policy,
      rolling_upgrade_policy,
      instances,
      data_disk,
    ]
  }

  # As per the recomendation by Terraform documentation
  depends_on = [azurerm_lb_rule.lbrule]
}

#---------------------------------------
# Windows Virutal machine scale set
#---------------------------------------
resource "azurerm_windows_virtual_machine_scale_set" "winsrv_vmss" {
  count                                             = var.os_flavor == "windows" ? 1 : 0
  name                                              = format("%s", lower(replace(var.vmscaleset_name, "/[[:^alnum:]]/", "")))
  computer_name_prefix                              = var.computer_name_prefix == null && var.instances_count == 1 ? substr(var.vmscaleset_name, 0, 9) : substr(format("%s%s", lower(replace(var.vmscaleset_name, "/[[:^alnum:]]/", "")), count.index + 1), 0, 9)
  resource_group_name                               = azurerm_resource_group.rg.name
  location                                          = azurerm_resource_group.rg.location
  sku                                               = var.virtual_machine_size
  instances                                         = var.instances_count
  admin_username                                    = var.admin_username
  admin_password                                    = var.admin_password == null ? element(concat(random_password.passwd.*.result, [""]), 0) : var.admin_password
  custom_data                                       = var.custom_data
  overprovision                                     = var.overprovision
  do_not_run_extensions_on_overprovisioned_machines = var.do_not_run_extensions_on_overprovisioned_machines
  enable_automatic_updates                          = var.os_upgrade_mode != "Automatic" ? var.enable_windows_vm_automatic_updates : false
  encryption_at_host_enabled                        = var.enable_encryption_at_host
  health_probe_id                                   = var.enable_load_balancer ? azurerm_lb_probe.lbp[0].id : null
  license_type                                      = var.license_type
  platform_fault_domain_count                       = var.platform_fault_domain_count
  provision_vm_agent                                = true
  proximity_placement_group_id                      = var.enable_proximity_placement_group ? azurerm_proximity_placement_group.appgrp.0.id : null
  
  single_placement_group                            = var.single_placement_group
  source_image_id                                   = var.source_image_id != null ? var.source_image_id : null
  upgrade_mode                                      = var.os_upgrade_mode
  timezone                                          = var.vm_time_zone
  zones                                             = var.availability_zones
  zone_balance                                      = var.availability_zone_balance
  tags                                              = merge({ "resourcename" = format("%s", lower(replace(var.vmscaleset_name, "/[[:^alnum:]]/", ""))) }, var.resource_tags)

  dynamic "source_image_reference" {
    for_each = var.source_image_id != null ? [] : [1]
    content {
      publisher = var.custom_image != null ? var.custom_image["publisher"] : var.windows_distribution_list[lower(var.windows_distribution_name)]["publisher"]
      offer     = var.custom_image != null ? var.custom_image["offer"] : var.windows_distribution_list[lower(var.windows_distribution_name)]["offer"]
      sku       = var.custom_image != null ? var.custom_image["sku"] : var.windows_distribution_list[lower(var.windows_distribution_name)]["sku"]
      version   = var.custom_image != null ? var.custom_image["version"] : var.windows_distribution_list[lower(var.windows_distribution_name)]["version"]
    }
  }

  os_disk {
    storage_account_type      = var.os_disk_storage_account_type
    caching                   = var.os_disk_caching
    disk_encryption_set_id    = var.disk_encryption_set_id
    disk_size_gb              = var.disk_size_gb
    write_accelerator_enabled = var.enable_os_disk_write_accelerator
  }

  dynamic "additional_capabilities" {
    for_each = var.enable_ultra_ssd_data_disk_storage_support ? [1] : []
    content {
      ultra_ssd_enabled = var.enable_ultra_ssd_data_disk_storage_support
    }
  }

  dynamic "data_disk" {
    for_each = var.additional_data_disks
    content {
      lun                  = data_disk.key
      disk_size_gb         = data_disk.value
      caching              = "ReadWrite"
      create_option        = "Empty"
      storage_account_type = var.additional_data_disks_storage_account_type
    }
  }

  network_interface {
    name                          = lower("nic-${format("vm%s%s", lower(replace(var.vmscaleset_name, "/[[:^alnum:]]/", "")), count.index + 1)}")
    primary                       = true
    dns_servers                   = var.dns_servers
    enable_ip_forwarding          = var.enable_ip_forwarding
    enable_accelerated_networking = var.enable_accelerated_networking
    network_security_group_id     = var.existing_network_security_group_id == null ? azurerm_network_security_group.nsg.0.id : var.existing_network_security_group_id

    ip_configuration {
      name                                   = lower("ipconfig-${format("vm%s%s", lower(replace(var.vmscaleset_name, "/[[:^alnum:]]/", "")), count.index + 1)}")
      primary                                = true
      subnet_id                              = azurerm_subnet.snet.id
      load_balancer_backend_address_pool_ids = var.enable_load_balancer ? [azurerm_lb_backend_address_pool.bepool[0].id] : null
      load_balancer_inbound_nat_rules_ids    = var.enable_load_balancer && var.enable_lb_nat_pool ? [azurerm_lb_nat_pool.natpol.0.id] : null

      dynamic "public_ip_address" {
        for_each = var.assign_public_ip_to_each_vm_in_vmss ? [{}] : []
        content {
          name                = lower("pip-${format("vm%s%s", lower(replace(var.vmscaleset_name, "/[[:^alnum:]]/", "")), count.index + 1)}")
          public_ip_prefix_id = var.public_ip_prefix_id
        }
      }
    }
  }

  dynamic "automatic_os_upgrade_policy" {
    for_each = var.os_upgrade_mode == "Automatic" ? [1] : []
    content {
      disable_automatic_rollback  = true
      enable_automatic_os_upgrade = true
    }
  }

  dynamic "rolling_upgrade_policy" {
    for_each = var.os_upgrade_mode != "Manual" ? [1] : []
    content {
      max_batch_instance_percent              = var.rolling_upgrade_policy.max_batch_instance_percent
      max_unhealthy_instance_percent          = var.rolling_upgrade_policy.max_unhealthy_instance_percent
      max_unhealthy_upgraded_instance_percent = var.rolling_upgrade_policy.max_unhealthy_upgraded_instance_percent
      pause_time_between_batches              = var.rolling_upgrade_policy.pause_time_between_batches
    }
  }

  dynamic "automatic_instance_repair" {
    for_each = var.enable_automatic_instance_repair ? [1] : []
    content {
      enabled      = var.enable_automatic_instance_repair
      grace_period = var.grace_period
    }
  }

  dynamic "identity" {
    for_each = var.managed_identity_type != null ? [1] : []
    content {
      type         = var.managed_identity_type
      identity_ids = var.managed_identity_type == "UserAssigned" || var.managed_identity_type == "SystemAssigned, UserAssigned" ? var.managed_identity_ids : null
    }
  }

  dynamic "winrm_listener" {
    for_each = var.winrm_protocol != null ? [1] : []
    content {
      protocol        = var.winrm_protocol
      certificate_url = var.winrm_protocol == "Https" ? var.key_vault_certificate_secret_url : null
    }
  }

  dynamic "additional_unattend_content" {
    for_each = var.additional_unattend_content != null ? [1] : []
    content {
      content = var.additional_unattend_content
      setting = var.additional_unattend_content_setting
    }
  }

  dynamic "boot_diagnostics" {
    for_each = var.enable_boot_diagnostics ? [1] : []
    content {
      storage_account_uri = var.storage_account_name != null ? azurerm_storage_account.storeacc.0.primary_blob_endpoint : var.storage_account_uri
    }
  }

  lifecycle {
    ignore_changes = [
      tags,
      automatic_instance_repair,
      automatic_os_upgrade_policy,
      rolling_upgrade_policy,
      instances,
      winrm_listener,
      additional_unattend_content,
      data_disk,
    ]
  }
  # As per the recomendation by Terraform documentation
  depends_on = [azurerm_lb_rule.lbrule]
}

#-----------------------------------------------
# Auto Scaling for Virtual machine scale set
#-----------------------------------------------
resource "azurerm_monitor_autoscale_setting" "auto" {
  count               = var.enable_autoscale_for_vmss ? 1 : 0
  name                = lower("auto-scale-set-${var.vmscaleset_name}")
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  target_resource_id  = var.os_flavor == "windows" ? azurerm_windows_virtual_machine_scale_set.winsrv_vmss.0.id : azurerm_linux_virtual_machine_scale_set.linux_vmss.0.id

  profile {
    name = "default"
    capacity {
      default = var.instances_count
      minimum = var.minimum_instances_count == null ? var.instances_count : var.minimum_instances_count
      maximum = var.maximum_instances_count
    }

    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = var.os_flavor == "windows" ? azurerm_windows_virtual_machine_scale_set.winsrv_vmss.0.id : azurerm_linux_virtual_machine_scale_set.linux_vmss.0.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "GreaterThan"
        threshold          = var.scale_out_cpu_percentage_threshold
      }
      scale_action {
        direction = "Increase"
        type      = "ChangeCount"
        value     = var.scaling_action_instances_number
        cooldown  = "PT1M"
      }
    }

    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = var.os_flavor == "windows" ? azurerm_windows_virtual_machine_scale_set.winsrv_vmss.0.id : azurerm_linux_virtual_machine_scale_set.linux_vmss.0.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "LessThan"
        threshold          = var.scale_in_cpu_percentage_threshold
      }
      scale_action {
        direction = "Decrease"
        type      = "ChangeCount"
        value     = var.scaling_action_instances_number
        cooldown  = "PT1M"
      }
    }
  }
}

resource "azurerm_log_analytics_workspace" "law" {
  name                = "law-longmen"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

#--------------------------------------------------------------
# Azure Log Analytics Workspace Agent Installation for windows
#--------------------------------------------------------------


# #--------------------------------------------------------------
# # Azure Log Analytics Workspace Agent Installation for Linux
# #--------------------------------------------------------------
# resource "azurerm_virtual_machine_scale_set_extension" "omsagentlinux" {
#   count                        = var.deploy_log_analytics_agent && var.log_analytics_workspace_id != null && var.os_flavor == "linux" ? 1 : 0
#   name                         = "OmsAgentForLinux"
#   publisher                    = "Microsoft.EnterpriseCloud.Monitoring"
#   type                         = "OmsAgentForLinux"
#   type_handler_version         = "1.13"
#   auto_upgrade_minor_version   = true
#   virtual_machine_scale_set_id = azurerm_linux_virtual_machine_scale_set.linux_vmss.0.id

#   settings = <<SETTINGS
#     {
#       "workspaceId": "${og_analytics_workspace_primary_shared_key}"
#     }
#   SETTINGS

#   protected_settings = <<PROTECTED_SETTINGS
#     {
#     "workspaceKey": "${var.log_analytics_workspace_primary_shared_key}"
#     }
#   PROTECTED_SETTINGS
# }

#--------------------------------------
# azurerm monitoring diagnostics 
#--------------------------------------
resource "azurerm_monitor_diagnostic_setting" "vmmsdiag" {
  # count                      = azurerm_log_analytics_workspace.law.id != null ? 1 : 0
  name                       = lower("${var.vmscaleset_name}-diag")
  target_resource_id         = var.os_flavor == "windows" ? azurerm_windows_virtual_machine_scale_set.winsrv_vmss.0.id : azurerm_linux_virtual_machine_scale_set.linux_vmss.0.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id

  enabled_metric {
    category = "AllMetrics"
  }
}

resource "azurerm_monitor_diagnostic_setting" "nsg" {
  # count                      = var.existing_network_security_group_id == null && var.log_analytics_workspace_id != null ? 1 : 0
  name                       = lower("nsg-${var.vmscaleset_name}-diag")
  target_resource_id         = azurerm_network_security_group.nsg.0.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id 

  dynamic "enabled_log" {
    for_each = var.nsg_diag_logs
    iterator = log
    content {
      category = log.value
    }
  }
}

# resource "azurerm_monitor_diagnostic_setting" "lb_pip" {
#   count = var.load_balancer_type == "public" && length(azurerm_public_ip.pip) > 0 && azurerm_log_analytics_workspace.law.id != null ? 1 : 0
#   name                       = "${var.vmscaleset_name}-pip-diag"
#   target_resource_id         = azurerm_public_ip.pip[0].id
#   log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id

#   dynamic "enabled_log" {
#     for_each = var.pip_diag_logs
#     iterator = log
#     content {
#       category = log.value
#     }
#   }

#   enabled_metric {
#     category = "AllMetrics"
#   }

#   depends_on = [azurerm_public_ip.pip,
#   azurerm_log_analytics_workspace.law]
# }


resource "azurerm_monitor_diagnostic_setting" "lb" {
  # count                      = var.load_balancer_type == "public" && azurerm_log_analytics_workspace.law.id != null && var.storage_account_name != null ? 1 : 0
  name                       = "${var.vmscaleset_name}-lb-diag"
  target_resource_id         = azurerm_lb.vmsslb.0.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id

  dynamic "enabled_log" {
    for_each = var.lb_diag_logs
    iterator = log
    content {
      category = log.value
      retention_policy {
        enabled = false
        days    = 0
      }
    }
  }

  enabled_metric {
    category = "AllMetrics"
  }
}

#-----------------------------------------------------------
# Install IIS web server in every Instance in VM scale sets 
#-----------------------------------------------------------
resource "azurerm_virtual_machine_scale_set_extension" "vmss_iis" {
  count                        = var.intall_iis_server_on_instances && var.os_flavor == "windows" ? 1 : 0
  name                         = "install-iis"
  publisher                    = "Microsoft.Compute"
  type                         = "CustomScriptExtension"
  type_handler_version         = "1.9"
  virtual_machine_scale_set_id = azurerm_windows_virtual_machine_scale_set.winsrv_vmss[0].id

  settings = <<SETTINGS
    {
      "commandToExecute" : "powershell Install-WindowsFeature -name Web-Server -IncludeManagementTools"
    }
  SETTINGS
}

resource "azurerm_monitor_data_collection_endpoint" "dcer" {
  name                = "LongMen-dcre"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  lifecycle {
    create_before_destroy = true
  }
}

resource "azurerm_monitor_data_collection_rule" "dcr" {
  name                        = "LongMenDCR-rule"
  resource_group_name         = azurerm_resource_group.rg.name
  location                    = azurerm_resource_group.rg.location
  data_collection_endpoint_id = azurerm_monitor_data_collection_endpoint.dcer.id

  destinations {
    log_analytics {
      workspace_resource_id = azurerm_log_analytics_workspace.law.id
      name                  = "LongMen-destination-log"
    }

    azure_monitor_metrics {
      name = "LongMen-destination-metrics"
    }
  }

  data_flow {
    streams      = ["Microsoft-InsightsMetrics"]
    destinations = ["LongMen-destination-metrics"]
  }

  data_flow {
    streams      = ["Microsoft-InsightsMetrics", "Microsoft-Syslog", "Microsoft-Perf"]
    destinations = ["LongMen-destination-log"]
  }

  data_flow {
    streams       = ["Custom-MyTableRawData"]
    destinations  = ["LongMen-destination-log"]
    output_stream = "Microsoft-Syslog"
    transform_kql = "source | project TimeGenerated = Time, Computer, Message = AdditionalContext"
  }

  data_sources {
    syslog {
      facility_names = ["*"]
      log_levels     = ["*"]
      name           = "LongMen-datasource-syslog"
      streams        = ["Microsoft-Syslog"]
    }

    iis_log {
      streams         = ["Microsoft-W3CIISLog"]
      name            = "LongMen-datasource-iis"
      log_directories = ["C:\\Logs\\W3SVC1"]
    }

    log_file {
      name          = "LongMen-datasource-logfile"
      format        = "text"
      streams       = ["Custom-MyTableRawData"]
      file_patterns = ["C:\\JavaLogs\\*.log"]
      settings {
        text {
          record_start_timestamp_format = "ISO 8601"
        }
      }
    }

    performance_counter {
      streams                       = ["Microsoft-Perf", "Microsoft-InsightsMetrics"]
      sampling_frequency_in_seconds = 60
      counter_specifiers            = ["Processor(*)\\% Processor Time"]
      name                          = "LongMen-datasource-perfcounter"
    }

    windows_event_log {
      streams        = ["Microsoft-WindowsEvent"]
      x_path_queries = ["*![System/Level=1]"]
      name           = "LongMen-datasource-wineventlog"
    }

    extension {
      streams            = ["Microsoft-WindowsEvent"]
      input_data_sources = ["LongMen-datasource-wineventlog"]
      extension_name     = "LongMen-extension-name"
      extension_json = jsonencode({
        a = 1
        b = "hello"
      })
      name = "LongMen-datasource-extension"
    }
  }

  stream_declaration {
    stream_name = "Custom-MyTableRawData"
    column {
      name = "Time"
      type = "datetime"
    }
    column {
      name = "Computer"
      type = "string"
    }
    column {
      name = "AdditionalContext"
      type = "string"
    }
  }

  description = "data collection rule LongMen"
  tags = {
    foo = "bar"
  }
  depends_on = [
    azurerm_log_analytics_workspace.law
  ]
}

#-----------------------------------------------------------
# Install Azure Monitoring Agent Extension
#-----------------------------------------------------------

resource "azurerm_virtual_machine_scale_set_extension" "ama_extension" {
  name                         = "AzureMonitorWindowsAgent"
  virtual_machine_scale_set_id = azurerm_windows_virtual_machine_scale_set.winsrv_vmss[0].id
  publisher                    = "Microsoft.Azure.Monitor"
  type                         = "AzureMonitorWindowsAgent"
  type_handler_version         = "1.38"
  auto_upgrade_minor_version   = true

  settings = jsonencode({
    dataCollectionRule = azurerm_monitor_data_collection_rule.dcr.id
  })

  depends_on = [azurerm_monitor_data_collection_rule.dcr, azurerm_linux_virtual_machine_scale_set.linux_vmss]
}

data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "key_vault" {
  name                            = var.keyvault_name_override != "" ? var.keyvault_name_override : "kv-${var.app_or_service_name}-${var.subscription_type}-${var.instance_number}-MLong"
  location                        = azurerm_resource_group.rg.location
  resource_group_name             = azurerm_resource_group.rg.name
  tenant_id                       = data.azurerm_client_config.current.tenant_id
  enabled_for_deployment          = var.enabled_for_deployment
  enabled_for_disk_encryption     = var.enabled_for_disk_encryption
  enabled_for_template_deployment = var.enabled_for_template_deployment
  enable_rbac_authorization       = var.enable_rbac_authorization
  purge_protection_enabled        = var.purge_protection_enabled
  soft_delete_retention_days      = var.soft_delete_retention_days
  sku_name                        = var.sku
  tags                            = var.resource_tags
  public_network_access_enabled   = var.enable_public_network_access 

  network_acls {
    bypass = "AzureServices"
    default_action = "Allow"
  }   
}

resource "azurerm_key_vault_access_policy" "kv-access-policy" {
  count        = var.grant_access_to_service_principal == true ? 1 : 0
  key_vault_id = azurerm_key_vault.key_vault.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = data.azurerm_client_config.current.object_id

  certificate_permissions = [
    "Backup", "Create", "Delete", "DeleteIssuers", "Get", "GetIssuers", "Import", "List", "ListIssuers", "ManageContacts", "ManageIssuers", "Purge", "Recover", "Restore", "SetIssuers", "Update",
  ]

  key_permissions = [
    "Backup", "Create", "Decrypt", "Delete", "Encrypt", "Get", "Import", "List", "Purge", "Recover", "Restore", "Sign", "UnwrapKey", "Update", "Verify", "WrapKey", "Release", "Rotate", "GetRotationPolicy", "SetRotationPolicy",
  ]

  secret_permissions = [
    "Backup", "Delete", "Get", "List", "Purge", "Recover", "Restore", "Set",
  ]

  depends_on = [
    azurerm_key_vault.key_vault
  ]
}

resource "azurerm_key_vault_key" "vm-key" {
  count        = var.enabled_for_disk_encryption == true ? 1 : 0  
  name         = "des-key-${var.app_or_service_name}-${var.subscription_type}-${var.instance_number}"
  key_vault_id = azurerm_key_vault.key_vault.id
  key_type     = "RSA"
  key_size     = 2048

  depends_on = [
    azurerm_key_vault_access_policy.kv-access-policy
  ]

  key_opts = [
    "decrypt",
    "encrypt",
    "sign",
    "unwrapKey",
    "verify",
    "wrapKey",
  ]
}

resource "azurerm_disk_encryption_set" "en-set" {
  count               = var.enabled_for_disk_encryption == true ? 1 : 0    
  name                = "des_${var.app_or_service_name}_${var.subscription_type}_${var.instance_number}"
  resource_group_name = azurerm_resource_group.rg.name 
  location            = azurerm_resource_group.rg.location 
  key_vault_key_id    = azurerm_key_vault_key.vm-key[0].id

  identity {
    type = "SystemAssigned"
  }

  depends_on = [
    azurerm_key_vault_key.vm-key
  ] 
}

resource "azurerm_key_vault_access_policy" "kv-access-policy-des" {
  count        = var.enabled_for_disk_encryption == true ? 1 : 0    
  key_vault_id = azurerm_key_vault.key_vault.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = azurerm_disk_encryption_set.en-set[0].identity.0.principal_id

  key_permissions = [
    "Get",
    "WrapKey",
    "UnwrapKey"
  ]

  depends_on = [
    azurerm_disk_encryption_set.en-set
  ]   
}

resource "azurerm_virtual_machine_scale_set_extension" "daa_agent_vmss" {
  name                         = "DependencyAgentWindows"
  virtual_machine_scale_set_id = azurerm_windows_virtual_machine_scale_set.winsrv_vmss[0].id
  publisher                    = "Microsoft.Azure.Monitoring.DependencyAgent"
  type                         = "DependencyAgentWindows"
  type_handler_version         = "9.10"
  auto_upgrade_minor_version   = true
  automatic_upgrade_enabled    = true
  depends_on = [ azurerm_monitor_data_collection_rule.dcr, azurerm_linux_virtual_machine_scale_set.linux_vmss, azurerm_virtual_machine_scale_set_extension.ama_extension ]
}

# Deprecated as of August, 2024
# resource "azurerm_virtual_machine_scale_set_extension" "omsagent_vmss" {
#   name                          = "OmsAgentForWindows"
#   virtual_machine_scale_set_id = azurerm_windows_virtual_machine_scale_set.winsrv_vmss[0].id
#   publisher                     = "Microsoft.EnterpriseCloud.Monitoring"
#   type                          = "MicrosoftMonitoringAgent"
#   type_handler_version          = "1.0"
#   auto_upgrade_minor_version    = true

#   settings = jsonencode({
#     workspaceId             = azurerm_log_analytics_workspace.law.id
#     azureResourceId         = azurerm_windows_virtual_machine_scale_set.winsrv_vmss[0].id
#     stopOnMultipleConnections = "false"
#   })

#   protected_settings = jsonencode({
#     workspaceKey = azurerm_log_analytics_workspace.law.id
#   })

#   depends_on = [
#     azurerm_windows_virtual_machine_scale_set.winsrv_vmss, azurerm_log_analytics_workspace.law,
#      azurerm_monitor_data_collection_rule.dcr, azurerm_linux_virtual_machine_scale_set.linux_vmss, azurerm_virtual_machine_scale_set_extension.ama_extension
#   ]
# }

resource "azurerm_virtual_machine_scale_set_extension" "gc_vmss" {
  name                          = "AzurePolicyforWindows"
  virtual_machine_scale_set_id = azurerm_windows_virtual_machine_scale_set.winsrv_vmss[0].id
  publisher                     = "Microsoft.GuestConfiguration"
  type                          = "ConfigurationforWindows"
  type_handler_version          = "1.29"
  auto_upgrade_minor_version    = true

  depends_on = [
    azurerm_windows_virtual_machine_scale_set.winsrv_vmss, azurerm_log_analytics_workspace.law,
     azurerm_monitor_data_collection_rule.dcr, azurerm_linux_virtual_machine_scale_set.linux_vmss, azurerm_virtual_machine_scale_set_extension.ama_extension
     
  ]
}

resource "azurerm_virtual_machine_scale_set_extension" "bitlocker" {
  count                         = lower(var.vm_os_type) == "windows" ? 1 : 0
  name                          = "${random_string.azurerm_analysis_services_server_name.result}-bitlocker"
  virtual_machine_scale_set_id = azurerm_windows_virtual_machine_scale_set.winsrv_vmss[0].id
  publisher                     = "Microsoft.Azure.Security"
  type                          = "AzureDiskEncryption"
  type_handler_version          = var.type_handler_version != "" ? var.type_handler_version : "2.2"
  auto_upgrade_minor_version    = true

  settings = jsonencode({
    EncryptionOperation     = var.encrypt_operation
    KeyVaultURL             = azurerm_key_vault.key_vault.vault_uri
    KeyVaultResourceId      = azurerm_key_vault.key_vault.id      
    KeyEncryptionAlgorithm  = var.encryption_algorithm
    VolumeType              = var.volume_type
  })
  

  depends_on = [
    azurerm_windows_virtual_machine_scale_set.winsrv_vmss,
    azurerm_key_vault.key_vault
  ]
}
