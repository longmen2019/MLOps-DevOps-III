# 🚀 Kubernetes Disaster Recovery with Velero + MinIO  
### Automated Deployment Using Terraform & Ansible

This project implements a **production‑grade backup and restore pipeline** for Kubernetes using:

- **Terraform** — infrastructure provisioning  
- **Ansible** — cluster automation & application deployment  
- **MinIO** — S3‑compatible object storage  
- **Velero** — Kubernetes backup & restore engine  

It includes full automation, credential management, Helm deployments, and a validated disaster‑recovery test.

---

## 📌 Architecture Overview

### Components
- **AKS / Kubernetes Cluster**  
- **MinIO** (S3 backend for Velero)  
- **Velero** (backup/restore engine)  
- **Ansible roles** for:
  - MinIO installation  
  - Velero installation  
  - Secret management  
  - Helm deployments  

### Data Flow
1. Velero uses AWS‑style credentials stored in a Kubernetes secret.  
2. Velero connects to MinIO via an internal ClusterIP service.  
3. Backups are stored in the MinIO bucket `velero-backups`.  
4. Restores pull data back from MinIO into the cluster.

---

## 🛠️ Deployment Workflow

### 1. Provision Infrastructure (Terraform)
Terraform creates:

- Resource group  
- AKS cluster  
- Node pools  
- Networking  

After provisioning, Terraform outputs the kubeconfig path used by Ansible.

---

## 🧩 Ansible Automation

### 2. Deploy MinIO (Ansible Role)
The MinIO role:

- Creates the `minio` namespace  
- Deploys MinIO via Helm  
- Creates the MinIO root credentials secret  
- Exposes:
  - API on port **9000**
  - Console on port **9001**

MinIO environment variables (validated):

```
MINIO_ROOT_USER=DB5EXKNNkaogIYlqOUQa
MINIO_ROOT_PASSWORD=DsWvOk9r6iWP2z5aG3t7M8NfZBZgg3fLOJM01Izb
```

---

### 3. Deploy Velero (Ansible Role)

The Velero role performs:

#### ✔ Create Velero namespace
```yaml
kind: Namespace
name: velero
```

#### ✔ Create Velero credentials secret
This secret must match MinIO **exactly** (case‑sensitive):

```
[default]
aws_access_key_id=DB5EXKNNkaogIYlqOUQa
aws_secret_access_key=DsWvOk9r6iWP2z5aG3t7M8NfZBZgg3fLOJM01Izb
```

#### ✔ Deploy Velero via Helm
Key configuration:

```yaml
configuration:
  backupStorageLocation:
    - name: default
      provider: aws
      bucket: velero-backups
      config:
        region: minio
        s3Url: "http://minio.minio.svc.cluster.local:9000"
        s3ForcePathStyle: true
        insecureSkipTLSVerify: true
```

---

## 🐛 Debugging Journey (What We Fixed)

This project included a deep debugging session to resolve:

### 1. Velero not installing  
Cause: Helm used `release_namespace` instead of `namespace`.

### 2. Velero pod not restarting after secret updates  
Fix:  
```
kubectl rollout restart deployment/velero -n velero
```

### 3. BackupStorageLocation stuck in `Unavailable`  
Root cause:  
**Secret key mismatch — uppercase vs lowercase character.**

Example:

- MinIO password:  
  `DsWv...` (lowercase s)

- Velero secret:  
  `DSwv...` (uppercase S)

This caused:

```
SignatureDoesNotMatch
```

Fixing the secret key resolved the issue.

### 4. Final validation  
After correction:

```
velero backup-location get
PHASE: Available
```

---

## 🔥 Disaster Recovery Test (Validated)

### Step 1 — Create test namespace + workload
```bash
kubectl create namespace demo
kubectl -n demo create deployment nginx --image=nginx
kubectl -n demo expose deployment nginx --port=80
```

### Step 2 — Create backup
```bash
velero backup create demo-backup --include-namespaces demo
```

### Step 3 — Simulate disaster
```bash
kubectl delete namespace demo
```

### Step 4 — Restore
```bash
velero restore create --from-backup demo-backup
```

### Step 5 — Validate
```bash
kubectl get all -n demo
```

Result:  
**Namespace, deployment, service, and pods fully restored.**

---

## 📁 Repository Structure

```
terraform/
  main.tf
  outputs.tf
  variables.tf

ansible/
  inventory.ini
  site.yml
  roles/
    minio/
    velero/
group_vars/
  all.yml
```

---

## 🧪 What This Project Demonstrates

- Production‑grade Kubernetes DR pipeline  
- Automated MinIO + Velero deployment  
- Secure secret management  
- Helm‑based application automation  
- Real backup/restore validation  
- Debugging of AWS‑style S3 signatures  
- End‑to‑end reproducibility  

This is the kind of project that shows **real engineering maturity**.

---

## 🎯 Next Enhancements (Optional)

- Scheduled backups (Velero schedules)  
- Retention policies  
- Multi‑cluster DR  
- Terraform‑managed MinIO storage class  
- GitHub Actions CI/CD for Ansible + Terraform  

---

Absolutely — a diagram will make your README feel complete and professional.  
Since you’re building a portfolio‑grade project, the diagram should clearly show:

- How Velero talks to MinIO  
- How MinIO stores backups  
- How Ansible + Terraform automate everything  
- How the backup/restore workflow actually flows  

Below is a **clean, Markdown‑friendly architecture diagram** you can paste directly into your README.  
It uses ASCII‑style blocks so it renders perfectly on GitHub without images.

If you want a **visual PNG/SVG diagram**, I can generate a draw.io‑ready version too.

---

# 📊 **Architecture Diagram (Markdown‑Friendly)**

```
                          ┌──────────────────────────────┐
                          │        Terraform              │
                          │  • Creates AKS Cluster        │
                          │  • Outputs kubeconfig         │
                          └──────────────┬───────────────┘
                                         │
                                         ▼
                          ┌──────────────────────────────┐
                          │          Ansible              │
                          │  • Deploys MinIO via Helm     │
                          │  • Deploys Velero via Helm    │
                          │  • Creates Kubernetes Secrets │
                          └──────────────┬───────────────┘
                                         │
                                         ▼
        ┌──────────────────────────────────────────────────────────────────────┐
        │                        Kubernetes Cluster (AKS)                      │
        │                                                                      │
        │   ┌──────────────────────┐          ┌────────────────────────────┐   │
        │   │      Velero          │          │           MinIO            │   │
        │   │  Namespace: velero   │          │     Namespace: minio       │   │
        │   │                      │          │                            │   │
        │   │  • Velero Deployment │   S3 API │  • MinIO Deployment        │   │
        │   │  • AWS Plugin        │◀────────▶│  • Bucket: velero-backups  │   │
        │   │  • cloud-credentials │  Port:   │  • Credentials Secret      │   │
        │   │                      │   9000   │                            │   │
        │   └──────────────────────┘          └────────────────────────────┘   │
        │                                                                      │
        │   ┌──────────────────────────────────────────────────────────────┐   │
        │   │                     Application Workloads                    │   │
        │   │                 (e.g., demo namespace, nginx)                │   │
        │   └──────────────────────────────────────────────────────────────┘   │
        │                                                                      │
        └──────────────────────────────────────────────────────────────────────┘

```

---

# 🔄 **Backup & Restore Flow Diagram**

```
┌──────────────────────────┐
│ 1. Velero Backup Command │
│    velero backup create  │
└───────────────┬──────────┘
                │
                ▼
┌──────────────────────────────────────────────┐
│ 2. Velero Reads cloud-credentials Secret     │
│    • Access Key                              │
│    • Secret Key                              │
└───────────────┬──────────────────────────────┘
                │
                ▼
┌──────────────────────────────────────────────┐
│ 3. Velero AWS Plugin Signs S3 Requests       │
│    using MinIO-compatible HMAC               │
└───────────────┬──────────────────────────────┘
                │
                ▼
┌──────────────────────────────────────────────┐
│ 4. MinIO Receives S3 API Calls               │
│    • Stores backups in velero-backups bucket │
└───────────────┬──────────────────────────────┘
                │
                ▼
┌──────────────────────────┐
│ 5. Backup Completed       │
│    velero backup get     │
└──────────────────────────┘


RESTORE FLOW
────────────

┌──────────────────────────┐
│ velero restore create    │
└───────────────┬──────────┘
                │
                ▼
┌──────────────────────────────────────────────┐
│ Velero pulls objects from MinIO bucket       │
└───────────────┬──────────────────────────────┘
                │
                ▼
┌──────────────────────────────────────────────┐
│ Kubernetes objects recreated:                │
│ • Namespaces                                 │
│ • Deployments                                │
│ • Services                                   │
│ • Pods                                       │
└──────────────────────────────────────────────┘
```

---

