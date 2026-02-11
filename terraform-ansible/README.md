
# **Terraform + Ansible Nginx Deployment**

This project provisions Azure Linux virtual machines using **Terraform** and configures them automatically using **Ansible**. The configuration includes:

- Installing and managing **Nginx**
- Deploying a custom **index.html**
- Applying a templated Nginx site configuration
- Restarting Nginx via handlers when configuration changes

This repository demonstrates a clean, reproducible Infrastructure‑as‑Code workflow suitable for cloud automation, DevOps pipelines, and production‑grade deployments.

---

## **Project Structure**

```
terraform-ansible/
├── inventory.ini
├── main.tf
├── outputs.tf
├── providers.tf
├── variables.tf
├── roles/
│   └── nginx/
│       ├── tasks/
│       │   └── main.yml
│       ├── handlers/
│       │   └── main.yml
│       ├── templates/
│       │   └── default.j2
│       └── files/
│           └── index.html
├── site.yml
├── ssh.pem
└── terraform.tfstate
```

---

## **Prerequisites**

### **Local Machine**
- Windows 10/11 with **WSL2**
- Ubuntu 22.04+ inside WSL
- Terraform installed
- Ansible installed
- Azure CLI installed and authenticated

### **Azure**
- Subscription with permission to create:
  - Resource groups  
  - Virtual networks  
  - Public IPs  
  - Linux VMs  

---

## **1. Terraform Deployment**

### **Initialize Terraform**

```bash
terraform init
```

### **Validate configuration**

```bash
terraform validate
```

### **Plan the deployment**

```bash
terraform plan -out main.tfplan
```

### **Apply the deployment**

```bash
terraform apply main.tfplan
```

Terraform will output:

- Public IPs of the VMs  
- SSH connection details  

These values are used in the Ansible inventory.

---

## **2. Ansible Inventory**

`inventory.ini`:

```ini
[web]
vm0 ansible_host=<PUBLIC_IP_1> ansible_user=azureuser ansible_ssh_private_key_file=/mnt/c/Users/<user>/Downloads/terraform-ansible/ssh.pem ansible_ssh_common_args='-o StrictHostKeyChecking=no'
vm1 ansible_host=<PUBLIC_IP_2> ansible_user=azureuser ansible_ssh_private_key_file=/mnt/c/Users/<user>/Downloads/terraform-ansible/ssh.pem ansible_ssh_common_args='-o StrictHostKeyChecking=no'
```

---

## **3. Ansible Playbook**

`site.yml`:

```yaml
---
- hosts: web
  become: yes
  roles:
    - nginx
```

---

## **4. Nginx Role Structure**

### **Tasks**

`roles/nginx/tasks/main.yml`:

```yaml
---
- name: Install nginx
  apt:
    name: nginx
    state: present
    update_cache: yes

- name: Deploy nginx default site config
  template:
    src: default.j2
    dest: /etc/nginx/sites-available/default
  notify: restart nginx

- name: Deploy custom index.html
  copy:
    src: index.html
    dest: /var/www/html/index.html
    mode: '0644'

- name: Ensure nginx is running
  service:
    name: nginx
    state: started
    enabled: yes
```

### **Handlers**

`roles/nginx/handlers/main.yml`:

```yaml
---
- name: restart nginx
  service:
    name: nginx
    state: restarted
```

### **Template**

`roles/nginx/templates/default.j2`:

```nginx
server {
    listen 80 default_server;
    listen [::]:80 default_server;

    root /var/www/html;
    index index.html;

    server_name _;

    location / {
        try_files $uri $uri/ =404;
    }
}
```

### **Static File**

`roles/nginx/files/index.html`:

```html
<html>
  <head><title>Terraform + Ansible Deployment</title></head>
  <body>
    <h1>Deployed by Terraform + Ansible</h1>
    <p>This VM is configured automatically.</p>
  </body>
</html>
```

---

## **5. Run Ansible**

From inside WSL:

```bash
ansible -i inventory.ini web -m ping
```

Then apply the full configuration:

```bash
ansible-playbook -i inventory.ini site.yml
```

---

## **6. Verify Deployment**

```bash
curl http://<PUBLIC_IP_1>
curl http://<PUBLIC_IP_2>
```

You should see your custom HTML page.

---

## **7. Cleanup**

To destroy all Azure resources:

```bash
terraform destroy
```

---

## **Next Steps (Optional Enhancements)**

You can extend this project with:

- HTTPS + Certbot (Let’s Encrypt)
- Reverse proxy configuration
- Docker installation + container deployment
- Node/Python app deployment
- Terraform → Ansible automation via `null_resource`
- Monitoring stack (Prometheus + Grafana)
