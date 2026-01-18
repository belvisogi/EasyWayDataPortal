param(
    [string]$TargetRoot = "$PSScriptRoot/../..",
    [switch]$Force
)

$ErrorActionPreference = 'Stop'

function Ensure-Dir($path) {
    if (-not (Test-Path $path)) {
        Write-Host " [NEW] Directory: $path" -ForegroundColor Green
        New-Item -ItemType Directory -Path $path -Force | Out-Null
    }
    else {
        Write-Host " [OK]  Directory: $path" -ForegroundColor Gray
    }
}

function Ensure-File($path, $content) {
    if (-not (Test-Path $path) -or $Force) {
        Write-Host " [NEW] File: $path" -ForegroundColor Green
        $dir = Split-Path -Parent $path
        Ensure-Dir $dir
        Set-Content -LiteralPath $path -Value $content -Encoding utf8
    }
    else {
        Write-Host " [OK]  File: $path" -ForegroundColor Gray
    }
}

$root = (Resolve-Path $TargetRoot).Path
Write-Host "Scaffolding Axet project structure in: $root" -ForegroundColor Cyan

# 1. Standard Folder Structure (Outside Rules)
Ensure-Dir "$root/Client/Generali/Wiki"
Ensure-Dir "$root/Wiki"
Ensure-Dir "$root/agents/kb"
Ensure-Dir "$root/agents/intents"
Ensure-Dir "$root/agents/orchestrations"
Ensure-Dir "$root/docs/agentic/templates/intents"

# 2. Key Placeholder Files

# KB Recipes
Ensure-File "$root/agents/kb/recipes.jsonl" "{}"

# Wiki Placeholder (if empty)
$wikiMain = "$root/Wiki/AdaDataProject.wiki"
# Try to read from Rules manifest if available
$manifestPath = "$root/Rules/manifest.json"
$homePath = "$wikiMain/Home.md"
if (Test-Path $manifestPath) {
    try {
        $m = Get-Content $manifestPath -Raw | ConvertFrom-Json
        if ($m.wikiHome) { $homePath = $m.wikiHome }
    }
    catch {}
}

if (-not (Test-Path $wikiMain)) {
    Ensure-Dir $wikiMain
}
if (-not (Test-Path $homePath)) {
    Ensure-Dir (Split-Path $homePath)
    Ensure-File $homePath "---\nid: home\ntitle: Home\ntags: [home]\n---\n\n# Welcome to the Project Wiki"
}

# 3. Governance Config (if Rules exists in target)
$rulesConfig = "$root/Rules/governance.config.json"
if (Test-Path "$root/Rules") {
    $configContent = @{
        WikiPath    = "Wiki/AdaDataProject.wiki"
        ProjectRoot = "."
    } | ConvertTo-Json -Depth 2
    
    if (-not (Test-Path $rulesConfig)) {
        Ensure-File $rulesConfig $configContent
    }
}

Write-Host "Scaffolding complete." -ForegroundColor Green

