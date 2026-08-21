# 🛠️ Troubleshooting

This section covers the most common issues encountered when provisioning the EC2 instance, running Terraform, configuring Ansible, and interacting with the k3d Kubernetes cluster.

---

## 🔑 SSH Key Errors  
### **Symptom**
```
Load key "loki-monitoring.pem": invalid format
Permission denied (publickey).
```

### **Cause**  
The `.pem` file was exported using Windows default encoding (UTF‑16), which corrupts the key format.

### **Fix**
Export the key correctly:

```powershell
terraform output -raw private_key_pem | Out-File -Encoding ascii loki-monitoring.pem
```

Move the key into WSL:

```bash
cp loki-monitoring.pem ~/.ssh/
chmod 600 ~/.ssh/loki-monitoring.pem
```

Test SSH:

```bash
ssh -i ~/.ssh/loki-monitoring.pem ubuntu@<EC2_PUBLIC_IP>
```

Update Ansible inventory:

```
ansible_ssh_private_key_file=~/.ssh/loki-monitoring.pem
```

---

## 🌐 Wrong EC2 IP / No Public IP  
### **Symptom**
```
curl -s http://169.254.169.254/latest/meta-data/public-ipv4
# returns nothing
```

### **Cause**  
Terraform created the instance without assigning a public IP.

### **Fix**
Add this to your EC2 resource:

```hcl
associate_public_ip_address = true
```

Reapply:

```bash
terraform apply
```

Retrieve the correct IP:

```bash
aws ec2 describe-instances --filters "Name=tag:Name,Values=monitoring-vm" \
  --query "Reservations[*].Instances[*].PublicIpAddress" --output text
```

---

## 🔒 Port 80 Refused  
### **Symptom**
```
nc -vz <EC2_IP> 80
Connection refused
```

### **Cause**  
The EC2 Security Group does not allow inbound HTTP traffic.

### **Fix**
Add this rule:

```hcl
ingress {
  description = "HTTP for Grafana Ingress"
  from_port   = 80
  to_port     = 80
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
}
```

Apply:

```bash
terraform apply
```

---

## 🧩 Kubectl: “Connection refused on localhost:8080”  
### **Symptom**
```
The connection to the server localhost:8080 was refused
```

### **Cause**  
The kubeconfig file does not exist for the `ubuntu` user.

### **Fix**
```bash
mkdir -p ~/.kube
k3d kubeconfig get monitoring > ~/.kube/config
chmod 600 ~/.kube/config
```

Test:

```bash
kubectl get nodes
kubectl get pods -n monitoring
```

Optional alias:

```bash
echo "alias k='kubectl'" >> ~/.bashrc
source ~/.bashrc
```

---

## 🌀 Terraform Provider Not Downloading  
### **Symptom**
Terraform prints “Installing provider…” but never downloads anything.

### **Cause**  
Terraform is running on **Windows**, but the providers are Linux binaries.  
WSL must run Terraform.

### **Fix**
Install Terraform inside WSL:

```bash
curl -LO https://releases.hashicorp.com/terraform/1.9.5/terraform_1.9.5_linux_amd64.zip
sudo apt install unzip -y
unzip terraform_1.9.5_linux_amd64.zip
sudo mv terraform /usr/local/bin/
terraform version
```

You must see:

```
Terraform v1.9.5 on linux_amd64
```

Reinitialize:

```bash
rm -rf .terraform .terraform.lock.hcl
terraform init
terraform plan
```

---

## 🔌 SSH Tunnel Not Working (Grafana on localhost:3000 fails)  
### **Symptom**
Browser shows:

```
localhost:3000 → connection refused
```

### **Cause**  
SSH tunnel failed because the wrong key path was used.

### **Fix**

On your laptop:

```bash
ssh -i ~/.ssh/loki-monitoring.pem -L 3000:localhost:3000 ubuntu@<EC2_PUBLIC_IP>
```

Inside EC2:

```bash
kubectl port-forward svc/grafana 3000:3000 -n monitoring
```

Grafana now loads at:

```
http://localhost:3000
```

---

## 📦 Pods Stuck in `ContainerCreating`  
### **Cause**  
Images are still pulling after cluster recreation.

### **Fix**
```bash
kubectl get pods -n monitoring -w
```

Wait until all pods reach `Running`.

---

## 🌐 Ingress Active but Grafana Not Loading  
### **Checklist**
1. Pods are **Running**
2. Loadbalancer exposes **80/443**
3. EC2 SG allows **port 80**
4. Correct EC2 public IP is used
5. Ingress exists:

```bash
kubectl get ingress -n monitoring
```