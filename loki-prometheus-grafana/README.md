## 🚀 Architecture Overview

### **Infrastructure (Terraform)**
- Creates a dedicated VPC (`10.0.0.0/16`)
- Public subnet (`10.0.1.0/24`)
- Internet Gateway + Route Table
- Security Group allowing:
  - SSH (22)
  - HTTP (80) — **Traefik Ingress**
  - Optional: Grafana (3000), Loki (3100)
- EC2 instance (Ubuntu 24.04)
  - `associate_public_ip_address = true` ensures external access

### **Configuration (Ansible)**
- Installs Docker + k3d
- Creates a k3d cluster with:
  - 1 server
  - 1 agent
  - Loadbalancer exposing ports:
    - `80:80@loadbalancer`
    - `443:443@loadbalancer`
- Copies Kubernetes manifests to the EC2 instance
- Applies:
  - Grafana
  - Loki
  - Prometheus
  - Promtail
  - Alertmanager
  - Traefik Ingress

### **Kubernetes (k3d / k3s)**
- All monitoring components run inside the `monitoring` namespace
- Traefik (built into k3s) handles Ingress routing
- Grafana becomes reachable at:

```
http://<EC2_PUBLIC_IP>/
```

---

## 📦 Components Deployed

| Component     | Purpose |
|---------------|---------|
| **Grafana**   | Dashboards + visualization |
| **Loki**      | Log aggregation |
| **Promtail**  | Log shipping from nodes |
| **Prometheus**| Metrics collection |
| **Alertmanager** | Alert routing |
| **Traefik**   | Ingress controller (k3s default) |

---

## 🧱 Prerequisites

- Terraform ≥ 1.5
- Ansible ≥ 2.15
- AWS credentials configured locally
- SSH key pair for EC2 access

---

## 🛠️ Deployment Steps

### **1. Provision AWS Infrastructure**

```bash
terraform init
terraform apply
```

Terraform outputs the EC2 public IP.

### **2. SSH into the EC2 Instance**

```bash
ssh ubuntu@<EC2_PUBLIC_IP>
```

### **3. Run Ansible Playbook**

From your local machine:

```bash
ansible-playbook -i inventory monitoring.yaml
```

This will:

- Install Docker
- Install k3d
- Create the cluster
- Apply all monitoring manifests

---

## 🌐 Accessing Grafana

Once the cluster is up and manifests applied:

```
http://<EC2_PUBLIC_IP>/
```

If the page doesn’t load, verify:

1. EC2 Security Group allows inbound port **80**
2. k3d loadbalancer exposes **80 → 80**
3. Ingress exists:

```bash
kubectl get ingress -n monitoring
```

You should see:

```
grafana-ingress   *   <internal k3d IPs>   80
```

---

## 🔍 Troubleshooting

### **Pods stuck in `ContainerCreating`**
Images are still pulling. Wait 20–60 seconds:

```bash
kubectl get pods -n monitoring
```

### **`ERR_CONNECTION_REFUSED`**
This always means **AWS Security Group is blocking port 80** or the instance has **no public IP**.

Check public IP:

```bash
curl -s http://169.254.169.254/latest/meta-data/public-ipv4
```

If empty → instance has no public IP → fix Terraform:

```hcl
associate_public_ip_address = true
```

### **Ingress not routing**
Check Traefik:

```bash
kubectl get svc -n kube-system | grep traefik
```

---

## 📁 Repository Structure

```
.
├── terraform/
│   ├── main.tf
│   ├── variables.tf
│   └── outputs.tf
├── ansible/
│   ├── monitoring.yaml
│   ├── inventory
│   └── roles/
├── k8s/
│   ├── grafana/
│   ├── loki/
│   ├── prometheus/
│   └── promtail/
└── README.md
```

---

## 🧹 Cleanup

Destroy all resources:

```bash
terraform destroy
```

---

## 📘 Summary

This project gives you a fully automated, reproducible monitoring stack on AWS using modern tooling:

- Terraform for infrastructure
- Ansible for configuration
- k3d/k3s for lightweight Kubernetes
- Traefik for ingress
- Grafana + Loki + Prometheus + Promtail + Alertmanager for observability



