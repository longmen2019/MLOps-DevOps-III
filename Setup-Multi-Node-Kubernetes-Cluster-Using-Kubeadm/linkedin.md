Got it — I'll update the playbook section to match your actual playbook names. Here's the corrected post:

Here's your corrected post with the actual playbook names:

---

🚀 Excited to add a new project to my cloud engineering portfolio — a fully automated Terraform → Ansible deployment pipeline that provisions Azure infrastructure, configures a multi-node Kubernetes cluster, and enables secure bastion-proxied access end‑to‑end with clean, reproducible Infrastructure‑as‑Code.

On the Terraform side, the project demonstrates:
 🔹 Automated provisioning of Azure resource groups, virtual networks, subnets, NSGs, and Linux VMs
 🔹 A dedicated bastion host architecture with least‑privilege NSG rules isolating cluster nodes from public access
 🔹 Runtime SSH key injection via the `-var` flag — secrets never touch version control or `.tfvars` files
 🔹 Sensitive variable masking and input validation for secure, predictable deployments
 🔹 Clean outputs for seamless handoff to Ansible inventory and operational visibility

On the Ansible and Kubernetes side, the project showcases:
 🔹 Bastion‑proxied SSH with agent forwarding — private keys never stored on jump hosts or cluster nodes
 🔹 Idempotent playbooks for OS hardening, containerd installation, kubeadm initialization, CNI deployment, and worker node joins
 🔹 A sequenced playbook architecture orchestrating the full cluster lifecycle from prerequisites to worker registration
 🔹 Role‑based organization with parameterized group variables for reusable, environment‑agnostic configurations
 🔹 A fully integrated, end‑to‑end automation pipeline delivering a production‑ready Kubernetes cluster built entirely through code

The playbook pipeline breaks down as follows:
 📘 **prereqs** — Disables swap, loads required kernel modules (overlay, br_netfilter), sets sysctl parameters for bridged traffic, and prepares all cluster nodes for Kubernetes installation
 📘 **install‑k8s** — Adds the Kubernetes apt repository and installs version‑pinned kubeadm, kubelet, kubectl, and the containerd container runtime across all nodes
 📘 **master‑init** — Runs kubeadm init on the control plane node, configures kubeconfig for the admin user, and captures the join token for worker registration
 📘 **calico** — Deploys the Calico CNI plugin on the control plane to enable pod networking and enforces the configured pod CIDR across the cluster
 📘 **workers‑join** — Retrieves the join command from the control plane and executes kubeadm join on each worker node to register them with the cluster

This project highlights modern cloud infrastructure automation, combining Terraform for provisioning and Ansible for configuration management — a pattern widely used across DevOps, platform engineering, and cloud security teams. It's clean, documented with architecture diagrams and troubleshooting runbooks, and ready to scale into HA multi‑control‑plane deployments, GitOps workflows, or enterprise‑grade monitoring with Microsoft Sentinel.

🔗 GitHub Repository: https://github.com/longmen2019/MLOps-DevOps-III/tree/main/Setup-Multi-Node-Kubernetes-Cluster-Using-Kubeadm

#Kubernetes #Terraform #Ansible #Azure #DevOps #IaC #Automation #CloudEngineering #CloudSecurity #SRE #TechPortfolio #Reproducibility #InfrastructureAsCode

---

All five playbooks now match your actual repo. Ready to post. 🎯