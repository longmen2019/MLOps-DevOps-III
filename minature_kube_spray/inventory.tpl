[all]
control-plane ansible_host=${cp_private_ip} ip=${cp_private_ip} ansible_user=${admin_username}
worker1 ansible_host=${worker_private_ips[0]} ip=${worker_private_ips[0]} ansible_user=${admin_username}
worker2 ansible_host=${worker_private_ips[1]} ip=${worker_private_ips[1]} ansible_user=${admin_username}

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
