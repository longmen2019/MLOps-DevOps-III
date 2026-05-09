## 🚀 Excited to add a new project to my cloud engineering portfolio — a fully automated **Kubernetes ETCD backup orchestration pipeline**, built end‑to‑end with Terraform and native Kubernetes controllers.

🧱 **Infrastructure & Automation Highlights**  
This project delivers a complete, reproducible backup automation environment, including:

- A dedicated `etcd-backup` namespace provisioned through Terraform  
- A PersistentVolumeClaim for storing ETCD snapshots with CSI‑backed storage  
- A ConfigMap‑driven backup script designed for snapshot creation, retention, and optional MinIO upload  
- A Kubernetes CronJob that schedules recurring ETCD backup jobs  
- On‑demand backup execution using `kubectl create job --from=cronjob/...`  
- Clean, modular Terraform code managing all Kubernetes resources declaratively  

🌐 **Backup Workflow Highlights**  
The pipeline is engineered to support:

- Automated execution of ETCD backup logic inside a dedicated pod  
- Script‑based snapshot generation using `etcdctl` (ready for clusters exposing ETCD access)  
- Optional off‑cluster archival to MinIO or S3‑compatible storage  
- Retention cleanup to manage backup lifecycle  
- Clear separation of concerns between storage, scheduling, and execution layers  
- Full reproducibility across clusters using IaC  

🎯 **Why This Project Matters**  
This work demonstrates real‑world Kubernetes DR automation patterns — CronJob‑driven workflows, PVC‑backed state management, ConfigMap‑injected scripts, and Terraform‑managed cluster resources.  
It reflects the exact skillset used across platform engineering, SRE, and cloud infrastructure teams for building reliable, repeatable, and production‑ready backup systems.

The setup is clean, modular, and ready to run on any self‑managed Kubernetes control plane where ETCD access is available — forming the foundation for a complete snapshot + restore disaster recovery workflow.

🔗 *Project link:* (add your GitHub link here)

#Kubernetes #ETCD #Terraform #CloudEngineering #DevOps #SRE #DisasterRecovery #Automation #InfrastructureAsCode #TechPortfolio #Reproducibility #Containers #Linux

