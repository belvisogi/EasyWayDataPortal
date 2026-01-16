<#
.SYNOPSIS
    Syncs local .env file variables to Azure Key Vault secrets.
    
.DESCRIPTION
    Reads a .env file (KEY=VALUE), converts the KEY to KEBAB-CASE (replacing '_' with '-'),
    and uses 'az keyvault secret set' to upsert the value into the specified Vault.
    
    REQUIRES: Azure CLI ('az') logged in.

.PARAMETER EnvFile
    Path to the .env file to sync. Default: ".env"

.PARAMETER VaultName
    Name of the target Azure Key Vault.

.EXAMPLE
    .\sync-env-to-akv.ps1 -EnvFile "../.env.local" -VaultName "kv-easyway-dev"
#>
param(
    [string]$EnvFile = ".env",
    [Parameter(Mandatory = $true)]
    [string]$VaultName
)

if (-not (Test-Path $EnvFile)) {
    Write-Error "File not found: $EnvFile"
    exit 1
}

Write-Host "Syncing secrets from [$EnvFile] to Key Vault [$VaultName]..." -ForegroundColor Cyan

# Read file, ignore comments and empty lines
$lines = Get-Content $EnvFile | Where-Object { $_ -notmatch '^\s*#' -and $_ -match '=' }

foreach ($line in $lines) {
    # Parse KEY=VALUE (naive split on first =)
    $parts = $line -split '=', 2
    $rawKey = $parts[0].Trim()
    $val = $parts[1].Trim()
    
    # Skip meaningless keys
    if ($rawKey -in @("NODE_ENV", "PORT")) { continue }

    # CONVENTION: DB_PASS -> DB-PASS
    $akvName = $rawKey.Replace('_', '-')
    
    Write-Host "  $rawKey -> $akvName ... " -NoNewline
    
    try {
        # Check if exists (optional optimization, but 'set' creates/updates handling versions)
        # We assume 'az' is installed.
        $null = az keyvault secret set --vault-name $VaultName --name $akvName --value $val --output none 2>&1
        Write-Host "OK" -ForegroundColor Green
    }
    catch {
        Write-Host "ERROR" -ForegroundColor Red
        Write-Error $_
    }
}

Write-Host "Sync Complete." -ForegroundColor Green
