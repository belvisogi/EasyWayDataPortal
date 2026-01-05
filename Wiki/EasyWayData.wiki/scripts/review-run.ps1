<#!
.SYNOPSIS
  Orchestrates a full documentation review run (check → front matter → link updates → indices → optional anchor check → log).

.DESCRIPTION
  Runs a sequence of steps using functions from review-examples.ps1.

.PARAMETERS
  -Root, -Mode, -FrontMatterCsv, -LinksMapCsv, -IndexFolders, -ReportDir, -Owner, -Split, -DryRun(-WhatIf), -NoGlobalIndex, -CheckAnchors

.EXAMPLE
  ./review-run.ps1 -FrontMatterCsv fm.csv -LinksMapCsv links.csv -Mode kebab -CheckAnchors
#>

[CmdletBinding()]
param(
  [string]$Root = (Join-Path $PSScriptRoot '..\EasyWayData.wiki'),
  [ValidateSet('kebab','snake','both')][string]$Mode = 'kebab',
  [string]$FrontMatterCsv,
  [string]$LinksMapCsv,
  [string[]]$IndexFolders,
  [string]$ReportDir = (Join-Path $PSScriptRoot '..\logs\reports'),
  [string]$Owner = 'team-docs',
  [ValidateSet('none','monthly','scope')][string]$Split = 'monthly',
  [Alias('WhatIf')][switch]$DryRun,
  [switch]$NoGlobalIndex,
  [switch]$CheckAnchors
)

Set-StrictMode -Version Latest
$PSDefaultParameterValues['*:ErrorAction'] = 'Stop'

. (Join-Path $PSScriptRoot 'review-examples.ps1')

if (!(Test-Path -LiteralPath $ReportDir)) { New-Item -ItemType Directory -Path $ReportDir | Out-Null }
$ts = (Get-Date).ToUniversalTime().ToString('yyyyMMddHHmmss')
$reportPath = Join-Path $ReportDir ("naming-${ts}.txt")

Write-Host "[1/5] Checking naming compliance ($Mode) under $Root ..." -ForegroundColor Cyan
$issues = @( Get-NameCompliance -Root $Root -Mode $Mode )
$reportLines = @()
foreach($i in $issues){ $reportLines += ("{0} | {1}" -f $i.Path, $i.Issues) }
if ($reportLines.Count -gt 0) { $reportLines | Set-Content -LiteralPath $reportPath -Encoding UTF8 } else { "No issues" | Set-Content -LiteralPath $reportPath -Encoding UTF8 }
$issueCount = $issues.Count
Write-Host "  → Issues found: $issueCount (saved to $(Resolve-Path $reportPath))"

$fmAdded = 0
if ($FrontMatterCsv -and (Test-Path -LiteralPath $FrontMatterCsv)) {
  Write-Host "[2/5] Adding front matter if missing from CSV: $FrontMatterCsv ..." -ForegroundColor Cyan
  $rows = Import-Csv -LiteralPath $FrontMatterCsv
  foreach($r in $rows){
    $p = $r.Path; if (-not $p) { continue }
    $full = if ([IO.Path]::IsPathRooted($p)) { $p } else { Join-Path $Root $p }
    if (Test-Path -LiteralPath $full) {
      $content = Get-Content -LiteralPath $full -Raw -Encoding UTF8
      if ($content -notmatch '(?s)^---\s*\n') {
        $id = if ($r.Id) { $r.Id } else { 'ew-' + [IO.Path]::GetFileNameWithoutExtension($full).ToLower() }
        $title = if ($r.Title) { $r.Title } else { [IO.Path]::GetFileNameWithoutExtension($full) }
        $tags = if ($r.Tags) { $r.Tags } else { 'layer/reference' }
        $owner = if ($r.Owner) { $r.Owner } else { $Owner }
        $summary = if ($r.Summary) { $r.Summary } else { 'Breve descrizione del documento.' }
        if ($DryRun) { Write-Host "    (dry-run) would add front matter → $p" -ForegroundColor DarkGray } else { Add-FrontMatterIfMissing -Path $full -Id $id -Title $title -Tags $tags -Owner $owner -Summary $summary }
        $fmAdded++
      }
    }
  }
  Write-Host "  → Front matter added to $fmAdded files"
} else {
  Write-Host "[2/5] Skipping front matter (no CSV provided)" -ForegroundColor DarkGray
}

$linksUpdated = 0
if ($LinksMapCsv -and (Test-Path -LiteralPath $LinksMapCsv)) {
  Write-Host "[3/5] Updating markdown links from CSV: $LinksMapCsv ..." -ForegroundColor Cyan
  $map = @{}
  $rows = Import-Csv -LiteralPath $LinksMapCsv
  foreach($r in $rows){ if($r.Old -and $r.New){ $map[$r.Old] = $r.New } }
  if ($DryRun) { Write-Host "    (dry-run) would apply $($map.Count) link mappings" -ForegroundColor DarkGray } else { Update-MdLinks -Root $Root -Map $map }
  $linksUpdated = $map.Count
  Write-Host "  → Link mappings applied: $linksUpdated"
} else {
  Write-Host "[3/5] Skipping link updates (no CSV provided)" -ForegroundColor DarkGray
}

if (-not $IndexFolders -or $IndexFolders.Count -eq 0) {
  $IndexFolders = @(
    (Join-Path $Root 'EasyWay_WebApp/05_codice_easyway_portale/easyway_portal_api/ENDPOINT'),
    (Join-Path $Root 'EasyWay_WebApp/02_logiche_easyway'),
    (Join-Path $Root 'EasyWay_WebApp/03_datalake_dev')
  )
}
$idxCount = 0
Write-Host "[4/5] Generating index.md for selected folders ..." -ForegroundColor Cyan
foreach($f in $IndexFolders){ if(Test-Path -LiteralPath $f){ if($DryRun){ Write-Host "    (dry-run) would generate index.md in $f" -ForegroundColor DarkGray } else { New-FolderIndex -Folder $f }; $idxCount++ } }
Write-Host "  → Indices generated: $idxCount"

if (-not $NoGlobalIndex) {
  Write-Host "[4b/5] Generating global index.md ..." -ForegroundColor Cyan
  if ($DryRun) { Write-Host "    (dry-run) would generate EasyWayData.wiki/index.md" -ForegroundColor DarkGray } else { New-RootIndex -Root $Root }
}

$anchorsCount = 0
if ($CheckAnchors) {
  Write-Host "[5/5a] Checking markdown anchors ..." -ForegroundColor Cyan
  $ai = @( Get-AnchorIssues -Root $Root )
  $anchorsCount = $ai.Count
  $ats = (Get-Date).ToUniversalTime().ToString('yyyyMMddHHmmss')
  $alink = Join-Path $ReportDir ("anchors-${ats}.md")
  $rows = @("# Anchor Check ($ats)", '', '| File | Link | Issue |', '|---|---|---|')
  foreach($r in $ai){ $rows += "| $($r.File) | $($r.Link) | $($r.Issue) |" }
  $rows -join "`n" | Set-Content -LiteralPath $alink -Encoding UTF8
}

Write-Host "[5/5] Writing activity log ..." -ForegroundColor Cyan
Write-Activity -Type 'REVIEW' -Scope 'wiki' -Status 'success' -Owner $Owner -Message ("review-run: issues={0}, fm={1}, links={2}, indices={3}, report={4}, anchors={5}, dry-run={6}, global-index={7}" -f $issueCount,$fmAdded,$linksUpdated,$idxCount,([IO.Path]::GetFileName($reportPath)),$anchorsCount,$DryRun,(-not $NoGlobalIndex)) -Split $Split
Write-Host "Done." -ForegroundColor Green

