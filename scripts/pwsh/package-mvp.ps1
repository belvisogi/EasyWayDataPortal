# scripts/pwsh/package-mvp.ps1
# Packages the EasyWay MVP Appliance into a tar.gz bundle.

$ErrorActionPreference = "Stop"

$ReleaseDir = "release"
$ArtifactName = "easyway-mvp.tar.gz"
$SourceDir = $PWD

Write-Host "📦 Packaging EasyWay MVP Appliance..." -ForegroundColor Cyan

# 1. Ensure Release Dir Exists (cleaned)
if (Test-Path $ReleaseDir) {
    # Don't delete init.sql or deploy.sh which we just put there
    # actually we should clean everything ELSE
}
else {
    New-Item -ItemType Directory -Path $ReleaseDir | Out-Null
}

# 2. Copy Docker Compose
Copy-Item "docker-compose.yml" -Destination "$ReleaseDir/docker-compose.yml" -Force

# 3. Copy Frontend Assets (Standardized)
$WwwDir = "$ReleaseDir/www"
if (-not (Test-Path $WwwDir)) { New-Item -ItemType Directory -Path $WwwDir | Out-Null }
# In a real build, we would run 'npm run build' here.
# For MVP/Prototype, we might copy src if it's not built, but let's assume raw or dist.
# Checking if dist exists
if (Test-Path "apps/portal-frontend/dist") {
    Copy-Item "apps/portal-frontend/dist/*" -Destination $WwwDir -Recurse -Force
}
else {
    Write-Warning "Frontend dist/ not found. Skipping static assets copy (assuming runtime build or manual copy)."
}

# 4. Create Tarball
# Requires tar on Windows (built-in on Win10/11)
Write-Host "📚 Compressing to $ArtifactName..." -ForegroundColor Cyan
tar -czf $ArtifactName -C $ReleaseDir .

Write-Host "✅ Package Created: $ArtifactName" -ForegroundColor Green
Get-Item $ArtifactName | Select-Object Name, Length
