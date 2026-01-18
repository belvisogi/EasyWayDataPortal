<#
Genera un intent JSON `db-table:create` a partire da file CSV "Excel-friendly".

Uso (esempio):
  pwsh scripts/db-table-intent-from-sheet.ps1 `
    -TableCsv docs/agentic/templates/sheets/db-table-create.table.csv `
    -ColumnsCsv docs/agentic/templates/sheets/db-table-create.columns.csv `
    -IndexesCsv docs/agentic/templates/sheets/db-table-create.indexes.csv `
    -OutIntent intent.db-table-create.generated.json
#>

[CmdletBinding()]
param(
  [Parameter(Mandatory=$true)][string]$TableCsv,
  [Parameter(Mandatory=$true)][string]$ColumnsCsv,
  [string]$IndexesCsv = '',
  [string]$OutIntent = 'out/intents/intent.db-table-create.generated.json'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

trap {
  Write-Error ("[db-table-intent-from-sheet] " + $_.Exception.Message)
  if ($_.ScriptStackTrace) { Write-Error $_.ScriptStackTrace }
  if ($_.InvocationInfo -and $_.InvocationInfo.PositionMessage) { Write-Error $_.InvocationInfo.PositionMessage }
  throw
}

function Require-Path([string]$p) {
  if (-not (Test-Path -LiteralPath $p)) { throw "File not found: $p" }
}

function Ensure-Dir([string]$p) {
  if (-not $p) { return }
  if (-not (Test-Path -LiteralPath $p)) { New-Item -ItemType Directory -Force -Path $p | Out-Null }
}

function Norm([string]$s) {
  if ($null -eq $s) { return '' }
  return ($s.Trim())
}

function Parse-Bool($v, [bool]$default = $false) {
  if ($null -eq $v) { return $default }
  $s = ('' + $v).Trim().ToLowerInvariant()
  if ($s -eq '') { return $default }
  if ($s -in @('1','true','t','yes','y','si','sì')) { return $true }
  if ($s -in @('0','false','f','no','n')) { return $false }
  throw "Invalid boolean value: '$v' (expected true/false, 1/0, yes/no)"
}

function Split-List([string]$s) {
  $t = Norm $s
  if (-not $t) { return @() }
  return @(
    $t -split '[,;]' |
    ForEach-Object { $_.Trim() } |
    Where-Object { $_ }
  )
}

Require-Path $TableCsv
Require-Path $ColumnsCsv
if ($IndexesCsv) { Require-Path $IndexesCsv }

Write-Verbose "Reading table CSV: $TableCsv"
$tableRows = @(Import-Csv -LiteralPath $TableCsv)
if ($tableRows.Count -ne 1) { throw "TableCsv must contain exactly 1 row (got $($tableRows.Count))" }
$t = $tableRows[0]

Write-Verbose "Parsing table metadata"
$schema = Norm $t.schema
$table = Norm $t.table
if (-not $schema -or -not $table) { throw "schema/table are required in TableCsv" }

$logicalName = if (Norm $t.logical_name) { Norm $t.logical_name } else { '' }
$description = if (Norm $t.description) { Norm $t.description } else { '' }
$owner = if (Norm $t.owner) { Norm $t.owner } else { 'team-data' }
$domain = if (Norm $t.domain) { Norm $t.domain } else { '' }
$classification = if (Norm $t.classification) { Norm $t.classification } else { '' }
$summary = if ($description) { $description } elseif (Norm $t.summary) { Norm $t.summary } else { ("Tabella ${schema}.${table} (generata da sheet).") }
$tags = @(Split-List $t.tags)

$tenantColumn = if (Norm $t.tenant_column) { Norm $t.tenant_column } else { '' }
$rlsRequired = Parse-Bool $t.rls_required $false
$includeAudit = Parse-Bool $t.include_audit $false
$includeSoftDelete = Parse-Bool $t.include_soft_delete $false
$writeWiki = Parse-Bool $t.writeWiki $true
$writeFlyway = Parse-Bool $t.writeFlyway $true
$correlationId = if (Norm $t.correlationId) { Norm $t.correlationId } else { ("db-table-create-{0}" -f (Get-Date).ToString('yyyyMMddHHmmss')) }
$summaryOut = if (Norm $t.summaryOut) { Norm $t.summaryOut } else { ("out/db/db-table-create.{0}.{1}.json" -f $schema.ToLowerInvariant(), $table.ToLowerInvariant()) }

Write-Verbose "Reading columns CSV: $ColumnsCsv"
$colRows = @(Import-Csv -LiteralPath $ColumnsCsv)
if ($colRows.Count -lt 1) { throw "ColumnsCsv must contain at least 1 row" }

$columns = New-Object System.Collections.Generic.List[object]
foreach ($r in $colRows) {
  $name = Norm $r.name
  $sqlType = Norm $r.sql_type
  if (-not $name -or -not $sqlType) { throw "Each column row requires name + sql_type" }

  $col = [ordered]@{
    name = $name
    sql_type = $sqlType
    nullable = Parse-Bool $r.nullable $true
    pk = Parse-Bool $r.pk $false
    identity = Parse-Bool $r.identity $false
    pii = if (Norm $r.pii) { (Norm $r.pii) } else { 'none' }
  }

  if (Norm $r.logical_name) { $col['logical_name'] = (Norm $r.logical_name) }
  if (Norm $r.default) { $col['default'] = (Norm $r.default) }
  if (Norm $r.description) { $col['description'] = (Norm $r.description) }
  if (Norm $r.classification) { $col['classification'] = (Norm $r.classification) }
  if (Norm $r.masking) { $col['masking'] = (Norm $r.masking) }
  if (Norm $r.example_value) { $col['example_value'] = (Norm $r.example_value) }

  $rs = Norm $r.ref_schema
  $rt = Norm $r.ref_table
  $rc = Norm $r.ref_column
  if ($rs -or $rt -or $rc) {
    if (-not $rs -or -not $rt -or -not $rc) { throw "FK requires ref_schema + ref_table + ref_column for column '$name'" }
    $col['references'] = [ordered]@{ schema = $rs; table = $rt; column = $rc }
  }

  $columns.Add($col) | Out-Null
}

$indexes = New-Object System.Collections.Generic.List[object]
if ($IndexesCsv) {
  Write-Verbose "Reading indexes CSV: $IndexesCsv"
  $ixRows = @(Import-Csv -LiteralPath $IndexesCsv)
  foreach ($ix in $ixRows) {
    $cols = @(Split-List $ix.columns)
    if ($cols.Count -eq 0) { continue }
    $obj = [ordered]@{
      columns = $cols
      unique = Parse-Bool $ix.unique $false
    }
    if (Norm $ix.name) { $obj['name'] = (Norm $ix.name) }
    $indexes.Add($obj) | Out-Null
  }
}

Write-Verbose "Building intent object"
Write-Verbose ("Counts: columns={0} indexes={1}" -f $columns.Count, $indexes.Count)

$columnsArr = $columns.ToArray()
$indexesArr = $indexes.ToArray()

$intentParams = [ordered]@{
  schema = $schema
  table = $table
  columns = $columnsArr
  indexes = $indexesArr
  tenanting = [ordered]@{
    tenant_column = $tenantColumn
    rls_required = [bool]$rlsRequired
  }
  documentation = [ordered]@{
    owner = $owner
    summary = $summary
    tags = @($tags)
  }
  includeAudit = [bool]$includeAudit
  includeSoftDelete = [bool]$includeSoftDelete
  writeWiki = [bool]$writeWiki
  writeFlyway = [bool]$writeFlyway
  writeDatabaseSnapshot = $false
  summaryOut = $summaryOut
}

if ($logicalName) { $intentParams.documentation['logical_name'] = $logicalName }
if ($description) { $intentParams.documentation['description'] = $description }
if ($domain) { $intentParams.documentation['domain'] = $domain }
if ($classification) { $intentParams.documentation['classification'] = $classification }

$intent = [ordered]@{
  action = 'db-table:create'
  params = $intentParams
  correlationId = $correlationId
  nonInteractive = $true
  whatIf = $false
}

Write-Verbose "Writing intent JSON: $OutIntent"
$outDir = Split-Path -Parent $OutIntent
if ($outDir) { Ensure-Dir $outDir }
$json = ($intent | ConvertTo-Json -Depth 10)
Set-Content -LiteralPath $OutIntent -Value $json -Encoding UTF8
Write-Output $json
