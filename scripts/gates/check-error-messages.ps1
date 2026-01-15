#!/usr/bin/env pwsh
<#
.SYNOPSIS
Quality Gate: Error Messages UX
Checks that error messages follow user-friendly best practices

.DESCRIPTION
Automated checks for error-messages-ux.md gate:
- No raw error.message usage
- No alert() calls  
- No English error strings
- ErrorTranslator usage compliance

.PARAMETER Path
Directory to scan (default: src/)

.PARAMETER Fix
Auto-fix violations where possible

.EXAMPLE
pwsh scripts/gates/check-error-messages.ps1
pwsh scripts/gates/check-error-messages.ps1 -Path "src/components" -Fix
#>

param(
    [string]$Path = "easyway-webapp/05_codice_easyway_portale/easyway-portal-frontend/src",
    [switch]$Fix = $false
)

$ErrorCount = 0
$WarningCount = 0

Write-Host "🔍 Error Messages UX Quality Gate" -ForegroundColor Cyan
Write-Host "Scanning: $Path" -ForegroundColor Gray
Write-Host ""

# Check 1: Raw error.message usage
Write-Host "📋 Check 1: No raw error.message..." -ForegroundColor Yellow
$files = Get-ChildItem -Path $Path -Recurse -Include "*.tsx", "*.ts" -File
$rawErrorFiles = @()

foreach ($file in $files) {
    $content = Get-Content $file.FullName -Raw
    if ($content -match 'error\.message' -and $content -notmatch 'console\.error') {
        $rawErrorFiles += $file.FullName
    }
}

if ($rawErrorFiles.Count -gt 0) {
    Write-Host "   ❌ Found $($rawErrorFiles.Count) files with raw error.message:" -ForegroundColor Red
    $rawErrorFiles | ForEach-Object { Write-Host "      - $_" -ForegroundColor Red }
    $ErrorCount += $rawErrorFiles.Count
}
else {
    Write-Host "   ✅ No raw error.message usage" -ForegroundColor Green
}

# Check 2: alert() usage
Write-Host ""
Write-Host "📋 Check 2: No alert() calls..." -ForegroundColor Yellow
$alertFiles = @()

foreach ($file in $files) {
    $content = Get-Content $file.FullName -Raw
    if ($content -match '\balert\s*\(' -and $file.Name -notmatch '\.test\.' ) {
        $alertFiles += $file.FullName
    }
}

if ($alertFiles.Count -gt 0) {
    Write-Host "   ⚠️  Found $($alertFiles.Count) files with alert():" -ForegroundColor Yellow
    $alertFiles | ForEach-Object { Write-Host "      - $_" -ForegroundColor Yellow }
    $WarningCount += $alertFiles.Count
}
else {
    Write-Host "   ✅ No alert() usage" -ForegroundColor Green
}

# Check 3: English error strings
Write-Host ""
Write-Host "📋 Check 3: No English error messages..." -ForegroundColor Yellow
$englishErrorFiles = @()

foreach ($file in $files) {
    $content = Get-Content $file.FullName -Raw
    # Match common English error patterns like: toast.error("Error: ...")
    if ($content -match 'toast\.error\s*\(\s*["\'](?!.*[àèéìòù])[A-Z][a-z]+') {
        $englishErrorFiles += $file.FullName
    }
}

if ($englishErrorFiles.Count -gt 0) {
    Write-Host "   ⚠️  Found $($englishErrorFiles.Count) files with potential English errors:" -ForegroundColor Yellow
    $englishErrorFiles | ForEach-Object { Write-Host "      - $_" -ForegroundColor Yellow }
    $WarningCount += $englishErrorFiles.Count
} else {
    Write-Host "   ✅ Error messages appear to be in Italian" -ForegroundColor Green
}

# Check 4: ErrorTranslator import presence
Write-Host ""
Write-Host "📋 Check 4: ErrorTranslator usage..." -ForegroundColor Yellow
$filesWithCatch = @()
$filesWithTranslator = @()

foreach ($file in $files) {
    $content = Get-Content $file.FullName -Raw
    if ($content -match '\bcatch\s*\(') {
        $filesWithCatch += $file
        if ($content -match 'errorTranslator | handleError') {
            $filesWithTranslator += $file
        }
    }
}

$coverage = if ($filesWithCatch.Count -gt 0) { 
    [math]::Round(($filesWithTranslator.Count / $filesWithCatch.Count) * 100, 1) 
} else { 
    100 
}

Write-Host "   Files with try-catch: $($filesWithCatch.Count)" -ForegroundColor Gray
Write-Host "   Files using errorTranslator: $($filesWithTranslator.Count)" -ForegroundColor Gray
Write-Host "   Coverage: $coverage%" -ForegroundColor $(if ($coverage -ge 80) { "Green" } else { "Yellow" })

if ($coverage -lt 80) {
    $WarningCount++
}

# Summary
Write-Host ""
Write-Host "═══════════════════════════════════════" -ForegroundColor Magenta
Write-Host "📊 GATE SUMMARY" -ForegroundColor Magenta
Write-Host "═══════════════════════════════════════" -ForegroundColor Magenta

if ($ErrorCount -eq 0 -and $WarningCount -eq 0) {
    Write-Host "✅ ALL CHECKS PASSED" -ForegroundColor Green
    Write-Host ""
    Write-Host "🎉 Error messages quality is excellent!" -ForegroundColor Green
    exit 0
} elseif ($ErrorCount -eq 0) {
    Write-Host "⚠️  WARNINGS: $WarningCount" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Gate passed with warnings. Consider fixing:" -ForegroundColor Yellow
    Write-Host "  - Replace alert() with ErrorToast" -ForegroundColor Yellow
    Write-Host "  - Translate English messages to Italian" -ForegroundColor Yellow
    Write-Host "  - Increase errorTranslator coverage" -ForegroundColor Yellow
    exit 0
} else {
    Write-Host "❌ ERRORS: $ErrorCount" -ForegroundColor Red
    Write-Host "⚠️  WARNINGS: $WarningCount" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "GATE FAILED. Fix these issues:" -ForegroundColor Red
    Write-Host "  1. Remove raw error.message usage" -ForegroundColor Red
    Write-Host "  2. Use errorTranslator.translate() instead" -ForegroundColor Red
    Write-Host ""
    Write-Host "See: control-plane/gates/error-messages-ux.md" -ForegroundColor Cyan
    exit 1
}
