# 📘 ETCD Backup Automation (Phase 1)  
**Automated Kubernetes ETCD Backup Pipeline — Infrastructure, Scheduling, and Storage Layer**

This repository contains the **first half** of a complete ETCD Disaster Recovery (DR) system: the full automation pipeline responsible for orchestrating ETCD snapshot backups on a Kubernetes cluster.

Phase 1 focuses on building the **infrastructure, scheduling, and automation logic** required to perform ETCD backups in a production‑grade environment.  
Phase 2 (coming next) will run this pipeline on a **self‑managed kubeadm control plane**, where ETCD certificates and direct access to the datastore are available.

---

## 🚀 Phase 1 Overview  
The goal of Phase 1 is to build a **fully automated ETCD backup pipeline** using:

- **Terraform** for declarative infrastructure  
- **Kubernetes CronJobs** for scheduled execution  
- **ConfigMaps** for backup scripts  
- **PersistentVolumeClaims** for snapshot storage  
- **Secrets** (placeholder) for ETCD TLS certificates  
- **MinIO** (optional) for off‑cluster backup retention  

This phase delivers the entire automation layer — everything required to perform ETCD backups once the cluster provides ETCD access.

---

## 🧩 Architecture Diagram (Phase 1)

```
+-----------------------------+
|        Terraform            |
|  - Namespace                |
|  - PVC                      |
|  - ConfigMap (backup.sh)   |
|  - CronJob                  |
|  - Secret (TLS placeholder) |
+--------------+--------------+
               |
               v
+-----------------------------+
|       Kubernetes            |
| Namespace: etcd-backup      |
|                             |
| +-------------------------+ |
| | CronJob: etcd-backup   | |
| |  - Runs backup.sh      | |
| |  - Creates Jobs        | |
| +-----------+-------------+ |
|             |               |
|             v               |
| +-------------------------+ |
| | Job: manual/cron run   | |
| |  - Mounts PVC          | |
| |  - Mounts script       | |
| |  - Mounts TLS secret*  | |
| +-----------+-------------+ |
|             |               |
|             v               |
| +-------------------------+ |
| | Pod: etcd-backup       | |
| |  - Executes etcdctl*   | |
| |  - Saves snapshot      | |
| |  - Uploads to MinIO*   | |
| +-------------------------+ |
|                             |
+-----------------------------+

* ETCD access and TLS certs are added in Phase 2.
```

---

## 📦 Components Delivered in Phase 1

### **1. Namespace**
A dedicated namespace isolates all backup resources:

```
etcd-backup
```

---

### **2. PersistentVolumeClaim (PVC)**  
Stores ETCD snapshots locally before upload or retention cleanup.

- StorageClass: Azure Disk (AKS)
- Binding mode: WaitForFirstConsumer
- Size: configurable via Terraform

---

### **3. ConfigMap: `backup.sh`**  
Contains the full backup script, including:

- Snapshot creation (Phase 2)
- MinIO upload logic
- Retention cleanup
- Logging and error handling

The script is mounted into the backup pod at runtime.

---

### **4. CronJob: `etcd-backup-cron`**  
Schedules automated backups using Kubernetes native CronJob controller.

- Default schedule: hourly (`0 * * * *`)
- Creates Jobs → Pods → Executes backup script
- Fully Terraform‑managed

---

### **5. Manual Backup Job**  
Triggered via:

```bash
kubectl -n etcd-backup create job --from=cronjob/etcd-backup-cron manual-backup
```

Useful for:

- Testing the pipeline  
- On‑demand snapshots  
- DR validation workflows  

---

### **6. Secret (TLS Placeholder)**  
Terraform defines the secret resource, but ETCD TLS certs are added in **Phase 2**, when running on a self‑managed kubeadm control plane.

---

## 🧠 Why Phase 1 Does Not Produce an ETCD Snapshot  
This phase was developed on **AKS**, which is a *managed control plane*.  
AKS does **not** expose:

- ETCD endpoints  
- ETCD client certificates  
- Control plane filesystem  
- SSH access  

Therefore:

- The backup pod cannot authenticate to ETCD  
- The ETCD snapshot command cannot run  
- The TLS secret cannot be populated  

This is expected and correct for AKS.

Phase 1 is about building the automation pipeline — not executing the snapshot yet.

---

## 🏁 Phase 2 (Next Step)  
Phase 2 will run this pipeline on a **self‑managed kubeadm control plane**, enabling:

- Access to `/etc/kubernetes/pki/etcd/*`  
- Real ETCD snapshots via `etcdctl`  
- MinIO uploads  
- Full DR restore testing  

This will complete the end‑to‑end ETCD Disaster Recovery workflow.

---

## 📚 Summary  
Phase 1 successfully delivers:

- A complete, production‑grade ETCD backup automation pipeline  
- Fully Terraform‑managed Kubernetes resources  
- A reusable backup script with snapshot, upload, and retention logic  
- A CronJob‑driven scheduling system  
- A PVC‑backed storage layer  
- A clean foundation for Phase 2 (real ETCD access)

You now have the **entire automation layer** ready to run on any cluster where ETCD is accessible.

Phase 2 will complete the project by running this pipeline on a kubeadm control plane and generating real ETCD snapshots.

---

