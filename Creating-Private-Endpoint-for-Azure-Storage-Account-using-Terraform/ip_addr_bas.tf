resource "azurerm_public_ip" "pip" {
  name                = "pip-sd2488-non-prod-weu"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_bastion_host" "bas" {
  name                = "bas-sd2488-non-prod-weu"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                 = "bas-configuration"
    subnet_id            = azurerm_subnet.snet_bas.id
    public_ip_address_id = azurerm_public_ip.pip.id
  }
}
