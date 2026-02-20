# scripts/pwsh/build-init-sql.ps1
# Generates release/init.sql by concatenating migrations in correct order.
# Order: V* files (sorted by version), then others (sorted by name).

$ErrorActionPreference = "Stop"

$migrationDir = "db/migrations"
$outputFile = "release/init.sql"

if (-not (Test-Path $migrationDir)) {
    Write-Error "Migration directory $migrationDir not found."
}

if (-not (Test-Path "release")) {
    New-Item -ItemType Directory -Path "release" | Out-Null
}

$files = Get-ChildItem "$migrationDir/*.sql"

# Filter V* files
$vFiles = $files | Where-Object { $_.Name -match '^V' }
# Filter other files
$otherFiles = $files | Where-Object { $_.Name -notmatch '^V' }

# Sort V files by major version number
$vSorted = $vFiles | Sort-Object { 
    $ver = $_.Name -replace '^V', '' -replace '[_].*', ''
    if ($ver -match '^\d+$') { [int]$ver } else { 999999 }
}, Name

# Sort other files by name
$otherSorted = $otherFiles | Sort-Object Name

# Combine
$allFiles = @($vSorted) + @($otherSorted)

Write-Host "Found $($allFiles.Count) migration files."
Write-Host "First file: $($allFiles[0].Name)"

# Concatenate
$allFiles | Get-Content | Out-File $outputFile -Encoding UTF8

Write-Host "Generated $outputFile"
