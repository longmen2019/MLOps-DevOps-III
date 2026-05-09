locals {
  s3_enabled    = var.enable_s3 && var.s3_bucket_name != ""
  azure_enabled = var.enable_azure && var.azure_storage_account_name != "" && var.azure_container_name != ""
}

resource "aws_s3_bucket" "etcd_backups" {
  count = local.s3_enabled ? 1 : 0

  bucket = var.s3_bucket_name

  tags = {
    "Name"        = "${var.cluster_name}-etcd-backups"
    "Environment" = "etcd-backup"
    "ManagedBy"   = "terraform"
  }
}

resource "aws_s3_bucket_versioning" "etcd_backups" {
  count = local.s3_enabled ? 1 : 0

  bucket = aws_s3_bucket.etcd_backups[0].id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "etcd_backups" {
  count = local.s3_enabled ? 1 : 0

  bucket = aws_s3_bucket.etcd_backups[0].id

  rule {
    id     = "expire-old-backups"
    status = "Enabled"

    expiration {
      days = 30
    }
  }
}

resource "azurerm_storage_account" "etcd_backups" {
  count = local.azure_enabled ? 1 : 0

  name                     = var.azure_storage_account_name
  resource_group_name      = var.azure_resource_group
  location                 = "eastus"
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = {
    "Name"        = "${var.cluster_name}-etcd-backups"
    "Environment" = "etcd-backup"
    "ManagedBy"   = "terraform"
  }
}

resource "azurerm_storage_container" "etcd_backups" {
  count = local.azure_enabled ? 1 : 0

  name                  = var.azure_container_name
  storage_account_name  = azurerm_storage_account.etcd_backups[0].name
  container_access_type = "private"
}
