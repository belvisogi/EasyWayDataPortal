<#
PowerShell script (Az module) to collect an inventory JSON of Azure resources useful for Phase 0 (inventory → RTO/RPO).
Run steps:
1. Open PowerShell (Windows) with Az module installed.
   - If Az is not installed: Install-Module -Name Az -Scope CurrentUser
2. Connect and select subscription:
   - Connect-AzAccount
   - Select-AzSubscription -SubscriptionId "<SUBSCRIPTION_ID>"   # optional if you have multiple subscriptions
3. Run the script:
   - .\collect_azure_inventory.ps1
4. The script writes ./azure_inventory.json (and prints it to console). Paste the JSON here.

What it collects (non-destructive):
- Resource groups
- App Service / Web Apps (Microsoft.Web/sites)
- Container Apps (resource type Microsoft.App/containerApps) if present
- Azure SQL servers & databases (Microsoft.Sql/servers, Microsoft.Sql/servers/databases)
- Key Vaults (Microsoft.KeyVault/vaults)
- Storage Accounts (Microsoft.Storage/storageAccounts) and HNS flag for ADLS Gen2
- Private Endpoints (Microsoft.Network/privateEndpoints) and their connected resources
- Application Gateways (Microsoft.Network/applicationGateways)
- Front Door (Microsoft.Network/frontDoors) and CDN profiles (Microsoft.Cdn/profiles) if present
- Traffic Manager profiles (Microsoft.Network/trafficManagerProfiles)
- DNS zones (Microsoft.Network/dnsZones)
- Public IPs, VNETs, Subnets
- Role assignments for resource groups (optional summary)
- Tags and principal identifying info where available

Note: script uses Get-AzResource for some resource types for broader compatibility.
#>

param(
  [string]$OutputFile = ".\azure_inventory.json"
)

function SafeCall {
  param($ScriptBlock)
  try {
    & $ScriptBlock
  } catch {
    Write-Verbose "Error executing block: $($_.Exception.Message)"
    return $null
  }
}

Write-Host "Starting Azure inventory collection..."
# Check Az module
if (-not (Get-Module -ListAvailable -Name Az)) {
  Write-Warning "Az module not found in this session. If not installed, run: Install-Module -Name Az -Scope CurrentUser"
}

# Basic context
$ctx = $null
try {
  $ctx = Get-AzContext
} catch {
  Write-Host "Please run Connect-AzAccount before executing the script."
  exit 1
}
if (-not $ctx) {
  Write-Host "No Az context. Please run Connect-AzAccount and Select-AzSubscription if needed."
  exit 1
}

$subscription = @{
  Account = $ctx.Account
  Subscription = $ctx.Subscription
  Tenant = $ctx.Tenant
}

# Helper to query resource type using Get-AzResource and return simplified objects
function Get-ResourcesByType([string]$type) {
  try {
    $list = Get-AzResource -ResourceType $type -ErrorAction Stop | Select-Object ResourceId, ResourceGroupName, Name, Location, ResourceType, Tags
    return $list
  } catch {
    # fallback: return empty array
    return @()
  }
}

# Resource groups
$resourceGroups = Get-AzResourceGroup | Select-Object ResourceGroupName = @{Expression={$_.ResourceGroupName}}, Location, Tags

# Web Apps (App Service)
$webApps = @()
try {
  $webApps = Get-AzWebApp | Select-Object Name, ResourceGroup, Location, State, DefaultHostName, Tags
} catch {
  $webApps = @()
}

# Container Apps (Azure Container Apps) - resource type Microsoft.App/containerApps (may return via Get-AzResource)
$containerApps = Get-ResourcesByType "Microsoft.App/containerApps"

# Azure SQL servers and DBs (using Get-AzResource as well)
$sqlServers = Get-ResourcesByType "Microsoft.Sql/servers"
$sqlDatabases = Get-ResourcesByType "Microsoft.Sql/servers/databases"

# Key Vaults
$keyVaults = Get-ResourcesByType "Microsoft.KeyVault/vaults"

# Storage Accounts (and ADLS/HNS property)
$storageAccounts = @()
try {
  $sas = Get-AzStorageAccount -ErrorAction Stop
  foreach ($sa in $sas) {
    $storageAccounts += [PSCustomObject]@{
      Name = $sa.StorageAccountName
      ResourceGroup = $sa.ResourceGroupName
      Location = $sa.Location
      Sku = $sa.SkuName
      Kind = $sa.Kind
      IsHnsEnabled = $sa.IsHnsEnabled
      Tags = $sa.Tags
      Id = $sa.Id
    }
  }
} catch {
  $storageAccounts = Get-ResourcesByType "Microsoft.Storage/storageAccounts"
}

# Private Endpoints
$privateEndpoints = Get-ResourcesByType "Microsoft.Network/privateEndpoints"

# Application Gateways
$applicationGateways = Get-ResourcesByType "Microsoft.Network/applicationGateways"

# Front Door (try multiple possible resource types)
$frontDoors = Get-ResourcesByType "Microsoft.Network/frontDoors"
$cdnProfiles = Get-ResourcesByType "Microsoft.Cdn/profiles"

# Traffic Manager
$trafficManagers = Get-ResourcesByType "Microsoft.Network/trafficManagerProfiles"

# DNS Zones
$dnsZones = Get-ResourcesByType "Microsoft.Network/dnsZones"

# Virtual Networks & Subnets
$vNets = Get-ResourcesByType "Microsoft.Network/virtualNetworks"
$publicIPs = Get-ResourcesByType "Microsoft.Network/publicIPAddresses"

# Role assignments summary per subscription (this can be noisy; keep only top-level summary)
$roleAssignments = @()
try {
  $ra = Get-AzRoleAssignment -ErrorAction Stop
  # Limit to principalName/principalId & roleDefinitionName & scope
  $roleAssignments = $ra | Select-Object @{Name='PrincipalId';Expression={$_.PrincipalId}}, @{Name='PrincipalName';Expression={$_.DisplayName}}, RoleDefinitionName = @{Expression={$_.RoleDefinitionName}}, Scope, @{Name='ObjectType';Expression={$_.ObjectType}} 
} catch {
  $roleAssignments = @()
}

# Private endpoint connection mapping: expand properties for useful info if present
$privateEndpointsExpanded = @()
foreach ($pe in $privateEndpoints) {
  $details = $null
  try {
    $details = Get-AzResource -ResourceId $pe.ResourceId -ExpandProperties | Select-Object -ExpandProperty Properties
  } catch { $details = $null }
  $privateEndpointsExpanded += [PSCustomObject]@{
    Name = $pe.Name
    ResourceGroup = $pe.ResourceGroupName
    Id = $pe.ResourceId
    Location = $pe.Location
    Properties = $details
    Tags = $pe.Tags
  }
}

# Build the inventory object
$inventory = [PSCustomObject]@{
  CollectedAt = (Get-Date).ToString("o")
  Context = $subscription
  ResourceGroups = $resourceGroups
  WebApps = $webApps
  ContainerApps = $containerApps
  SqlServers = $sqlServers
  SqlDatabases = $sqlDatabases
  KeyVaults = $keyVaults
  StorageAccounts = $storageAccounts
  PrivateEndpoints = $privateEndpointsExpanded
  ApplicationGateways = $applicationGateways
  FrontDoors = $frontDoors
  CDNProfiles = $cdnProfiles
  TrafficManagers = $trafficManagers
  DnsZones = $dnsZones
  VirtualNetworks = $vNets
  PublicIPAddresses = $publicIPs
  RoleAssignmentsSample = $roleAssignments
}

# Serialize to JSON and write file
try {
  $json = $inventory | ConvertTo-Json -Depth 6 -Compress
  $json | Out-File -FilePath $OutputFile -Encoding utf8
  Write-Host "`nInventory saved to: $OutputFile`n"
  Write-Host "---- Begin JSON (trimmed) ----"
  $preview = $json
  # print a short preview to console (first 2000 chars)
  if ($preview.Length -gt 2000) { $preview.Substring(0,2000) + " ... (truncated)" } else { $preview }
  Write-Host "`n---- End JSON preview ----`n"
  Write-Host "Please paste the contents of $OutputFile here when ready."
} catch {
  Write-Error "Failed to write output file: $($_.Exception.Message)"
  exit 1
}
