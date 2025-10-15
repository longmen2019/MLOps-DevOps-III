# Azure Virtual Machine Scale Set (VMSS) Module

This project is a **Terraform module** for deploying a customizable and feature-rich **Azure Virtual Machine Scale Set (VMSS)** with all necessary supporting infrastructure. It provides a robust, scalable, and observable foundation for applications running on either **Linux** or **Windows**.

-----

## Features ✨

### Core Infrastructure

  * **OS Choice:** Deploy either a **Linux** or **Windows** Virtual Machine Scale Set.
  * **Dynamic Naming:** Uses random resources for unique, predictable naming of the Resource Group and other Azure assets.
  * **Networking:** Provisions a **Resource Group**, **Virtual Network (VNet)**, and **Subnet**.
  * **Load Balancing:** Optional **Azure Load Balancer** (Public or Internal) with **NAT Pool**, **Health Probe**, and **Load Balancer Rules**.
  * **Security:** Provisions a new **Network Security Group (NSG)** with customizable inbound rules.
  * **Scalability:** Optional **Azure Monitor Auto-scaling** based on CPU percentage.
  * **Storage:** Creates an associated **Azure Storage Account** for general use.
  * **Proximity Placement Group:** Optional deployment for low-latency grouping.
  * **Authentication:** Supports password or SSH key authentication (Linux). Generates a random password if none is provided.
  * **Disks:** Configurable OS and additional data disks, including **Ultra SSD** support.

### Added Features (Monitoring, Security, and Extensions)

  * **Load Balancer Diagnostics:** Configures **Diagnostic Settings** for the Azure Load Balancer to stream logs and metrics to **Log Analytics**.
  * **IIS Installation:** For Windows VMSS, conditionally installs the **IIS Web Server** using the Custom Script Extension.
  * **Advanced Monitoring (AMA):** Deploys an **Azure Monitor Data Collection Endpoint (DCE)** and a **Data Collection Rule (DCR)** to define sophisticated log and metric ingestion (Syslog, IIS, performance counters, custom logs) into Log Analytics.
  * **Azure Monitoring Agent (AMA):** Installs the **Azure Monitor Windows Agent Extension** and links it to the DCR for data collection.
  * **Dependency Agent (DAA):** Installs the **Dependency Agent Extension** for use with Azure Monitor's VM Insights and Service Map.
  * **Guest Configuration:** Installs the **Guest Configuration Extension** for Azure Policy initiatives.
  * **Disk Encryption (BitLocker):** Optional configuration for **Azure Disk Encryption** (BitLocker for Windows) using a dedicated **Key Vault** and **Disk Encryption Set (DES)**. Access policies are set up to enable the DES to retrieve the encryption key.
  * **Key Vault:** Provisions an **Azure Key Vault** with configurable access policies, used for disk encryption keys or general secrets/certificates.

-----

## Prerequisites 🛠️

  * **Azure Subscription**
  * **Azure CLI:** Installed and configured.
  * **Terraform:** Installed (version 1.0+ recommended).
  * **Azure Provider:** Configured for Terraform.

-----

## Usage 🚀

1.  **Clone the Repository and Initialize:**

    ```bash
    git clone <repository-url>
    cd <repository-directory>
    terraform init
    ```

2.  **Define Variables:**
    Create a `terraform.tfvars` file. Ensure you configure variables for the new features, especially for monitoring and disk encryption if you intend to use them.

    *Example variables for new features:*

    ```hcl
    # For IIS Installation
    intall_iis_server_on_instances = true

    # For Load Balancer Diagnostics
    enable_load_balancer = true
    lb_diag_logs = ["LoadBalancerAlertEvents", "LoadBalancerProbeHealthStatus"]

    # For Key Vault and Disk Encryption
    enabled_for_disk_encryption = true
    keyvault_name_override = "my-vmss-kv-001"
    app_or_service_name = "vmssapp"
    subscription_type = "dev"
    instance_number = "01"
    vm_os_type = "windows"
    encrypt_operation = "EnableEncryption" # or "DisableEncryption"
    encryption_algorithm = "RSA-OAEP"
    volume_type = "All"
    ```

3.  **Review the Plan and Apply:**

    ```bash
    terraform plan
    terraform apply
    ```

-----

## Outputs 📝

*(Note: These outputs are suggested and must be explicitly defined in an `outputs.tf` file.)*

| Name | Description |
| :--- | :--- |
| `resource_group_name` | The name of the deployed Azure Resource Group. |
| `virtual_network_name` | The name of the deployed Virtual Network. |
| `load_balancer_public_ip` | The public IP address of the Load Balancer (if applicable). |
| `log_analytics_workspace_id` | The ID of the Azure Log Analytics Workspace. |
| `azure_key_vault_uri` | The URI of the deployed Azure Key Vault. |
| `disk_encryption_set_id` | The ID of the Azure Disk Encryption Set (if enabled). |
| `ssh_private_key` | The generated SSH private key (if `generate_admin_ssh_key` is true). |

-----
