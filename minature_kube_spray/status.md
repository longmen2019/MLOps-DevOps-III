
## 🚀 Excited to add a new project to my cloud engineering portfolio — a full **Kubespray → Calico → Kubernetes networking diagnostic and recovery lab**, built and debugged end‑to‑end on Azure.

On the cluster provisioning side, the experiment demonstrates:

🔹 Deployment of a multi‑node Kubernetes cluster using **Kubespray** on Azure  
🔹 Automated provisioning of control plane + worker nodes with clean, reproducible IaC  
🔹 Validation of node networking, routing tables, and pod CIDR assignments  
🔹 Inspection of kubelet, kube‑proxy, and container runtime behavior across nodes  
🔹 A fully functioning cluster with workloads scheduled and running on worker nodes  

On the networking and troubleshooting side, the project showcases:

🔹 Deep‑dive analysis of **Calico VXLAN overlay networking** using live packet captures  
🔹 Verification of encapsulated traffic (`UDP 4789`) between nodes at the packet level  
🔹 Inspection of Calico‑programmed routes, blackhole routes, and interface mappings  
🔹 Validation of **kube‑proxy in IPVS mode**, including service VIP routing  
🔹 Debugging and restoring API service reachability (`10.233.0.1 → 10.10.1.6:6443`)  
🔹 Recovery of Calico controllers and DNS pods after service VIP propagation  
🔹 Deployment and exposure of nginx using Kubernetes Services + port‑forwarding  

This project highlights **modern Kubernetes networking fundamentals**, combining cluster provisioning, overlay networking, service routing, and packet‑level diagnostics — the exact skillset used across DevOps, SRE, and cloud platform engineering teams. It’s clean, transparent, and ready to scale into more advanced CNI tuning, multi‑cluster networking, or service mesh experimentation.

#Kubernetes #Calico #Kubespray #Azure #CloudEngineering #DevOps #SRE #Networking #Containers #Linux #Troubleshooting #TechPortfolio #Reproducibility

