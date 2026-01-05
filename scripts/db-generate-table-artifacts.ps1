param(
  [Parameter(Mandatory=$true)][string]$IntentPath,
  [string]$FlywayDir = "db/flyway",
  [string]$WikiRoot = "Wiki/EasyWayData.wiki",
  [switch]$WhatIf,
  [switch]$FailOnError,
  [string]$SummaryOut = "db-table-create.json"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Read-Json($p) {
  if (-not (Test-Path -LiteralPath $p)) { throw "Intent not found: $p" }
  return (Get-Content -LiteralPath $p -Raw | ConvertFrom-Json)
}

function Normalize-Ident([string]$s) {
  if ([string]::IsNullOrWhiteSpace($s)) { return '' }
  return ($s.Trim() -replace '\s+','_')
}

function To-Kebab([string]$s) {
  if ([string]::IsNullOrWhiteSpace($s)) { return '' }
  $t = $s.Trim().ToLowerInvariant()
  $t = $t -replace '[^a-z0-9]+','-'
  $t = $t -replace '^-+',''
  $t = $t -replace '-+$',''
  return $t
}

function Ensure-Dir([string]$p) {
  if (-not (Test-Path -LiteralPath $p)) { New-Item -ItemType Directory -Force -Path $p | Out-Null }
}

function Build-CreateTableSql($schema,$table,$cols,$indexes) {
  $schemaEsc = Normalize-Ident $schema
  $tableEsc = Normalize-Ident $table
  if (-not $schemaEsc -or -not $tableEsc) { throw "schema/table missing" }

  $pkCols = @($cols | Where-Object { $_.pk -eq $true } | ForEach-Object { Normalize-Ident $_.name })
  $colLines = New-Object System.Collections.Generic.List[string]
  foreach ($c in $cols) {
    $name = Normalize-Ident ([string]$c.name)
    $type = ([string]$c.sql_type).Trim()
    if (-not $name -or -not $type) { throw "Invalid column (name/type required)" }
    $nullSql = if ($c.nullable -eq $false) { "NOT NULL" } else { "NULL" }
    $identSql = if ($c.identity -eq $true) { "IDENTITY(1,1)" } else { "" }
    $defSql = if ($c.default) { ("DEFAULT " + [string]$c.default) } else { "" }
    $parts = @("[${name}]", $type, $identSql, $defSql, $nullSql) | Where-Object { $_ -and $_.Trim() }
    $colLines.Add(("  " + ($parts -join ' '))) | Out-Null
  }

  $constraintLines = New-Object System.Collections.Generic.List[string]
  if ($pkCols.Count -gt 0) {
    $pkName = "PK_${schemaEsc}_${tableEsc}"
    $pkColsSql = ($pkCols | ForEach-Object { "[${_}]" }) -join ', '
    $constraintLines.Add(("  CONSTRAINT [${pkName}] PRIMARY KEY (" + $pkColsSql + ")")) | Out-Null
  }

  # FKs
  foreach ($c in $cols) {
    if (-not $c.references) { continue }
    $col = Normalize-Ident ([string]$c.name)
    $rs = Normalize-Ident ([string]$c.references.schema)
    $rt = Normalize-Ident ([string]$c.references.table)
    $rc = Normalize-Ident ([string]$c.references.column)
    if (-not $rs -or -not $rt -or -not $rc) { continue }
    $fkName = "FK_${schemaEsc}_${tableEsc}_${col}_${rs}_${rt}"
    $constraintLines.Add(("  CONSTRAINT [${fkName}] FOREIGN KEY ([${col}]) REFERENCES [${rs}].[${rt}]([${rc}])")) | Out-Null
  }

  $bodyLines = @()
  $bodyLines += $colLines
  if ($constraintLines.Count -gt 0) {
    $bodyLines += $constraintLines
  }

  $sql = @()
  $sql += "IF NOT EXISTS (SELECT 1 FROM sys.tables t JOIN sys.schemas s ON t.schema_id=s.schema_id WHERE s.name=N'${schemaEsc}' AND t.name=N'${tableEsc}')"
  $sql += "BEGIN"
  $sql += "  CREATE TABLE [${schemaEsc}].[${tableEsc}] ("
  $sql += ($bodyLines -join ",`n")
  $sql += "  );"
  $sql += "END"
  $sql += "GO"

  # Indexes after create
  foreach ($ix in @($indexes)) {
    $ixCols = @($ix.columns | ForEach-Object { Normalize-Ident $_ } | Where-Object { $_ })
    if ($ixCols.Count -eq 0) { continue }
    $ixName = if ($ix.name) { Normalize-Ident $ix.name } else { "IX_${schemaEsc}_${tableEsc}_" + ($ixCols -join '_') }
    $unique = if ($ix.unique -eq $true) { "UNIQUE " } else { "" }
    $colsSql = ($ixCols | ForEach-Object { "[${_}]" }) -join ', '
    $sql += "IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name=N'${ixName}' AND object_id=OBJECT_ID(N'[${schemaEsc}].[${tableEsc}]'))"
    $sql += "BEGIN"
    $sql += "  CREATE ${unique}INDEX [${ixName}] ON [${schemaEsc}].[${tableEsc}] (${colsSql});"
    $sql += "END"
    $sql += "GO"
  }

  return ($sql -join "`r`n")
}

$intent = Read-Json $IntentPath
if (-not $intent.action) { throw "Intent missing action" }
if ($intent.action -ne 'db-table:create') { throw "Unsupported action for this generator: $($intent.action)" }

$p = $intent.params
$schema = Normalize-Ident ([string]$p.schema)
$table = Normalize-Ident ([string]$p.table)
$cols = @($p.columns)
$indexes = @($p.indexes)
if (-not $schema -or -not $table) { throw "schema/table are required" }
if ($cols.Count -eq 0) { throw "columns[] is required" }

$ts = (Get-Date).ToUniversalTime().ToString('yyyyMMddHHmmss')
$writeFlyway = ($p.writeFlyway -ne $false)
$writeWiki = ($p.writeWiki -ne $false)
$writeSnapshot = ($p.writeDatabaseSnapshot -eq $true)

if ($writeFlyway) { Ensure-Dir $FlywayDir }

$flywayName = ("V{0}__create_{1}_{2}.sql" -f $ts, ($schema.ToLowerInvariant()), ($table.ToLowerInvariant()))
$flywayPath = Join-Path $FlywayDir $flywayName

$ddlSql = Build-CreateTableSql -schema $schema -table $table -cols $cols -indexes $indexes

$wikiPage = $null
if ($writeWiki) {
  $schemaDir = Join-Path $WikiRoot ("easyway-webapp/01_database_architecture/01b_schema_structure/{0}" -f $schema)
  $tablesDir = Join-Path $schemaDir "tables"
  Ensure-Dir $tablesDir
  $wikiFileName = (To-Kebab ($schema + '-' + $table)) + ".md"
  $wikiPage = Join-Path $tablesDir $wikiFileName

  $owner = if ($p.documentation.owner) { [string]$p.documentation.owner } else { 'team-data' }
  $summary = if ($p.documentation.summary) { [string]$p.documentation.summary } else { ("Tabella ${schema}.${table} (generata da intent).") }
  $tags = @('domain/db','layer/reference','audience/dev','audience/dba','privacy/internal','language/it')
  if ($p.documentation.tags) { $tags += @($p.documentation.tags) }
  $tags = @($tags | Where-Object { $_ } | Select-Object -Unique)

  $tagInline = '[{0}]' -f (($tags | ForEach-Object { $_ }) -join ', ')
  $docId = ("ew-db-table-{0}-{1}" -f ($schema.ToLowerInvariant()), ($table.ToLowerInvariant()))

  $md = @()
  $md += '---'
  $md += "id: $docId"
  $md += ("title: " + (To-Kebab ("db-table-" + $schema + "-" + $table)))
  $md += ("summary: " + $summary)
  $md += 'status: draft'
  $md += ("owner: " + $owner)
  $md += ("tags: " + $tagInline)
  $md += 'llm:'
  $md += '  include: true'
  $md += '  pii: none'
  $md += '  chunk_hint: 250-400'
  $md += '  redaction: [email, phone]'
  $md += 'entities: []'
  $md += ("updated: '{0}'" -f (Get-Date).ToString('yyyy-MM-dd'))
  $md += 'next: Compilare descrizione colonne, esempi query e policy (tenanting/audit).'
  $md += '---'
  $md += ''
  $md += "# ${schema}.${table}"
  $md += ''
  $md += '## Scopo'
  $md += '- TODO: descrivere lo scopo della tabella (1-3 frasi).'
  $md += ''
  $md += '## DDL (source-of-truth)'
  $md += ("- Migrazione: `{0}`" -f $flywayPath.Replace('\\','/'))
  $md += ''
  $md += '## Colonne'
  foreach ($c in $cols) {
    $md += ("- `{0}` ({1})" -f (Normalize-Ident $c.name), ([string]$c.sql_type).Trim())
  }
  $md += ''
  $md += '## Domande a cui risponde'
  $md += "- Qual e' lo scopo della tabella ${schema}.${table}?"
  $md += "- Quali colonne contiene e quali sono obbligatorie?"
  $md += '- Quali sono PK/FK/indici e come impattano le query?'
  $md += '- Quali dati sono sensibili (PII) e quali policy si applicano?'
  $md += ''
}

$artifacts = New-Object System.Collections.Generic.List[string]
$notes = New-Object System.Collections.Generic.List[string]

if ($writeFlyway) { $artifacts.Add($flywayPath.Replace('\\','/')) | Out-Null }
if ($wikiPage) { $artifacts.Add($wikiPage.Replace('\\','/')) | Out-Null }
$notes.Add("ERwin/data model: aggiornamento non automatizzato in questo step; produrre/exportare artifact e linkarlo nella pagina tabella.") | Out-Null
if ($writeSnapshot) { $notes.Add("Snapshot DDL in DataBase/: non implementato in questo step (serve policy di merge e formato canonico).") | Out-Null }

if (-not $WhatIf) {
  if ($writeFlyway) { Set-Content -LiteralPath $flywayPath -Value $ddlSql -Encoding utf8 }
  if ($wikiPage) { Set-Content -LiteralPath $wikiPage -Value ($md -join "`r`n") -Encoding utf8 }
} else {
  $notes.Add('WhatIf: nessun file scritto (solo preview).') | Out-Null
}

$result = [ordered]@{
  action = 'db-table:create'
  ok = $true
  whatIf = [bool]$WhatIf
  schema = $schema
  table = $table
  artifacts = @($artifacts)
  ddl = if ($writeFlyway) { $flywayPath.Replace('\\','/') } else { $null }
  wikiPage = if ($wikiPage) { $wikiPage.Replace('\\','/') } else { $null }
  notes = ($notes -join ' ')
}

$json = ($result | ConvertTo-Json -Depth 8)
Set-Content -LiteralPath $SummaryOut -Value $json -Encoding utf8
Write-Output $json
if ($FailOnError -and -not $result.ok) { exit 1 }
