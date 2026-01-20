# Declare that the resource has been renamed from "storage" to "main" to preserve state
moved {
  from = azurerm_storage_account.storage  # Previous resource name in state
  to   = azurerm_storage_account.main     # New resource name to map to
}

resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

# Define the main Azure Storage Account resource
resource "azurerm_storage_account" "main" {
  name                = local.name                      # Storage account name derived from local variable
  resource_group_name = var.resource_group_name         # Resource group where the storage account will reside
  location            = var.location                    # Azure region for deployment
  depends_on = [ azurerm_resource_group.rg ]

  # Conditionally set access tier unless it's a Premium BlockBlobStorage account
  access_tier              = var.account_kind == "BlockBlobStorage" && var.account_tier == "Premium" ? null : var.access_tier
  account_tier             = var.account_tier             # Specifies the performance tier (Standard or Premium)
  account_kind             = var.account_kind             # Specifies the type of storage (StorageV2, BlobStorage, etc.)
  account_replication_type = var.account_replication_type # Defines replication strategy (LRS, ZRS, GRS, etc.)

  min_tls_version                 = var.min_tls_version                 # Minimum TLS version for secure access
  allow_nested_items_to_be_public = var.public_nested_items_allowed     # Controls public access to nested items
  public_network_access_enabled   = var.public_network_access_enabled   # Enables or disables public network access
  shared_access_key_enabled       = var.shared_access_key_enabled       # Enables use of shared access keys
  large_file_share_enabled        = contains(["FileStorage", "StorageV2"], var.account_kind) # Enables large file shares if supported

  sftp_enabled                      = var.sftp_enabled                      # Enables SFTP protocol
  nfsv3_enabled                     = var.nfsv3_enabled                     # Enables NFSv3 protocol
  is_hns_enabled                    = var.nfsv3_enabled || var.sftp_enabled ? true : var.hns_enabled # Enables hierarchical namespace if needed
  https_traffic_only_enabled        = var.nfsv3_enabled ? false : var.https_traffic_only_enabled     # Forces HTTPS unless NFS is enabled
  cross_tenant_replication_enabled  = var.cross_tenant_replication_enabled  # Enables replication across tenants
  infrastructure_encryption_enabled = var.infrastructure_encryption_enabled # Enables encryption at infrastructure level
  allowed_copy_scope                = var.allowed_copy_scope                # Restricts copy operations to specific scopes

  # Configure identity block if identity_type is provided
  dynamic "identity" {
    for_each = var.identity_type[*]
    content {
      type         = var.identity_type
      identity_ids = endswith(var.identity_type, "UserAssigned") ? var.identity_ids : null
    }
  }

  # Configure static website hosting if enabled
  dynamic "static_website" {
    for_each = var.static_website_config[*]
    content {
      index_document     = var.static_website_config.index_document     # Default page
      error_404_document = var.static_website_config.error_404_document # Error page
    }
  }

  # Configure custom domain if provided
  dynamic "custom_domain" {
    for_each = var.custom_domain_name[*]
    content {
      name          = var.custom_domain_name # Custom domain name
      use_subdomain = var.use_subdomain      # Whether to use subdomain
    }
  }

  # Configure customer-managed keys for encryption
  dynamic "customer_managed_key" {
    for_each = var.customer_managed_key[*]
    content {
      key_vault_key_id          = var.customer_managed_key.key_vault_key_id
      managed_hsm_key_id        = var.customer_managed_key.managed_hsm_key_id
      user_assigned_identity_id = var.customer_managed_key.user_assigned_identity_id
    }
  }

  # Configure blob properties if applicable
  dynamic "blob_properties" {
    for_each = (
      var.account_kind != "FileStorage" && (var.blob_data_protection != null || length(var.blob_cors_rules) > 0) ? ["enabled"] : []
    )

    content {
      change_feed_enabled           = var.nfsv3_enabled || var.sftp_enabled ? false : var.blob_data_protection.change_feed_enabled
      change_feed_retention_in_days = var.nfsv3_enabled || var.sftp_enabled || !var.blob_data_protection.change_feed_enabled ? null : var.blob_data_protection.change_feed_retention_in_days
      versioning_enabled            = var.nfsv3_enabled || var.sftp_enabled ? false : var.blob_data_protection.versioning_enabled
      last_access_time_enabled      = var.nfsv3_enabled || var.sftp_enabled ? false : var.blob_data_protection.last_access_time_enabled

      # Configure CORS rules for blob service
      dynamic "cors_rule" {
        for_each = var.blob_cors_rules
        content {
          allowed_headers    = cors_rule.value.allowed_headers
          allowed_methods    = cors_rule.value.allowed_methods
          allowed_origins    = cors_rule.value.allowed_origins
          exposed_headers    = cors_rule.value.exposed_headers
          max_age_in_seconds = cors_rule.value.max_age_in_seconds
        }
      }

      # Configure blob delete retention policy
      dynamic "delete_retention_policy" {
        for_each = var.blob_data_protection.delete_retention_policy_in_days > 0 ? ["enabled"] : []
        content {
          days = var.blob_data_protection.delete_retention_policy_in_days
        }
      }

      # Configure container delete retention policy
      dynamic "container_delete_retention_policy" {
        for_each = var.blob_data_protection.container_delete_retention_policy_in_days > 0 ? ["enabled"] : []
        content {
          days = var.blob_data_protection.container_delete_retention_policy_in_days
        }
      }

      # Configure point-in-time restore policy
      dynamic "restore_policy" {
        for_each = local.pitr_enabled ? ["enabled"] : []
        content {
          days = var.blob_data_protection.container_delete_retention_policy_in_days - 1
        }
      }
    }
  }

  # Configure file share properties if applicable
  dynamic "share_properties" {
    for_each = var.file_share_cors_rules != null || var.file_share_retention_policy_in_days != null || var.file_share_properties_smb != null ? ["enabled"] : []
    content {
      # CORS rules for file shares
      dynamic "cors_rule" {
        for_each = var.file_share_cors_rules[*]
        content {
          allowed_headers    = var.file_share_cors_rules.allowed_headers
          allowed_methods    = var.file_share_cors_rules.allowed_methods
          allowed_origins    = var.file_share_cors_rules.allowed_origins
          exposed_headers    = var.file_share_cors_rules.exposed_headers
          max_age_in_seconds = var.file_share_cors_rules.max_age_in_seconds
        }
      }

      # Retention policy for deleted file shares
      dynamic "retention_policy" {
        for_each = var.file_share_retention_policy_in_days[*]
        content {
          days = var.file_share_retention_policy_in_days
        }
      }

      # SMB protocol settings
      dynamic "smb" {
        for_each = var.file_share_properties_smb[*]
        content {
          authentication_types            = var.file_share_properties_smb.authentication_types
          channel_encryption_type         = var.file_share_properties_smb.channel_encryption_type
          kerberos_ticket_encryption_type = var.file_share_properties_smb.kerberos_ticket_encryption_type
          versions                        = var.file_share_properties_smb.versions
          multichannel_enabled            = var.file_share_properties_smb.multichannel_enabled
        }
      }
    }
  }

  # Configure Azure Files authentication
  dynamic "azure_files_authentication" {
    for_each = var.file_share_authentication[*]
    content {
      directory_type = var.file_share_authentication.directory_type

      # Active Directory settings if AD is used
      dynamic "active_directory" {
        for_each = var.file_share_authentication.directory_type == "AD" ? [var.file_share_authentication.active_directory] : []
        iterator = ad
        content {
          storage_sid         = ad.value.storage_sid
          domain_name         = ad.value.domain_name
          domain_sid          = ad.value.domain_sid
          domain_guid         = ad.value.domain_guid
          forest_name         = ad.value.forest_name
          netbios_domain_name = ad.value.netbios_domain_name
        }
      }
    }
  }

  # Configure network rules only when NFSv3 is enabled
  dynamic "network_rules" {
    for_each = var.nfsv3_enabled ? ["enabled"] : []
    content {
      default_action             = var.default_firewall_action
      bypass                     = var.network_bypass
      ip_rules                   = local.storage_ip_rules
      virtual_network_subnet_ids = var.subnet_ids

      # Configure private link access
      dynamic "private_link_access" {
        for_each = var.private_link_access
        content {
          endpoint_resource_id = private_link_access.value.endpoint_resource_id
          endpoint_tenant_id   = private_link_access.value.endpoint_tenant_id
        }
      }
    }
  }

  # Merge default and extra tags for resource labeling
  tags = merge(local.default_tags, var.extra_tags)

  # Enforce lifecycle constraint to prevent unsupported PITR with Premium tier
  lifecycle {
    precondition {
      condition     = var.account_tier != "Premium" || !local.pitr_enabled
      error_message = "Point in time restore is not supported with Premium Storage Accounts."
    }
  }
}
