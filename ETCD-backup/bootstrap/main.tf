resource "azurerm_resource_group" "tfstate" {
  name     = "rg-etcd"
  location = "eastus"
}

resource "azurerm_storage_account" "tfstate" {
  name                     = "tfstateacctlongmen"
  resource_group_name      = azurerm_resource_group.tfstate.name
  location                 = azurerm_resource_group.tfstate.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_container" "tfstate" {
  name                  = "tfstate"
  storage_account_id    = azurerm_storage_account.tfstate.id
  container_access_type = "private"
}
