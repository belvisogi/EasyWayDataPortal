#Requires -Version 5.1
[CmdletBinding()]
param(
    [string]$RepoPath = ".",
    [string]$Branch = "develop",
    [int]$PrId = 0,
    [switch]$SkipSessionInit,
    [switch]$SkipPester
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Assert-Tool {
    param([string]$Name, [string]$Command)
    if (-not (Get-Command $Command -ErrorAction SilentlyContinue)) {
        throw "$Name not found in PATH."
    }
}

Assert-Tool -Name "git" -Command "git"
Assert-Tool -Name "pwsh" -Command "pwsh"

$repo = Resolve-Path $RepoPath
Set-Location $repo

Write-Host "[1/5] Git fetch/prune..." -ForegroundColor Cyan
git fetch origin --prune

if ($PrId -gt 0) {
    Write-Host "[2/5] Checkout PR branch pr/$PrId..." -ForegroundColor Cyan
    git fetch origin ("refs/pull/{0}/head:pr/{0}" -f $PrId)
    git checkout ("pr/{0}" -f $PrId)
}
else {
    Write-Host "[2/5] Checkout and pull branch '$Branch'..." -ForegroundColor Cyan
    git checkout $Branch
    git pull origin $Branch
}

if (-not $SkipSessionInit) {
    Write-Host "[3/5] Session init (ADO verify)..." -ForegroundColor Cyan
    $initScript = Join-Path $repo "scripts\pwsh\Initialize-AzSession.ps1"
    if (-not (Test-Path $initScript)) { throw "Missing script: $initScript" }
    pwsh -NoProfile -File $initScript -VerifyFromFile
}
else {
    Write-Host "[3/5] Session init skipped." -ForegroundColor Yellow
}

if (-not $SkipPester) {
    Write-Host "[4/5] Running conformance tests..." -ForegroundColor Cyan
    $testA = Join-Path $repo "agents\tests\AgentFormalizationL2.Tests.ps1"
    $testB = Join-Path $repo "agents\tests\AgentTieringRBAC.Tests.ps1"
    if (-not (Test-Path $testA)) { throw "Missing test: $testA" }
    if (-not (Test-Path $testB)) { throw "Missing test: $testB" }
    pwsh -NoProfile -Command "Invoke-Pester -Path '$testA', '$testB'"
}
else {
    Write-Host "[4/5] Pester tests skipped." -ForegroundColor Yellow
}

Write-Host "[5/5] Summary" -ForegroundColor Cyan
Write-Host ("Repo:   {0}" -f $repo)
if ($PrId -gt 0) {
    Write-Host ("Mode:   PR validation (PR #{0})" -f $PrId)
}
else {
    Write-Host ("Mode:   Branch sync ({0})" -f $Branch)
}
Write-Host "Status: OK (sync + validation completed)" -ForegroundColor Green
