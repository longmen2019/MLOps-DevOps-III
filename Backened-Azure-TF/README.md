```markdown
# Azure Storage Infrastructure with Terraform

## 📌 Overview
This project provisions Azure storage resources using Terraform. It demonstrates how to define and deploy:
- A resource group
- A storage account (Standard tier, ZRS replication)
- Storage containers
- File shares with ACLs and metadata

The configuration is modular and designed for reproducibility, making it easy to adapt for different environments (dev, test, prod).

---

## 🗂 Resources Created
The Terraform plan provisions the following:

- **Resource Group**
  - `rg-test` in `northeurope`

- **Storage Account**
  - Name: `stcitestesturopetest`
  - Tier: `Standard`
  - Kind: `StorageV2`
  - Replication: `ZRS`
  - Features: TLS 1.2 enforced, HTTPS only, large file shares enabled

- **Storage Containers**
  - `images` (metadata: environment=dev)
  - `logs` (metadata: environment=prod)

- **File Shares**
  - `share1` (SMB, quota 200 GB, metadata + ACL defined)
  - `share2` (SMB, quota 500 GB, metadata only)

---

## ⚙️ Prerequisites
- [Terraform](https://developer.hashicorp.com/terraform/downloads) v1.5+
- Azure CLI authenticated (`az login`)
- Properly configured backend (if using remote state)

---

## 🚀 Usage
1. **Initialize Terraform**
   ```bash
   terraform init
   ```

2. **Validate the configuration**
   ```bash
   terraform validate
   ```

3. **Plan the deployment**
   ```bash
   terraform plan -out tfplan
   ```

4. **Apply the plan**
   ```bash
   terraform apply "tfplan"
   ```

---

## 🔒 Notes
- **NFS file shares require Premium storage accounts.**  
  Since this project uses a Standard tier account, all file shares are created with SMB protocol.
- Metadata and ACLs can be customized per share in the `file_shares` variable.
- Tags (`env`, `foo`, `stack`) are applied to the storage account for environment tracking.

---

## 📂 Project Structure
```
.
├── main.tf              # Core resources
├── variables.tf         # Input variables (file_shares, account_tier, etc.)
├── r-file-shares.tf     # File share definitions
├── outputs.tf           # Useful outputs (connection strings, endpoints)
└── README.md            # Project documentation
```

---

## 🧩 Customization
- Adjust `file_shares` in `variables.tf` to define new shares.
- Modify tags in `main.tf` for environment labeling.
- Update replication type or location to fit your region and redundancy needs.

---

## ✅ Best Practices
- Always re-run `terraform init` if you change modules or backend configuration.
- Use `terraform plan` before `apply` to review changes.
- Store sensitive values (like keys) securely using environment variables or a secrets manager.

---

