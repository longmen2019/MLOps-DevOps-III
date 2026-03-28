
# ---------------------------------------------------------
# 1. Management Group + Subscription Association
# ---------------------------------------------------------

resource "azurerm_management_group" "mg" {
  name         = var.management_group_name
  display_name = var.management_group_display_name
}

resource "azurerm_management_group_subscription_association" "mg_assoc" {
  management_group_id = azurerm_management_group.mg.id
  subscription_id     = var.subscription_id
}

# ---------------------------------------------------------
# 2. Resource Group
# ---------------------------------------------------------

resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

# ---------------------------------------------------------
# 3. Log Analytics Workspace
# ---------------------------------------------------------

resource "azurerm_log_analytics_workspace" "law" {
  name                = var.log_analytics_workspace_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

# ---------------------------------------------------------
# 4. Sentinel Onboarding (Correct Resource)
# ---------------------------------------------------------

resource "azurerm_sentinel_log_analytics_workspace_onboarding" "sentinel" {
  workspace_id = azurerm_log_analytics_workspace.law.id
}

# ---------------------------------------------------------
# 5. Networking (VNet, Subnet, NSG)
# ---------------------------------------------------------

resource "azurerm_virtual_network" "vnet" {
  name                = "sentinel-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "subnet" {
  name                 = "sentinel-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_network_security_group" "nsg" {
  name                = "sentinel-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_network_security_rule" "allow_ssh" {
  name                        = "allow_ssh"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.nsg.name
}

# ---------------------------------------------------------
# 6. Public IP (Standard SKU — Required for Your Subscription)
# ---------------------------------------------------------

resource "azurerm_public_ip" "vm_pip" {
  name                = "sentinel-vm-pip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

# ---------------------------------------------------------
# 7. NIC
# ---------------------------------------------------------

resource "azurerm_network_interface" "nic" {
  name                = "sentinel-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.0.1.4"
    public_ip_address_id          = azurerm_public_ip.vm_pip.id
  }
}

resource "azurerm_network_interface_security_group_association" "nic_nsg" {
  network_interface_id      = azurerm_network_interface.nic.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

# ---------------------------------------------------------
# 8. Linux VM
# ---------------------------------------------------------

resource "azurerm_linux_virtual_machine" "vm" {
  name                = "sentinel-vm"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  size                = "Standard_B1s"
  admin_username      = "azureuser"

  network_interface_ids = [
    azurerm_network_interface.nic.id
  ]

  disable_password_authentication = false
  admin_password                  = var.admin_password

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
}

# ---------------------------------------------------------
# 9. Azure Monitor Agent (AMA)
# ---------------------------------------------------------

resource "azurerm_virtual_machine_extension" "ama" {
  name                       = "AzureMonitorLinuxAgent"
  virtual_machine_id         = azurerm_linux_virtual_machine.vm.id
  publisher                  = "Microsoft.Azure.Monitor"
  type                       = "AzureMonitorLinuxAgent"
  type_handler_version       = "1.0"
  auto_upgrade_minor_version = true
  settings                   = "{}"
}

# ---------------------------------------------------------
# 10. Data Collection Rule (Syslog)
# ---------------------------------------------------------

resource "azurerm_monitor_data_collection_rule" "dcr" {
  name                = "sentinel-syslog-dcr"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  destinations {
    log_analytics {
      name                  = "law_dest"
      workspace_resource_id = azurerm_log_analytics_workspace.law.id
    }
  }

  data_sources {
    syslog {
      name           = "syslog"
      facility_names = ["*"]
      log_levels     = ["Error", "Warning", "Info"]
      streams        = ["Microsoft-Syslog"]
    }
  }

  data_flow {
    streams      = ["Microsoft-Syslog"]
    destinations = ["law_dest"]
  }
}

# ---------------------------------------------------------
# 11. DCR Association
# ---------------------------------------------------------

resource "azurerm_monitor_data_collection_rule_association" "dcr_assoc" {
  name                    = "sentinel-dcr-assoc"
  target_resource_id      = azurerm_linux_virtual_machine.vm.id
  data_collection_rule_id = azurerm_monitor_data_collection_rule.dcr.id
}

# ---------------------------------------------------------
# 12. AAD Diagnostic Settings (No Retention Blocks)
# ---------------------------------------------------------

resource "azurerm_monitor_aad_diagnostic_setting" "aad" {
  name                       = "aad-diag"
  log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id

  enabled_log {
    category = "AuditLogs"

    retention_policy {
      enabled = false
      days    = 0
    }
  }

  enabled_log {
    category = "SignInLogs"

    retention_policy {
      enabled = false
      days    = 0
    }
  }

  enabled_log {
    category = "ServicePrincipalSignInLogs"

    retention_policy {
      enabled = false
      days    = 0
    }
  }

  enabled_log {
    category = "NonInteractiveUserSignInLogs"

    retention_policy {
      enabled = false
      days    = 0
    }
  }
}


# ---------------------------------------------------------
# 13. Sentinel Alert Rule — Failed SSH Login
# ---------------------------------------------------------

resource "azurerm_sentinel_alert_rule_scheduled" "ssh_fail" {
  depends_on = [
    azurerm_sentinel_log_analytics_workspace_onboarding.sentinel
  ]

  name                       = "Failed-SSH-Login"
  display_name               = "Failed SSH Login Detection"
  log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id

  query = <<EOF
Syslog
| where SyslogMessage contains "Failed password"
| sort by TimeGenerated desc
EOF

  severity         = "High"
  query_frequency  = "PT5M"
  query_period     = "PT5M"
  trigger_operator = "GreaterThan"
  trigger_threshold = 0
}
