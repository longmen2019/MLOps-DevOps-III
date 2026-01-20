resource "azurerm_storage_account" "st" {
  name                     = "longmend2488nonproeu"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  min_tls_version = "TLS1_2"
  network_rules {
    default_action             = "Deny"
    ip_rules                   = []
  }

  tags = {
    Owner="sd2488"
  }
}