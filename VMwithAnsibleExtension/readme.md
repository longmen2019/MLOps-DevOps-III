```markdown
# 🌐 Azure Infrastructure Automation with Terraform

This project provisions a secure, scalable, and fully automated Azure environment using [Terraform](https://www.terraform.io/). It deploys a Linux virtual machine with Ansible pre-installed via a VM extension, while integrating key Azure services like networking, security, identity, and secrets management.

---

## 🚀 Features

- **Modular Infrastructure**: Clean separation of resources including networking, security, compute, and identity.
- **Secure Access**: NSG rules restrict SSH access to the current user's public IP.
- **Secrets Management**: Admin credentials are securely stored in Azure Key Vault.
- **Dynamic Provisioning**: VM extension installs Ansible and Azure modules automatically.
- **Reproducible Builds**: Uses Terraform variables and random resources for consistent, unique deployments.

---

## 📦 Resources Deployed

| Resource Type                          | Description                                                                 |
|---------------------------------------|-----------------------------------------------------------------------------|
| `azurerm_resource_group`              | Central container for all resources                                         |
| `azurerm_virtual_network`             | Defines private IP space                                                   |
| `azurerm_subnet`                      | Isolated subnet for VM traffic                                             |
| `azurerm_network_security_group`      | SSH access restricted to client IP                                         |
| `azurerm_subnet_network_security_group_association` | Binds NSG to subnet                                              |
| `azurerm_key_vault`                   | Stores secrets and encryption keys securely                                |
| `azurerm_key_vault_secret`           | Stores randomly generated admin password                                   |
| `random_password`                     | Generates secure password                                                  |
| `azurerm_public_ip`                   | Static public IP for VM                                                    |
| `azurerm_network_interface`           | Attaches public and private IPs to VM                                      |
| `azurerm_linux_virtual_machine`       | Ubuntu 22.04 LTS VM with password authentication                           |
| `azurerm_virtual_machine_extension`   | Executes Ansible installation script via CustomScript extension            |

---

## 🛠️ Prerequisites

- [Terraform CLI](https://developer.hashicorp.com/terraform/downloads)
- Azure CLI authenticated with appropriate permissions
- GitHub-hosted `AnsibleSetup.sh` script accessible via raw HTTPS

---

## 📄 Usage

1. **Clone the repository**
   ```bash
   git clone https://github.com/your-org/terraform-azure-ansible.git
   cd terraform-azure-ansible
   ```

2. **Initialize Terraform**
   ```bash
   terraform init
   ```

3. **Review and customize variables**
   Edit `terraform.tfvars` or pass variables via CLI.

4. **Plan the deployment**
   ```bash
   terraform plan
   ```

5. **Apply the deployment**
   ```bash
   terraform apply
   ```

6. **Import existing VM extension if needed**
   ```bash
   terraform import azurerm_virtual_machine_extension.ansibe-base-setup "/subscriptions/<sub-id>/resourceGroups/<rg-name>/providers/Microsoft.Compute/virtualMachines/<vm-name>/extensions/ansible-basesetup"
   ```

---

## 📂 File Structure

```
.
├── main.tf
├── variables.tf
├── terraform.tfvars
├── outputs.tf
└── README.md
```

---

## 🧪 Validation

After deployment:
- SSH into the VM using the public IP and admin credentials.
- Run `ansible --version` to confirm installation.
- Check Key Vault for stored secrets.

---

## 📬 Support

For issues or enhancements, please open an issue or submit a pull request.

---

## 📄 License

This project is licensed under the MIT License.
```
