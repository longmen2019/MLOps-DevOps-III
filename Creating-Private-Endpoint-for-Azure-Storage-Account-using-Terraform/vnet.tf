
resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-sd2488-non-prod-weu"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["10.1.0.0/16"]  

  tags = {
    Owner="sd2488"
  }
}

resource "azurerm_subnet" "snet_endpoint" {
  name = "PrivateSubnet"
  virtual_network_name = azurerm_virtual_network.vnet.name
  resource_group_name = azurerm_resource_group.rg.name
  address_prefixes      = ["10.1.0.0/24"]  

}

resource "azurerm_subnet" "snet_bas" {
  name = "AzureBastionSubnet"
  virtual_network_name = azurerm_virtual_network.vnet.name
  resource_group_name = azurerm_resource_group.rg.name
  address_prefixes      = ["10.1.1.0/24"]
}