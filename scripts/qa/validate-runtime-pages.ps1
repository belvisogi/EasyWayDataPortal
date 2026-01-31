<#
.SYNOPSIS
    EasyWay Core - Runtime Pages Validation (QA)
    Validates runtime JSON contracts for pages, theme packs, and assets.

.DESCRIPTION
    This is a "schema-lite" validator (no external deps):
    - Ensures required files exist in portal-frontend/public
    - Ensures manifest -> spec paths resolve
    - Ensures ids/routes are unique
    - Ensures theme packs and assets references are consistent

.EXAMPLE
    pwsh .\scripts\qa\validate-runtime-pages.ps1
#>

[CmdletBinding()]
param(
    [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\\..")).Path
)

$ErrorActionPreference = "Continue"

function Fail([string]$msg) {
    Write-Host "❌ $msg" -ForegroundColor Red
    $script:Failures++
}

function Warn([string]$msg) {
    Write-Host "⚠️  $msg" -ForegroundColor Yellow
}

function Ok([string]$msg) {
    Write-Host "✅ $msg" -ForegroundColor Green
}

$Failures = 0
$frontendPublic = Join-Path $RepoRoot "apps\\portal-frontend\\public"

Write-Host "🧪 VALIDATING RUNTIME PAGES (public/*)..." -ForegroundColor Cyan
Write-Host "Root: $frontendPublic" -ForegroundColor DarkGray

if (-not (Test-Path $frontendPublic)) {
    Fail "portal-frontend public folder not found: $frontendPublic"
    exit 1
}

function Read-Json([string]$path) {
    if (-not (Test-Path $path)) { return $null }
    try {
        return Get-Content -Raw -Path $path | ConvertFrom-Json
    } catch {
        Fail "Invalid JSON: $path ($($_.Exception.Message))"
        return $null
    }
}

function Resolve-PublicPath([string]$publicHref) {
    # publicHref is expected like "/pages.home.json" or "/theme-packs/theme-pack.x.json"
    $trim = $publicHref.Trim()
    if (-not $trim.StartsWith("/")) { return $null }
    $rel = $trim.TrimStart("/") -replace "/", "\\"
    return Join-Path $frontendPublic $rel
}

# --- Validate Pages Manifest ---
$pagesManifestPath = Join-Path $frontendPublic "pages\\pages.manifest.json"
$pagesManifest = Read-Json $pagesManifestPath
if (-not $pagesManifest) {
    Fail "Missing or invalid pages.manifest.json"
    exit 1
}

if ($pagesManifest.version -ne "1") { Warn "pages.manifest.json version is '$($pagesManifest.version)' (expected '1')" }
if (-not $pagesManifest.pages) { Fail "pages.manifest.json missing 'pages' array" }

$pageIds = @{}
$routes = @{}
$allowedSectionTypes = @("hero","cards","comparison","cta","spacer")

foreach ($p in ($pagesManifest.pages | ForEach-Object { $_ })) {
    if (-not $p.id) { Fail "Page missing id in pages.manifest.json"; continue }
    if ($pageIds.ContainsKey($p.id)) { Fail "Duplicate page id: $($p.id)" } else { $pageIds[$p.id] = $true }

    if (-not $p.route -or -not $p.route.StartsWith("/")) { Fail "Page '$($p.id)' has invalid route '$($p.route)'" }
    if ($routes.ContainsKey($p.route)) { Fail "Duplicate route: $($p.route)" } else { $routes[$p.route] = $true }

    if (-not $p.spec -or -not $p.spec.StartsWith("/")) { Fail "Page '$($p.id)' has invalid spec '$($p.spec)'" }
    $specPath = Resolve-PublicPath $p.spec
    if (-not $specPath) { Fail "Page '$($p.id)' spec path could not be resolved: $($p.spec)"; continue }
    if (-not (Test-Path $specPath)) { Fail "Missing page spec file for '$($p.id)': $specPath"; continue }

    Ok "Manifest: $($p.id) -> $($p.route) -> $($p.spec)"
}

# --- Validate Page Specs ---
foreach ($p in ($pagesManifest.pages | ForEach-Object { $_ })) {
    $specPath = Resolve-PublicPath $p.spec
    if (-not $specPath -or -not (Test-Path $specPath)) { continue }

    $spec = Read-Json $specPath
    if (-not $spec) { continue }

    if ($spec.version -ne "1") { Warn "PageSpec '$($p.id)' version is '$($spec.version)' (expected '1')" }
    if ($spec.id -ne $p.id) { Fail "PageSpec id mismatch: manifest '$($p.id)' vs spec '$($spec.id)' ($specPath)" }
    if (-not $spec.sections) { Fail "PageSpec '$($p.id)' missing 'sections' array ($specPath)"; continue }

    foreach ($s in ($spec.sections | ForEach-Object { $_ })) {
        if (-not $s.type) { Fail "PageSpec '$($p.id)' has section without type ($specPath)"; continue }
        if ($allowedSectionTypes -notcontains $s.type) { Fail "PageSpec '$($p.id)' has unsupported section type '$($s.type)'" }

        if ($s.type -eq "cards") {
            if ($s.variant -ne "catalog") { Fail "PageSpec '$($p.id)' cards.variant must be 'catalog' ($specPath)" }
            if (-not $s.items) { Fail "PageSpec '$($p.id)' cards.items missing ($specPath)" }
        }
    }
}

Ok "Pages manifest/spec basic structure OK (schema-lite)"

# --- Validate Theme Packs + Assets ---
$themePacksManifestPath = Join-Path $frontendPublic "theme-packs.manifest.json"
$themePacksManifest = Read-Json $themePacksManifestPath
if (-not $themePacksManifest) { Fail "Missing or invalid theme-packs.manifest.json" }

$assetsManifestPath = Join-Path $frontendPublic "assets.manifest.json"
$assetsManifest = Read-Json $assetsManifestPath
if (-not $assetsManifest) { Fail "Missing or invalid assets.manifest.json" }

$images = @{}
if ($assetsManifest -and $assetsManifest.images) {
    foreach ($k in $assetsManifest.images.PSObject.Properties.Name) {
        $images[$k] = $assetsManifest.images.$k
        $assetPath = Resolve-PublicPath $assetsManifest.images.$k
        if (-not $assetPath) { Fail "Asset image path must be absolute (start with '/'): $k -> $($assetsManifest.images.$k)"; continue }
        if (-not (Test-Path $assetPath)) { Warn "Asset file missing on disk (ok in early dev): $k -> $assetPath" }
    }
}

if ($themePacksManifest -and $themePacksManifest.packs) {
    foreach ($packId in $themePacksManifest.packs.PSObject.Properties.Name) {
        $packHref = $themePacksManifest.packs.$packId
        $packPath = Resolve-PublicPath $packHref
        if (-not $packPath) { Fail "Theme pack path invalid: $packId -> $packHref"; continue }
        if (-not (Test-Path $packPath)) { Fail "Missing theme pack file: $packId -> $packPath"; continue }

        $pack = Read-Json $packPath
        if (-not $pack) { continue }
        if ($pack.id -ne $packId) { Fail "Theme pack id mismatch: manifest '$packId' vs pack '$($pack.id)' ($packPath)" }
        if (-not $pack.cssVars) { Warn "Theme pack '$packId' missing cssVars (allowed but unusual)" }

        $heroBgId = $pack.assets.heroBgId
        if ($heroBgId -and -not $images.ContainsKey($heroBgId)) {
            Fail "Theme pack '$packId' references missing assets.images id: $heroBgId"
        }
    }
}

Write-Host "------------------------------------------------"
if ($Failures -eq 0) {
    Write-Host "🚀 VALIDATION PASSED. Runtime contracts look consistent." -ForegroundColor Green
} else {
    Write-Host "🛑 VALIDATION FAILED. Fix $Failures issue(s)." -ForegroundColor Red
    exit 1
}
