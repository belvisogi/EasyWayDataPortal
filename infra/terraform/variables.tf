variable "project_name" {
  description = "Project name prefix for resources"
  type        = string
}

variable "location" {
  description = "Azure location (e.g. westeurope)"
  type        = string
  default     = "westeurope"
}

variable "resource_group_name" {
  description = "Existing Resource Group name (or provide if creating externally)"
  type        = string
}

variable "storage_account_name" {
  description = "Storage Account name (must be globally unique, 3-24 lowercase letters and numbers)"
  type        = string
}

variable "account_tier" {
  type        = string
  default     = "Standard"
  description = "Storage account tier"
}

variable "account_replication_type" {
  type        = string
  default     = "LRS"
  description = "Replication type: LRS, GRS, RAGRS, ZRS"
}

variable "tenants" {
  description = "List of tenant ids to pre-create dirs for"
  type        = list(string)
  default     = ["tenant01"]
}

variable "key_vault_name" {
  description = "Name of the Key Vault (globally unique). Example: kv-easyway-dev"
  type        = string
}

variable "assign_reader_principal_id" {
  description = "Optional principal/object id to assign Storage Blob Data Reader on containers"
  type        = string
  default     = ""
}

