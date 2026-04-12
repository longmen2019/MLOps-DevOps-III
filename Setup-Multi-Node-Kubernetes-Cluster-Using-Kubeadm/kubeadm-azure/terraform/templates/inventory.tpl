[master]
cp1 ansible_host=${nodes["cp1"]} ansible_user=azureuser

[workers]
worker1 ansible_host=${nodes["worker1"]} ansible_user=azureuser
worker2 ansible_host=${nodes["worker2"]} ansible_user=azureuser

[kubernetes:children]
master
workers
