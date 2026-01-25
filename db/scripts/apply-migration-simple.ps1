# apply-migration-simple.ps1
# Simple wrapper to apply any SQL migration using db-deploy-ai
# Usage: .\apply-migration-simple.ps1 -MigrationFile "20260119_agent_management_console.sql"

param(
    [Parameter(Mandatory = $true)]
    [string]$MigrationFile
)

$ErrorActionPreference = 'Stop'

# Load .env if exists
$envFile = Join-Path $PSScriptRoot "..\db-deploy-ai\.env"
if (Test-Path $envFile) {
    Write-Host "📋 Loading environment from .env" -ForegroundColor Gray
    Get-Content $envFile | ForEach-Object {
        if ($_ -match '^([^=]+)=(.*)$') {
            [System.Environment]::SetEnvironmentVariable($matches[1], $matches[2])
        }
    }
}

$migrationPath = Join-Path $PSScriptRoot "..\migrations\$MigrationFile"

if (-not (Test-Path $migrationPath)) {
    Write-Error "Migration file not found: $migrationPath"
    exit 1
}

Write-Host "🚀 Applying migration: $MigrationFile" -ForegroundColor Cyan

# Simple approach: pipe SQL directly to db-deploy-ai
Push-Location (Join-Path $PSScriptRoot "..\db-deploy-ai")

try {
    Get-Content $migrationPath -Raw | npm run apply
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Migration applied successfully!" -ForegroundColor Green
    }
    else {
        Write-Error "Migration failed"
    }
}
finally {
    Pop-Location
}
