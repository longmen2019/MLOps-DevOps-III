# 📘 **Kubernetes Scheduling & Application Platform — End‑to‑End Project**

This project is a complete, production‑ready Kubernetes platform built on Azure Kubernetes Service (AKS).  
It includes cluster provisioning, workload deployments, scheduling strategies, resource management, networking, ingress routing, persistent storage, and multi‑namespace application isolation.

The work spans multiple days of iterative engineering, debugging, and refinement — resulting in a fully functioning, modular, and extensible Kubernetes environment.

---

# 🚀 **Project Overview**

This repository contains:

- **AKS cluster provisioning** using Terraform  
- **Node pool configuration** and scheduling strategies  
- **MongoDB StatefulSet** with persistent storage  
- **Nginx application stack** (Deployment, Service, Ingress)  
- **Todo application stack** (API + UI Deployments, Services, Ingress)  
- **Namespace isolation** (`nginx`, `todo`, `default`)  
- **Ingress routing** (host‑based + path‑based)  
- **Resource requests/limits** to prevent noisy‑neighbor issues  
- **RBAC, DaemonSets, CronJobs, Autoscaling, and more** (folder structure included)  

This project demonstrates real‑world Kubernetes engineering:  
from cluster creation → to workload deployment → to debugging → to production‑grade architecture.

---

# 🏗️ **1. AKS Cluster Provisioning (Terraform)**

You built an AKS cluster using Terraform with:

- Resource group creation  
- AKS cluster definition  
- Node pool configuration  
- Outputs for kubeconfig and node resource group  
- Versioned providers and lock files  

You also learned how to:

- Refresh kubeconfig when AKS regenerates the API server DNS  
- Fix stale kubeconfig errors  
- Re‑authenticate and overwrite credentials  

Commands used:

```powershell
az aks get-credentials --resource-group rg-k8s-scheduling --name k8s-scheduling --overwrite-existing
kubectl config get-contexts
kubectl get nodes
```

---

# 🗂️ **2. Namespace Architecture**

You created two isolated namespaces:

### `nginx` namespace  
Used for the nginx demo application.

### `todo` namespace  
Used for the full todo application stack.

Each namespace includes labels for:

- team ownership  
- environment  
- resource targeting  

---

# 🧱 **3. Nginx Application Stack**

You deployed a complete nginx stack:

### ✔ Namespace  
### ✔ Deployment (4 replicas)  
### ✔ ReplicaSet  
### ✔ Pod (standalone example)  
### ✔ Service (ClusterIP)  
### ✔ Ingress (TLS‑ready, host‑based)  

You corrected:

- resource requests/limits  
- container naming  
- selector/label alignment  
- ingressClassName  
- service port mismatches  

This resulted in a fully functional nginx endpoint:

```
https://nginx-demo.com
```

---

# 🗄️ **4. MongoDB StatefulSet (Persistent Storage)**

You deployed a production‑grade MongoDB StatefulSet with:

- 3 replicas  
- PersistentVolumeClaims  
- StorageClass  
- ConfigMap for `mongodb.conf`  
- Secret for credentials  
- Liveness, readiness, and startup probes  
- Headless Service (`mongo`)  

You also learned:

- StatefulSets cannot update immutable fields  
- How to restart vs. recreate StatefulSets  
- How to preserve or wipe PVCs  

Commands used:

```powershell
kubectl rollout restart statefulset mongo
kubectl delete statefulset mongo --cascade=orphan
kubectl delete pvc -l app=mongo
```

---

# 🧩 **5. Todo Application Stack (API + UI)**

You deployed a full two‑tier application:

## **Todo API**
- Deployment (2 replicas)  
- Corrected MongoDB URI  
- Resource requests/limits  
- Container port 8082  
- Service (ClusterIP, port 80 → 8082)  

## **Todo UI**
- Deployment (2 replicas)  
- Correct backend URL (`http://todo.com/api`)  
- Resource requests/limits  
- Container port 80  
- Service (ClusterIP, port 80)  

---

# 🌐 **6. Ingress Routing (Host‑Based + Path‑Based)**

You built two routing strategies:

## **Host‑Based Routing**
```
todo-ui.com → todo-ui-service
todo-api.com → todo-api-service
```

## **Path‑Based Routing**
```
todo.com/        → todo-ui-service
todo.com/api     → todo-api-service
```

You corrected:

- ingressClassName  
- rewrite-target rules  
- regex path handling  
- service port mismatches  
- namespace scoping  

---

# ⚙️ **7. Scheduling, Resource Management & Best Practices**

Throughout the project, you implemented:

- CPU/memory requests and limits  
- Prevention of noisy‑neighbor issues  
- Pod anti‑affinity (optional)  
- Node affinity (optional)  
- Clean label/selector patterns  
- Idempotent manifests  
- Correct ordering of namespace creation  

You also debugged:

- DNS lookup failures  
- kubeconfig corruption  
- namespace ordering issues  
- immutable StatefulSet fields  
- service/ingress mismatches  

---

# 📦 **8. Repository Structure**

Your repo now includes:

```
.
├── autoscaling/
├── cronjobs/
├── daemonset/
├── ingress-nginx/
├── rbac/
├── resourcemanagement/
├── scheduling/
├── statefulsets/
├── main.tf
├── nodepool.tf
├── variables.tf
├── outputs.tf
├── terraform.tfstate
└── version.tf
```

Each folder represents a Kubernetes concept you practiced and deployed.

---

# 🧪 **9. Verification Commands**

Useful commands you used repeatedly:

```powershell
kubectl get pods -A -o wide
kubectl get svc -A
kubectl get ingress -A
kubectl describe pod <name>
kubectl logs <pod>
kubectl apply -f <folder>/
kubectl delete -f <file>
```

---

# 🏁 **10. Final Result**

By the end of this project, you built:

- A fully functional AKS cluster  
- A multi‑namespace Kubernetes environment  
- A persistent MongoDB database  
- A two‑tier todo application  
- A standalone nginx application  
- Host‑based and path‑based ingress routing  
- Production‑grade resource management  
- Clean, reusable YAML manifests  
- A complete Terraform‑driven infrastructure  

This project demonstrates **real‑world Kubernetes engineering**, including provisioning, deployment, debugging, networking, storage, and best practices.

---