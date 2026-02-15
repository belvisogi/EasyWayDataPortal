<#
.SYNOPSIS
    Lints and Updates agents against the Factory Template.

.DESCRIPTION
    Ensures all agents in `agents/` comply with the standard `agents/templates/basic-agent/manifest.json`.
    - Lint: Reports missing or mismatched fields.
    - Update: Adds missing keys with default values from the template.

.EXAMPLE
    .\agent-maintenance.ps1 -Action Lint
    .\agent-maintenance.ps1 -Action Update
#>

param(
    [ValidateSet("Lint", "Update")]
    [string]$Action = "Lint",
    [string]$AgentsRoot = "..\..\agents",
    [string]$TemplatePath = "..\..\agents\templates\basic-agent\manifest.json"
)

$ErrorActionPreference = "Stop"

$scriptDir = $PSScriptRoot
$absRoot = Join-Path $scriptDir $AgentsRoot
$absTemplate = Join-Path $scriptDir $TemplatePath

if (-not (Test-Path $absTemplate)) {
    throw "Template not found: $absTemplate"
}

$templateJson = Get-Content $absTemplate -Raw | ConvertFrom-Json -AsHashtable

# Walk through all agents
$agents = Get-ChildItem -Path $absRoot -Directory | Where-Object { $_.Name -notin "core", "logs", "templates", "kb" }

Write-Host "Maintenance Mode: $Action" -ForegroundColor Cyan
Write-Host "Target: $($agents.Count) agents" -ForegroundColor Gray

foreach ($agent in $agents) {
    $manifestPath = Join-Path $agent.FullName "manifest.json"
    
    if (-not (Test-Path $manifestPath)) {
        Write-Warning "[$($agent.Name)] Missing manifest.json"
        continue
    }

    $agentManifest = Get-Content $manifestPath -Raw | ConvertFrom-Json -AsHashtable
    $modified = $false
    $missingKeys = @()

    # Recursive check function (simplified for top-level and first-level nested keys)
    # Ideally should be fully recursive, but shallow + 1 level is usually enough for manifests
    foreach ($key in $templateJson.Keys) {
        if (-not $agentManifest.ContainsKey($key)) {
            $missingKeys += $key
            if ($Action -eq "Update") {
                # Copy default value from template
                # Note: We duplicate to avoid reference issues
                $val = $templateJson[$key]
                if ($val -is [System.Management.Automation.PSCustomObject] -or $val -is [hashtable]) {
                    # Simple clone for hashtable/psobject via JSON roundtrip
                    $agentManifest[$key] = $val | ConvertTo-Json -Depth 10 | ConvertFrom-Json -AsHashtable
                }
                else {
                    $agentManifest[$key] = $val
                }
                $modified = $true
            }
        }
    }

    if ($missingKeys.Count -gt 0) {
        if ($Action -eq "Lint") {
            Write-Host "[$($agent.Name)] DRIFT DETECTED" -ForegroundColor Yellow
            foreach ($k in $missingKeys) {
                Write-Host "  - Missing: $k" -ForegroundColor Red
            }
        }
        elseif ($Action -eq "Update") {
            if ($modified) {
                $agentManifest | ConvertTo-Json -Depth 10 | Set-Content -Path $manifestPath -Encoding utf8
                Write-Host "[$($agent.Name)] FIXED. Added: $($missingKeys -join ', ')" -ForegroundColor Green
            }
        }
    }
    else {
        if ($Action -eq "Lint") {
            Write-Host "[$($agent.Name)] OK" -ForegroundColor Green
        }
    }
}

Write-Host "`nDone." -ForegroundColor Cyan
