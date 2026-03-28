# 📘 **README.md — Microsoft Sentinel Production Deployment (Terraform)**

## 🔹 Overview

This Terraform project deploys a **production‑ready Microsoft Sentinel environment** in Azure, including:

- Management Group + Subscription association  
- Resource Group  
- Log Analytics Workspace  
- Microsoft Sentinel onboarding  
- Virtual Network, Subnet, NSG  
- Linux VM with Public IP (Standard SKU)  
- Azure Monitor Agent (AMA)  
- Data Collection Rule (DCR) for Syslog  
- DCR Association to VM  
- Azure AD Diagnostic Settings → Sentinel  
- Sentinel Scheduled Alert Rule (Failed SSH Login)

This deployment follows **modern Azure best practices**, avoids deprecated resources, and is validated for **East US**.

---

## 🔹 Architecture Diagram (Conceptual)

```
Management Group
      │
Subscription
      │
Resource Group (sentinel-rg)
      ├── Log Analytics Workspace (LAW)
      ├── Sentinel Onboarding
      ├── Virtual Network (10.0.0.0/16)
      │     └── Subnet (10.0.1.0/24)
      ├── NSG + SSH Rule
      ├── Public IP (Standard SKU)
      ├── NIC
      ├── Linux VM (Ubuntu 22.04)
      │     ├── AMA Extension
      │     └── DCR Association
      ├── Data Collection Rule (Syslog)
      ├── AAD Diagnostic Settings
      └── Sentinel Alert Rule (Failed SSH Login)
```

---

## 🔹 Prerequisites

Before running Terraform:

- Azure CLI installed and logged in  
- Contributor or Owner role on the subscription  
- Management Group write permissions  
- Terraform v1.5+  
- Provider `azurerm` v3.100+  

Login:

```bash
az login
az account set --subscription "<subscription-id>"
```

---

## 🔹 Files in This Project

| File | Purpose |
|------|---------|
| `main.tf` | Core Terraform resources |
| `variables.tf` | Input variables |
| `terraform.tfvars` | Environment‑specific values |
| `outputs.tf` | Useful outputs (public IP, workspace ID) |

---

## 🔹 How to Use

### **1. Initialize Terraform**

```bash
terraform init
```

### **2. Validate**

```bash
terraform validate
```

### **3. Preview changes**

```bash
terraform plan
```

### **4. Deploy**

```bash
terraform apply
```

Type `yes` when prompted.

---

## 🔹 SSH Access to the VM

After deployment, retrieve the VM’s public IP:

```bash
terraform output vm_public_ip
```

SSH into the VM:

```bash
ssh azureuser@<public-ip>
```

---

## 🔹 Verifying AMA + Syslog Ingestion

Run this KQL query in Sentinel:

```kusto
Syslog
| take 50
```

If logs appear, AMA + DCR are working.

---

## 🔹 Verifying Sentinel Onboarding

Run:

```bash
az sentinel alert-rule list \
  --resource-group <rgname> \
  --workspace-name <workspacename>
```

You should see:

- Built‑in Fusion rule  
- Failed SSH Login rule  

---

## 🔹 Testing the Failed SSH Login Alert

From any machine, attempt an invalid SSH login:

```bash
ssh wronguser@<public-ip>
```

Then run this KQL:

```kusto
Syslog
| where SyslogMessage contains "Failed password"
```

Sentinel will generate an incident within 5 minutes.

---

## 🔹 Destroying the Environment

To remove all resources:

```bash
terraform destroy
```

---

## 🔹 Notes & Best Practices

- Public IP uses **Standard SKU** to avoid subscription limits.  
- Sentinel onboarding uses the **modern onboarding resource**, not deprecated solutions.  
- AMA + DCR is the **only supported** ingestion method going forward.  
- AAD diagnostic settings do **not** support retention policies.  
- VM password authentication is enabled for simplicity; SSH keys are recommended for production.

---

## 🔹 Support

For Azure Sentinel documentation:  
[https://learn.microsoft.com/azure/sentinel/](https://learn.microsoft.com/azure/sentinel/)

For Terraform AzureRM provider:  
`https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs` [(registry.terraform.io in Bing)](https://www.bing.com/search?q="https%3A%2F%2Fregistry.terraform.io%2Fproviders%2Fhashicorp%2Fazurerm%2Flatest%2Fdocs")

