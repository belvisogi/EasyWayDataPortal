#!/usr/bin/env pwsh
<#
.SYNOPSIS
  Compare database metadata between two environments

.DESCRIPTION
  Extracts metadata from two databases and generates a detailed diff report
  Shows: new objects, deleted objects, modified objects, schema drift
  Use before deploying changes to PROD or syncing to Synapse

.PARAMETER SourceEnv
  Source environment label (e.g., "DEV", "STAGE")

.PARAMETER SourceServer
  Source SQL Server

.PARAMETER SourceDatabase
  Source database name

.PARAMETER TargetEnv
  Target environment label (e.g., "PROD", "SYNAPSE")

.PARAMETER TargetServer
  Target SQL Server

.PARAMETER TargetDatabase
  Target database name

.PARAMETER Username
  SQL Auth username (same for both if not AAD)

.PARAMETER Password
  SQL Auth password

.PARAMETER OutputReport
  Output HTML report path (default: db-diff-report.html)

.EXAMPLE
  .\db-diff-environments.ps1 -SourceDatabase EASYWAY_PORTAL_DEV -TargetDatabase EASYWAY_PORTAL_PROD
#>

param(
    [string]$SourceEnv = "DEV",
    [string]$SourceServer = $env:DB_SERVER ?? "repos-easyway-dev.database.windows.net",
    [string]$SourceDatabase,
    [string]$TargetEnv = "PROD",
    [string]$TargetServer = $env:DB_SERVER,
    [string]$TargetDatabase,
    [string]$Username = $env:DB_USER ?? "easyway-admin",
    [string]$Password = $env:DB_PASSWORD,
    [string]$OutputReport = "db-diff-report.html"
)

$ErrorActionPreference = "Stop"

if (-not $SourceDatabase -or -not $TargetDatabase) {
    throw "Both SourceDatabase and TargetDatabase required"
}

Write-Host "`n🔬 Database Metadata Diff Tool" -ForegroundColor Cyan
Write-Host ("=" * 60) -ForegroundColor Cyan
Write-Host "Source: $SourceEnv ($SourceDatabase)" -ForegroundColor White
Write-Host "Target: $TargetEnv ($TargetDatabase)" -ForegroundColor White
Write-Host ("=" * 60) -ForegroundColor Cyan

# Extract metadata from both environments
Write-Host "`n📊 Step 1: Extracting metadata from $SourceEnv..." -ForegroundColor Yellow
.\db-extract-metadata.ps1 -Server $SourceServer -Database $SourceDatabase -Username $Username -Password $Password -OutputFile "metadata-$SourceEnv.json" | Out-Null

Write-Host "`n📊 Step 2: Extracting metadata from $TargetEnv..." -ForegroundColor Yellow
.\db-extract-metadata.ps1 -Server $TargetServer -Database $TargetDatabase -Username $Username -Password $Password -OutputFile "metadata-$TargetEnv.json" | Out-Null

# Load metadata
$sourceMeta = Get-Content "metadata-$SourceEnv.json" | ConvertFrom-Json
$targetMeta = Get-Content "metadata-$TargetEnv.json" | ConvertFrom-Json

$sourceTables = ($sourceMeta.tables | ConvertFrom-Json)
$targetTables = ($targetMeta.tables | ConvertFrom-Json)
$sourceProcs = ($sourceMeta.procedures | ConvertFrom-Json)
$targetProcs = ($targetMeta.procedures | ConvertFrom-Json)
$sourceFuncs = ($sourceMeta.functions | ConvertFrom-Json)
$targetFuncs = ($targetMeta.functions | ConvertFrom-Json)

Write-Host "`n🔍 Step 3: Analyzing differences..." -ForegroundColor Yellow

# Compare tables
$newTables = $sourceTables | Where-Object {
    $srcTable = $_
    -not ($targetTables | Where-Object { $_.schema -eq $srcTable.schema -and $_.name -eq $srcTable.name })
}

$deletedTables = $targetTables | Where-Object {
    $tgtTable = $_
    -not ($sourceTables | Where-Object { $_.schema -eq $tgtTable.schema -and $_.name -eq $tgtTable.name })
}

# Compare stored procedures
$newProcs = $sourceProcs | Where-Object {
    $srcProc = $_
    -not ($targetProcs | Where-Object { $_.schema -eq $srcProc.schema -and $_.name -eq $srcProc.name })
}

$deletedProcs = $targetProcs | Where-Object {
    $tgtProc = $_
    -not ($sourceProcs | Where-Object { $_.schema -eq $tgtProc.schema -and $_.name -eq $tgtProc.name })
}

$modifiedProcs = $sourceProcs | Where-Object {
    $srcProc = $_
    $matchingTarget = $targetProcs | Where-Object { $_.schema -eq $srcProc.schema -and $_.name -eq $srcProc.name }
    if ($matchingTarget -and $matchingTarget.modified -ne $srcProc.modified) {
        $true
    }
}

# Generate summary
$summary = @{
    source_env  = $SourceEnv
    target_env  = $TargetEnv
    analyzed_at = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    differences = @{
        tables     = @{
            new          = $newTables.Count
            deleted      = $deletedTables.Count
            total_source = $sourceTables.Count
            total_target = $targetTables.Count
        }
        procedures = @{
            new          = $newProcs.Count
            deleted      = $deletedProcs.Count
            modified     = $modifiedProcs.Count
            total_source = $sourceProcs.Count
            total_target = $targetProcs.Count
        }
        functions  = @{
            new          = ($sourceFuncs | Where-Object { $func = $_; -not ($targetFuncs | Where-Object { $_.schema -eq $func.schema -and $_.name -eq $func.name }) }).Count
            deleted      = ($targetFuncs | Where-Object { $func = $_; -not ($sourceFuncs | Where-Object { $_.schema -eq $func.schema -and $_.name -eq $func.name }) }).Count
            total_source = $sourceFuncs.Count
            total_target = $targetFuncs.Count
        }
    }
}

# Display console summary
Write-Host "`n📋 DIFF SUMMARY:" -ForegroundColor Cyan
Write-Host ("=" * 60) -ForegroundColor Cyan

Write-Host "`nTables:" -ForegroundColor White
Write-Host "  ➕ New in $SourceEnv: " -NoNewline; Write-Host $newTables.Count -ForegroundColor Green
Write-Host "  ➖ Deleted from $TargetEnv: " -NoNewline; Write-Host $deletedTables.Count -ForegroundColor Red

Write-Host "`nStored Procedures:" -ForegroundColor White
Write-Host "  ➕ New: " -NoNewline; Write-Host $newProcs.Count -ForegroundColor Green
Write-Host "  ➖ Deleted: " -NoNewline; Write-Host $deletedProcs.Count -ForegroundColor Red
Write-Host "  📝 Modified: " -NoNewline; Write-Host $modifiedProcs.Count -ForegroundColor Yellow

# Generate HTML report
$html = @"
<!DOCTYPE html>
<html>
<head>
  <title>DB Diff: $SourceEnv vs $TargetEnv</title>
  <style>
    body { font-family: -apple-system, system-ui; margin: 40px; background: #f5f5f5; }
    h1 { color: #2563eb; }
    .summary { background: white; padding: 20px; border-radius: 8px; margin: 20px 0; box-shadow: 0 2px 8px rgba(0,0,0,0.1); }
    .stat { display: inline-block; margin: 10px 20px 10px 0; padding: 12px 20px; border-radius: 6px; }
    .new { background: #dcfce7; color: #166534; }
    .deleted { background: #fee2e2; color: #991b1b; }
    .modified { background: #fef3c7; color: #92400e; }
    table { width: 100%; border-collapse: collapse; background: white; margin: 20px 0; border-radius: 8px; overflow: hidden; box-shadow: 0 2px 8px rgba(0,0,0,0.1); }
    th { background: #3b82f6; color: white; padding: 12px; text-align: left; }
    td { padding: 10px 12px; border-bottom: 1px solid #e5e7eb; }
    tr:hover { background: #f9fafb; }
  </style>
</head>
<body>
  <h1>🔍 Database Metadata Diff Report</h1>
  <div class="summary">
    <h2>$SourceEnv → $TargetEnv</h2>
    <p><strong>Analyzed:</strong> $($summary.analyzed_at)</p>
    <div class="stat new">➕ $($newTables.Count) New Tables</div>
    <div class="stat deleted">➖ $($deletedTables.Count) Deleted Tables</div>
    <div class="stat new">➕ $($newProcs.Count) New Procedures</div>
    <div class="stat deleted">➖ $($deletedProcs.Count) Deleted Procedures</div>
    <div class="stat modified">📝 $($modifiedProcs.Count) Modified Procedures</div>
  </div>
"@

if ($newTables.Count -gt 0) {
    $html += "<h2>➕ New Tables in $SourceEnv</h2><table><tr><th>Schema</th><th>Table</th><th>Columns</th></tr>"
    foreach ($table in $newTables) {
        $colCount = ($table.columns | ConvertFrom-Json).Count
        $html += "<tr><td>$($table.schema)</td><td>$($table.name)</td><td>$colCount columns</td></tr>"
    }
    $html += "</table>"
}

if ($newProcs.Count -gt 0) {
    $html += "<h2>➕ New Stored Procedures in $SourceEnv</h2><table><tr><th>Schema</th><th>Procedure</th><th>Created</th></tr>"
    foreach ($proc in $newProcs) {
        $html += "<tr><td>$($proc.schema)</td><td>$($proc.name)</td><td>$($proc.created)</td></tr>"
    }
    $html += "</table>"
}

if ($modifiedProcs.Count -gt 0) {
    $html += "<h2>📝 Modified Stored Procedures</h2><table><tr><th>Schema</th><th>Procedure</th><th>Source Modified</th><th>Target Modified</th></tr>"
    foreach ($proc in $modifiedProcs) {
        $targetProc = $targetProcs | Where-Object { $_.schema -eq $proc.schema -and $_.name -eq $proc.name }
        $html += "<tr><td>$($proc.schema)</td><td>$($proc.name)</td><td>$($proc.modified)</td><td>$($targetProc.modified)</td></tr>"
    }
    $html += "</table>"
}

$html += "</body></html>"

$html | Out-File -FilePath $OutputReport -Encoding UTF8

Write-Host "`n💾 Report saved to: $OutputReport" -ForegroundColor Green
Write-Host "`nOpen in browser:" -ForegroundColor Cyan
Write-Host "  start $OutputReport" -ForegroundColor White

# Return summary object
return $summary
"@

<parameter name="Complexity">9
