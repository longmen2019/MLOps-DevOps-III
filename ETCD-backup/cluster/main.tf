resource "azurerm_resource_group" "etcd" {
  name     = var.azure_resource_group
  location = var.location
}

resource "azurerm_kubernetes_cluster" "etcd" {
  name                = var.aks_name
  location            = azurerm_resource_group.etcd.location
  resource_group_name = azurerm_resource_group.etcd.name
  dns_prefix          = "etcd-aks"

  default_node_pool {
    name       = "system"
    node_count = 1
    vm_size    = "Standard_B4ms"
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin = "azure"
  }
}
