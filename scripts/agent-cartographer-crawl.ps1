# agent-cartographer-crawl.ps1
# Scans the ecosystem and populates the Dependency Graph based on file evidence.

$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot
$graphFile = Join-Path $root '..\Wiki\EasyWayData.wiki\concept\dependency-graph.md'

if (-not (Test-Path $graphFile)) { Write-Error "Map not found!"; exit 1 }

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
        $files = Get-ChildItem -Path (Join-Path $root '..') -Recurse -Filter $probe.PathMatch -ErrorAction SilentlyContinue
    } elseif ($probe.ContentMatch) {
         # Simplified for speed: just checking extension for now
         $files = Get-ChildItem -Path (Join-Path $root '..') -Recurse -Filter "*$($probe.Extension)" -ErrorAction SilentlyContinue
    } else {
        $files = Get-ChildItem -Path (Join-Path $root '..') -Recurse -Filter "*$($probe.Extension)" -ErrorAction SilentlyContinue
    }

    foreach ($f in $files) {
        if ($f.FullName -match 'node_modules' -or $f.FullName -match '.git') { continue }
        
        $relPath = $f.FullName.Replace((Join-Path $root '..'), '').Trim('\')
        $findings += "Found evidence of **$($probe.Type)**: `file:///$relPath` (Category: $($probe.Category))"
    }
}

# Append to Graph
$newContent = "`n## 🕵️ Crawler Findings (Auto-Generated - $(Get-Date))`n"
foreach ($finding in $findings) {
    $newContent += "* $finding`n"
}

Add-Content -Path $graphFile -Value $newContent

Write-Host "✅ Map Updated with $($findings.Count) new items." -ForegroundColor Green
