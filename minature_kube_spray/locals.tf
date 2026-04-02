locals {
  inventory = <<EOT
[all]
control-plane ansible_host=${azurerm_linux_virtual_machine.cp.private_ip_address} ip=${azurerm_linux_virtual_machine.cp.private_ip_address} ansible_user=${var.admin_username}
worker1 ansible_host=${azurerm_linux_virtual_machine.worker1.private_ip_address} ip=${azurerm_linux_virtual_machine.worker1.private_ip_address} ansible_user=${var.admin_username}
worker2 ansible_host=${azurerm_linux_virtual_machine.worker2.private_ip_address} ip=${azurerm_linux_virtual_machine.worker2.private_ip_address} ansible_user=${var.admin_username}

[kube_control_plane]
control-plane

[etcd]
control-plane

[kube_node]
worker1
worker2

[k8s_cluster:children]
kube_control_plane
kube_node
EOT
}
