<#
.SYNOPSIS
    Bulk fixes missing frontmatter in Wiki Markdown files.

.DESCRIPTION
    Scans the specified Wiki path for Markdown files.
    If a file lacks frontmatter or missing specific fields (owner, status, tags),
    it injects default values based on the file path and taxonomy.
    
    Supports:
    - Identifying missing frontmatter.
    - Parsing partial frontmatter and adding missing keys.
    - Inferring tags from directory structure.
    - Dry-run mode by default (use -Apply to execute).

.PARAMETER WikiPath
    Path to the Wiki root directory. Default: "Wiki/EasyWayData.wiki"

.PARAMETER Apply
    Switch to actually apply changes. If omitted, runs in Dry-Run mode.

.PARAMETER VerboseLog
    Switch to enable verbose logging of generated frontmatter.

.EXAMPLE
    .\fix-frontmatter-bulk.ps1 -Apply
    
.EXAMPLE
    .\fix-frontmatter-bulk.ps1 -VerboseLog
#>
param(
    [string]$WikiPath = "Wiki/EasyWayData.wiki",
    [switch]$Apply,
    [switch]$VerboseLog
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-TagsFromPath([string]$RelPath) {
    $tags = @()
    $p = $RelPath.Replace('\', '/').ToLowerInvariant()

    if ($p -match 'runbooks/') { $tags += 'layer/runbook' }
    if ($p -match 'agents/') { $tags += 'layer/agent' }
    if ($p -match 'easyway-webapp/05_codice_easyway_portale/') { $tags += 'domain/portal'; $tags += 'layer/code' }
    if ($p -match 'easyway-portal-api') { $tags += 'layer/api' }
    if ($p -match 'easyway-portal-frontend') { $tags += 'layer/frontend' }
    if ($p -match 'easyway-webapp/01_database_architecture/') { $tags += 'domain/db'; $tags += 'layer/data' }
    if ($p -match 'easyway-webapp/03_datalake_dev/') { $tags += 'domain/datalake'; $tags += 'layer/data' }
    if ($p -match 'ux/') { $tags += 'domain/ux' }
    if ($p -match 'argos/') { $tags += 'domain/data'; $tags += 'layer/observability' }
    if ($p -match 'security/') { $tags += 'domain/security' }
    if ($p -match 'orchestrations/') { $tags += 'layer/orchestration' }
    if ($p -match 'blueprints/') { $tags += 'layer/blueprint' }
  
    if ($tags.Count -eq 0) { $tags += 'domain/general' }
    return $tags | Select-Object -Unique
}

$files = Get-ChildItem -LiteralPath $WikiPath -Recurse -Filter *.md -File
$count = 0

foreach ($f in $files) {
    $content = Get-Content -LiteralPath $f.FullName -Raw -Encoding UTF8
    $m = [regex]::Match($content, '^(?s)---\r?\n(?<fm>.*?)\r?\n---\r?\n')
  
    $needsFix = $false
    $fmText = ""
    $body = ""
    $isNewFm = $false

    if ($m.Success) {
        $fmText = $m.Groups['fm'].Value
        $body = $content.Substring($m.Length)
    }
    else {
        $isNewFm = $true
        $body = $content
    }

    # Parse FM roughly (key: value)
    $fmData = @{}
    if (-not $isNewFm) {
        foreach ($line in ($fmText -split '\r?\n')) {
            if ($line -match '^(?<k>[^:]+):\s*(?<v>.*)$') {
                $k = $Matches['k'].Trim()
                $v = $Matches['v'].Trim()
                $fmData[$k] = $v
            }
        }
    }

    # Check defaults
    if (-not $fmData.ContainsKey('title') -and $isNewFm) {
        $fmData['title'] = $f.BaseName.Replace('-', ' ')
        $needsFix = $true
    }
  
    if (-not $fmData.ContainsKey('owner')) {
        $fmData['owner'] = 'team-platform'
        $needsFix = $true
    }

    if (-not $fmData.ContainsKey('status')) {
        $fmData['status'] = 'draft'
        $needsFix = $true
    }

    if (-not $fmData.ContainsKey('tags')) {
        $rel = $f.FullName.Substring((Resolve-Path $WikiPath).Path.Length + 1)
        $tags = Get-TagsFromPath $rel
        $fmData['tags'] = "['" + ($tags -join "', '") + "']"
        $needsFix = $true
    }

    if (-not $fmData.ContainsKey('summary')) {
        $fmData['summary'] = "Documentazione per $($fmData['title'])."
        $needsFix = $true
    }

    if (-not $fmData.ContainsKey('updated')) {
        $fmData['updated'] = (Get-Date).ToString('yyyy-MM-dd')
        $needsFix = $true
    }

    if ($needsFix) {
        $newFm = "---`n"
        foreach ($k in $fmData.Keys) {
            $val = $fmData[$k]
            $newFm += "${k}: $val`n"
        }
        $newFm += "---`n"
    
        $rel = $f.FullName.Substring((Resolve-Path $WikiPath).Path.Length + 1)
    
        if ($Apply) {
            Set-Content -LiteralPath $f.FullName -Value ($newFm + $body) -Encoding UTF8
            Write-Host "Fixed: $rel" -ForegroundColor Green
        }
        else {
            Write-Host "[DryRun] Would patch FM in: $rel" -ForegroundColor Cyan
            if ($VerboseLog) { Write-Host $newFm -ForegroundColor DarkGray }
        }
        $count++
    }
}

Write-Host "Total files processed: $($files.Count)"
Write-Host "Files needing fix: $count"
if (-not $Apply) { Write-Host "Run with -Apply to execute changes." -ForegroundColor Yellow }
