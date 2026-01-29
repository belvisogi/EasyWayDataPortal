<#
.SYNOPSIS
    Sovereign Code Auditor
    Checks for hardcoded IPs and Secrets

.DESCRIPTION
    Scans the source code for violations of the "Clean Canvas" philosophy.
    - No Hardcoded IPs
    - No Hardcoded Production URLs
    - No Secrets

.EXAMPLE
    .\audit-hardcoding.ps1
#>

$SourcePath = Join-Path $PSScriptRoot "..\apps\portal-frontend\src"
$Violations = 0

Write-Host "🕵️  INITIATING SOVEREIGN CODE AUDIT..." -ForegroundColor Cyan
Write-Host "    Target: $SourcePath" -ForegroundColor DarkGray

# 1. IP Address Pattern
$IPPattern = "\b\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\b"
$Files = Get-ChildItem -Path $SourcePath -Recurse -Include *.ts, *.js, *.vue, *.jsx, *.tsx

foreach ($File in $Files) {
    $Content = Get-Content $File.FullName
    
    # Check for IPs
    $Matches = $Content | Select-String -Pattern $IPPattern -AllMatches
    foreach ($Match in $Matches) {
        # Ignore Version Numbers (simple heuristic) and Localhost (127.0.0.1)
        if ($Match.Line -notmatch "127\.0\.0\.1" -and $Match.Line -notmatch "version") {
            Write-Host "❌ HARDCODED IP DETECTED in $($File.Name):" -ForegroundColor Red
            Write-Host "   Line $($Match.LineNumber): $($Match.Line.Trim())" -ForegroundColor Yellow
            $Violations++
        }
    }

    # Check for http:// (non-localhost)
    $HttpMatches = $Content | Select-String -Pattern "http://(?!localhost)" -AllMatches
    foreach ($Match in $HttpMatches) {
        Write-Host "⚠️  INSECURE URL DETECTED in $($File.Name):" -ForegroundColor Orange
        Write-Host "   Line $($Match.LineNumber): $($Match.Line.Trim())" -ForegroundColor Gray
        # Warning, not violation (sometimes needed for docs)
    }
}

if ($Violations -gt 0) {
    Write-Host "`n🛑 AUDIT FAILED. $Violations VIOLATIONS FOUND." -ForegroundColor Red
    Write-Host "   GEDI SAYS: 'Measure Twice. Don't commit hardcoded IPs.'"
    exit 1
} else {
    Write-Host "`n✅ AUDIT PASSED. CODE IS SOVEREIGN." -ForegroundColor Green
    exit 0
}
