# Get current client config (for tenant_id)
data "azurerm_client_config" "current" {}

# Generate random suffixes
resource "random_string" "kv_suffix" {
  length  = 6
  upper   = false
  special = false
}
resource "random_string" "sa_suffix" {
  length  = 6
  upper   = false
  special = false
}
resource "random_string" "alert_suffix" {
  length  = 4
  upper   = false
  special = false
}

# 1. Resource Group
resource "azurerm_resource_group" "demo_rg" {
  name     = "sentinel-demo-rg"
  location = var.location
}

locals {
  location = azurerm_resource_group.demo_rg.location
  rg_name  = azurerm_resource_group.demo_rg.name
}

# 2. Log Analytics Workspace
resource "azurerm_log_analytics_workspace" "demo_law" {
  name                = "sentinelDemoLAW"
  location            = local.location
  resource_group_name = local.rg_name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

# 3. Microsoft Sentinel Onboarding
resource "azurerm_sentinel_log_analytics_workspace_onboarding" "sentinel" {
  workspace_id = azurerm_log_analytics_workspace.demo_law.id
}

# 4. Key Vault
resource "azurerm_key_vault" "demo_kv" {
  name                       = "sentinelDemoKV-${random_string.kv_suffix.result}"
  location                   = local.location
  resource_group_name        = local.rg_name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  purge_protection_enabled   = false
  soft_delete_retention_days = 90
}

# 5. Storage Account
resource "azurerm_storage_account" "demo_sa" {
  name                     = "sentineldemosa${random_string.sa_suffix.result}"
  location                 = local.location
  resource_group_name      = local.rg_name
  account_tier             = "Standard"
  account_replication_type = "LRS"
  min_tls_version          = "TLS1_2"

  network_rules {
    default_action = "Deny"
  }
}

# 6. Virtual Network + NSG
resource "azurerm_virtual_network" "demo_vnet" {
  name                = "sentinelDemoVNet"
  address_space       = ["10.0.0.0/16"]
  location            = local.location
  resource_group_name = local.rg_name
}

resource "azurerm_network_security_group" "demo_nsg" {
  name                = "sentinelDemoNSG"
  location            = local.location
  resource_group_name = local.rg_name
}

# 7. Diagnostic Settings for Key Vault
resource "azurerm_monitor_diagnostic_setting" "kv_diag" {
  name                       = "kvDiag"
  target_resource_id         = azurerm_key_vault.demo_kv.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.demo_law.id

  enabled_log {
    category = "AuditEvent"
  }
}

# 8. Diagnostic Settings for Storage Account (Blob service)
resource "azurerm_monitor_diagnostic_setting" "sa_diag_blob" {
  name                       = "saDiagBlob"
  target_resource_id         = "${azurerm_storage_account.demo_sa.id}/blobServices/default"
  log_analytics_workspace_id = azurerm_log_analytics_workspace.demo_law.id

  enabled_log {
    category = "StorageRead"
  }
  enabled_log {
    category = "StorageWrite"
  }
  enabled_log {
    category = "StorageDelete"
  }
  enabled_metric {
    category = "Transaction"
  }
}

# 9. Diagnostic Settings for NSG
resource "azurerm_monitor_diagnostic_setting" "nsg_diag" {
  name                       = "nsgDiag"
  target_resource_id         = azurerm_network_security_group.demo_nsg.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.demo_law.id

  enabled_log {
    category = "NetworkSecurityGroupEvent"
  }
  enabled_log {
    category = "NetworkSecurityGroupRuleCounter"
  }
}

# 10. Sentinel Scheduled Alert Rule (Key Vault Access)
resource "azurerm_sentinel_alert_rule_scheduled" "kv_access_alert" {
  depends_on                 = [azurerm_sentinel_log_analytics_workspace_onboarding.sentinel]
  name                       = "SuspiciousKeyVaultAccess-${random_string.alert_suffix.result}"
  display_name               = "Suspicious Key Vault Access"
  log_analytics_workspace_id = azurerm_log_analytics_workspace.demo_law.id
  severity                   = "Medium"
  query_frequency            = "PT1H"
  query_period               = "PT1H"
  trigger_operator           = "GreaterThan"
  trigger_threshold          = 0
  enabled                    = true
  suppression_enabled        = false
  description                = "Detects access to Key Vault resources (simplified query without IP/Identity columns)"
  tactics                    = ["CredentialAccess", "Persistence"]
  techniques                 = ["T1555"]

  query = <<QUERY
AzureDiagnostics
| where Category == "AuditEvent" and ResourceType == "VAULTS"
| summarize Count = count() by bin(TimeGenerated, 1h)
QUERY
}