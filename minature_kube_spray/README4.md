
# **Kubernetes Networking Deep‑Dive & Recovery Lab (Kubespray + Calico + Azure)**

This project documents a full lifecycle Kubernetes networking investigation, built on Azure using **Kubespray**, **Calico**, and **IPVS‑based kube‑proxy**.  
It covers cluster provisioning, overlay networking validation, service routing diagnostics, packet‑level analysis, and workload verification — all executed with production‑grade rigor.

---

## **📌 Table of Contents**
- [Overview](#overview)  
- [Architecture](#architecture)  
- [Objectives](#objectives)  
- [Cluster Deployment](#cluster-deployment)  
- [Networking Validation](#networking-validation)  
- [Service Routing & kube-proxy Analysis](#service-routing--kube-proxy-analysis)  
- [Calico Diagnostics](#calico-diagnostics)  
- [Workload Deployment](#workload-deployment)  
- [Issue Resolution Summary](#issue-resolution-summary)  
- [Key Learnings](#key-learnings)  
- [Technologies Used](#technologies-used)

---

# **Overview**

This project demonstrates a complete, architect‑level walkthrough of Kubernetes networking — from cluster provisioning to VXLAN packet capture, IPVS service routing, and workload validation.

The environment was deployed using **Kubespray** on Azure, with Calico providing the CNI and kube‑proxy operating in **IPVS mode**.  
The focus of the lab was to diagnose and resolve a real‑world networking issue where pods on a worker node were unable to reach the Kubernetes API service (`10.233.0.1:443`).

---

# **Architecture**

### **Cluster Topology**
- **1× Control Plane Node**  
  - Internal IP: `10.10.1.6`  
  - Public IP: Azure‑assigned  
- **2× Worker Nodes**  
  - Worker1: `10.10.1.5`  
  - Worker2: `10.10.1.7`

### **Networking Components**
- **Calico VXLAN overlay** (`UDP 4789`)
- **Pod CIDRs**: `10.233.0.0/16`  
- **Service CIDRs**: `10.233.0.0/18`  
- **kube-proxy**: IPVS mode  
- **Azure VNet**: Flat L3 network, no NSG restrictions on internal traffic

---

# **Objectives**

### **Primary Goals**
- Deploy a reproducible Kubernetes cluster using Kubespray  
- Validate Calico VXLAN overlay networking  
- Diagnose service VIP routing failures  
- Restore full cluster networking health  
- Deploy and expose workloads for functional verification  

### **Secondary Goals**
- Strengthen packet‑level observability  
- Validate kube‑proxy behavior in IPVS mode  
- Understand Calico routing, blackhole routes, and VTEP mappings  
- Build a reusable troubleshooting workflow for future clusters  

---

# **Cluster Deployment**

The cluster was deployed using **Kubespray**, leveraging:

- Ansible‑driven provisioning  
- Automated control plane bootstrapping  
- Automated worker node join  
- Calico CNI installation  
- kube‑proxy configured in IPVS mode  
- Deterministic, idempotent cluster creation

After deployment:

```bash
kubectl get nodes -o wide
```

confirmed all nodes were registered and Ready.

---

# **Networking Validation**

### **1. VXLAN Encapsulation Verification**

Using `tcpdump` on worker1:

```bash
sudo tcpdump -ni any udp port 4789
```

Captured bidirectional VXLAN traffic:

```
10.10.1.5.xxx > 10.10.1.6.4789: VXLAN vni 4096
10.10.1.6.xxx > 10.10.1.5.4789: VXLAN vni 4096
```

This confirmed:
- VXLAN tunnels were established  
- Encapsulation/decapsulation was functioning  
- Azure VNet was not blocking overlay traffic  

---

### **2. Pod Routing Validation**

`ip route` on worker1 showed:

```
10.233.120.0/26 via 10.233.120.0 dev vxlan.calico onlink
10.233.125.0/26 via 10.233.125.0 dev vxlan.calico onlink
blackhole 10.233.105.128/26 proto 80
```

This validated:
- Calico programmed pod CIDR routes correctly  
- Blackhole routes were expected for host‑local pod blocks  
- No routing inconsistencies existed  

---

# **Service Routing & kube-proxy Analysis**

### **1. kube-proxy Mode Verification**

Logs confirmed IPVS mode:

```
Using ipvs Proxier
```

### **2. IPVS Table Inspection**

```bash
sudo ipvsadm -Ln
```

Showed:

```
TCP 10.233.0.1:443 rr
  -> 10.10.1.6:6443 Masq
```

This validated:
- The Kubernetes API service VIP was programmed  
- kube-proxy was healthy  
- Endpoint load balancing was active  

---

# **Calico Diagnostics**

### **Problem Observed**
`calico-kube-controllers` was failing with:

```
dial tcp 10.233.0.1:443: i/o timeout
```

This indicated:
- Pods on worker1 could not reach the API service VIP  
- kube-proxy had not yet programmed service rules at the time  

### **Resolution**
Once kube-proxy finished syncing and IPVS entries appeared, restarting the Calico controllers resolved the issue:

```bash
kubectl delete pod -n kube-system -l k8s-app=calico-kube-controllers
```

After restart:
- Calico controllers became Ready  
- CoreDNS on worker2 recovered  
- Cluster networking became fully healthy  

---

# **Workload Deployment**

### **1. Deploy nginx**

```bash
kubectl run nginx --image=nginx
```

### **2. Create a Service**

```yaml
apiVersion: v1
kind: Service
metadata:
  name: nginx
spec:
  selector:
    app: nginx
  ports:
  - port: 80
    targetPort: 80
```

### **3. Port‑Forward for Local Access**

```bash
sudo kubectl port-forward svc/nginx 8080:80
```

Accessed via:

```
http://127.0.0.1:8080
```

---

# **Issue Resolution Summary**

### **Root Cause**
Service VIP (`10.233.0.1`) was unreachable from worker1 pods because kube-proxy had not yet programmed IPVS rules.

### **Fix**
- Verified kube-proxy health  
- Confirmed IPVS service entries  
- Restarted Calico controllers after VIP became reachable  

### **Outcome**
- Full cluster networking restored  
- DNS, Calico, and workloads became healthy  
- End‑to‑end connectivity validated  

---

# **Key Learnings**

- VXLAN packet capture is invaluable for validating overlay networks  
- kube-proxy in IPVS mode provides clear visibility into service routing  
- Calico routing tables and blackhole routes are essential for pod isolation  
- Service VIP propagation delays can cascade into CNI failures  
- A structured, packet‑level troubleshooting workflow accelerates root cause analysis  

---

# **Technologies Used**

- **Kubernetes (v1.28)**  
- **Kubespray**  
- **Calico CNI (VXLAN mode)**  
- **kube-proxy (IPVS)**  
- **Azure Virtual Machines & VNet**  
- **containerd**  
- **tcpdump, ipvsadm, iptables**  

---
