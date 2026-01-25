# apply-agent-management-migration.ps1
# Apply Agent Management Console migration using db-deploy-ai

param(
    [Parameter(Mandatory = $false)]
    [string]$Server = $env:DB_SERVER,
    
    [Parameter(Mandatory = $false)]
    [string]$Database = $env:DB_NAME,
    
    [Parameter(Mandatory = $false)]
    [string]$Username = $env:DB_USER,
    
    [Parameter(Mandatory = $false)]
    [string]$Password = $env:DB_PASSWORD,
    
    [Parameter(Mandatory = $false)]
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'

Write-Host "🚀 Applying Agent Management Console Migration" -ForegroundColor Cyan
Write-Host ""

# Validate parameters
if (-not $Server -or -not $Database) {
    Write-Error "Missing database connection parameters. Set environment variables or pass as parameters."
    Write-Host ""
    Write-Host "Usage:" -ForegroundColor Yellow
    Write-Host "  .\apply-agent-management-migration.ps1 -Server 'server.database.windows.net' -Database 'EASYWAY_PORTAL_DEV' -Username 'admin' -Password 'pass'"
    Write-Host ""
    Write-Host "Or set environment variables:" -ForegroundColor Yellow
    Write-Host "  `$env:DB_SERVER = 'server.database.windows.net'"
    Write-Host "  `$env:DB_NAME = 'EASYWAY_PORTAL_DEV'"
    Write-Host "  `$env:DB_USER = 'admin'"
    Write-Host "  `$env:DB_PASSWORD = 'pass'"
    exit 1
}

# Paths
$migrationFile = Join-Path $PSScriptRoot "..\migrations\20260119_agent_management_console.sql"
$dbDeployPath = Join-Path $PSScriptRoot "..\db-deploy-ai"

if (-not (Test-Path $migrationFile)) {
    Write-Error "Migration file not found: $migrationFile"
    exit 1
}

Write-Host "📄 Migration file: $migrationFile" -ForegroundColor Gray
Write-Host "🗄️  Target database: $Database on $Server" -ForegroundColor Gray
Write-Host ""

# Create JSON payload for db-deploy-ai
$migrationSql = Get-Content $migrationFile -Raw

$payload = @{
    connection = @{
        server   = $Server
        database = $Database
        options  = @{
            encrypt                = $true
            trustServerCertificate = $false
        }
    }
    statements = @(
        @{
            id          = "agent_management_console"
            sql         = $migrationSql
            description = "Create Agent Management Console schema and tables"
        }
    )
} | ConvertTo-Json -Depth 10

# Add authentication
if ($Username -and $Password) {
    $payloadObj = $payload | ConvertFrom-Json
    $payloadObj.connection.auth = @{
        type    = "default"
        options = @{
            userName = $Username
            password = $Password
        }
    }
    $payload = $payloadObj | ConvertTo-Json -Depth 10
}

if ($DryRun) {
    Write-Host "🔍 DRY RUN MODE - No changes will be made" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Payload:" -ForegroundColor Gray
    Write-Host $payload
    Write-Host ""
    Write-Host "To apply for real, run without -DryRun flag" -ForegroundColor Yellow
    exit 0
}

# Apply migration using db-deploy-ai
Write-Host "⚙️  Applying migration via db-deploy-ai..." -ForegroundColor Cyan

Push-Location $dbDeployPath

try {
    # Check if node_modules exists
    if (-not (Test-Path "node_modules")) {
        Write-Host "📦 Installing db-deploy-ai dependencies..." -ForegroundColor Yellow
        npm install
    }
    
    # Apply migration
    $payload | node src/cli.js apply
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-Host "✅ Migration applied successfully!" -ForegroundColor Green
        Write-Host ""
        Write-Host "Next steps:" -ForegroundColor Cyan
        Write-Host "  1. Sync agents to database: .\sync-agents-to-db.ps1"
        Write-Host "  2. Test telemetry: Import-Module .\modules\Agent-Management-Telemetry.psm1"
        Write-Host "  3. View dashboard: Invoke-Sqlcmd -Query 'SELECT * FROM AGENT_MGMT.vw_agent_dashboard'"
    }
    else {
        Write-Error "Migration failed with exit code $LASTEXITCODE"
    }
}
catch {
    Write-Error "Error applying migration: $_"
}
finally {
    Pop-Location
}
