#Requires -Version 5.1
<#
.SYNOPSIS
    Initialize GitHub CLI session for PR workflows.

.DESCRIPTION
    Loads secrets via Sovereign Gatekeeper and exports process token variables:
      - GH_TOKEN
      - GITHUB_TOKEN (fallback alias for tools expecting this name)

    By default, uses AgentId `agent_developer` so access is enforced by
    `C:\old\rbac-master.json` allowed profiles.
#>
[CmdletBinding()]
param(
    [string]$AgentId = "agent_developer",
    [switch]$NoTokenReset,
    [switch]$Verify
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repoRoot = (git rev-parse --show-toplevel 2>$null)
if (-not $repoRoot) { $repoRoot = $PWD.Path }

# Prevent stale process token values from shadowing .env/RBAC values.
if (-not $NoTokenReset) {
    Remove-Item Env:GH_TOKEN -ErrorAction SilentlyContinue
    Remove-Item Env:GITHUB_TOKEN -ErrorAction SilentlyContinue
}

$importSecretsScript = Join-Path $repoRoot "agents" "skills" "utilities" "Import-AgentSecrets.ps1"
if (-not (Test-Path $importSecretsScript)) {
    throw "Universal Token Broker not found at $importSecretsScript"
}

. $importSecretsScript
$secrets = Import-AgentSecrets -AgentId $AgentId

$ghToken = $env:GH_TOKEN
if (-not $ghToken) { $ghToken = $env:GITHUB_TOKEN }

if (-not $ghToken) {
    throw "GH_TOKEN/GITHUB_TOKEN not granted by Global Gatekeeper (RBAC_DENY or missing profile key)."
}

# Normalize both vars for compatibility.
[System.Environment]::SetEnvironmentVariable("GH_TOKEN", $ghToken, [System.EnvironmentVariableTarget]::Process)
[System.Environment]::SetEnvironmentVariable("GITHUB_TOKEN", $ghToken, [System.EnvironmentVariableTarget]::Process)

Write-Host "GitHub token loaded by Gatekeeper ($($ghToken.Length) chars)." -ForegroundColor Green

if (Get-Command gh -ErrorAction SilentlyContinue) {
    if ($Verify) {
        Write-Host "Running: gh auth status" -ForegroundColor Cyan
        gh auth status
    }
    else {
        Write-Host "GitHub session initialized. Use: gh pr create ..." -ForegroundColor Cyan
    }
}
else {
    Write-Warning "GitHub CLI (gh) not found in PATH. Session variables are set, but CLI checks are skipped."
}
