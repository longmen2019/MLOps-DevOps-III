resource "azurerm_resource_group" "rg" {
  name = "rg-sd2488-non-prod-weu-infra"
  location = "westeurope"
  tags = {
    Owner="sd2488"
  }
}
