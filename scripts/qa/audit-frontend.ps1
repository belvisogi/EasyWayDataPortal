<#
.SYNOPSIS
    EasyWay Core - Frontend Audit (Framework Compliance)
    Checks static HTML pages for framework usage and font consistency.

.EXAMPLE
    .\audit-frontend.ps1
#>

$ErrorActionPreference = "Continue"

Write-Host "🧭 STARTING FRONTEND AUDIT..." -ForegroundColor Cyan

$RootPath = Resolve-Path "$PSScriptRoot\..\.."
$FrontendPath = "$RootPath\apps\portal-frontend"
$Failures = 0

if (-not (Test-Path $FrontendPath)) {
    Write-Host "❌ Frontend path not found: $FrontendPath" -ForegroundColor Red
    exit 1
}

$HtmlFiles = Get-ChildItem $FrontendPath -Filter "*.html"
if (-not $HtmlFiles) {
    Write-Host "⚠️  No HTML files found in $FrontendPath" -ForegroundColor Yellow
    exit 0
}

foreach ($file in $HtmlFiles) {
    $Content = Get-Content $file.FullName -Raw
    $Missing = @()

    if ($Content -notmatch "/src/theme\.css") { $Missing += "theme.css" }
    if ($Content -notmatch "/src/framework\.css") { $Missing += "framework.css" }

    if ($Missing.Count -gt 0) {
        Write-Host "❌ $($file.Name): Missing styles -> $($Missing -join ', ')" -ForegroundColor Red
        $Failures++
    }
    else {
        Write-Host "✅ $($file.Name): Core styles OK" -ForegroundColor Green
    }

    if ($Content -match "fonts\.googleapis\.com|fonts\.gstatic\.com") {
        Write-Host "❌ $($file.Name): External fonts detected (Google Fonts)" -ForegroundColor Red
        $Failures++
    }

    $FontMatches = [regex]::Matches($Content, 'font-family\s*:\s*([^;]+);', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
    foreach ($match in $FontMatches) {
        $Value = $match.Groups[1].Value.Trim()
        $ValueLower = $Value.ToLowerInvariant()
        if ($ValueLower -notlike "*var(--font-family)*" -and $ValueLower -notlike "*var(--font-mono)*" -and $ValueLower -notlike "*monospace*" -and $ValueLower -notlike "*inherit*") {
            Write-Host "❌ $($file.Name): Hardcoded font-family -> $Value" -ForegroundColor Red
            $Failures++
        }
    }

    $H1Matches = [regex]::Matches($Content, '<h1[^>]*>', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
    foreach ($match in $H1Matches) {
        if ($match.Value -notmatch 'class\s*=\s*\"[^\"]*\bh1\b') {
            Write-Host "❌ $($file.Name): H1 missing .h1 class -> $($match.Value)" -ForegroundColor Red
            $Failures++
        }
    }

    $H2Matches = [regex]::Matches($Content, '<h2[^>]*>', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
    foreach ($match in $H2Matches) {
        if ($match.Value -notmatch 'class\s*=\s*\"[^\"]*\bh2\b') {
            Write-Host "❌ $($file.Name): H2 missing .h2 class -> $($match.Value)" -ForegroundColor Red
            $Failures++
        }
    }
}

if ($Failures -eq 0) {
    Write-Host "✅ FRONTEND AUDIT PASSED" -ForegroundColor Green
}
else {
    Write-Host "🛑 FRONTEND AUDIT FAILED: $Failures issues found" -ForegroundColor Red
    exit 1
}
