<#
.SYNOPSIS
    EasyWay Core - Run All QA Checks
#>

$ErrorActionPreference = "Stop"

Write-Host "✅ Running Frontend Audit..." -ForegroundColor Cyan
& "$PSScriptRoot\audit-frontend.ps1"

Write-Host "✅ Running HTTP Smoke Test..." -ForegroundColor Cyan
& "$PSScriptRoot\http-smoke.ps1"

Write-Host "✅ Running Error Glossary Check..." -ForegroundColor Cyan
& "$PSScriptRoot\error-glossary-check.ps1"

Write-Host "✅ Running Runtime JSON Validation..." -ForegroundColor Cyan
Push-Location "$PSScriptRoot\..\..\apps\portal-frontend"
npm run validate:runtime | Out-Null
if ($LASTEXITCODE -ne 0) {
    Pop-Location
    throw "Runtime JSON validation failed."
}
Pop-Location

Write-Host "✅ All QA checks passed" -ForegroundColor Green
