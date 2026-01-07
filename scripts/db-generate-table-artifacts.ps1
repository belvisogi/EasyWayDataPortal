param(
  [Parameter(Mandatory=$true)][string]$IntentPath,
  [string]$FlywayDir = "db/flyway/sql",
  [string]$WikiRoot = "Wiki/EasyWayData.wiki",
  [switch]$WhatIf,
  [switch]$FailOnError,
  [string]$SummaryOut = "out/db/db-table-create.json"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-Prop($obj, [string]$name) {
  if ($null -eq $obj) { return $null }
  $p = $obj.PSObject.Properties[$name]
  if ($null -eq $p) { return $null }
  return $p.Value
}

function Get-BoolProp($obj, [string]$name, [bool]$default = $false) {
  $v = Get-Prop $obj $name
  if ($null -eq $v) { return $default }
  return [bool]$v
}

function Get-StringProp($obj, [string]$name, [string]$default = '') {
  $v = Get-Prop $obj $name
  if ($null -eq $v) { return $default }
  return [string]$v
}

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

  $pkCols = @()
  foreach ($c0 in @($cols)) {
    if (Get-BoolProp $c0 'pk' $false) { $pkCols += (Normalize-Ident (Get-StringProp $c0 'name' '')) }
  }
  $colLines = New-Object System.Collections.Generic.List[string]
  foreach ($c in $cols) {
    $name = Normalize-Ident (Get-StringProp $c 'name' '')
    $type = (Get-StringProp $c 'sql_type' '').Trim()
    if (-not $name -or -not $type) { throw "Invalid column (name/type required)" }
    $nullable = Get-BoolProp $c 'nullable' $true
    $identity = Get-BoolProp $c 'identity' $false
    $def = Get-Prop $c 'default'
    $nullSql = if ($nullable -eq $false) { "NOT NULL" } else { "NULL" }
    $identSql = if ($identity -eq $true) { "IDENTITY(1,1)" } else { "" }
    $defSql = if ($null -ne $def -and ('' + $def).Trim()) { ("DEFAULT " + [string]$def) } else { "" }
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
    $refs = Get-Prop $c 'references'
    if (-not $refs) { continue }
    $col = Normalize-Ident (Get-StringProp $c 'name' '')
    $rs = Normalize-Ident (Get-StringProp $refs 'schema' '')
    $rt = Normalize-Ident (Get-StringProp $refs 'table' '')
    $rc = Normalize-Ident (Get-StringProp $refs 'column' '')
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
    $ixCols = @()
    foreach ($ixc in @((Get-Prop $ix 'columns'))) { $ixCols += (Normalize-Ident ([string]$ixc)) }
    $ixCols = @($ixCols | Where-Object { $_ })
    if ($ixCols.Count -eq 0) { continue }
    $ixName = if (Get-Prop $ix 'name') { Normalize-Ident (Get-StringProp $ix 'name' '') } else { "IX_${schemaEsc}_${tableEsc}_" + ($ixCols -join '_') }
    $unique = if (Get-BoolProp $ix 'unique' $false) { "UNIQUE " } else { "" }
    $colsSql = ($ixCols | ForEach-Object { "[${_}]" }) -join ', '
    $sql += "IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name=N'${ixName}' AND object_id=OBJECT_ID(N'[${schemaEsc}].[${tableEsc}]'))"
    $sql += "BEGIN"
    $sql += "  CREATE ${unique}INDEX [${ixName}] ON [${schemaEsc}].[${tableEsc}] (${colsSql});"
    $sql += "END"
    $sql += "GO"
  }

  return ($sql -join "`r`n")
}

function Escape-SqlNLiteral([string]$s) {
  if ($null -eq $s) { return 'N'''''}
  return ("N'" + ($s -replace "'", "''") + "'")
}

function Normalize-SqlTypeKey([string]$t) {
  if (-not $t) { return '' }
  return ($t.Trim().ToLowerInvariant() -replace '\s+','')
}

function Normalize-DefaultKey([string]$d) {
  if ($null -eq $d) { return '' }
  $x = ('' + $d).Trim()
  if (-not $x) { return '' }
  $x = ($x -replace '\s+','').ToUpperInvariant()
  # Strip one layer of surrounding parentheses (common in defaults)
  if ($x.StartsWith('(') -and $x.EndsWith(')') -and $x.Length -gt 2) {
    $x = $x.Substring(1, $x.Length - 2)
  }
  return $x
}

function Find-Column([object[]]$cols, [string]$name) {
  foreach ($c in @($cols)) {
    $n = Normalize-Ident (Get-StringProp $c 'name' '')
    if ($n -and $name -and ($n.ToLowerInvariant() -eq $name.ToLowerInvariant())) { return $c }
  }
  return $null
}

function Add-StandardColumns([object[]]$cols, [bool]$includeAudit, [bool]$includeSoftDelete) {
  $out = New-Object System.Collections.Generic.List[object]
  foreach ($c in @($cols)) { $out.Add($c) | Out-Null }

  $notes = New-Object System.Collections.Generic.List[string]
  $existing = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
  foreach ($c in @($cols)) {
    $n = Normalize-Ident (Get-StringProp $c 'name' '')
    if ($n) { $existing.Add($n) | Out-Null }
  }

  $standard = @()
  if ($includeAudit) {
    $standard += @(
      [pscustomobject]@{ name='created_by'; sql_type='nvarchar(255)'; nullable=$false; default="('MANUAL')"; logical_name='Created by'; description='Utente/processo che ha creato il record.' },
      [pscustomobject]@{ name='created_at'; sql_type='datetime2'; nullable=$false; default='(SYSUTCDATETIME())'; logical_name='Created at'; description='Timestamp creazione (UTC).' },
      [pscustomobject]@{ name='updated_at'; sql_type='datetime2'; nullable=$false; default='(SYSUTCDATETIME())'; logical_name='Updated at'; description='Timestamp ultimo aggiornamento (UTC).' }
    )
  }
  if ($includeSoftDelete) {
    $standard += @(
      [pscustomobject]@{ name='is_deleted'; sql_type='bit'; nullable=$false; default='(0)'; logical_name='Is deleted'; description='Flag soft delete.' },
      [pscustomobject]@{ name='deleted_at'; sql_type='datetime2'; nullable=$true; default=$null; logical_name='Deleted at'; description='Timestamp soft delete (UTC).' },
      [pscustomobject]@{ name='deleted_by'; sql_type='nvarchar(255)'; nullable=$true; default=$null; logical_name='Deleted by'; description='Utente/processo che ha eseguito il soft delete.' }
    )
  }

  foreach ($s in $standard) {
    if ($existing.Contains($s.name)) { continue }
    $obj = [pscustomobject]@{
      name = $s.name
      sql_type = $s.sql_type
      nullable = [bool]$s.nullable
      default = $s.default
      pk = $false
      identity = $false
      pii = 'none'
      classification = 'internal'
      masking = 'none'
      logical_name = $s.logical_name
      description = $s.description
    }
    $out.Add($obj) | Out-Null
    $notes.Add("Auto-added standard column: $($s.name)") | Out-Null
  }

  return @{
    columns = $out.ToArray()
    notes = $notes.ToArray()
  }
}

function Build-ExtendedPropertiesSql([string]$schema,[string]$table,[object]$doc,[object[]]$cols) {
  $schemaEsc = Normalize-Ident $schema
  $tableEsc = Normalize-Ident $table
  $body = New-Object System.Collections.Generic.List[string]
  $hasAny = $false

  $tableDesc = ''
  if ($doc) {
    $tableDesc = (Get-StringProp $doc 'description' '')
    if (-not $tableDesc) { $tableDesc = (Get-StringProp $doc 'summary' '') }
    if (-not $tableDesc) { $tableDesc = (Get-StringProp $doc 'logical_name' '') }
  }

  function Add-PropStmt([string]$propName,[string]$value,[string]$colName = '') {
    if (-not $value) { return }
    Set-Variable -Name hasAny -Scope 1 -Value $true
    $v = Escape-SqlNLiteral $value
    if (-not $colName) {
      $body.Add("IF EXISTS (SELECT 1 FROM sys.extended_properties ep JOIN sys.tables t ON ep.major_id=t.object_id JOIN sys.schemas s ON t.schema_id=s.schema_id WHERE ep.name=N'$propName' AND ep.minor_id=0 AND s.name=N'${schemaEsc}' AND t.name=N'${tableEsc}')") | Out-Null
      $body.Add("  EXEC sys.sp_updateextendedproperty @name=N'$propName', @value=$v, @level0type=N'SCHEMA',@level0name='${schemaEsc}', @level1type=N'TABLE',@level1name='${tableEsc}';") | Out-Null
      $body.Add("ELSE") | Out-Null
      $body.Add("  EXEC sys.sp_addextendedproperty @name=N'$propName', @value=$v, @level0type=N'SCHEMA',@level0name='${schemaEsc}', @level1type=N'TABLE',@level1name='${tableEsc}';") | Out-Null
      $body.Add("") | Out-Null
      return
    }

    $colEsc = Normalize-Ident $colName
    $body.Add("IF EXISTS (SELECT 1 FROM sys.extended_properties ep JOIN sys.tables t ON ep.major_id=t.object_id JOIN sys.schemas s ON t.schema_id=s.schema_id JOIN sys.columns c ON c.object_id=t.object_id AND c.column_id=ep.minor_id WHERE ep.name=N'$propName' AND s.name=N'${schemaEsc}' AND t.name=N'${tableEsc}' AND c.name=N'${colEsc}')") | Out-Null
    $body.Add("  EXEC sys.sp_updateextendedproperty @name=N'$propName', @value=$v, @level0type=N'SCHEMA',@level0name='${schemaEsc}', @level1type=N'TABLE',@level1name='${tableEsc}', @level2type=N'COLUMN',@level2name='${colEsc}';") | Out-Null
    $body.Add("ELSE") | Out-Null
    $body.Add("  EXEC sys.sp_addextendedproperty @name=N'$propName', @value=$v, @level0type=N'SCHEMA',@level0name='${schemaEsc}', @level1type=N'TABLE',@level1name='${tableEsc}', @level2type=N'COLUMN',@level2name='${colEsc}';") | Out-Null
    $body.Add("") | Out-Null
  }

  if ($tableDesc) {
    Add-PropStmt -propName 'MS_Description' -value $tableDesc
    Add-PropStmt -propName 'Description' -value $tableDesc
  }

  foreach ($c in @($cols)) {
    $name = Normalize-Ident (Get-StringProp $c 'name' '')
    if (-not $name) { continue }
    $d = Get-StringProp $c 'description' ''
    $ln = Get-StringProp $c 'logical_name' ''
    $v = ''
    if ($ln -and $d) { $v = ($ln + ' | ' + $d) }
    elseif ($d) { $v = $d }
    elseif ($ln) { $v = $ln }
    if (-not $v) { continue }
    Add-PropStmt -propName 'MS_Description' -value $v -colName $name
    Add-PropStmt -propName 'Description' -value $v -colName $name
  }

  if (-not $hasAny) { return $null }
  $sql = New-Object System.Collections.Generic.List[string]
  $sql.Add("/* Auto-generated extended properties for ${schemaEsc}.${tableEsc} */") | Out-Null
  $sql.Add("SET NOCOUNT ON;") | Out-Null
  $sql.Add("IF OBJECT_ID(N'[${schemaEsc}].[${tableEsc}]','U') IS NULL") | Out-Null
  $sql.Add("BEGIN") | Out-Null
  $sql.Add("  PRINT 'Skip extended properties: table not found (${schemaEsc}.${tableEsc}).';") | Out-Null
  $sql.Add("  RETURN;") | Out-Null
  $sql.Add("END") | Out-Null
  $sql.Add("") | Out-Null
  foreach ($l in $body) { $sql.Add($l) | Out-Null }
  return (($sql -join "`r`n").TrimEnd() + "`r`n")
}

$intent = Read-Json $IntentPath
if (-not $intent.action) { throw "Intent missing action" }
if ($intent.action -ne 'db-table:create' -and $intent.action -ne 'db.table.create') { throw "Unsupported action for this generator: $($intent.action)" }

$p = $intent.params
$schema = Normalize-Ident ([string]$p.schema)
$table = Normalize-Ident ([string]$p.table)
$cols = @($p.columns)
$indexes = @($p.indexes)
if (-not $schema -or -not $table) { throw "schema/table are required" }
if ($cols.Count -eq 0) { throw "columns[] is required" }

$includeAudit = Get-BoolProp $p 'includeAudit' $false
$includeSoftDelete = Get-BoolProp $p 'includeSoftDelete' $false
$std = Add-StandardColumns -cols $cols -includeAudit:$includeAudit -includeSoftDelete:$includeSoftDelete
$cols = @($std.columns)

$ts = (Get-Date).ToUniversalTime().ToString('yyyyMMddHHmmss')
$writeFlyway = ($p.writeFlyway -ne $false)
$writeWiki = ($p.writeWiki -ne $false)
$writeSnapshot = ($p.writeDatabaseSnapshot -eq $true)

if ($writeFlyway) { Ensure-Dir $FlywayDir }

$flywayName = ("V{0}__create_{1}_{2}.sql" -f $ts, ($schema.ToLowerInvariant()), ($table.ToLowerInvariant()))
$flywayPath = Join-Path $FlywayDir $flywayName

$ddlSql = Build-CreateTableSql -schema $schema -table $table -cols $cols -indexes $indexes

$doc = Get-Prop $p 'documentation'
$descSql = $null
$descFlywayPath = $null
if ($writeFlyway) {
  $descSql = Build-ExtendedPropertiesSql -schema $schema -table $table -doc $doc -cols $cols
  if ($descSql) {
    $descFlywayName = ("V{0}_1__description_{1}_{2}.sql" -f $ts, ($schema.ToLowerInvariant()), ($table.ToLowerInvariant()))
    $descFlywayPath = Join-Path $FlywayDir $descFlywayName
  }
}

$wikiPage = $null
if ($writeWiki) {
  $schemaDir = Join-Path $WikiRoot ("easyway-webapp/01_database_architecture/01b_schema_structure/{0}" -f $schema)
  $tablesDir = Join-Path $schemaDir "tables"
  Ensure-Dir $tablesDir
  $wikiFileName = (To-Kebab ($schema + '-' + $table)) + ".md"
  $wikiPage = Join-Path $tablesDir $wikiFileName

  $owner = if ($doc -and (Get-Prop $doc 'owner')) { Get-StringProp $doc 'owner' 'team-data' } else { 'team-data' }
  $logicalName = if ($doc -and (Get-Prop $doc 'logical_name')) { Get-StringProp $doc 'logical_name' '' } else { $null }
  $summary = if ($doc -and (Get-Prop $doc 'summary')) { Get-StringProp $doc 'summary' '' } else { ("Tabella ${schema}.${table} (generata da intent).") }
  $purpose = if ($doc -and (Get-Prop $doc 'description')) { Get-StringProp $doc 'description' '' } else { $summary }
  $tags = @('domain/db','layer/reference','audience/dev','audience/dba','privacy/internal','language/it')
  if ($doc -and (Get-Prop $doc 'tags')) { $tags += @((Get-Prop $doc 'tags')) }
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
  if ($logicalName) { $md += ("# {0}.{1} — {2}" -f $schema, $table, $logicalName) }
  else { $md += "# ${schema}.${table}" }
  $md += ''
  $md += '## Scopo'
  $md += ("- {0}" -f $purpose)
  $md += ''
  $md += '## DDL (source-of-truth)'
  $md += ('- Migrazione: `{0}`' -f $flywayPath.Replace('\\','/'))
  if ($descFlywayPath) { $md += ('- Extended properties (MS_Description): `{0}`' -f $descFlywayPath.Replace('\\','/')) }
  $md += ''
  $md += '## Colonne'
  foreach ($c in $cols) {
    $colName = Normalize-Ident (Get-StringProp $c 'name' '')
    $colType = (Get-StringProp $c 'sql_type' '').Trim()
    $colDesc = if (Get-Prop $c 'description') { Get-StringProp $c 'description' '' } else { $null }
    $colLogical = if (Get-Prop $c 'logical_name') { Get-StringProp $c 'logical_name' '' } else { $null }

    $tailParts = @()
    if ($colLogical) { $tailParts += $colLogical }
    if ($colDesc) { $tailParts += $colDesc }
    $tail = if ($tailParts.Count -gt 0) { (" — " + ($tailParts -join ' | ')) } else { '' }

    $md += ('- `{0}` ({1}){2}' -f $colName, $colType, $tail)
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
if ($descFlywayPath) { $artifacts.Add($descFlywayPath.Replace('\\','/')) | Out-Null }
if ($wikiPage) { $artifacts.Add($wikiPage.Replace('\\','/')) | Out-Null }
foreach ($n in @($std.notes)) { $notes.Add([string]$n) | Out-Null }
$notes.Add("ERwin/data model: aggiornamento non automatizzato in questo step; produrre/exportare artifact e linkarlo nella pagina tabella.") | Out-Null
if ($writeSnapshot) { $notes.Add("Snapshot DDL deprecato: usare solo migrazioni Flyway in db/flyway/sql/ (storici in old/db/).") | Out-Null }

if (-not $WhatIf) {
  if ($writeFlyway) { Set-Content -LiteralPath $flywayPath -Value $ddlSql -Encoding utf8 }
  if ($descFlywayPath) { Set-Content -LiteralPath $descFlywayPath -Value $descSql -Encoding utf8 }
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
$summaryDir = Split-Path -Parent $SummaryOut
if ($summaryDir) { Ensure-Dir $summaryDir }
Set-Content -LiteralPath $SummaryOut -Value $json -Encoding utf8
Write-Output $json
if ($FailOnError -and -not $result.ok) { exit 1 }
