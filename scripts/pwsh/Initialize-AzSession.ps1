#Requires -Version 5.1
<#
.SYNOPSIS
    Initialize Azure DevOps CLI session for PR creation.

.DESCRIPTION
    Loads secrets from C:\old\.env.developer (outside the git repo) and sets:
    - $env:AZURE_DEVOPS_EXT_PAT  → used by az repos pr create
    - az devops default org/project

    Run once at the start of each Claude Code session before creating PRs.

.PARAMETER SecretsFile
    Path to the local secrets file. Defaults to C:\old\.env.developer
    This file must NOT be inside the git repository.

.PARAMETER OrgUrl
    Azure DevOps organization URL. Default: https://dev.azure.com/EasyWayData

.PARAMETER Project
    Azure DevOps project name. Default: EasyWay-DataPortal

.EXAMPLE
    pwsh scripts/pwsh/Initialize-AzSession.ps1

.EXAMPLE
    # Verify current session state
    pwsh scripts/pwsh/Initialize-AzSession.ps1 -Verify

.NOTES
    Secrets file format (C:\old\.env.developer):
        AZURE_DEVOPS_EXT_PAT=your-pat-here-52chars
        DEEPSEEK_API_KEY=sk-...

    A valid PAT must have scopes: Code (Read & Write) + Pull Request Contribute.
    PAT length: ~52 characters. If az returns user 'aaaa-aaaa', the PAT is invalid.

    See: Wiki/EasyWayData.wiki/agents/platform-operational-memory.md - Section 5
#>
[CmdletBinding()]
param(
    [string]$SecretsFile = "C:\old\.env.developer",
    [string]$OrgUrl = "https://dev.azure.com/EasyWayData",
    [string]$Project = "EasyWay-DataPortal",
    [switch]$Verify,
    [switch]$VerifyFromFile
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# ─── Load secrets via Universal Broker ─────────────────────────────────────────

$repoRoot = (git rev-parse --show-toplevel 2>$null)
if (-not $repoRoot) { $repoRoot = $PWD.Path }
$importSecretsScript = Join-Path $repoRoot "agents" "skills" "utilities" "Import-AgentSecrets.ps1"

if (-not (Test-Path $importSecretsScript)) {
    Write-Error "Universal Token Broker not found at $importSecretsScript"
    exit 1
}

# The Broker checks rbac-master.json and loads allowed .env files securely.
# We claim identity 'agent_developer' which is authorized for ADO PRs.
. $importSecretsScript
$secrets = Import-AgentSecrets -AgentId "agent_developer"

# ─── Set AZURE_DEVOPS_EXT_PAT ────────────────────────────────────────────────
if (-not $secrets.ContainsKey("AZURE_DEVOPS_EXT_PAT")) {
    Write-Error "AZURE_DEVOPS_EXT_PAT not granted by Global Gatekeeper (RBAC_DENY)"
    exit 1
}

$pat = $env:AZURE_DEVOPS_EXT_PAT

if ($pat.Length -lt 40) {
    Write-Warning "PAT seems too short ($($pat.Length) chars). A valid Azure DevOps PAT is ~52 chars."
    Write-Warning "Get a new PAT at: https://dev.azure.com/EasyWayData/_usersSettings/tokens"
}

Write-Host "AZURE_DEVOPS_EXT_PAT: loaded by Gatekeeper ($($pat.Length) chars)" -ForegroundColor Green

# ─── Configure az devops defaults ────────────────────────────────────────────
Write-Host "Configuring az devops defaults..." -ForegroundColor Cyan
az devops configure --defaults organization=$OrgUrl project=$Project 2>&1 | Out-Null
Write-Host "az devops defaults: org=$OrgUrl, project=$Project" -ForegroundColor Green

# ─── Quick validation ─────────────────────────────────────────────────────────
Write-Host ""
Write-Host "Session initialized. Ready to create PRs:" -ForegroundColor Cyan
Write-Host "  az repos pr create --source-branch feat/<name> --target-branch develop --title '...' --description '...'"
Write-Host ""
Write-Host "Tip: use -Verify flag to check current session state."
