
$ErrorActionPreference = 'Stop'

Write-Host "🏗️  Starting Scripts Refactor Migration..." -ForegroundColor Cyan

# 1. Create Directories
$dirs = @('scripts/pwsh', 'scripts/python', 'scripts/node')
foreach ($d in $dirs) {
    if (-not (Test-Path $d)) {
        New-Item -ItemType Directory -Path $d -Force | Out-Null
        Write-Host "  + Created $d" -ForegroundColor Green
    }
}

# 2. Move Files (PowerShell)
$psFiles = Get-ChildItem "scripts" -Filter "*.ps1" -File
foreach ($file in $psFiles) {
    if ($file.Name -ne "migrate-scripts-structure.ps1") {
        Move-Item $file.FullName -Destination "scripts/pwsh/" -Force
        Write-Host "  > Moved $($file.Name) to pwsh/" -ForegroundColor Gray
    }
}

# 3. Move Files (Python)
$pyFiles = Get-ChildItem "scripts" -Filter "*.py" -File
foreach ($file in $pyFiles) {
    Move-Item $file.FullName -Destination "scripts/python/" -Force
    Write-Host "  > Moved $($file.Name) to python/" -ForegroundColor Gray
}

# 4. Move Files (Node)
$jsFiles = Get-ChildItem "scripts" -Include "*.js", "*.mjs" -Recurse -Depth 0 | Where-Object { $_.PSIsContainer -eq $false }
foreach ($file in $jsFiles) {
    Move-Item $file.FullName -Destination "scripts/node/" -Force
    Write-Host "  > Moved $($file.Name) to node/" -ForegroundColor Gray
}

# 5. Move Core to pwsh/core (Preserve relative imports)
if (Test-Path "scripts/core") {
    if (Test-Path "scripts/pwsh/core") { Remove-Item "scripts/pwsh/core" -Recurse -Force }
    Move-Item "scripts/core" -Destination "scripts/pwsh/" -Force
    Write-Host "  > Moved core/ to pwsh/core/" -ForegroundColor Yellow
}

# 6. Update Manifests
Write-Host "📝 Updating Manifests..." -ForegroundColor Cyan
$manifests = Get-ChildItem "agents" -Recurse -Filter "manifest.json"
foreach ($m in $manifests) {
    $content = Get-Content $m.FullName -Raw
    $newContent = $content
    
    # Replace PS1 paths: "scripts/foo.ps1" -> "scripts/pwsh/foo.ps1"
    # Regex look for "scripts/[something].ps1"
    $newContent = $newContent -replace 'scripts/([\w\-\.]+)\.ps1', 'scripts/pwsh/$1.ps1'
    
    # Replace Python paths
    $newContent = $newContent -replace 'scripts/([\w\-\.]+)\.py', 'scripts/python/$1.py'
    
    # Replace Node paths
    $newContent = $newContent -replace 'scripts/([\w\-\.]+)\.m?js', 'scripts/node/$1.js' # Simplistic, assumes extension match

    if ($content -ne $newContent) {
        Set-Content -Path $m.FullName -Value $newContent -Encoding UTF8
        Write-Host "  * Updated $($m.FullName)" -ForegroundColor Green
    }
}

Write-Host "✅ Migration Complete." -ForegroundColor Cyan
