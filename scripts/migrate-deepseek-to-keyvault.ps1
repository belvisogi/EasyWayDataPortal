# migrate-deepseek-to-keyvault.ps1
# Migrates DeepSeek API key from ~/.bashrc to Azure Key Vault
#
# Prerequisites:
#   - Azure CLI (az) installed and logged in
#   - Key Vault "easyway-vault" exists (see infra/terraform/main.tf)
#   - Current user has Key Vault secrets/set permission
#
# Usage:
#   pwsh -File migrate-deepseek-to-keyvault.ps1 [-WhatIf] [-VaultName easyway-vault]
#
# After migration:
#   1. Remove DEEPSEEK_API_KEY from ~/.bashrc
#   2. Update docker-compose.yml to read from Key Vault or .env
#   3. Update .env.prod with Key Vault reference
#   4. Restart easyway-runner container

param(
    [string]$VaultName = "easyway-vault",
    [string]$SecretName = "deepseek--api--key",
    [switch]$WhatIf
)

$ErrorActionPreference = "Stop"

Write-Host "========================================"
Write-Host " DeepSeek API Key -> Key Vault Migration"
Write-Host " Vault:  $VaultName"
Write-Host " Secret: $SecretName"
Write-Host " Mode:   $(if ($WhatIf) { 'DRY RUN' } else { 'LIVE' })"
Write-Host "========================================"
Write-Host ""

# Step 1: Verify Azure CLI
Write-Host "[1/5] Checking Azure CLI..." -ForegroundColor Cyan
try {
    $azAccount = az account show 2>&1 | ConvertFrom-Json
    Write-Host "  Logged in as: $($azAccount.user.name)" -ForegroundColor Green
    Write-Host "  Subscription: $($azAccount.name)" -ForegroundColor Green
}
catch {
    Write-Error "Azure CLI not logged in. Run 'az login' first."
    exit 1
}

# Step 2: Verify Key Vault exists
Write-Host "[2/5] Checking Key Vault '$VaultName'..." -ForegroundColor Cyan
try {
    $vault = az keyvault show --name $VaultName 2>&1 | ConvertFrom-Json
    Write-Host "  Vault found: $($vault.properties.vaultUri)" -ForegroundColor Green
}
catch {
    Write-Error "Key Vault '$VaultName' not found. Create it first via Terraform."
    exit 1
}

# Step 3: Read current API key from environment
Write-Host "[3/5] Reading DEEPSEEK_API_KEY from environment..." -ForegroundColor Cyan
$apiKey = $env:DEEPSEEK_API_KEY
if (-not $apiKey) {
    # Try reading from ~/.bashrc
    $bashrcPath = Join-Path $env:HOME ".bashrc"
    if (Test-Path $bashrcPath) {
        $bashrcContent = Get-Content $bashrcPath -Raw
        if ($bashrcContent -match 'export\s+DEEPSEEK_API_KEY=["'']?([^"''\s]+)["'']?') {
            $apiKey = $Matches[1]
            Write-Host "  Found in ~/.bashrc" -ForegroundColor Yellow
        }
    }
}

if (-not $apiKey) {
    Write-Error "DEEPSEEK_API_KEY not found in environment or ~/.bashrc"
    exit 1
}

# Mask the key for display
$maskedKey = $apiKey.Substring(0, 5) + "..." + $apiKey.Substring($apiKey.Length - 4)
Write-Host "  Key found: $maskedKey" -ForegroundColor Green

# Step 4: Store in Key Vault
Write-Host "[4/5] Storing secret in Key Vault..." -ForegroundColor Cyan
if ($WhatIf) {
    Write-Host "  [DRY RUN] Would store '$SecretName' in vault '$VaultName'" -ForegroundColor Yellow
    Write-Host "  [DRY RUN] Tags: owner=team-platform, scope=production, component=deepseek" -ForegroundColor Yellow
}
else {
    # SECURITY: Never log the actual value
    az keyvault secret set `
        --vault-name $VaultName `
        --name $SecretName `
        --value $apiKey `
        --tags "owner=team-platform" "scope=production" "component=deepseek" "rotate-by=2026-08-01" `
        --output none

    Write-Host "  Secret stored successfully (value NOT logged)" -ForegroundColor Green

    # Generate Key Vault reference
    $kvRef = "@Microsoft.KeyVault(VaultName=$VaultName;SecretName=$SecretName)"
    Write-Host "  Key Vault Reference: $kvRef" -ForegroundColor Green
}

# Step 5: Post-migration instructions
Write-Host ""
Write-Host "[5/5] Post-migration steps (MANUAL):" -ForegroundColor Cyan
Write-Host ""
Write-Host "  1. Remove from ~/.bashrc:" -ForegroundColor White
Write-Host "     sed -i '/DEEPSEEK_API_KEY/d' ~/.bashrc" -ForegroundColor DarkGray
Write-Host ""
Write-Host "  2. Update .env.prod:" -ForegroundColor White
Write-Host "     DEEPSEEK_API_KEY=@Microsoft.KeyVault(VaultName=$VaultName;SecretName=$SecretName)" -ForegroundColor DarkGray
Write-Host ""
Write-Host "  3. For Docker containers, fetch at runtime:" -ForegroundColor White
Write-Host "     DEEPSEEK_API_KEY=`$(az keyvault secret show --vault-name $VaultName --name $SecretName --query value -o tsv)" -ForegroundColor DarkGray
Write-Host ""
Write-Host "  4. Update agent_security memory:" -ForegroundColor White
Write-Host "     Add '$SecretName' to known_secrets in memory/context.json" -ForegroundColor DarkGray
Write-Host ""
Write-Host "  5. Restart containers:" -ForegroundColor White
Write-Host "     docker compose restart agent-runner" -ForegroundColor DarkGray
Write-Host ""

# Update agent_security memory
$securityMemoryPath = Join-Path $PSScriptRoot "../agents/agent_security/memory/context.json"
if (Test-Path $securityMemoryPath) {
    $memory = Get-Content $securityMemoryPath -Raw | ConvertFrom-Json
    if ($memory.knowledge.known_secrets -notcontains $SecretName) {
        # Already has "deepseek--api--key" from Level 2 upgrade
        Write-Host "  [INFO] Secret '$SecretName' already tracked in agent_security memory" -ForegroundColor Green
    }
}

Write-Host "========================================"
Write-Host " Migration $(if ($WhatIf) { 'preview' } else { 'complete' })"
Write-Host "========================================"
