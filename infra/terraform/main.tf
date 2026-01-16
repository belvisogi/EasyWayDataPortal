terraform {
  required_version = ">= 1.6.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.100.0"
    }
  }
}

provider "azurerm" {
  features {}
}

# This module assumes the Resource Group exists (pass its name).
# If you want Terraform to create it, add an azurerm_resource_group resource here.

resource "azurerm_storage_account" "dl" {
  name                     = var.storage_account_name
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = var.account_tier
  account_replication_type = var.account_replication_type

  account_kind = "StorageV2"
  is_hns_enabled = true # ADLS Gen2

  blob_properties {
    versioning_enabled = true
  }

  tags = {
    project = var.project_name
    layer   = "datalake"
  }
}

# Filesystems (containers) for ADLS Gen2
resource "azurerm_storage_data_lake_gen2_filesystem" "datalake" {
  name               = "datalake"
  storage_account_id = azurerm_storage_account.dl.id
}

resource "azurerm_storage_data_lake_gen2_filesystem" "portal_assets" {
  name               = "portal-assets"
  storage_account_id = azurerm_storage_account.dl.id
}

# Branding prefix directory under portal-assets
resource "azurerm_storage_data_lake_gen2_path" "branding_prefix" {
  path               = "config" # default branding prefix
  filesystem_name    = azurerm_storage_data_lake_gen2_filesystem.portal_assets.name
  storage_account_id = azurerm_storage_account.dl.id
  resource           = "directory"
}

# Per-tenant standard folders under datalake filesystem
locals {
  standard_dirs = ["landing", "staging", "official", "invalidrows", "technical"]
}

resource "azurerm_storage_data_lake_gen2_path" "tenant_dirs" {
  for_each = { for t in var.tenants : t => t }
  path               = each.key
  filesystem_name    = azurerm_storage_data_lake_gen2_filesystem.datalake.name
  storage_account_id = azurerm_storage_account.dl.id
  resource           = "directory"
}

resource "azurerm_storage_data_lake_gen2_path" "tenant_subdirs" {
  for_each = { for combo in flatten([for t in var.tenants : [for d in local.standard_dirs : {
    path = "${t}/${d}"
  }]]) : combo.path => combo }

  path               = each.value.path
  filesystem_name    = azurerm_storage_data_lake_gen2_filesystem.datalake.name
  storage_account_id = azurerm_storage_account.dl.id
  resource           = "directory"
}

# Optional: assign reader on containers to an app principal (for API MI)

# =======================================================================================
# Azure Key Vault (Standard Tier)
# =======================================================================================

data "azurerm_client_config" "current_user" {}

resource "azurerm_key_vault" "kv" {
  name                        = var.key_vault_name
  location                    = var.location
  resource_group_name         = var.resource_group_name
  enabled_for_disk_encryption = true
  tenant_id                   = data.azurerm_client_config.current_user.tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false

  sku_name = "standard"

  # Access Policy: Current User (running Terraform) gets full access
  access_policy {
    tenant_id = data.azurerm_client_config.current_user.tenant_id
    object_id = data.azurerm_client_config.current_user.object_id

    key_permissions = [
      "Get", "List", "Create", "Delete", "Update", "Recover", "Purge", "GetRotationPolicy"
    ]

    secret_permissions = [
      "Get", "List", "Set", "Delete", "Recover", "Backup", "Restore", "Purge"
    ]

    certificate_permissions = [
      "Get", "List", "Update", "Create", "Import", "Delete", "Recover", "Backup", "Restore", "ManageContacts", "ManageIssuers", "GetKeyIssuers", "ListKeyIssuers", "SetKeyIssuers", "DeleteKeyIssuers", "Purge"
    ]
  }

  # Access Policy: Optional Application Principal (Managed Identity)
  dynamic "access_policy" {
    for_each = length(var.assign_reader_principal_id) > 0 ? [1] : []
    content {
      tenant_id = data.azurerm_client_config.current_user.tenant_id
      object_id = var.assign_reader_principal_id

      secret_permissions = [
        "Get", "List"
      ]
    }
  }

  tags = {
    project = var.project_name
    layer   = "security"
  }
}

