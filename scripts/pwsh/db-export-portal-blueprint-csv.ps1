<#
Esporta in CSV (Excel-friendly) il blueprint delle tabelle attualmente presenti nello schema PORTAL,
derivando colonne/indici dai file Flyway in `db/flyway/sql/`.

Output (default):
  - out/db/portal-blueprint.tables.csv
  - out/db/portal-blueprint.columns.csv
  - out/db/portal-blueprint.indexes.csv

Note:
  - I CSV usano gli header dei template in docs/agentic/templates/sheets/.
  - I campi logici (logical_name/description/pii/...) vengono lasciati vuoti o default "none" e vanno compilati.
#>

[CmdletBinding()]
param(
  [string]$FlywaySqlDir = "db/flyway/sql",
  [string]$OutDir = "out/db",
  [string]$Schema = "PORTAL"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Ensure-Dir([string]$p) {
  if (-not (Test-Path -LiteralPath $p)) { New-Item -ItemType Directory -Force -Path $p | Out-Null }
}

function To-Bool01([bool]$b) { if ($b) { return 'true' } return 'false' }

function Parse-Default([string]$after) {
  if (-not $after) { return '' }
  $m = [regex]::Match($after, '(?i)\bDEFAULT\b\s*(?<def>.+)$')
  if (-not $m.Success) { return '' }
  $def = $m.Groups['def'].Value.Trim()
  $def = $def.TrimEnd(',')
  return $def
}

function Split-IndexCols([string]$colsRaw) {
  if (-not $colsRaw) { return @() }
  return @(
    ($colsRaw -split ',') |
      ForEach-Object { $_.Trim().Trim('[',']') } |
      Where-Object { $_ }
  )
}

if (-not (Test-Path -LiteralPath $FlywaySqlDir)) { throw "Flyway sql dir not found: $FlywaySqlDir" }
Ensure-Dir $OutDir

$sql = ''
Get-ChildItem -LiteralPath $FlywaySqlDir -File -Filter *.sql |
  Sort-Object -Property Name |
  ForEach-Object { $sql += (Get-Content -LiteralPath $_.FullName -Raw) + "`n" }

$schemaNorm = $Schema.Trim().ToUpperInvariant()

# CREATE TABLE blocks (balanced-parentheses scan)
function Extract-CreateTableBlocks {
  param([string]$Text, [string]$SchemaName)

  $schemaU = $SchemaName.Trim().ToUpperInvariant()
  $rx = [regex]::new("(?im)\bCREATE\s+TABLE\s+${schemaU}\.(?<table>[A-Za-z0-9_]+)\b", [System.Text.RegularExpressions.RegexOptions]::None)
  $blocks = [System.Collections.Generic.List[object]]::new()

  foreach ($m in $rx.Matches($Text)) {
    $tableName = $m.Groups['table'].Value
    $start = $m.Index + $m.Length
    $open = $Text.IndexOf([char]'(', $start)
    if ($open -lt 0) { continue }

    $depth = 0
    $i = $open
    $end = -1
    while ($i -lt $Text.Length) {
      $ch = [char]$Text[$i]
      if ($ch -eq [char]'(') { $depth++ }
      elseif ($ch -eq [char]')') {
        $depth--
        if ($depth -eq 0) { $end = $i; break }
      }
      $i++
    }
    if ($end -lt 0) { continue }

    $body = $Text.Substring($open + 1, ($end - $open - 1))
    $blocks.Add([ordered]@{ table = $tableName; body = $body }) | Out-Null
  }

  return $blocks.ToArray()
}

$tableBlocks = @(Extract-CreateTableBlocks -Text $sql -SchemaName $schemaNorm)
$tables = [System.Collections.Generic.Dictionary[string, object]]::new()
$columns = [System.Collections.Generic.List[object]]::new()
$indexes = [System.Collections.Generic.List[object]]::new()

foreach ($b in $tableBlocks) {
  $tableName = [string]$b.table
  $tableKey = $tableName.ToUpperInvariant()
  if (-not $tables.ContainsKey($tableKey)) {
    $tables[$tableKey] = [ordered]@{
      schema = $schemaNorm
      table = $tableName.ToLowerInvariant()
      logical_name = ''
      description = ''
      owner = 'team-data'
      domain = ''
      classification = 'internal'
      tags = 'blueprint/existing'
      tenant_column = ''
      rls_required = 'false'
      include_audit = 'false'
      include_soft_delete = 'false'
      writeWiki = 'false'
      writeFlyway = 'false'
      correlationId = ''
      summaryOut = ("out/db/db-table-create.{0}.{1}.json" -f $schemaNorm.ToLowerInvariant(), $tableName.ToLowerInvariant())
    }
  }

  $body = [string]$b.body
  $lines = @($body -split "`n" | ForEach-Object { $_.Trim().TrimEnd("`r") } | Where-Object { $_ })
  foreach ($line0 in $lines) {
    $line = $line0.Trim().TrimEnd(',')
    if (-not $line) { continue }
    if ($line -match '^(?i)\s*CONSTRAINT\b') { continue }

    $cm = [regex]::Match($line, '^\s*(?:\[(?<col>[A-Za-z0-9_]+)\]|(?<col>[A-Za-z0-9_]+))\s+(?<rest>.+)$')
    if (-not $cm.Success) { continue }
    $col = $cm.Groups['col'].Value
    $rest = $cm.Groups['rest'].Value.Trim()

    $tm = [regex]::Match($rest, '^(?<type>[A-Za-z0-9_]+(?:\s*\([^)]+\))?)\s*(?<after>.*)$')
    if (-not $tm.Success) { continue }
    $sqlType = ($tm.Groups['type'].Value -replace '\s+','').ToLowerInvariant()
    $after = $tm.Groups['after'].Value

    $identity = ($after -match '(?i)\bIDENTITY\b')
    $pk = ($after -match '(?i)\bPRIMARY\s+KEY\b')
    $nullable = $true
    if ($after -match '(?i)\bNOT\s+NULL\b') { $nullable = $false }
    elseif ($after -match '(?i)\bNULL\b') { $nullable = $true }

    $def = Parse-Default $after
    $pii = 'none'
    $classification = 'internal'

    $columns.Add([ordered]@{
      schema = $schemaNorm
      table = $tableName.ToLowerInvariant()
      name = $col
      logical_name = ''
      description = ''
      sql_type = $sqlType
      nullable = To-Bool01 $nullable
      default = $def
      pk = To-Bool01 $pk
      identity = To-Bool01 $identity
      pii = $pii
      classification = $classification
      masking = ''
      example_value = ''
      ref_schema = ''
      ref_table = ''
      ref_column = ''
    }) | Out-Null
  }
}

# Indexes
$ixRx = [regex]::new("(?im)^\s*CREATE\s+(?<unique>UNIQUE\s+)?INDEX\s+(?<name>[A-Za-z0-9_]+)\s+ON\s+${schemaNorm}\.(?<table>[A-Za-z0-9_]+)\s*\((?<cols>[^)]+)\)\s*;", [System.Text.RegularExpressions.RegexOptions]::None)
foreach ($m in $ixRx.Matches($sql)) {
  $tableName = $m.Groups['table'].Value.ToLowerInvariant()
  $ixName = $m.Groups['name'].Value
  $unique = [bool]($m.Groups['unique'].Value)
  $cols = Split-IndexCols $m.Groups['cols'].Value
  if (@($cols).Count -eq 0) { continue }
  $indexes.Add([ordered]@{
    schema = $schemaNorm
    table = $tableName
    name = $ixName
    columns = ($cols -join ';')
    unique = To-Bool01 $unique
  }) | Out-Null
}

# Derive tenant_column/include_audit from parsed columns
$colsByTable = $columns | Group-Object -Property table
foreach ($g in $colsByTable) {
  $t = $g.Name.ToUpperInvariant()
  if (-not $tables.ContainsKey($t)) { continue }
  $colNames = @($g.Group | ForEach-Object { $_.name.ToLowerInvariant() })
  if ($colNames -contains 'tenant_id') { $tables[$t].tenant_column = 'tenant_id' }
  $hasAudit = ($colNames -contains 'created_at') -and ($colNames -contains 'updated_at')
  $tables[$t].include_audit = To-Bool01 $hasAudit
}

$tablesCsv = Join-Path $OutDir 'portal-blueprint.tables.csv'
$colsCsv = Join-Path $OutDir 'portal-blueprint.columns.csv'
$ixCsv = Join-Path $OutDir 'portal-blueprint.indexes.csv'

@($tables.Values) | Sort-Object { $_.table } | Export-Csv -LiteralPath $tablesCsv -NoTypeInformation -Encoding UTF8
@($columns) | Sort-Object table,name | Export-Csv -LiteralPath $colsCsv -NoTypeInformation -Encoding UTF8
@($indexes) | Sort-Object table,name | Export-Csv -LiteralPath $ixCsv -NoTypeInformation -Encoding UTF8

[ordered]@{
  ok = $true
  schema = $schemaNorm
  flywaySqlDir = $FlywaySqlDir
  tables = @($tables.Keys).Count
  columns = @($columns).Count
  indexes = @($indexes).Count
  outputs = @(
    $tablesCsv.Replace([char]92,'/'),
    $colsCsv.Replace([char]92,'/'),
    $ixCsv.Replace([char]92,'/')
  )
} | ConvertTo-Json -Depth 6
