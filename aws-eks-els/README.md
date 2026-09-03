# 📘 **AWS EKS + ELK Stack Deployment (Terraform)**
A fully automated deployment of an Amazon EKS cluster and an ELK (Elasticsearch, Logstash, Kibana, Filebeat) observability stack using Terraform.  
This project provisions AWS networking, Kubernetes infrastructure, and log ingestion pipelines end‑to‑end.

---

## 🧱 **Architecture Overview**

### **AWS Resources**
- Custom VPC  
- Public subnets  
- Internet Gateway  
- Route tables  
- EKS cluster  
- Managed node group  
- IAM roles & policies  

### **Kubernetes Resources**
- Elasticsearch Deployment + Service  
- Kibana Deployment + Service  
- Logstash Deployment + Service  
- Filebeat DaemonSet  
- RBAC (ServiceAccount, ClusterRole, ClusterRoleBinding)  
- ConfigMaps for Logstash & Filebeat  

### **Terraform Automation**
- VPC module  
- EKS module  
- Automatic kubeconfig update  
- Automatic ELK deployment via `null_resource`  

---

## 📂 **Project Structure**

```
aws-eks-els/
├── modules/
│   ├── vpc/
│   └── eks/
├── elk/
│   ├── elasticsearch-deployment.yaml
│   ├── kibana-deployment.yaml
│   ├── logstash-deployment.yaml
│   ├── filebeat-daemonset.yaml
│   ├── filebeat-configmap.yaml
│   ├── filebeat-service-account.yaml
│   ├── filebeat-cluster-role.yaml
│   ├── filebeat-cluster-role-binding.yaml
│   └── logstash-configmap.yaml
├── main.tf
├── variables.tf
├── outputs.tf
└── README.md
```

---

## 🚀 **Deployment Instructions**

### **1. Initialize Terraform**
```
terraform init
```

### **2. Validate configuration**
```
terraform validate
```

### **3. Deploy infrastructure**
```
terraform apply
```

Terraform will:
- Create the VPC  
- Create subnets, IGW, route tables  
- Deploy the EKS cluster  
- Deploy the node group  
- Update kubeconfig  
- Deploy the ELK stack into the cluster  

---

## 🔧 **Key Terraform Components**

### **VPC Module**
Creates:
- VPC  
- Public subnets  
- Internet gateway  
- Route tables  

### **EKS Module**
Creates:
- EKS control plane  
- Managed node group  
- Security groups  
- IAM roles  

### **Kubeconfig Auto‑Update**
```hcl
resource "null_resource" "update_kubeconfig" {
  depends_on = [module.eks]

  triggers = {
    cluster_name = module.eks.cluster_name
  }

  provisioner "local-exec" {
    command = "aws eks update-kubeconfig --name ${module.eks.cluster_name} --region us-west-2"
  }
}
```

### **ELK Auto‑Deployment**
Terraform applies all manifests inside `elk/`:

```hcl
resource "null_resource" "deploy_elk" {
  depends_on = [null_resource.update_kubeconfig]

  triggers = {
    elk_files_hash = sha256(join("", [
      for f in fileset("${path.module}/elk", "**") : filesha256("${path.module}/elk/${f}")
    ]))
  }

  provisioner "local-exec" {
    command = <<-EOT
      kubectl create namespace elk --dry-run=client -o yaml | kubectl apply -f -
      kubectl apply -f ${path.module}/elk/filebeat-service-account.yaml
      kubectl apply -f ${path.module}/elk/filebeat-cluster-role.yaml
      kubectl apply -f ${path.module}/elk/filebeat-cluster-role-binding.yaml
      kubectl apply -f ${path.module}/elk/logstash-configmap.yaml
      kubectl apply -f ${path.module}/elk/filebeat-configmap.yaml
      kubectl apply -f ${path.module}/elk/
    EOT
  }
}
```

---

## 📊 **ELK Stack Details**

### **Elasticsearch**
- Single‑node deployment  
- Stores logs from Filebeat → Logstash  

### **Kibana**
- Web UI for log visualization  
- Accessible via LoadBalancer service  

### **Logstash**
- Receives logs from Filebeat  
- Parses and forwards logs to Elasticsearch  

### **Filebeat**
- Runs as a DaemonSet  
- Harvests container logs from each node  
- Autodiscover enabled  
- Sends logs to Logstash  

Corrected DaemonSet includes:

```yaml
env:
  - name: NODE_NAME
    valueFrom:
      fieldRef:
        fieldPath: spec.nodeName
```

---

## 🔍 **Verification**

### **Check EKS cluster**
```
kubectl get nodes
```

### **Check ELK pods**
```
kubectl get pods -n elk
```

### **Check Elasticsearch indices**
```
kubectl port-forward -n elk svc/elasticsearch 9200:9200
curl localhost:9200/_cat/indices?v
```

### **Open Kibana**
```
kubectl get svc -n elk kibana
```
Open the LoadBalancer URL in your browser.

---

## 🧹 **Destroy Infrastructure**

```
terraform destroy
```

This removes:
- EKS cluster  
- Node groups  
- VPC  
- ELK stack  
- All Kubernetes resources  

---

## 📝 **Notes**
- Filebeat will only generate indices once pods produce logs.  
- Ensure AWS credentials and region (`us-west-2`) are configured.  
- ELK stack runs inside the EKS cluster; no external servers required.  

---

## 📦 **Future Enhancements**
- Add persistent storage for Elasticsearch  
- Add autoscaling for EKS nodes  
- Add Ingress for Kibana  
- Add Logstash pipelines for structured logs  
- Add monitoring dashboards  

---
