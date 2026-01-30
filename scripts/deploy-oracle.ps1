<#
.SYNOPSIS
    Sovereign Deployer for Oracle Cloud
    Uploads and launches the production stack.

.DESCRIPTION
    1. Checks for .env.prod
    2. Packages strict necessary files (no git, no node_modules)
    3. Uploads to target server via SCP
    4. Executes docker compose up remotely

.PARAMETER TargetUser
    SSH Username (e.g., ubuntu, opc)
.PARAMETER TargetIP
    IP Address of the Oracle Server
.PARAMETER KeyPath
    Path to SSH Private Key (optional if in ssh-agent)

.EXAMPLE
    .\deploy-oracle.ps1 -TargetUser ubuntu -TargetIP 80.225.86.168
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$TargetUser,

    [Parameter(Mandatory = $true)]
    [string]$TargetIP,

    [string]$KeyPath,

    [switch]$Bootstrap # If set, runs initial server setup (Docker, Firewall)
)

$ErrorActionPreference = "Stop"
$RootPath = Resolve-Path "$PSScriptRoot\.."
$DeployDir = "/opt/easyway"

Write-Host "🚀 INITIATING SOVEREIGN DEPLOYMENT to $TargetIP..." -ForegroundColor Cyan

# 0. Bootstrap (Optional)
if ($Bootstrap) {
    Write-Host "🐣 BOOTSTRAPPING FRESH SERVER..." -ForegroundColor Magenta
    $SshArgs = @()
    if ($KeyPath) { $SshArgs += "-i", $KeyPath }
    
    # Upload bootstrap script
    $BootstrapDest = "{0}@{1}:/tmp/bootstrap.sh" -f $TargetUser, $TargetIP
    scp @SshArgs "$PSScriptRoot\server-bootstrap.sh" $BootstrapDest
    
    # Execute it
    ssh @SshArgs "$TargetUser@$TargetIP" "chmod +x /tmp/bootstrap.sh && /tmp/bootstrap.sh"
    
    Write-Host "✅ Bootstrap Done. Waiting 5s for services..."
    Start-Sleep -Seconds 5
}

# 1. Validation
if (-not (Test-Path "$RootPath\.env.prod")) {
    Write-Error "❌ MISSING .env.prod! Copy .env.prod.example and fill it."
}

# 2. Packaging
Write-Host "📦 Packaging Artifacts..." -ForegroundColor Yellow
# Create a temporary deploy folder
$TempDir = Join-Path $env:TEMP "easyway-deploy"
if (Test-Path $TempDir) { Remove-Item $TempDir -Recurse -Force }
New-Item -ItemType Directory -Path $TempDir | Out-Null

# Copy specific files (Allowlist approach for security)
Copy-Item "$RootPath\docker-compose.prod.yml" "$TempDir\docker-compose.yml"
Copy-Item "$RootPath\.env.prod" "$TempDir\.env"
# Copy apps with exclusions
$AppsSource = "$RootPath\apps"
Get-ChildItem $AppsSource -Recurse | Where-Object { 
    $_.FullName -notmatch "node_modules|dist|\.git|tests|coverage"
} | ForEach-Object {
    $RelativePath = [System.IO.Path]::GetRelativePath($RootPath, $_.FullName)
    $Dest = Join-Path $TempDir $RelativePath
    
    if ($_.PSIsContainer) {
        New-Item -ItemType Directory -Path $Dest -Force | Out-Null
    }
    else {
        Copy-Item $_.FullName -Destination $Dest -Force
    }
}
Copy-Item "$RootPath\apps\portal-frontend\public\config.js" "$TempDir\config.js" # Runtime config

# Tar it (Windows requires tar or external tool. Windows 10+ has tar.exe)
$TarPath = "$env:TEMP\easyway-package.tar.gz"
tar -czf $TarPath -C $TempDir .

# 3. Transfer
Write-Host "📡 Uploading to Oracle Cloud..." -ForegroundColor Yellow
$SshArgs = @()
if ($KeyPath) { $SshArgs += "-i", $KeyPath }

# Create remote dir
ssh @SshArgs "$TargetUser@$TargetIP" "sudo mkdir -p $DeployDir && sudo chown ${TargetUser}:${TargetUser} $DeployDir"

# Upload
$TarDest = "{0}@{1}:{2}/package.tar.gz" -f $TargetUser, $TargetIP, $DeployDir
scp @SshArgs $TarPath $TarDest

# 4. Remote Execution
Write-Host "🔥 Igniting Remote Stack..." -ForegroundColor Magenta
$RemoteScript = @"
cd $DeployDir
tar -xzf package.tar.gz
# Ensure config is in the right place for build context if needed
# Build and Up
docker compose down --remove-orphans
docker compose up -d --build
docker system prune -f # Cleanup old images
"@

$RemoteScript = $RemoteScript -replace '\r', ''
if ($KeyPath) {
    ssh -i $KeyPath "$TargetUser@$TargetIP" $RemoteScript
}
else {
    ssh "$TargetUser@$TargetIP" $RemoteScript
}

Write-Host "✅ DEPLOYMENT COMPLETE." -ForegroundColor Green
Write-Host "   Frontend: http://$TargetIP:80"
Write-Host "   n8n:      http://$TargetIP/webhook/"
