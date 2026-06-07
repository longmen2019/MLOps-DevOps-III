data "azurerm_client_config" "current" {}

resource "random_pet" "rg_name" {
  length    = 2
  separator = "-"
}

resource "azurerm_resource_group" "rg" {
  name     = "rg-${random_pet.rg_name.id}"
  location = var.location
}

resource "azurerm_kubernetes_cluster" "aks" {
  name                = "aks-${random_pet.rg_name.id}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = "aks-${random_pet.rg_name.id}"

  kubernetes_version = var.kubernetes_version

  default_node_pool {
    name                = "nodepool1"
    vm_size             = var.node_vm_size
    node_count          = var.node_count
    os_disk_size_gb     = 30
    type                = "VirtualMachineScaleSets"
    orchestrator_version = var.kubernetes_version
  }

  identity {
    type = "SystemAssigned"
  }

  role_based_access_control_enabled = true

  network_profile {
    network_plugin = "azure"
    load_balancer_sku = "standard"
  }

  tags = {
    environment = "student-lab"
  }
}
