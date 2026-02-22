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

function Read-EnvFile {
    param([string]$Path)
    $vars = @{}
    Get-Content $Path -Encoding UTF8 | Where-Object { $_ -match '^\s*([^#][^=]+)=(.*)$' } | ForEach-Object {
        $key = $Matches[1].Trim()
        $value = $Matches[2].Trim()
        $vars[$key] = $value
    }
    return $vars
}

# ─── Verify mode ─────────────────────────────────────────────────────────────
if ($Verify) {
    $pat = $env:AZURE_DEVOPS_EXT_PAT
    if ([string]::IsNullOrEmpty($pat)) {
        Write-Host "AZURE_DEVOPS_EXT_PAT: NOT SET" -ForegroundColor Red
    }
    elseif ($pat.Length -lt 40) {
        Write-Host "AZURE_DEVOPS_EXT_PAT: SET but too short ($($pat.Length) chars - probably invalid)" -ForegroundColor Yellow
    }
    else {
        Write-Host "AZURE_DEVOPS_EXT_PAT: SET ($($pat.Length) chars) - OK" -ForegroundColor Green
    }
    $cfg = az devops configure --list 2>&1
    Write-Host "az devops config: $cfg"
    return
}

if ($VerifyFromFile) {
    if (-not (Test-Path $SecretsFile)) {
        Write-Host "Secrets file not found: $SecretsFile" -ForegroundColor Red
        return
    }
    $secrets = Read-EnvFile -Path $SecretsFile
    if (-not $secrets.ContainsKey("AZURE_DEVOPS_EXT_PAT")) {
        Write-Host "AZURE_DEVOPS_EXT_PAT not found in $SecretsFile" -ForegroundColor Red
        return
    }
    $patFromFile = $secrets["AZURE_DEVOPS_EXT_PAT"]
    if ([string]::IsNullOrEmpty($patFromFile)) {
        Write-Host "AZURE_DEVOPS_EXT_PAT in file is empty" -ForegroundColor Red
    }
    elseif ($patFromFile.Length -lt 40) {
        Write-Host "AZURE_DEVOPS_EXT_PAT in file is too short ($($patFromFile.Length) chars)" -ForegroundColor Yellow
    }
    else {
        Write-Host "AZURE_DEVOPS_EXT_PAT in file looks valid ($($patFromFile.Length) chars)" -ForegroundColor Green
    }
    return
}

# ─── Load secrets file ────────────────────────────────────────────────────────
if (-not (Test-Path $SecretsFile)) {
    Write-Warning "Secrets file not found: $SecretsFile"
    Write-Host ""
    Write-Host "Create it with:"
    Write-Host "  New-Item '$SecretsFile' -ItemType File"
    Write-Host "  Add-Content '$SecretsFile' 'AZURE_DEVOPS_EXT_PAT=your-52-char-pat'"
    Write-Host ""
    Write-Host "Get a PAT at: https://dev.azure.com/EasyWayData/_usersSettings/tokens"
    Write-Host "Required scopes: Code (Read & Write) + Pull Request Contribute"
    exit 1
}

$secrets = Read-EnvFile -Path $SecretsFile

# ─── Set AZURE_DEVOPS_EXT_PAT ────────────────────────────────────────────────
if (-not $secrets.ContainsKey("AZURE_DEVOPS_EXT_PAT")) {
    Write-Error "AZURE_DEVOPS_EXT_PAT not found in $SecretsFile"
    exit 1
}

$pat = $secrets["AZURE_DEVOPS_EXT_PAT"]

if ($pat.Length -lt 40) {
    Write-Warning "PAT seems too short ($($pat.Length) chars). A valid Azure DevOps PAT is ~52 chars."
    Write-Warning "Get a new PAT at: https://dev.azure.com/EasyWayData/_usersSettings/tokens"
}

$env:AZURE_DEVOPS_EXT_PAT = $pat
Write-Host "AZURE_DEVOPS_EXT_PAT: loaded ($($pat.Length) chars)" -ForegroundColor Green

# ─── Set other env vars from secrets file ────────────────────────────────────
foreach ($key in $secrets.Keys) {
    if ($key -ne "AZURE_DEVOPS_EXT_PAT") {
        Set-Item -Path "Env:\$key" -Value $secrets[$key]
        Write-Host "$($key): loaded" -ForegroundColor DarkGray
    }
}

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
