#!/usr/bin/env pwsh
<#
.SYNOPSIS
  Extract complete database metadata from SQL Server

.DESCRIPTION
  Queries INFORMATION_SCHEMA and sys tables to extract full metadata (tables, SPs, functions, views, sequences, security)
  Output as structured JSON for agent_dba analysis and diff operations

.PARAMETER Server
  SQL Server name (default: from env DB_SERVER)

.PARAMETER Database
  Database name (default: from env DB_NAME)

.PARAMETER Username
  SQL Auth username (default: from env DB_USER)

.PARAMETER Password
  SQL Auth password (default: from env DB_PASSWORD)

.PARAMETER OutputFile
  Output JSON file path (default: metadata-{database}.json)

.EXAMPLE
  .\extract-metadata.ps1 -Database EASYWAY_PORTAL_DEV -OutputFile dev-metadata.json
#>

param(
    [string]$Server = $env:DB_SERVER ?? "repos-easyway-dev.database.windows.net",
    [string]$Database = $env:DB_NAME,
    [string]$Username = $env:DB_USER ?? "easyway-admin",
    [string]$Password = $env:DB_PASSWORD,
    [string]$OutputFile
)

$ErrorActionPreference = "Stop"

if (-not $Database) {
    throw "Database parameter required"
}

if (-not $Password) {
    $SecurePassword = Read-Host "Password for $Username" -AsSecureString
    $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecurePassword)
    $Password = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
}

if (-not $OutputFile) {
    $OutputFile = "metadata-$Database.json"
}

Write-Host "🔍 Extracting metadata from $Database..." -ForegroundColor Cyan

# SQL query for complete metadata extraction
$sql = @"
SELECT 
    DB_NAME() AS database_name,
    SERVERPROPERTY('ProductVersion') AS server_version,
    DATABASEPROPERTYEX(DB_NAME(), 'Collation') AS collation,
    GETDATE() AS extraction_time,
    (
        SELECT 
            t.TABLE_SCHEMA AS [schema],
            t.TABLE_NAME AS [name],
            (
                SELECT 
                    c.COLUMN_NAME AS name,
                    c.DATA_TYPE AS type,
                    c.CHARACTER_MAXIMUM_LENGTH AS maxLength,
                    c.IS_NULLABLE AS nullable,
                    c.COLUMN_DEFAULT AS [default],
                    CAST(COLUMNPROPERTY(OBJECT_ID(t.TABLE_SCHEMA + '.' + t.TABLE_NAME), c.COLUMN_NAME, 'IsIdentity') AS BIT) AS isIdentity
                FROM INFORMATION_SCHEMA.COLUMNS c
                WHERE c.TABLE_SCHEMA = t.TABLE_SCHEMA
                    AND c.TABLE_NAME = t.TABLE_NAME
                ORDER BY c.ORDINAL_POSITION
                FOR JSON PATH
            ) AS columns,
            (
                SELECT COUNT(*) 
                FROM sys.indexes i 
                WHERE i.object_id = OBJECT_ID(t.TABLE_SCHEMA + '.' + t.TABLE_NAME) AND i.type > 0
            ) AS index_count
        FROM INFORMATION_SCHEMA.TABLES t
        WHERE t.TABLE_TYPE = 'BASE TABLE'
        FOR JSON PATH
    ) AS tables,
    (
        SELECT 
            ROUTINE_SCHEMA AS [schema],
            ROUTINE_NAME AS name,
            ROUTINE_TYPE AS type,
            CREATED AS created,
            LAST_ALTERED AS modified
        FROM INFORMATION_SCHEMA.ROUTINES
        WHERE ROUTINE_TYPE = 'PROCEDURE'
        FOR JSON PATH
    ) AS procedures,
    (
        SELECT 
            ROUTINE_SCHEMA AS [schema],
            ROUTINE_NAME AS name,
            DATA_TYPE AS returnType
        FROM INFORMATION_SCHEMA.ROUTINES
        WHERE ROUTINE_TYPE = 'FUNCTION'
        FOR JSON PATH
    ) AS functions,
    (
        SELECT 
            SEQUENCE_SCHEMA AS [schema],
            SEQUENCE_NAME AS name,
            START_VALUE AS startValue,
            INCREMENT AS increment
        FROM INFORMATION_SCHEMA.SEQUENCES
        FOR JSON PATH
    ) AS sequences
FOR JSON PATH, WITHOUT_ARRAY_WRAPPER;
"@

# Execute query
try {
    $result = sqlcmd -S $Server -d $Database -U $Username -P $Password -Q $sql -h -1 -W -y 0

    if ($LASTEXITCODE -ne 0) {
        throw "sqlcmd failed with exit code $LASTEXITCODE"
    }

    # Clean up result (remove extra whitespace, newlines)
    $jsonResult = ($result | Where-Object { $_ -match '\S' }) -join ''

    # Parse to validate JSON
    $metadata = $jsonResult | ConvertFrom-Json

    # Add summary stats
    $summary = @{
        database       = $metadata.database_name
        extracted_at   = $metadata.extraction_time
        server_version = $metadata.server_version
        counts         = @{
            tables     = ($metadata.tables | ConvertFrom-Json).Count
            procedures = ($metadata.procedures | ConvertFrom-Json).Count
            functions  = ($metadata.functions | ConvertFrom-Json).Count
            sequences  = ($metadata.sequences | ConvertFrom-Json).Count
        }
    }

    Write-Host "✅ Metadata extracted successfully!" -ForegroundColor Green
    Write-Host "   Tables: $($summary.counts.tables)" -ForegroundColor White
    Write-Host "   Procedures: $($summary.counts.procedures)" -ForegroundColor White
    Write-Host "   Functions: $($summary.counts.functions)" -ForegroundColor White
    Write-Host "   Sequences: $($summary.counts.sequences)" -ForegroundColor White

    # Write to file
    $jsonResult | Out-File -FilePath $OutputFile -Encoding UTF8
    Write-Host "`n💾 Saved to: $OutputFile" -ForegroundColor Cyan

    # Return summary
    return $summary

}
catch {
    Write-Error "Failed to extract metadata: $_"
    exit 1
}
"@

<parameter name="Complexity">8
