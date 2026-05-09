locals {
  azure_enabled = (
    var.enable_azure &&
    var.azure_storage_account_name != "" &&
    var.azure_container_name != ""
  )
}

resource "azurerm_storage_account" "etcd" {
  count = local.azure_enabled ? 1 : 0

  name                     = var.azure_storage_account_name
  resource_group_name      = var.azure_resource_group

  location                 = "eastus"
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = {
    "Name"      = "${var.cluster_name}-etcd-backups"
    "ManagedBy" = "terraform"
  }
}

resource "azurerm_storage_container" "etcd" {
  count = local.azure_enabled ? 1 : 0

  name                  = var.azure_container_name
  storage_account_name  = azurerm_storage_account.etcd[0].name
  container_access_type = "private"
}
