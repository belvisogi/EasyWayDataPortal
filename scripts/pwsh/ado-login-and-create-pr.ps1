param(
    [string]$Organization = "https://dev.azure.com/EasyWayData",
    [string]$Project = "EasyWay-DataPortal",
    [string]$Repository = "EasyWayDataPortal",
    [string]$SourceBranch = "fix-forgejo-local",
    [string]$TargetBranch = "develop",
    [string]$Title = "forgejo: local stack fix + PRD operating model hardening",
    [string]$Description = "",
    [string]$AzConfigDir = "c:\old\.azurecli",
    [switch]$OpenBrowserLogin
)

$ErrorActionPreference = "Stop"

function Get-PlainTextFromSecureString {
    param([Security.SecureString]$Secure)
    $bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($Secure)
    try {
        return [Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr)
    }
    finally {
        [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
    }
}

Write-Host "== Azure DevOps PR Helper ==" -ForegroundColor Cyan
Write-Host "Organization: $Organization"
Write-Host "Project:      $Project"
Write-Host "Repository:   $Repository"
Write-Host "PR:           $SourceBranch -> $TargetBranch"

$env:AZURE_CONFIG_DIR = $AzConfigDir

if ($OpenBrowserLogin) {
    Write-Host "Running az login (browser/device flow)..." -ForegroundColor Yellow
    az login | Out-Null
}

if (-not $env:AZURE_DEVOPS_EXT_PAT) {
    $patSecure = Read-Host "Inserisci Azure DevOps PAT (input nascosto)" -AsSecureString
    $pat = Get-PlainTextFromSecureString -Secure $patSecure
}
else {
    $pat = $env:AZURE_DEVOPS_EXT_PAT
}

try {
    $pat | az devops login --organization $Organization | Out-Null
    az devops configure --defaults organization=$Organization project=$Project | Out-Null

    $args = @(
        "repos", "pr", "create",
        "--repository", $Repository,
        "--source-branch", $SourceBranch,
        "--target-branch", $TargetBranch,
        "--title", $Title
    )

    if ($Description -and $Description.Trim().Length -gt 0) {
        $args += @("--description", $Description)
    }

    Write-Host "Creating PR..." -ForegroundColor Yellow
    az @args
}
finally {
    if ($pat -and -not $env:AZURE_DEVOPS_EXT_PAT) {
        $pat = $null
    }
}
