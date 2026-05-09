output "resource_group_name" {
  value = azurerm_resource_group.etcd.name
}

output "aks_name" {
  value = azurerm_kubernetes_cluster.etcd.name
}
