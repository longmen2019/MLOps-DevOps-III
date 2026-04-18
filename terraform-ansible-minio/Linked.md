## 🚀 Excited to add a new project to my cloud engineering portfolio — a fully automated **Kubernetes → MinIO → Velero disaster‑recovery pipeline**, built, debugged, and validated end‑to‑end using Terraform and Ansible.

---

## 🧱 Infrastructure & Automation Highlights  
This project delivers a complete, reproducible DR environment:

- Provisioned an AKS Kubernetes cluster using **Terraform**  
- Automated deployment of **MinIO** (S3‑compatible storage) via **Helm + Ansible**  
- Automated deployment of **Velero** with correct AWS‑style credentials  
- Implemented clean, idempotent Ansible roles for MinIO, Velero, and secret management  
- Verified MinIO API, credentials, bucket creation, and internal service routing  
- Ensured full reproducibility across cluster rebuilds and DR simulations  

---

## 💾 Backup & Restore Pipeline Highlights  
The project demonstrates a full disaster‑recovery workflow:

- Configured Velero to use MinIO as an S3 backend (`velero-backups` bucket)  
- Validated BackupStorageLocation health and S3 connectivity  
- Debugged and resolved AWS‑style HMAC signature mismatches  
- Performed a complete **backup → delete → restore** cycle of a live namespace  
- Successfully restored deployments, services, pods, and workloads from MinIO  
- Confirmed Velero’s end‑to‑end DR capability inside the cluster  

---

## 🐛 Deep‑Dive Debugging Wins  
This project included real engineering challenges:

- Correcting Helm namespace behavior (`namespace:` vs `release_namespace:`)  
- Ensuring Velero pods reload updated secrets (manual rollout restarts)  
- Diagnosing MinIO credential precedence and environment variable overrides  
- Tracking down a **single‑character case‑sensitive mismatch** in the secret key that caused `SignatureDoesNotMatch` errors  
- Validating S3 API calls, MinIO logs, and Velero plugin behavior  

These are the kinds of issues that appear only in real‑world DR pipelines — and solving them builds real operational confidence.

---

## 🎯 Why This Project Matters  
This work demonstrates practical, production‑grade **Kubernetes disaster recovery**:

- Automated infrastructure provisioning  
- Automated storage backend deployment  
- Automated Velero installation and configuration  
- Secure secret management  
- Real backup/restore validation  
- Troubleshooting across Kubernetes, S3 APIs, Helm, and Ansible  

It reflects the exact skillset used across DevOps, SRE, and cloud platform engineering teams — and the entire setup is clean, reproducible, and ready to scale into scheduled backups, retention policies, and multi‑cluster DR.

---

## 🔗 Project link: *[Add your GitHub repo link here]*

---

**#Kubernetes #Velero #MinIO #Terraform #Ansible #CloudEngineering #DevOps #SRE #DisasterRecovery #Backup #Automation #IaC #TechPortfolio #Reproducibility**

