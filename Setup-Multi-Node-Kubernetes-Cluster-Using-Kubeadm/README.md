
```markdown
# 🚀 Azure Kubernetes Cluster Automation

[![Ansible](https://img.shields.io/badge/Ansible-2.15+-EE0000?logo=ansible&logoColor=white)](https://www.ansible.com/)
[![Kubernetes](https://img.shields.io/badge/Kubernetes-1.28+-326CE5?logo=kubernetes&logoColor=white)](https://kubernetes.io/)
[![Terraform](https://img.shields.io/badge/Terraform-1.5+-7B42BC?logo=terraform&logoColor=white)](https://www.terraform.io/)
[![Azure](https://img.shields.io/badge/Azure-Cloud-0078D4?logo=microsoftazure&logoColor=white)](https://azure.microsoft.com/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

> **Production-grade, reproducible automation for deploying multi-node Kubernetes clusters on Azure — secured with bastion-proxied SSH, hardened with least-privilege principles, and orchestrated end-to-end with Ansible.**

---

## Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [SSH Flow](#ssh-flow)
- [Repository Structure](#repository-structure)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Terraform Workflow](#terraform-workflow)
- [Ansible Workflow](#ansible-workflow)
- [Playbook Reference](#playbook-reference)
- [Configuration Reference](#configuration-reference)
- [Common Operations](#common-operations)
- [Troubleshooting](#troubleshooting)
- [Security Considerations](#security-considerations)
- [Next Steps & Roadmap](#next-steps--roadmap)
- [Contributing](#contributing)
- [License](#license)

---

## Overview

This project automates the provisioning, configuration, and lifecycle management of a multi-node Kubernetes cluster running on Azure VMs. It combines **Terraform** for infrastructure-as-code provisioning with **Ansible** for configuration management, producing a cluster that is:

- **Reproducible** — every step is codified; tear down and rebuild in minutes
- **Secure** — SSH access is bastion-proxied; no private keys stored on jump hosts; SSH public keys injected at runtime via Terraform `-var` (never committed to repo)
- **Quota-Safe** — designed around Azure subscription constraints with right-sized VM SKUs
- **Hand-Off Ready** — annotated playbooks and runbooks that any engineer can pick up and execute

### What Gets Deployed

| Component         | Count | VM SKU             | OS              | Role                              |
|-------------------|-------|--------------------|-----------------|-----------------------------------|
| Bastion Host      | 1     | Standard_B1s       | Ubuntu 22.04    | SSH jump host, Ansible controller |
| Control Plane     | 1     | Standard_B2s       | Ubuntu 22.04    | K8s API server, etcd, scheduler   |
| Worker Nodes      | 2     | Standard_B2s       | Ubuntu 22.04    | Application workloads             |

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                        Azure Resource Group                         │
│                                                                     │
│  ┌──────────────┐    ┌────────────────────────────────────────────┐ │
│  │   Operator    │    │           Virtual Network (10.0.0.0/16)    │ │
│  │  Workstation  │    │                                            │ │
│  │  (Linux/WSL)  │    │  ┌─────────────┐     NSG: SSH only        │ │
│  └──────┬───────┘    │  │   Bastion    │◄── from operator IP      │ │
│         │ SSH:22      │  │  10.0.1.4   │                          │ │
│         │             │  │  (Public IP) │                          │ │
│         ▼             │  └──────┬──────┘                          │ │
│    ┌────────┐         │         │ SSH ProxyJump                   │ │
│    │Internet│─────────┼────────►│                                  │ │
│    └────────┘         │         ├──────────────────┐               │ │
│                       │         ▼                  ▼               │ │
│                       │  ┌─────────────┐   ┌─────────────┐        │ │
│                       │  │Control Plane │   │   Workers   │        │ │
│                       │  │  10.0.2.10   │   │ 10.0.2.11  │        │ │
│                       │  │             │   │ 10.0.2.12  │        │ │
│                       │  │  ┌────────┐ │   │             │        │ │
│                       │  │  │  etcd   │ │   │  ┌───────┐ │        │ │
│                       │  │  │  API    │ │   │  │kubelet│ │        │ │
│                       │  │  │ sched.  │ │   │  │kube-  │ │        │ │
│                       │  │  │ ctrl-mgr│ │   │  │proxy  │ │        │ │
│                       │  │  └────────┘ │   │  └───────┘ │        │ │
│                       │  └─────────────┘   └─────────────┘        │ │
│                       │       Subnet: 10.0.2.0/24                  │ │
│                       │       NSG: internal only + bastion SSH     │ │
│                       └────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────┘
```

---

## SSH Flow

All cluster access is **bastion-proxied** — no cluster node has a public IP address. The operator's SSH key is forwarded via `ssh-agent`; private keys never touch the bastion disk.

```
┌────────────┐         ┌────────────┐         ┌───────────────────┐
│  Operator  │  SSH    │  Bastion   │  SSH    │  Control Plane /  │
│ Workstation├────────►│  (jump)    ├────────►│  Worker Nodes     │
│            │ :22     │ Public IP  │ :22     │  Private IPs      │
└────────────┘         └────────────┘         └───────────────────┘
     ▲                       │
     │  ssh-agent fwd        │  No keys stored
     │  (-A flag)            │  on bastion
     └───────────────────────┘
```

### SSH Configuration

The following `~/.ssh/config` enables seamless ProxyJump access:

```ssh-config
# --- Bastion Host ---
Host bastion
    HostName <BASTION_PUBLIC_IP>
    User azureuser
    IdentityFile ~/.ssh/id_rsa
    ForwardAgent yes
    StrictHostKeyChecking accept-new

# --- Control Plane ---
Host cp1
    HostName 10.0.2.10
    User azureuser
    ProxyJump bastion
    ForwardAgent yes

# --- Worker Nodes ---
Host worker1
    HostName 10.0.2.11
    User azureuser
    ProxyJump bastion

Host worker2
    HostName 10.0.2.12
    User azureuser
    ProxyJump bastion
```

### Verifying Connectivity

```bash
# Start the SSH agent and add your key
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_rsa

# Test direct bastion access
ssh bastion "echo 'Bastion OK'"

# Test proxied access to control plane
ssh cp1 "hostname && kubectl get nodes"

# Test proxied access to workers
ssh worker1 "hostname"
ssh worker2 "hostname"
```

---

## Repository Structure

```
k8s-cluster-automation/
├── README.md                        # ← You are here
├── LICENSE
│
├── terraform/                       # Infrastructure provisioning
│   ├── main.tf                      # Resource group, VNet, subnets, NSGs
│   ├── vms.tf                       # Bastion, control plane, worker VMs
│   ├── variables.tf                 # Parameterized inputs (incl. ssh_public_key)
│   ├── outputs.tf                   # IPs, resource IDs for Ansible
│   └── terraform.tfvars.example     # Sample variable values (NO keys here)
│
├── ansible/                         # Configuration management
│   ├── ansible.cfg                  # Ansible settings (inventory, SSH args)
│   ├── inventory/
│   │   ├── hosts.ini                # Static inventory (bastion, cp, workers)
│   │   └── group_vars/
│   │       ├── all.yml              # Shared variables
│   │       ├── control_plane.yml    # CP-specific vars (pod CIDR, API addr)
│   │       └── workers.yml          # Worker-specific vars
│   │
│   ├── playbooks/
│   │   ├── 00-site.yml              # Master playbook — runs all in order
│   │   ├── 01-prerequisites.yml     # OS prep, swap off, kernel modules
│   │   ├── 02-containerd.yml        # Container runtime installation
│   │   ├── 03-kube-components.yml   # kubeadm, kubelet, kubectl
│   │   ├── 04-init-control-plane.yml# kubeadm init + CNI (Calico/Flannel)
│   │   ├── 05-join-workers.yml      # kubeadm join with token
│   │   ├── 06-post-install.yml      # Smoke tests, labels, taints
│   │   └── 99-teardown.yml          # Graceful drain, reset, cleanup
│   │
│   ├── roles/
│   │   ├── common/                  # Shared OS hardening, package updates
│   │   ├── container-runtime/       # containerd install + config
│   │   ├── kube-base/               # kubeadm, kubelet, kubectl
│   │   ├── control-plane/           # kubeadm init, CNI, kubeconfig
│   │   └── worker/                  # kubeadm join
│   │
│   └── files/
│       ├── containerd-config.toml   # containerd runtime configuration
│       ├── k8s-sysctl.conf          # Kernel params (ip_forward, bridge-nf)
│       └── calico-custom.yml        # CNI manifest with pod CIDR
│
├── scripts/
│   ├── bootstrap.sh                 # One-shot: Terraform apply → Ansible run
│   ├── validate-cluster.sh          # Post-deploy validation suite
│   └── rotate-join-token.sh         # Regenerate kubeadm join token
│
└── docs/
    ├── TROUBLESHOOTING.md           # Extended troubleshooting guide
    ├── SECURITY.md                  # Threat model and hardening notes
    └── RUNBOOK.md                   # Day-2 operations runbook
```

---

## Prerequisites

### Tools

| Tool        | Version   | Purpose                         |
|-------------|-----------|----------------------------------|
| Terraform   | ≥ 1.5     | Infrastructure provisioning      |
| Ansible     | ≥ 2.15    | Configuration management         |
| Azure CLI   | ≥ 2.50    | Azure authentication & queries   |
| ssh / ssh-agent | OpenSSH 8+ | Secure bastion-proxied access |
| kubectl     | ≥ 1.28    | Cluster interaction (optional)   |

### Azure Requirements

- An active Azure subscription with sufficient quota for **5 vCPUs** (B-series)
- A resource group (or permissions to create one)
- A service principal or `az login` session for Terraform

### Local Environment

> ⚠️ **Use a native Linux workstation or dedicated Linux VM for Ansible operations.** WSL can introduce SSH permission and path-resolution issues that are difficult to debug. If you must use WSL, ensure all key files are stored in the Linux filesystem (`~/.ssh/`), never on a `/mnt/c/` mount.

```bash
# Verify prerequisites
terraform version   # ≥ 1.5.x
ansible --version   # ≥ 2.15.x
az version          # ≥ 2.50.x
ssh -V              # OpenSSH 8+

# Ensure your SSH key pair exists
ls -la ~/.ssh/id_rsa ~/.ssh/id_rsa.pub
# If not, generate one:
ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -C "k8s-cluster-automation"
```

---

## Quick Start

### 1. Clone and Configure

```bash
git clone https://github.com/<your-username>/k8s-cluster-automation.git
cd k8s-cluster-automation

# Copy and edit Terraform variables (non-sensitive ones only)
cp terraform/terraform.tfvars.example terraform/terraform.tfvars
# Edit terraform.tfvars: set subscription_id, location, vm_size, etc.
# Do NOT put your SSH key in terraform.tfvars — it's injected at runtime
```

### 2. Provision Infrastructure

> 💡 **Why `-var` instead of `.tfvars`?** The SSH public key is injected at runtime via the `-var` flag so it **never touches disk or version control**. This is a deliberate security decision — `terraform.tfvars` is for non-sensitive configuration only.

```bash
cd terraform
terraform init

# Preview the infrastructure plan — SSH key is read from your local key pair
terraform plan -var="ssh_public_key=$(cat ~/.ssh/id_rsa.pub)"

# Apply — creates resource group, VNet, NSGs, bastion, and all cluster VMs
terraform apply -var="ssh_public_key=$(cat ~/.ssh/id_rsa.pub)"
```

After a successful apply, Terraform outputs the bastion public IP, control plane private IP, and worker private IPs.

```bash
# Capture outputs for Ansible inventory
terraform output -json > ../ansible/inventory/tf_outputs.json

# Quick-reference: grab the bastion IP
terraform output bastion_public_ip
```

### 3. Configure SSH Access

```bash
# Load your key into the SSH agent (same key Terraform just deployed)
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_rsa

# Update your SSH config with the bastion IP from Terraform output
# (see SSH Configuration section above)
```

### 4. Run the Ansible Playbooks

```bash
cd ansible

# Verify inventory and connectivity
ansible-inventory --list -i inventory/hosts.ini
ansible all -m ping

# Full cluster deployment (end-to-end)
ansible-playbook playbooks/00-site.yml

# Or run individual stages
ansible-playbook playbooks/01-prerequisites.yml
ansible-playbook playbooks/02-containerd.yml
ansible-playbook playbooks/03-kube-components.yml
ansible-playbook playbooks/04-init-control-plane.yml
ansible-playbook playbooks/05-join-workers.yml
ansible-playbook playbooks/06-post-install.yml
```

### 5. Validate the Cluster

```bash
# From the control plane (via bastion)
ssh cp1 "kubectl get nodes -o wide"

# Expected output:
# NAME    STATUS   ROLES           AGE   VERSION   INTERNAL-IP
# cp1     Ready    control-plane   10m   v1.28.x   10.0.2.10
# wk1     Ready    <none>          8m    v1.28.x   10.0.2.11
# wk2     Ready    <none>          8m    v1.28.x   10.0.2.12

# Run the validation suite
bash scripts/validate-cluster.sh
```

---

## Terraform Workflow

### Variable Declaration — `variables.tf`

The SSH public key is declared as a **sensitive, required variable** with validation:

```hcl
variable "ssh_public_key" {
  description = "SSH public key for VM admin access. Pass at runtime: -var=\"ssh_public_key=$(cat ~/.ssh/id_rsa.pub)\""
  type        = string
  sensitive   = true

  validation {
    condition     = can(regex("^ssh-rsa ", var.ssh_public_key))
    error_message = "The ssh_public_key must be a valid SSH RSA public key starting with 'ssh-rsa'."
  }
}

variable "resource_group_name" {
  description = "Name of the Azure resource group"
  type        = string
  default     = "k8s-cluster-rg"
}

variable "location" {
  description = "Azure region for all resources"
  type        = string
  default     = "eastus"
}

variable "vm_size_bastion" {
  description = "VM SKU for the bastion host"
  type        = string
  default     = "Standard_B1s"
}

variable "vm_size_cluster" {
  description = "VM SKU for control plane and worker nodes"
  type        = string
  default     = "Standard_B2s"
}
```

### VM Resource — `vms.tf`

The runtime key flows into every VM's `admin_ssh_key` block:

```hcl
resource "azurerm_linux_virtual_machine" "control_plane" {
  name                = "cp1"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  size                = var.vm_size_cluster

  admin_username                  = "azureuser"
  disable_password_authentication = true

  admin_ssh_key {
    username   = "azureuser"
    public_key = var.ssh_public_key   # ← Injected at runtime, never stored in state as plaintext
  }

  network_interface_ids = [azurerm_network_interface.cp1.id]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
}

# Worker nodes use the same admin_ssh_key block
# (see vms.tf for the full count-based or for_each worker definition)
```

### Outputs — `outputs.tf`

```hcl
output "bastion_public_ip" {
  description = "Public IP of the bastion host"
  value       = azurerm_public_ip.bastion.ip_address
}

output "control_plane_private_ip" {
  description = "Private IP of the control plane node"
  value       = azurerm_network_interface.cp1.private_ip_address
}

output "worker_private_ips" {
  description = "Private IPs of all worker nodes"
  value       = [for nic in azurerm_network_interface.workers : nic.private_ip_address]
}
```

### The `-var` Runtime Injection Pattern

```
┌──────────────────────────────────────────────────────────────────┐
│                    Terraform Execution Flow                      │
│                                                                  │
│   ~/.ssh/id_rsa.pub                                              │
│         │                                                        │
│         ▼  $(cat ...)                                            │
│   ┌─────────────┐    ┌──────────────┐    ┌────────────────────┐ │
│   │  -var flag   │───►│ variables.tf │───►│ admin_ssh_key {    │ │
│   │  (runtime)   │    │  (sensitive) │    │   public_key = ... │ │
│   └─────────────┘    │  (validated) │    │ }                  │ │
│                      └──────────────┘    └────────┬───────────┘ │
│                                                   │              │
│   ✗ NOT in terraform.tfvars                       ▼              │
│   ✗ NOT in version control           Azure VM provisioned with   │
│   ✗ NOT echoed in plan output        authorized SSH key          │
│     (marked sensitive)                                           │
└──────────────────────────────────────────────────────────────────┘
```

---

## Ansible Workflow

### Execution Model

```
Operator Workstation (Ansible Controller)
         │
         │  SSH ProxyJump via Bastion
         │
         ▼
    ┌─────────┐    01-prerequisites ──► All nodes
    │ Ansible  │    02-containerd   ──► All nodes
    │ Engine   │    03-kube-comp.   ──► All nodes
    │         │    04-init-cp      ──► Control plane only
    │         │    05-join-wk      ──► Workers only
    │         │    06-post-inst.   ──► Control plane (validation)
    └─────────┘
```

### Key Configuration — `ansible.cfg`

```ini
[defaults]
inventory          = inventory/hosts.ini
remote_user        = azureuser
host_key_checking  = accept-new
timeout            = 30
forks              = 5
retry_files_enabled = True

[ssh_connection]
# Bastion-proxied SSH with agent forwarding
ssh_args = -o ForwardAgent=yes -o ProxyJump=azureuser@<BASTION_IP>
pipelining = True
```

### Inventory — `inventory/hosts.ini`

```ini
[bastion]
bastion  ansible_host=<BASTION_PUBLIC_IP>  ansible_user=azureuser

[control_plane]
cp1      ansible_host=10.0.2.10  ansible_user=azureuser

[workers]
wk1      ansible_host=10.0.2.11  ansible_user=azureuser
wk2      ansible_host=10.0.2.12  ansible_user=azureuser

[k8s_cluster:children]
control_plane
workers

[k8s_cluster:vars]
ansible_ssh_common_args=-o ProxyJump=azureuser@<BASTION_PUBLIC_IP>
```

---

## Playbook Reference

### `01-prerequisites.yml` — OS Preparation

Targets all cluster nodes. Ensures the OS is ready for Kubernetes.

```yaml
# Key tasks:
- Disable swap (required by kubelet)
- Load kernel modules: overlay, br_netfilter
- Set sysctl: net.bridge.bridge-nf-call-iptables = 1
- Set sysctl: net.ipv4.ip_forward = 1
- Update apt cache and install base packages
- Configure NTP synchronization
```

### `02-containerd.yml` — Container Runtime

Installs and configures `containerd` as the CRI-compliant container runtime.

```yaml
# Key tasks:
- Install containerd from official Docker repository
- Generate default config: containerd config default
- Set SystemdCgroup = true (required for K8s ≥ 1.22)
- Enable and start containerd service
- Validate: ctr version
```

### `03-kube-components.yml` — Kubernetes Binaries

Installs `kubeadm`, `kubelet`, and `kubectl` at pinned versions.

```yaml
# Key tasks:
- Add Kubernetes apt repository and GPG key
- Install kubeadm, kubelet, kubectl (version-pinned)
- Hold packages to prevent unplanned upgrades
- Enable kubelet service
```

### `04-init-control-plane.yml` — Cluster Initialization

Runs `kubeadm init` on the control plane node and deploys the CNI plugin.

```yaml
# Key tasks:
- kubeadm init with --pod-network-cidr and --apiserver-advertise-address
- Copy admin kubeconfig to azureuser's ~/.kube/config
- Deploy Calico (or Flannel) CNI manifest
- Generate and register join command + token
- Store join command as Ansible fact for worker playbook
```

### `05-join-workers.yml` — Worker Node Join

Joins each worker to the cluster using the token from the control plane.

```yaml
# Key tasks:
- Retrieve join command from hostvars[cp1]
- Execute kubeadm join on each worker
- Validate: kubectl get nodes shows worker as Ready
```

### `06-post-install.yml` — Validation & Labeling

Runs post-deployment checks and applies node labels.

```yaml
# Key tasks:
- Verify all nodes report Ready status
- Label workers: node-role.kubernetes.io/worker=worker
- Deploy a test nginx pod and service
- Validate pod scheduling across workers
- Print cluster summary
```

### `99-teardown.yml` — Graceful Cleanup

Safely dismantles the cluster for rebuild.

```yaml
# Key tasks:
- Drain and delete worker nodes
- kubeadm reset on all nodes
- Remove CNI configuration and iptables rules
- Clean /etc/kubernetes and /var/lib/kubelet
```

---

## Configuration Reference

### Group Variables

**`group_vars/all.yml`**

```yaml
---
k8s_version: "1.28.2-1.1"                  # Pinned Kubernetes version
containerd_version: "1.7.2-1"              # Pinned containerd version
pod_network_cidr: "192.168.0.0/16"         # Calico default CIDR
service_cidr: "10.96.0.0/12"               # Kubernetes service CIDR
cni_plugin: "calico"                        # Options: calico, flannel
timezone: "America/New_York"
```

**`group_vars/control_plane.yml`**

```yaml
---
apiserver_advertise_address: "10.0.2.10"
apiserver_cert_extra_sans: "cp1,10.0.2.10"
```

---

## Common Operations

### Terraform Commands (Always Include the `-var` Flag)

```bash
cd terraform

# Preview changes
terraform plan -var="ssh_public_key=$(cat ~/.ssh/id_rsa.pub)"

# Apply changes
terraform apply -var="ssh_public_key=$(cat ~/.ssh/id_rsa.pub)"

# Apply a specific resource (targeted)
terraform apply -var="ssh_public_key=$(cat ~/.ssh/id_rsa.pub)" \
  -target=azurerm_linux_virtual_machine.control_plane

# View current outputs
terraform output

# Destroy the entire environment
# ⚠️  The -var flag is required even on destroy — Terraform must resolve all variables
terraform destroy -var="ssh_public_key=$(cat ~/.ssh/id_rsa.pub)"

# Refresh state (reconcile with Azure)
terraform plan -var="ssh_public_key=$(cat ~/.ssh/id_rsa.pub)" -refresh-only

# Import an existing resource into state
terraform import -var="ssh_public_key=$(cat ~/.ssh/id_rsa.pub)" \
  azurerm_linux_virtual_machine.control_plane /subscriptions/.../virtualMachines/cp1
```

### SSH Key Rotation

To rotate the SSH key pair deployed to all VMs:

```bash
# Generate a new key pair
ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa_new -C "k8s-cluster-key-rotated"

# Apply with the new public key — Terraform updates all VMs
terraform apply -var="ssh_public_key=$(cat ~/.ssh/id_rsa_new.pub)"

# Update your SSH agent
ssh-add -D                    # Remove old keys
ssh-add ~/.ssh/id_rsa_new     # Add new key

# Verify connectivity
ssh bastion "echo 'Bastion OK with new key'"
ssh cp1 "echo 'CP OK with new key'"
```

### Ansible Operations

```bash
cd ansible

# Ping all nodes
ansible all -m ping

# Run a single playbook
ansible-playbook playbooks/03-kube-components.yml

# Run with verbose output for debugging
ansible-playbook playbooks/04-init-control-plane.yml -vvv

# Run on a specific host group
ansible-playbook playbooks/01-prerequisites.yml --limit workers

# Dry run (check mode)
ansible-playbook playbooks/01-prerequisites.yml --check --diff

# Re-run the full site playbook (idempotent — safe to repeat)
ansible-playbook playbooks/00-site.yml
```

---

## Troubleshooting

### Terraform Issues

<details>
<summary><strong>❌ "No value for required variable" on plan/apply</strong></summary>

**Symptom:**

```
Error: No value for required variable
  on variables.tf line 1:
   1: variable "ssh_public_key" {
```

**Root Cause:** You ran `terraform plan` or `terraform apply` without the `-var` flag.

**Fix:**

```bash
# ✗ WRONG — missing the SSH key variable
terraform plan

# ✓ CORRECT — inject the key at runtime
terraform plan -var="ssh_public_key=$(cat ~/.ssh/id_rsa.pub)"
terraform apply -var="ssh_public_key=$(cat ~/.ssh/id_rsa.pub)"
```

> 📌 The `-var` flag is required on **every** Terraform command that evaluates variables — including `plan`, `apply`, `destroy`, `import`, and `refresh`.

</details>

<details>
<summary><strong>❌ "Validation failed" for ssh_public_key</strong></summary>

**Symptom:**

```
Error: Invalid value for variable
  The ssh_public_key must be a valid SSH RSA public key starting with 'ssh-rsa'.
```

**Root Cause:** Your key is not RSA, or the file path is wrong.

```bash
# Check your key type
head -c 20 ~/.ssh/id_rsa.pub
# Should start with: ssh-rsa

# If you have an ed25519 key instead, either:
# 1. Generate an RSA key:
ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -C "k8s-cluster"

# 2. Or update the validation regex in variables.tf to accept ed25519:
#    condition = can(regex("^ssh-(rsa|ed25519) ", var.ssh_public_key))
```

</details>

<details>
<summary><strong>❌ Azure quota exceeded</strong></summary>

**Symptom:**

```
Error: creating Virtual Machine: quota for vCPUs in region exceeded
```

**Fix:**

```bash
# Check current usage
az vm list-usage --location eastus --output table | grep -i "Standard BS"

# Options:
# 1. Request a quota increase in the Azure portal
# 2. Switch to a different region in terraform.tfvars
# 3. Reduce worker count or use smaller SKUs
```

</details>

<details>
<summary><strong>❌ State drift after manual Azure changes</strong></summary>

```bash
# Reconcile Terraform state with actual Azure resources
terraform plan -var="ssh_public_key=$(cat ~/.ssh/id_rsa.pub)" -refresh-only

# If resources were created outside Terraform, import them
terraform import -var="ssh_public_key=$(cat ~/.ssh/id_rsa.pub)" \
  azurerm_linux_virtual_machine.control_plane \
  /subscriptions/<SUB_ID>/resourceGroups/k8s-cluster-rg/providers/Microsoft.Compute/virtualMachines/cp1
```

</details>

### SSH & Connectivity Issues

<details>
<summary><strong>🔑 Permission denied (publickey) when connecting through bastion</strong></summary>

**Root Cause:** SSH agent forwarding is not active, or the key wasn't added to the agent.

```bash
# Verify the agent is running and your key is loaded
ssh-add -l
# Expected: shows your id_rsa fingerprint

# If empty, re-add:
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_rsa
```

**WSL-Specific Fix:** If running from WSL, ensure the key file lives in the Linux filesystem:

```bash
# ✗ BAD — mounted Windows path causes permission issues
ls -la /mnt/c/Users/you/.ssh/id_rsa  # -rwxrwxrwx (too open)

# ✓ GOOD — native Linux path
cp /mnt/c/Users/you/.ssh/id_rsa ~/.ssh/
chmod 600 ~/.ssh/id_rsa
chmod 644 ~/.ssh/id_rsa.pub
```

</details>

<details>
<summary><strong>⏱ Ansible SSH timeout through bastion</strong></summary>

**Root Cause:** ProxyJump configuration mismatch or NSG blocking internal traffic.

```bash
# Test raw SSH with verbose output
ssh -vvv -o ProxyJump=azureuser@<BASTION_IP> azureuser@10.0.2.10

# Verify NSG allows bastion → cluster subnet traffic
az network nsg rule list \
  --resource-group k8s-cluster-rg \
  --nsg-name cluster-subnet-nsg \
  --output table
```

</details>

### Ansible Execution Issues

<details>
<summary><strong>📂 Inventory parsing errors</strong></summary>

**Root Cause:** Ansible can't locate or parse the inventory file.

```bash
# Verify inventory path in ansible.cfg matches actual location
grep inventory ansible.cfg
# Should output: inventory = inventory/hosts.ini

# Validate inventory parses correctly
ansible-inventory --list -i inventory/hosts.ini | python3 -m json.tool

# Common fix: ensure no Windows line endings (CRLF)
file inventory/hosts.ini
# Should say: ASCII text
# If "with CRLF line terminators":
sed -i 's/\r$//' inventory/hosts.ini
```

</details>

<details>
<summary><strong>🔌 Ansible reports "unreachable" for cluster nodes</strong></summary>

```bash
# Step 1: Confirm bastion is reachable
ansible bastion -m ping

# Step 2: Confirm SSH args include ProxyJump
ansible all -m ping -vvvv 2>&1 | grep ProxyJump

# Step 3: Confirm ansible.cfg is being loaded from the correct directory
ansible --version | head -5
# Look for: "config file = /path/to/ansible/ansible.cfg"

# Fix: Run Ansible from the ansible/ directory
cd ansible && ansible all -m ping
```

</details>

### Kubernetes Issues

<details>
<summary><strong>🐳 kubeadm init fails: container runtime not running</strong></summary>

```bash
# Check containerd status on the control plane
ssh cp1 "sudo systemctl status containerd"

# If not running:
ssh cp1 "sudo systemctl restart containerd"

# Verify SystemdCgroup is set to true
ssh cp1 "sudo cat /etc/containerd/config.toml | grep SystemdCgroup"
# Expected: SystemdCgroup = true
```

</details>

<details>
<summary><strong>🌐 Nodes stuck in NotReady status</strong></summary>

```bash
# Check if CNI pods are running
ssh cp1 "kubectl get pods -n kube-system | grep -E 'calico|flannel'"

# Check kubelet logs on the affected node
ssh worker1 "sudo journalctl -u kubelet --no-pager -n 50"

# Common fix: re-apply CNI manifest
ssh cp1 "kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml"
```

</details>

<details>
<summary><strong>🔄 Join token expired (24h TTL)</strong></summary>

```bash
# Generate a new token from the control plane
ssh cp1 "sudo kubeadm token create --print-join-command"

# Or use the provided script
bash scripts/rotate-join-token.sh
```

</details>

### Linux vs. WSL Workspace Issues

<details>
<summary><strong>🐧 Ansible behaves differently on WSL vs. native Linux</strong></summary>

**Recommendation:** Always run Ansible from a **native Linux filesystem** path.

```bash
# ✗ Avoid running from Windows-mounted paths
cd /mnt/c/projects/k8s-cluster-automation/ansible  # Permission issues likely

# ✓ Clone into the Linux home directory
cd ~/projects/k8s-cluster-automation/ansible

# Verify no permission anomalies
ls -la ansible.cfg       # Should be -rw-r--r-- (644)
ls -la inventory/        # Directory should be drwxr-xr-x (755)
ls -la ~/.ssh/id_rsa     # Key should be -rw------- (600)
```

</details>

---

## Security Considerations

### Implemented Controls

| Control                              | Implementation                                                      |
|--------------------------------------|---------------------------------------------------------------------|
| **Runtime SSH key injection**        | Public key passed via `-var` flag — never committed to repo or `.tfvars` |
| **Sensitive variable masking**       | `sensitive = true` in `variables.tf` — key is redacted in plan/apply output |
| **No public IPs on cluster nodes**   | Only the bastion has a public IP; cluster nodes are private-subnet only |
| **SSH agent forwarding**             | Private keys never stored on bastion or cluster nodes                |
| **NSG least-privilege**              | Bastion: SSH from operator IP only; Cluster: internal + bastion only |
| **No secrets on control plane**      | Join tokens are ephemeral; kubeconfig is user-scoped                 |
| **Version pinning**                  | All K8s and containerd versions are pinned to prevent drift          |
| **Swap disabled**                    | Required by kubelet; enforced in prerequisites playbook              |
| **Idempotent playbooks**            | Safe to re-run without side effects                                  |

### Recommendations for Production

- [ ] Enable **Azure Disk Encryption** on all VM OS disks
- [ ] Rotate SSH keys on a scheduled cadence (use the key rotation workflow above)
- [ ] Integrate **Azure Key Vault** for secret management
- [ ] Enable **Azure Monitor Agent** + **Microsoft Sentinel** for log collection and alerting
- [ ] Implement **NetworkPolicy** resources for pod-to-pod traffic control
- [ ] Add RBAC policies and restrict `cluster-admin` access
- [ ] Enable Terraform remote state backend (Azure Storage) with state encryption
- [ ] Implement `terraform plan` in CI — apply only via protected pipeline

---

## Next Steps & Roadmap

- [x] Multi-node cluster deployment (1 CP + 2 workers)
- [x] Bastion-proxied SSH with agent forwarding
- [x] Ansible end-to-end automation
- [x] Idempotent playbook design
- [x] Runtime SSH key injection via Terraform `-var` flag (no secrets in repo)
- [ ] **CI/CD Integration** — GitHub Actions pipeline for `terraform plan` and `ansible-lint`
- [ ] **Monitoring Stack** — Deploy Prometheus + Grafana via Helm charts
- [ ] **Ingress Controller** — NGINX Ingress with Azure Load Balancer integration
- [ ] **cert-manager** — Automated TLS certificate provisioning with Let's Encrypt
- [ ] **Persistent Storage** — Azure Disk CSI driver for StatefulSet workloads
- [ ] **Multi-Control-Plane HA** — Expand to 3 CP nodes with external etcd
- [ ] **GitOps** — ArgoCD or Flux for declarative application delivery
- [ ] **Sentinel Integration** — Azure Monitor Agent + DCR for cluster telemetry and AAD log ingestion
- [ ] **Terraform Remote State** — Azure Storage backend with locking and encryption

---

## Contributing

Contributions are welcome! Please follow these guidelines:

1. **Fork** this repository
2. Create a **feature branch**: `git checkout -b feature/my-improvement`
3. **Commit** with clear messages: `git commit -m "Add Helm-based monitoring stack"`
4. **Push** and open a **Pull Request**

Please ensure:
- Playbooks pass `ansible-lint` with no errors
- Terraform passes `terraform validate` and `terraform fmt`
- All new playbooks are idempotent and include appropriate `tags`
- Documentation is updated for any new features
- **No SSH keys, secrets, or populated `.tfvars` files are committed** — use the `-var` runtime injection pattern
- `.gitignore` includes `*.tfvars`, `*.tfstate*`, and `~/.ssh/` paths

---

## License

This project is licensed under the [MIT License](LICENSE).

---