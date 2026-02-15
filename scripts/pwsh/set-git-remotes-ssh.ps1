param(
    [string]$AdoUrl = "",
    [string]$GitHubUrl = "",
    [string]$ForgejoUrl = "",
    [switch]$Apply,
    [switch]$AlsoSetOriginToAdo,
    [switch]$Strict
)

$ErrorActionPreference = "Stop"

function Invoke-GitCapture {
    param([Parameter(Mandatory = $true)][string[]]$Args)
    $output = & git @Args 2>&1
    return [PSCustomObject]@{
        ExitCode = $LASTEXITCODE
        Output   = ($output -join "`n").Trim()
    }
}

function Get-RemoteUrl {
    param([Parameter(Mandatory = $true)][string]$Remote)
    $res = Invoke-GitCapture -Args @("remote", "get-url", $Remote)
    if ($res.ExitCode -ne 0) {
        return ""
    }
    return $res.Output
}

function Convert-ToSshUrl {
    param([Parameter(Mandatory = $true)][string]$Url)
    $u = $Url.Trim()
    if ($u -match "^git@|^ssh://") {
        return $u
    }

    if ($u -match "^https://dev\.azure\.com/([^/]+)/([^/]+)/_git/([^/]+)$") {
        return "git@ssh.dev.azure.com:v3/$($Matches[1])/$($Matches[2])/$($Matches[3])"
    }

    if ($u -match "^https://github\.com/([^/]+)/([^/]+?)(?:\.git)?$") {
        return "git@github.com:$($Matches[1])/$($Matches[2]).git"
    }

    if ($u -match "^https://([^/]+)/([^/]+)/([^/]+?)(?:\.git)?$") {
        return "ssh://git@$($Matches[1])/$($Matches[2])/$($Matches[3]).git"
    }

    return $u
}

function Upsert-Remote {
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        [AllowEmptyString()][string]$Url
    )

    if ([string]::IsNullOrWhiteSpace($Url)) {
        if ($Strict) {
            throw "Target URL missing for remote '$Name'."
        }
        Write-Host "Skipping '$Name': URL not provided." -ForegroundColor Yellow
        return
    }

    $existing = Get-RemoteUrl -Remote $Name
    if ([string]::IsNullOrWhiteSpace($existing)) {
        Write-Host "Add remote '$Name' -> $Url"
        if ($Apply) {
            & git remote add $Name $Url
            if ($LASTEXITCODE -ne 0) {
                throw "Failed to add remote '$Name'."
            }
        }
        return
    }

    if ($existing -eq $Url) {
        Write-Host "Remote '$Name' already aligned."
        return
    }

    Write-Host "Set remote '$Name': $existing -> $Url"
    if ($Apply) {
        & git remote set-url $Name $Url
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to set URL for remote '$Name'."
        }
    }
}

Write-Host "== Git remote SSH migration ==" -ForegroundColor Cyan
if ($Apply) {
    Write-Host "Mode: apply"
}
else {
    Write-Host "Mode: plan"
}

if ([string]::IsNullOrWhiteSpace($AdoUrl)) {
    $adoCandidate = Get-RemoteUrl -Remote "ado"
    if ([string]::IsNullOrWhiteSpace($adoCandidate)) {
        $adoCandidate = Get-RemoteUrl -Remote "origin"
    }
    if (-not [string]::IsNullOrWhiteSpace($adoCandidate)) {
        $AdoUrl = Convert-ToSshUrl -Url $adoCandidate
    }
}
else {
    $AdoUrl = Convert-ToSshUrl -Url $AdoUrl
}

if (-not [string]::IsNullOrWhiteSpace($GitHubUrl)) {
    $GitHubUrl = Convert-ToSshUrl -Url $GitHubUrl
}
elseif (-not [string]::IsNullOrWhiteSpace((Get-RemoteUrl -Remote "github"))) {
    $GitHubUrl = Convert-ToSshUrl -Url (Get-RemoteUrl -Remote "github")
}

if (-not [string]::IsNullOrWhiteSpace($ForgejoUrl)) {
    $ForgejoUrl = Convert-ToSshUrl -Url $ForgejoUrl
}
elseif (-not [string]::IsNullOrWhiteSpace((Get-RemoteUrl -Remote "forgejo"))) {
    $ForgejoUrl = Convert-ToSshUrl -Url (Get-RemoteUrl -Remote "forgejo")
}

Write-Host "Target remotes:"
Write-Host " - ado:     $AdoUrl"
Write-Host " - github:  $GitHubUrl"
Write-Host " - forgejo: $ForgejoUrl"
if ($AlsoSetOriginToAdo) {
    Write-Host " - origin:  $AdoUrl"
}

Upsert-Remote -Name "ado" -Url $AdoUrl
Upsert-Remote -Name "github" -Url $GitHubUrl
Upsert-Remote -Name "forgejo" -Url $ForgejoUrl

if ($AlsoSetOriginToAdo) {
    Upsert-Remote -Name "origin" -Url $AdoUrl
}

if ($Apply) {
    Write-Host ""
    Write-Host "Final remotes:" -ForegroundColor Green
    & git remote -v
}
else {
    Write-Host ""
    Write-Host "No changes applied. Re-run with -Apply to execute." -ForegroundColor Yellow
}
