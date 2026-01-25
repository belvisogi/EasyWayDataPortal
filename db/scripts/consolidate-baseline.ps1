# consolidate-baseline.ps1
# Consolidate V1-V11 migrations into single baseline file

param(
    [Parameter(Mandatory = $false)]
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'

Write-Host "🔄 Consolidating V1-V11 Migrations into Baseline" -ForegroundColor Cyan
Write-Host ""

$migrationsPath = Join-Path $PSScriptRoot "..\migrations"
$outputFile = Join-Path $migrationsPath "20260119_ALL_baseline.sql"
$archivePath = Join-Path $migrationsPath "_archive"

# Files to consolidate (in order)
$filesToConsolidate = @(
    "V1__baseline.sql",
    "V1__create_schemas.sql",
    "V2__core_sequences.sql",
    "V3__portal_core_tables.sql",
    "V3_1__portal_more_tables.sql",
    "V4__portal_logging_tables.sql",
    "V5__rls_setup.sql",
    "V6__stored_procedures_core.sql",
    "V7__seed_minimum.sql",
    "V8__extended_properties.sql",
    "V9__stored_procedures_users_config_acl.sql",
    "V10__rls_configuration.sql",
    "V11__stored_procedures_users_read.sql"
)

Write-Host "📋 Files to consolidate:" -ForegroundColor Yellow
$filesToConsolidate | ForEach-Object { Write-Host "   - $_" -ForegroundColor Gray }
Write-Host ""

if ($DryRun) {
    Write-Host "🔍 DRY RUN MODE - No files will be modified" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Would create: $outputFile" -ForegroundColor Gray
    Write-Host "Would archive: $archivePath" -ForegroundColor Gray
    exit 0
}

# Create consolidated file
$consolidatedContent = @"
-- 20260119_ALL_baseline.sql
-- Complete database baseline (consolidates V1-V11)
-- 
-- This file represents the initial state of the EasyWay Portal database
-- combining all legacy Flyway migrations into a single baseline.
--
-- Schemas: PORTAL, BRONZE, SILVER, GOLD, REPORTING, WORK
-- Created: 2026-01-19
-- Replaces: V1 through V11 migrations

SET NOCOUNT ON;
GO

-- =====================================================
-- SECTION 1: SCHEMAS
-- =====================================================

"@

Write-Host "📝 Creating consolidated baseline..." -ForegroundColor Cyan

foreach ($file in $filesToConsolidate) {
    $filePath = Join-Path $migrationsPath $file
    
    if (-not (Test-Path $filePath)) {
        Write-Warning "File not found: $file (skipping)"
        continue
    }
    
    Write-Host "   Adding: $file" -ForegroundColor Gray
    
    # Read file content
    $content = Get-Content $filePath -Raw
    
    # Add section header
    $consolidatedContent += "`n-- =====================================================`n"
    $consolidatedContent += "-- FROM: $file`n"
    $consolidatedContent += "-- =====================================================`n`n"
    
    # Add content
    $consolidatedContent += $content
    $consolidatedContent += "`n`nGO`n"
}

# Add footer
$consolidatedContent += @"

-- =====================================================
-- BASELINE COMPLETE
-- =====================================================
-- 
-- This baseline includes:
-- - All schemas (PORTAL, BRONZE, SILVER, GOLD, REPORTING, WORK)
-- - Core sequences
-- - Portal tables (TENANT, USERS, CONFIGURATION, etc.)
-- - Logging tables
-- - RLS setup and configuration
-- - Stored procedures (core, users, config, ACL)
-- - Seed data
-- - Extended properties
--
-- Next migrations should use format: YYYYMMDD_SCHEMA_description.sql
-- Example: 20260120_PORTAL_add_notifications.sql
--
"@

# Write consolidated file
Set-Content -Path $outputFile -Value $consolidatedContent -Encoding UTF8

Write-Host ""
Write-Host "✅ Consolidated baseline created: $outputFile" -ForegroundColor Green
Write-Host ""

# Create archive directory
if (-not (Test-Path $archivePath)) {
    New-Item -ItemType Directory -Path $archivePath | Out-Null
    Write-Host "📁 Created archive directory: $archivePath" -ForegroundColor Gray
}

# Move old files to archive
Write-Host "📦 Archiving old V## files..." -ForegroundColor Cyan

foreach ($file in $filesToConsolidate) {
    $sourcePath = Join-Path $migrationsPath $file
    $destPath = Join-Path $archivePath $file
    
    if (Test-Path $sourcePath) {
        Move-Item -Path $sourcePath -Destination $destPath -Force
        Write-Host "   Archived: $file" -ForegroundColor Gray
    }
}

# Also archive other V## files
Get-ChildItem -Path $migrationsPath -Filter "V*.sql" | ForEach-Object {
    $destPath = Join-Path $archivePath $_.Name
    Move-Item -Path $_.FullName -Destination $destPath -Force
    Write-Host "   Archived: $($_.Name)" -ForegroundColor Gray
}

Write-Host ""
Write-Host "✅ Consolidation complete!" -ForegroundColor Green
Write-Host ""
Write-Host "Summary:" -ForegroundColor Cyan
Write-Host "  📄 Created: 20260119_ALL_baseline.sql" -ForegroundColor Green
Write-Host "  📦 Archived: $($filesToConsolidate.Count) files to _archive/" -ForegroundColor Yellow
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "  1. Review consolidated baseline: code $outputFile"
Write-Host "  2. Test in DEV: .\apply-migration-simple.ps1 -MigrationFile '20260119_ALL_baseline.sql'"
Write-Host "  3. Update README.md to reflect new structure"
Write-Host ""
Write-Host "New migration format: YYYYMMDD_SCHEMA_description.sql" -ForegroundColor Yellow
Write-Host "Example: 20260120_PORTAL_add_notifications.sql"
