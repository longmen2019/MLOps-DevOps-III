############################################
# RESOURCE GROUP
############################################
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

############################################
# AKS CLUSTER (minimal default node pool)
############################################
resource "azurerm_kubernetes_cluster" "aks" {
  name                = var.cluster_name
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = "${var.cluster_name}-dns"

  kubernetes_version = var.k8s_version

  identity {
    type = "SystemAssigned"
  }

  default_node_pool {
    name       = "default"
    vm_size    = "Standard_B2s"
    node_count = 1
  }


  network_profile {
    network_plugin     = "azure"
    network_policy     = "azure"
    load_balancer_sku  = "standard"
    outbound_type      = "loadBalancer"
  }
}

############################################
# SYSTEM NODE POOL (tainted)
############################################
resource "azurerm_kubernetes_cluster_node_pool" "system" {
  name                  = "system"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.aks.id
  vm_size               = "Standard_B2s"
  node_count            = 1
  mode                  = "System"

  node_labels = {
    "nodepool-type" = "system"
  }

  node_taints = [
    "CriticalAddonsOnly=true:NoSchedule"
  ]
}

