<#
.SYNOPSIS
    EasyWay Core - Frontend HTTP Smoke Test
    Verifies that key routes respond with HTTP 200.

.EXAMPLE
    .\http-smoke.ps1 -BaseUrl http://80.225.86.168
#>

param(
    [string]$BaseUrl = "http://80.225.86.168"
)

$ErrorActionPreference = "Continue"

Write-Host "🌐 HTTP SMOKE TEST @ $BaseUrl" -ForegroundColor Cyan

$Routes = @(
    "/",
    "/demo",
    "/manifesto",
    "/manifesto.html",
    "/memory",
    "/pricing"
)

$Failures = 0

foreach ($route in $Routes) {
    $Url = ($BaseUrl.TrimEnd('/') + $route)
    try {
        $res = Invoke-WebRequest -Uri $Url -UseBasicParsing -Method GET -TimeoutSec 10
        if ($res.StatusCode -eq 200) {
            Write-Host "✅ $route -> 200" -ForegroundColor Green
        } else {
            Write-Host "❌ $route -> $($res.StatusCode)" -ForegroundColor Red
            $Failures++
        }
    } catch {
        Write-Host "❌ $route -> ERROR ($($_.Exception.Message))" -ForegroundColor Red
        $Failures++
    }
}

if ($Failures -eq 0) {
    Write-Host "✅ HTTP SMOKE PASSED" -ForegroundColor Green
} else {
    Write-Host "🛑 HTTP SMOKE FAILED: $Failures issues" -ForegroundColor Red
    exit 1
}
