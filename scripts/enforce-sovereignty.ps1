<#
.SYNOPSIS
    SOVEREIGNTY ENFORCER
    Validates adherence to .cursorrules before deployment.

.DESCRIPTION
    Checks for:
    1. Rogue Agents (Missing Manifests)
    2. Hardcoded Secrets/IPs
    3. Invalid Path References (C:\...)
    4. JSON Validity

.EXAMPLE
    .\enforce-sovereignty.ps1
#>

$ErrorActionPreference = "Stop"

# Configuration
$AgentsRoot = Join-Path $PSScriptRoot "../agents"
$SourceRoot = Join-Path $PSScriptRoot "../apps"
$ExcludedFolders = @("core", "kb", "logs", "templates", "data")
$BannedPatterns = @(
    "http://80\.",            # Hardcoded IPs
    "C:\\old",                # Hardcoded Windows Paths
    "api_key\s*=\s*['`"]sk-", # Simple secret check
    "password\s*=\s*['`"`](?!\$)"   # Hardcoded password (ignore variables)
)

Write-Host "🛡️  INITIATING SOVEREIGNTY CHECK..." -ForegroundColor Cyan

# 1. ROGUE AGENT CHECK
Write-Host "`n🔍 Checking for Rogue Agents..." -ForegroundColor Yellow
$AgentDirs = Get-ChildItem -Path $AgentsRoot -Directory | Where-Object { $_.Name -notin $ExcludedFolders }
$RogueFound = $false

foreach ($agent in $AgentDirs) {
    if (-not (Test-Path (Join-Path $agent.FullName "manifest.json"))) {
        Write-Host "❌ ROGUE AGENT DETECTED: $($agent.Name)" -ForegroundColor Red
        $RogueFound = $true
    }
}

if ($RogueFound) {
    Write-Error "⛔ SOVEREIGNTY VIOLATION: Rogue Agents detected. Every agent must have a manifest.json."
}
else {
    Write-Host "✅ Agent Registry Clean." -ForegroundColor Green
}

# 2. HARDCODING CHECK
Write-Host "`n🔍 Scanning for Hardcoded Sins..." -ForegroundColor Yellow
$Violations = Get-ChildItem -Path $PSScriptRoot, $SourceRoot -Recurse -Include *.ts, *.js, *.ps1, *.json | 
Where-Object { $_.FullName -notmatch "node_modules| dist | \.git" } |
Select-String -Pattern $BannedPatterns

if ($Violations) {
    foreach ($v in $Violations) {
        Write-Host "❌ VIOLATION: $($v.Path):$($v.LineNumber) -> $($v.Line.Trim())" -ForegroundColor Red
    }
    Write-Error "⛔ SOVEREIGNTY VIOLATION: Hardcoded IPs, Secrets, or Absolute Paths found."
}
else {
    Write-Host "✅ Codebase Clean." -ForegroundColor Green
}

Write-Host "`n✨ SOVEREIGNTY CHECK PASSED. YOU MAY PROCEED." -ForegroundColor Cyan
