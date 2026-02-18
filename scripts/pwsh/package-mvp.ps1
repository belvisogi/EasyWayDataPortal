# scripts/pwsh/package-mvp.ps1
# Packages the EasyWay MVP Appliance into a tar.gz bundle.

$ErrorActionPreference = "Stop"

$ReleaseDir = "release"
$ArtifactName = "easyway-mvp.tar.gz"
$SourceDir = $PWD

Write-Host "📦 Packaging EasyWay MVP Appliance..." -ForegroundColor Cyan

# 1. Clean & Prepare Release Directory
if (Test-Path $ReleaseDir) {
    # Keep init.sql and deploy.sh if present
    Get-ChildItem $ReleaseDir -Exclude "init.sql", "deploy.sh" | Remove-Item -Recurse -Force
}
else {
    New-Item -ItemType Directory -Path $ReleaseDir | Out-Null
}

# 2. Copy Docker Compose
Copy-Item "docker-compose.yml" -Destination "$ReleaseDir/docker-compose.yml" -Force

# 3. Copy Critical Components (Agents, Scripts, Wiki)
# Required for agent-runner service
Write-Host "   Copying Agents, Scripts, Wiki..."
Copy-Item "agents" -Destination "$ReleaseDir/agents" -Recurse -Force
Copy-Item "scripts" -Destination "$ReleaseDir/scripts" -Recurse -Force
Copy-Item "Wiki" -Destination "$ReleaseDir/Wiki" -Recurse -Force

# exclude node_modules if accidentally copied
if (Test-Path "$ReleaseDir/scripts/node_modules") {
    Remove-Item "$ReleaseDir/scripts/node_modules" -Recurse -Force
}

# 4. Copy Frontend Assets (Standardized)
$WwwDir = "$ReleaseDir/www"
if (-not (Test-Path $WwwDir)) { New-Item -ItemType Directory -Path $WwwDir | Out-Null }

if (Test-Path "apps/portal-frontend/dist") {
    Write-Host "   Copying Frontend dist/..."
    Copy-Item "apps/portal-frontend/dist/*" -Destination $WwwDir -Recurse -Force
    
    # Copy nginx.conf
    Copy-Item "apps/portal-frontend/nginx.conf" -Destination "$ReleaseDir/nginx.conf" -Force
}
else {
    Write-Warning "Frontend dist/ not found. Release package will lack UI assets."
}

# 5. Patch docker-compose.yml for Release (Use Nginx Image + Mounts instead of Build)
Write-Host "   Patching docker-compose.yml for Release..."
$composeContent = Get-Content "$ReleaseDir/docker-compose.yml" -Raw

# Replace 'build: ... Dockerfile' block with 'image: nginx...' and volumes
# We target the specic 'frontend' service definition we wrote.
# Note: Indentation matters in YAML.
$oldBlock = @"
    build:
      context: ./apps/portal-frontend
      dockerfile: Dockerfile
"@

$newBlock = @"
    image: nginxinc/nginx-unprivileged:alpine
    volumes:
      - ./www:/usr/share/nginx/html
      - ./nginx.conf:/etc/nginx/conf.d/default.conf
"@

if ($composeContent -match "context: ./apps/portal-frontend") {
    $composeContent = $composeContent.Replace($oldBlock, $newBlock)
    $composeContent | Set-Content "$ReleaseDir/docker-compose.yml" -Encoding UTF8
    Write-Host "   -> Frontend service converted to static nginx mount."
}
else {
    Write-Warning "Could not patch docker-compose.yml (Pattern mismatch). Frontend might fail to Start."
}

# 6. Create Tarball
Write-Host "📚 Compressing to $ArtifactName..." -ForegroundColor Cyan
tar -czf $ArtifactName -C $ReleaseDir .

Write-Host "✅ Package Created: $ArtifactName" -ForegroundColor Green
Get-Item $ArtifactName | Select-Object Name, Length
