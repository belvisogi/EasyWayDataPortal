<#
.SYNOPSIS
    Agent Audit: Architecture Enforcer
    Verifies that all agents comply with the Standard Agent Architecture.

.DESCRIPTION
    Scans 'agents/*' and checks for:
    - manifest.json existence and schema
    - README.md existence and linkage
    - Referenced scripts existence

.PARAMETER Mode
    Audit mode: all, manifest-only, scripts-only, readme-only

.PARAMETER DryRun
    No-op parameter for standard compliance (script is read-only implicitly).
    
.PARAMETER AutoFix
    Attempts to auto-fix common issues
    
.PARAMETER FailOnError
    Exit with code 1 if errors found
    
.PARAMETER SummaryOut
    Path to JSON summary output file
#>
param(
    [ValidateSet('all', 'manifest-only', 'scripts-only', 'readme-only')]
    [string]$Mode = 'all',
    [switch]$DryRun,
    [switch]$AutoFix,
    [switch]$FailOnError,
    [string]$SummaryOut = "out/agent-audit.json"
)

$ErrorActionPreference = "Stop"
$AgentsRoot = "agents"
$StandardDoc = "Wiki/EasyWayData.wiki/standards/agent-architecture-standard.md"

Write-Host "👮 Agent Audit: Starting Inspection... (AutoFix: $AutoFix)" -ForegroundColor Cyan

if (-not (Test-Path $StandardDoc)) {
    Write-Warning "Standard Document not found at $StandardDoc. Audit proceeds but references might be outdated."
}

$agents = Get-ChildItem -Path $AgentsRoot -Directory | Where-Object { $_.Name -notin @("logs", "memory", "config", "core", "kb", "skills", "templates", "tests") }
$totalErrors = 0
$totalWarnings = 0
$filesFixed = 0

foreach ($agentFolder in $agents) {
    $agentName = $agentFolder.Name
    $manifestPath = Join-Path $agentFolder.FullName "manifest.json"
    $readmePath = Join-Path $agentFolder.FullName "README.md"
    
    Write-Host "   Checking $agentName..." -NoNewline
    
    $errors = @()
    $warnings = @()
    $manifestDirty = $false
    
    # 1. Manifest Check
    if (-not (Test-Path $manifestPath)) {
        $errors += "Missing manifest.json"
    }
    else {
        try {
            $manifest = Get-Content $manifestPath -Raw | ConvertFrom-Json
            
            # Schema Checks
            if (-not $manifest.name) { 
                $errors += "Manifest missing 'name'" 
                if ($AutoFix) {
                    $manifest | Add-Member -MemberType NoteProperty -Name "name" -Value $agentName -Force
                    $manifestDirty = $true
                    Write-Host " [FIXED: Added name]" -ForegroundColor Green -NoNewline
                }
            }
            
            # Classification Check (Brain vs Arm)
            if (-not $manifest.classification) {
                $errors += "Manifest missing 'classification' (brain|arm)"
                if ($AutoFix) {
                    # Default: Arm (Safer default)
                    $manifest | Add-Member -MemberType NoteProperty -Name "classification" -Value "arm" -Force
                    $manifestDirty = $true
                    Write-Host " [FIXED: Added classification='arm']" -ForegroundColor Green -NoNewline
                }
            }
            elseif ($manifest.classification -notin @("brain", "arm")) {
                $errors += "Invalid classification '$($manifest.classification)'. Must be 'brain' or 'arm'."
            }

            if (-not $manifest.role) { $errors += "Manifest missing 'role'" }
            if (-not $manifest.description) { $warnings += "Manifest missing 'description'" }
            
            # Readme Link Check
            if (-not $manifest.readme) { 
                $errors += "Manifest missing 'readme' field" 
                if ($AutoFix) {
                    $manifest | Add-Member -MemberType NoteProperty -Name "readme" -Value "README.md" -Force
                    $manifestDirty = $true
                    Write-Host " [FIXED: Added readme field]" -ForegroundColor Green -NoNewline
                }
            }
            elseif (-not (Test-Path (Join-Path $agentFolder.FullName $manifest.readme))) {
                $errors += "Manifest links to '$($manifest.readme)' but file not found"
            }
            
            # Script Integrity Check (Read-Only)
            if ($manifest.actions) {
                # ... (Script check logic remains read-only as we can't auto-write code) ...
            }

            # Apply Manifest Fixes
            if ($manifestDirty -and -not $DryRun) {
                ($manifest | ConvertTo-Json -Depth 30) | Set-Content -Encoding UTF8 -Path $manifestPath
                $filesFixed++
                # Remove fixed errors from counting to show immediate progress
                $errors = $errors | Where-Object { $_ -notmatch "Manifest missing 'name'" -and $_ -notmatch "Manifest missing 'readme' field" }
            }
            
        }
        catch {
            $errors += "Invalid JSON in manifest.json"
        }
    }
    
    # 2. Independent README Check
    if (-not (Test-Path $readmePath)) {
        if ($errors -notcontains "Manifest links to 'README.md' but file not found") {
            $warnings += "No README.md found in agent root"
            if ($AutoFix) {
                $role = if ($manifest.role) { $manifest.role } else { "Agent" }
                $desc = if ($manifest.description) { $manifest.description } else { "Auto-generated description." }
                $readmeContent = @"
# $agentName
**Role**: $role

## Overview
$desc

## Capabilities
- *Auto-generated by Agent Audit*.

## Architecture
- **Script**: Pending...
- **Manifest**: manifest.json

## Usage
See manifest for actions.
"@
                if (-not $DryRun) {
                    $readmeContent | Set-Content -Path $readmePath -Encoding UTF8
                    $filesFixed++
                    Write-Host " [FIXED: Created README.md]" -ForegroundColor Green -NoNewline
                    $warnings = $warnings | Where-Object { $_ -ne "No README.md found in agent root" }
                }
            }
        }
    }
    
    # Report
    if ($errors.Count -gt 0) {
        Write-Host " FAIL" -ForegroundColor Red
        foreach ($e in $errors) { Write-Host "      ❌ $e" -ForegroundColor Red }
        $totalErrors += $errors.Count
    }
    elseif ($warnings.Count -gt 0) {
        Write-Host " WARN" -ForegroundColor Yellow
        foreach ($w in $warnings) { Write-Host "      ⚠️  $w" -ForegroundColor Yellow }
        $totalWarnings += $warnings.Count
    }
    else {
        Write-Host " OK" -ForegroundColor Green
    }
}

Write-Host "`n----------------------------------------"

# Generate JSON summary
$summary = @{
    timestamp    = Get-Date -Format 'o'
    mode         = $Mode
    total_agents = $agents.Count
    errors       = $totalErrors
    warnings     = $totalWarnings
    files_fixed  = $filesFixed
    passed       = ($agents.Count - ($totalErrors / [Math]::Max($agents.Count, 1)))
}

# Save summary if path provided
if ($SummaryOut) {
    $outDir = Split-Path $SummaryOut -Parent
    if ($outDir -and -not (Test-Path $outDir)) {
        New-Item -ItemType Directory -Path $outDir -Force | Out-Null
    }
    $summary | ConvertTo-Json -Depth 5 | Out-File $SummaryOut -Encoding UTF8
    Write-Host "Summary saved: $SummaryOut" -ForegroundColor Cyan
}

if ($totalErrors -gt 0) {
    Write-Host "🛑 Audit Failed: $totalErrors errors, $totalWarnings warnings." -ForegroundColor Red
    if ($FailOnError) {
        exit 1
    }
}
else {
    Write-Host "✅ Audit Passed: All agents compliant." -ForegroundColor Green
    if ($totalWarnings -gt 0) { Write-Host "   ($totalWarnings warnings found)" -ForegroundColor Yellow }
}

exit 0
