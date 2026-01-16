output "storage_account_name" {
  value       = azurerm_storage_account.dl.name
  description = "Storage account name"
}

output "storage_connection_string" {
  value       = azurerm_storage_account.dl.primary_connection_string
  sensitive   = true
  description = "Connection string for AZURE_STORAGE_CONNECTION_STRING (if not using MI)"
}

output "branding_container_name" {
  value       = azurerm_storage_data_lake_gen2_filesystem.portal_assets.name
  description = "Container name for BRANDING_CONTAINER"
}

output "branding_prefix" {
  value       = azurerm_storage_data_lake_gen2_path.branding_prefix.path
  description = "Default BRANDING_PREFIX (directory inside portal-assets)"
}

output "key_vault_name" {
  value       = azurerm_key_vault.kv.name
  description = "Key Vault Name"
}

output "key_vault_uri" {
  value       = azurerm_key_vault.kv.vault_uri
  description = "Key Vault URI"
}

