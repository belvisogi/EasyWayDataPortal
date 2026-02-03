param(
    [Parameter(Mandatory = $true)]
    [string]$PackagePath,
    
    [Parameter(Mandatory = $true)]
    [string]$RemoteUrl,
    
    [string]$Branch = "main",
    [string]$CommitMsg = "chore(release): snapshot publish"
)

$ErrorActionPreference = "Stop"

# 1. Validation
if (-not (Test-Path $PackagePath)) {
    Write-Error "Package path not found: $PackagePath"
    exit 1
}

Write-Host "🚀 Publishing $PackagePath to $RemoteUrl..." -ForegroundColor Cyan

# 2. Create Temp Publish Dir
$TempDir = Join-Path $env:TEMP "publish-$(Get-Random)"
New-Item -ItemType Directory -Path $TempDir | Out-Null

try {
    # 3. Copy files (exclude sensitive/garbage)
    Write-Host "-> Copying files to temp workspace..."
    Copy-Item -Path "$PackagePath\*" -Destination $TempDir -Recurse -Force
    
    # 4. Initialize Temp Git
    Write-Host "-> Initializing isolated git repository..."
    Push-Location $TempDir
    git init
    git add .
    git commit -m "$CommitMsg"
    
    # 5. Push to Remote (Force to overwrite history with clean slice)
    Write-Host "-> Pushing to Sovereign Fortress..."
    git remote add origin $RemoteUrl
    git branch -M $Branch
    git push -u origin $Branch --force
    
    Write-Host "✅ SUCCESS! Package published to $RemoteUrl" -ForegroundColor Green
}
catch {
    Write-Error "❌ FAILED: $_"
}
finally {
    # 6. Cleanup
    Pop-Location
    Remove-Item -Path $TempDir -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "-> Cleanup complete."
}
