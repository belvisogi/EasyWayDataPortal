<#
.SYNOPSIS
Sync theme packs + assets from the canonical workspace folder into the portal-frontend public folder.

.DESCRIPTION
This script copies runtime theme-pack JSON and assets so they can be served by Nginx without rebuilding the app/image.

Defaults:
- Workspace: C:\old\Work-space-frontend
- Target:    <RepoRoot>\apps\portal-frontend\public

Non-destructive by default: it copies/overwrites known files, but does not delete extras.

.EXAMPLE
pwsh .\scripts\sync-workspace-frontend-themes.ps1

.EXAMPLE
pwsh .\scripts\sync-workspace-frontend-themes.ps1 -WhatIf
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path,
    [string]$WorkspaceRoot = "C:\old\Work-space-frontend",
    [switch]$Verify,
    [switch]$Clean,
    [string]$ReportPath
)

$ErrorActionPreference = "Stop"

$targetPublic = Join-Path $RepoRoot "apps\portal-frontend\public"

if (-not (Test-Path $WorkspaceRoot)) {
    throw "WorkspaceRoot not found: $WorkspaceRoot"
}
if (-not (Test-Path $targetPublic)) {
    throw "Target portal public folder not found: $targetPublic"
}

$workspaceThemePacks = Join-Path $WorkspaceRoot "theme-packs"
$workspaceAssetsThemes = Join-Path $WorkspaceRoot "assets\themes"

$Summary = [ordered]@{
    timestampUtc = (Get-Date).ToUniversalTime().ToString("o")
    workspaceRoot = $WorkspaceRoot
    repoRoot = $RepoRoot
    targetPublic = $targetPublic
    clean = [bool]$Clean
    copied = [ordered]@{
        files = @()
        folders = @()
    }
    removed = [ordered]@{
        themePacksFiles = 0
        assetsThemesFiles = 0
    }
}

$requiredWorkspaceItems = @(
    (Join-Path $WorkspaceRoot "theme-packs.manifest.json"),
    (Join-Path $WorkspaceRoot "assets.manifest.json"),
    $workspaceThemePacks,
    $workspaceAssetsThemes
)

foreach ($p in $requiredWorkspaceItems) {
    if (-not (Test-Path $p)) {
        throw "Missing required workspace item: $p"
    }
}

function Ensure-Dir([string]$path) {
    if (Test-Path $path) { return }
    if ($PSCmdlet.ShouldProcess($path, "Create directory")) {
        New-Item -ItemType Directory -Force -Path $path | Out-Null
    }
}

Ensure-Dir (Join-Path $targetPublic "theme-packs")
Ensure-Dir (Join-Path $targetPublic "assets")
Ensure-Dir (Join-Path $targetPublic "assets\themes")

if ($Clean) {
    $dstThemePacks = Join-Path $targetPublic "theme-packs"
    $dstAssetsThemes = Join-Path $targetPublic "assets\themes"

    $existingThemePacks = @(Get-ChildItem -Force -File -Recurse $dstThemePacks -ErrorAction SilentlyContinue)
    $existingAssetsThemes = @(Get-ChildItem -Force -File -Recurse $dstAssetsThemes -ErrorAction SilentlyContinue)

    $Summary.removed.themePacksFiles = $existingThemePacks.Count
    $Summary.removed.assetsThemesFiles = $existingAssetsThemes.Count

    if ($PSCmdlet.ShouldProcess($dstThemePacks, "Clean folder contents")) {
        Remove-Item -Force -Recurse -ErrorAction SilentlyContinue -Path (Join-Path $dstThemePacks "*")
    }
    if ($PSCmdlet.ShouldProcess($dstAssetsThemes, "Clean folder contents")) {
        Remove-Item -Force -Recurse -ErrorAction SilentlyContinue -Path (Join-Path $dstAssetsThemes "*")
    }
}

function Copy-File([string]$src, [string]$dst) {
    if ($PSCmdlet.ShouldProcess($dst, "Copy file from $src")) {
        Copy-Item -Force -Path $src -Destination $dst
        $Summary.copied.files += $dst
    }
}

function Copy-Folder([string]$src, [string]$dst) {
    # Copy folder contents to avoid nested directories like <dst>\<folder>\<folder>\...
    $srcItems = Join-Path $src "*"
    if ($PSCmdlet.ShouldProcess($dst, "Copy folder contents from $src")) {
        Copy-Item -Force -Recurse -Path $srcItems -Destination $dst
        $Summary.copied.folders += [ordered]@{ src = $src; dst = $dst }
    }
}

Copy-File (Join-Path $WorkspaceRoot "theme-packs.manifest.json") (Join-Path $targetPublic "theme-packs.manifest.json")
Copy-File (Join-Path $WorkspaceRoot "assets.manifest.json") (Join-Path $targetPublic "assets.manifest.json")

# Copy known folders (overwrite on collisions)
Copy-Folder $workspaceThemePacks (Join-Path $targetPublic "theme-packs")
Copy-Folder $workspaceAssetsThemes (Join-Path $targetPublic "assets\themes")

if ($Verify) {
    $checks = @(
        (Join-Path $targetPublic "theme-packs.manifest.json"),
        (Join-Path $targetPublic "assets.manifest.json"),
        (Join-Path $targetPublic "theme-packs\theme-pack.easyway-arcane.json"),
        (Join-Path $targetPublic "assets\themes\easyway-arcane\hero.svg")
    )

    foreach ($c in $checks) {
        if (-not (Test-Path $c)) {
            throw "Verify failed: missing $c"
        }
    }
}

Write-Host "OK: synced theme packs + assets into $targetPublic" -ForegroundColor Green
Write-Host (" - Clean: {0} (removed theme packs files: {1}, assets/themes files: {2})" -f $Summary.clean, $Summary.removed.themePacksFiles, $Summary.removed.assetsThemesFiles)
Write-Host (" - Copied files: {0}" -f $Summary.copied.files.Count)
Write-Host (" - Copied folders: {0}" -f $Summary.copied.folders.Count)

if ($ReportPath) {
    if ($PSCmdlet.ShouldProcess($ReportPath, "Write JSON report")) {
        $dir = Split-Path -Parent $ReportPath
        if ($dir -and -not (Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
        $Summary | ConvertTo-Json -Depth 6 | Set-Content -Path $ReportPath -Encoding UTF8
        Write-Host "Report written: $ReportPath" -ForegroundColor Cyan
    }
}
