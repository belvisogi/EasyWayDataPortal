<#
.SYNOPSIS
    EasyWay Core - Pre-Flight Check (QA)
    Verifies code integrity, imports, and mobile readiness before deployment.

.EXAMPLE
    .\pre-flight-check.ps1
#>

$ErrorActionPreference = "Continue"

Write-Host "🕵️  STARTING PRE-FLIGHT CHECK..." -ForegroundColor Cyan

$RootPath = Resolve-Path "$PSScriptRoot\..\.."
$FrontendPath = "$RootPath\apps\portal-frontend"
$Failures = 0

# 1. CHECK IMPORTS IN MAIN.TS
$MainTs = "$FrontendPath\src\main.ts"
if (Test-Path $MainTs) {
    $Content = Get-Content $MainTs -Raw
    if ($Content -match "import.*sovereign-header") {
        Write-Host "✅ Main.ts imports Header" -ForegroundColor Green
    }
    else {
        Write-Host "❌ Main.ts MISSING Header Import!" -ForegroundColor Red
        $Failures++
    }
    if ($Content -match "import.*sovereign-footer") {
        Write-Host "✅ Main.ts imports Footer" -ForegroundColor Green
    }
    else {
        Write-Host "❌ Main.ts MISSING Footer Import!" -ForegroundColor Red
        $Failures++
    }
}
else {
    Write-Host "❌ src/main.ts Not Found!" -ForegroundColor Red
    $Failures++
}

# 2. CHECK HTML FILES FOR MOBILE VIEWPORT
$HtmlFiles = Get-ChildItem $FrontendPath -Filter "*.html"
foreach ($file in $HtmlFiles) {
    $Content = Get-Content $file.FullName -Raw
    if ($Content -match '<meta name="viewport"') {
        Write-Host "✅ $($file.Name): Mobile Viewport OK" -ForegroundColor Green
    }
    else {
        Write-Host "❌ $($file.Name): MISSING Viewport Meta Tag!" -ForegroundColor Red
        $Failures++
    }
    
    if ($Content -match '<title>EasyWay') {
        Write-Host "✅ $($file.Name): Title Correct" -ForegroundColor Green
    }
    else {
        Write-Host "⚠️ $($file.Name): Title might differ from standard." -ForegroundColor Yellow
    }
}

# 2.1 FRONTEND FRAMEWORK AUDIT
$AuditScript = "$PSScriptRoot\audit-frontend.ps1"
if (Test-Path $AuditScript) {
    Write-Host "------------------------------------------------"
    Write-Host "🔎 Running frontend framework audit..." -ForegroundColor Cyan
    & $AuditScript
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Frontend audit failed" -ForegroundColor Red
        $Failures++
    }
}
else {
    Write-Host "⚠️  Frontend audit script not found" -ForegroundColor Yellow
}

# 2.2 HTTP SMOKE TEST (optional)
$SmokeScript = "$PSScriptRoot\http-smoke.ps1"
if (Test-Path $SmokeScript) {
    Write-Host "------------------------------------------------"
    Write-Host "🌐 Running HTTP smoke test..." -ForegroundColor Cyan
    & $SmokeScript
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ HTTP smoke failed" -ForegroundColor Red
        $Failures++
    }
}
else {
    Write-Host "⚠️  HTTP smoke script not found" -ForegroundColor Yellow
}

# 2.3 ERROR GLOSSARY COVERAGE
$GlossaryScript = "$PSScriptRoot\error-glossary-check.ps1"
if (Test-Path $GlossaryScript) {
    Write-Host "------------------------------------------------"
    Write-Host "📘 Running error glossary check..." -ForegroundColor Cyan
    & $GlossaryScript
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Error glossary check failed" -ForegroundColor Red
        $Failures++
    }
}
else {
    Write-Host "⚠️  Error glossary script not found" -ForegroundColor Yellow
}

# 3. CHECK PACKAGE.JSON VERSION
$PkgJson = "$FrontendPath\package.json"
if (Test-Path $PkgJson) {
    $Json = Get-Content $PkgJson | ConvertFrom-Json
    Write-Host "📦 Current Version: $($Json.version)" -ForegroundColor Magenta
}

Write-Host "------------------------------------------------"
# 4. VALIDATE RUNTIME JSON CONTRACTS (Pages/Themes/Assets)
try {
    if (Test-Path $PkgJson) {
        Push-Location $FrontendPath
        Write-Host "🧾 Validating runtime JSON (AJV)..." -ForegroundColor Cyan
        npm run validate:runtime | Out-Null
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ Runtime JSON contracts OK" -ForegroundColor Green
        }
        else {
            Write-Host "❌ Runtime JSON validation failed" -ForegroundColor Red
            $Failures++
        }
    }
}
catch {
    Write-Host "⚠️  Runtime JSON validation skipped/failed: $($_.Exception.Message)" -ForegroundColor Yellow
    $Failures++
}
finally {
    Pop-Location -ErrorAction SilentlyContinue
}

if ($Failures -eq 0) {
    Write-Host "🚀 PRE-FLIGHT PASSED. READY FOR DEPLOY." -ForegroundColor Green
}
else {
    Write-Host "🛑 PRE-FLIGHT FAILED. FIX $Failures ERRORS." -ForegroundColor Red
    exit 1
}
