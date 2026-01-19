# agent-cartographer-crawl.ps1
# Scans the ecosystem and populates the Dependency Graph based on file evidence.
# Uses centralized path configuration for portability.

$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot

# Load path configuration
$configPath = Join-Path $root '..\..\\.config\paths.json'
if (-not (Test-Path $configPath)) { 
    Write-Error "Configuration file not found: $configPath"
    Write-Host "Please ensure .config/paths.json exists in the project root." -ForegroundColor Yellow
    exit 1 
}

try {
    $config = Get-Content $configPath -Raw | ConvertFrom-Json
    $projectRoot = $config.paths.projectRoot
    Write-Host "📍 Using project root: $projectRoot" -ForegroundColor Cyan
} catch {
    Write-Error "Failed to load configuration: $_"
    exit 1
}

$graphFile = Join-Path $projectRoot 'Wiki\EasyWayData.wiki\concept\dependency-graph.md'

if (-not (Test-Path $graphFile)) { Write-Error "Map not found: $graphFile"; exit 1 }

Write-Host "🕷️  Cartographer Crawler Initiated..." -ForegroundColor Cyan

# Define Probes
$probes = @(
    @{ Type="PowerBI"; Extension=".pbix"; Category="Analytics" },
    @{ Type="Synapse/SQL"; Extension=".sql"; Category="Data Platform" },
    @{ Type="WebApp"; Extension=".html"; Category="Frontend" },
    @{ Type="LogicApp/Flow"; Extension=".json"; ContentMatch="Microsoft.Logic"; Category="Services" },
    @{ Type="AzureDevOps"; PathMatch="scripts/agent-ado"; Category="VM/DevOps" }
)

$findings = @()

# Scan
foreach ($probe in $probes) {
    if ($probe.PathMatch) {
        $files = Get-ChildItem -Path $projectRoot -Recurse -Filter $probe.PathMatch -ErrorAction SilentlyContinue
    } elseif ($probe.ContentMatch) {
         # Simplified for speed: just checking extension for now
         $files = Get-ChildItem -Path $projectRoot -Recurse -Filter "*$($probe.Extension)" -ErrorAction SilentlyContinue
    } else {
        $files = Get-ChildItem -Path $projectRoot -Recurse -Filter "*$($probe.Extension)" -ErrorAction SilentlyContinue
    }

    foreach ($f in $files) {
        if ($f.FullName -match 'node_modules' -or $f.FullName -match '\.git') { continue }
        
        # Generate relative path for portability
        $relPath = $f.FullName.Replace($projectRoot, '').TrimStart('\').Replace('\', '/')
        $findings += "Found evidence of **$($probe.Type)**: file:///$relPath (Category: $($probe.Category))"
    }
}

# Append to Graph
$newContent = "`n## 🕵️ Crawler Findings (Auto-Generated - $(Get-Date -Format 'MM/dd/yyyy HH:mm:ss'))`n"
$newContent += "> Generated using relative paths from .config/paths.json`n`n"
foreach ($finding in $findings) {
    $newContent += "* $finding`n"
}

Add-Content -Path $graphFile -Value $newContent

Write-Host "✅ Map Updated with $($findings.Count) new items." -ForegroundColor Green
Write-Host "📝 All paths are now relative for portability." -ForegroundColor Green
