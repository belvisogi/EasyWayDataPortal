# EasyWay Data Portal – Terraform (ADLS Gen2)

This folder provisions the Azure Storage (ADLS Gen2) layout described in the Wiki.

What it creates
- Storage Account (HNS enabled)
- Filesystems (containers):
  - `datalake`
  - `portal-assets`
- Directories:
  - Under `portal-assets`: `config/` (branding prefix)
  - Under `datalake`: for each tenant in `var.tenants` → `tenantX/{landing,staging,official,invalidrows,technical}`
- Optional RBAC: assign `Storage Blob Data Reader` to a principal id

Inputs (variables.tf)
- `project_name` (string)
- `location` (default `westeurope`)
- `resource_group_name` (string)
- `storage_account_name` (string, globally unique)
- `account_tier` (default `Standard`)
- `account_replication_type` (default `LRS`)
- `tenants` (list(string), default `["tenant01"]`)
- `assign_reader_principal_id` (string, optional)

Outputs (map to API env)
- `storage_connection_string` → `AZURE_STORAGE_CONNECTION_STRING`
- `branding_container_name` → `BRANDING_CONTAINER` (value: `portal-assets`)
- `branding_prefix` → `BRANDING_PREFIX` (value: `config`)

Usage
```
terraform init
terraform plan -var "project_name=easyway" \
  -var "resource_group_name=rg-easyway-dev" \
  -var "storage_account_name=ewdlkdev123" \
  -var "tenants=[\"tenant01\",\"tenant02\"]"
terraform apply
```

After apply
- Export outputs to your CI/CD Variable Group:
  - `AZURE_STORAGE_CONNECTION_STRING`
  - `BRANDING_CONTAINER=portal-assets`
  - `BRANDING_PREFIX=config`
- Or switch the API to Managed Identity (RBAC) and remove the connection string from app config.

Notes
- This module expects the Resource Group to exist.
- For production, prefer RBAC + Managed Identity for the API over connection strings.

