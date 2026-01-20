---

# **README.md — Azure Windows 11 VDI Image Pipeline (Packer + Terraform)**

This project automates the creation of a **custom Windows 11 AVD/VDI image** using Packer and deploys it into an **Azure Virtual Machine Scale Set (VMSS)** using Terraform.  
It also provisions networking, a load balancer, and an optional Windows jumpbox VM for administrative access.

This workflow is ideal when you want a reproducible, hardened Windows 11 base image delivered through the **Azure Shared Image Gallery (SIG)** and consumed by scalable compute infrastructure.

---

## **Architecture Diagram (SIG → VMSS + Jumpbox)**

```
                          +-----------------------------+
                          |        Packer Build         |
                          |-----------------------------|
                          |  win11-vdi.pkr.hcl          |
                          |  - Azure ARM builder        |
                          |  - WinRM provisioning       |
                          |  - Sysprep + SIG publish    |
                          +--------------+--------------+
                                         |
                                         | SIG Image Version
                                         v
                   +------------------------------------------------+
                   |   Azure Resource Group: myPackerImages         |
                   |------------------------------------------------|
                   |  Shared Image Gallery (myGallery)              |
                   |  Image Definition (myWin11VDIImage)            |
                   |  Image Version (e.g., 1.0.0)                   |
                   +------------------------------------------------+

                                         |
                                         | source_image_id
                                         v

+--------------------------------------------------------------------------+
|                     Terraform Deployment (VMSS + Jumpbox)                |
+--------------------------------------------------------------------------+
|                                                                          |
|  +-------------------+                                                   |
|  | Resource Group    |                                                   |
|  | myPackerImages    |                                                   |
|  +---------+---------+                                                   |
|            |                                                             |
|            v                                                             |
|  +-------------------+        +----------------------------+             |
|  | Virtual Network   |        | Windows VM Scale Set       |             |
|  | vmss-vnet         |        | vmscaleset                 |             |
|  | Subnet: vmss-sub  |        |----------------------------|             |
|  +---------+---------+        | Uses SIG Win11 VDI Image   |             |
|            |                  | Capacity: 1+               |             |
|            |                  | RDP access via LB          |             |
|            |                  +----------------------------+             |
|            |                                 |                           |
|            v                                 v                           |
|  +-------------------+        +----------------------------+              |
|  | Load Balancer     |<-------| Backend Pool               |              |
|  | vmss-lb (Standard)|        | Health Probe (RDP 3389)    |              |
|  | Public IP (Std)   |        +----------------------------+              |
|  +-------------------+                                                     |
|                                                                          |
|  +-------------------+                                                    |
|  | Jumpbox VM        |                                                    |
|  | - Windows Server  |                                                    |
|  | - Public IP       |                                                    |
|  | - RDP access      |                                                    |
|  +-------------------+                                                    |
|                                                                          |
+--------------------------------------------------------------------------+
```

---

## **Workflow Overview**

1. **Packer** builds a Windows 11 AVD/VDI image:
   - Uses Azure ARM builder  
   - Connects via WinRM  
   - Runs Windows Update + customization  
   - Executes Sysprep  
   - Publishes a version to the **Shared Image Gallery**

2. **Terraform** deploys:
   - Windows VM Scale Set using the SIG image version  
   - Standard Load Balancer with RDP probe  
   - Virtual network + subnet  
   - Optional Windows jumpbox VM for administrative access  

3. VMSS instances receive traffic through the load balancer  
4. Jumpbox provides direct RDP access into the VNet  

---

## **Prerequisites**

- Azure CLI installed and authenticated  
- Terraform v1.0+  
- Packer v1.11.2+  
- A Shared Image Gallery + image definition created by Terraform  
- A Packer-built **Windows 11 VDI SIG image version**  
- Permissions to create compute, network, and storage resources  

---

## **Project Structure**

```
.
├── main.tf
├── variables.tf
├── outputs.tf
├── README.md
└── packer/
    └── win11-vdi.pkr.hcl
```

---

## **Variables**

| Variable | Description | Default |
|---------|-------------|---------|
| `location` | Azure region for deployment | `eastus` |
| `packer_resource_group_name` | Resource group containing SIG + images | `myPackerImages` |
| `admin_user` | Admin username for VMSS + jumpbox | `azureuser` |
| `admin_password` | Admin password (required for Windows) | `null` |
| `tags` | Resource tags | `{ environment = "codelab" }` |

---

## **Deployment Instructions**

### **1. Build the Windows 11 VDI Image**

```
packer init .
packer build win11-vdi.pkr.hcl
```

This publishes a new version into:

```
myGallery / myWin11VDIImage
```

### **2. Initialize Terraform**

```
terraform init
```

### **3. Review the Plan**

```
terraform plan -out main.tfplan
```

### **4. Deploy**

```
terraform apply main.tfplan
```

---

## **Outputs**

Terraform will output:

- VMSS public IP  
- Jumpbox public IP  
- Resource group name  
- SIG image version used  

---

## **Destroying the Deployment**

```
terraform destroy
```

---

## **Notes**

- VMSS and jumpbox both use the **Windows 11 VDI SIG image**  
- Load balancer and public IPs use **Standard SKU**  
- VMSS uses **RDP (3389)** for health probes and access  
- SIG image definition is protected with `prevent_destroy`  
- Packer uses WinRM + Sysprep to prepare the Windows image  

---