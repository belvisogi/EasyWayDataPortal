param(
  [string]$DbDir = "DataBase",
  [string]$PortalTablesFile = "DDL_PORTAL_TABLE_EASYWAY_DATAPORTAL.sql",
  [string]$PortalProceduresFile = "DDL_PORTAL_STOREPROCES_EASYWAY_DATAPORTAL.sql",
  [string]$StatlogProceduresFile = "DDL_STATLOG_STOREPROCES_EASYWAY_DATAPORTAL.sql",
  [string]$WikiOut = "Wiki/EasyWayData.wiki/easyway-webapp/01_database_architecture/ddl-inventory.md",
  [switch]$WriteWiki,
  [string]$SummaryOut = "db-ddl-inventory.json"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Read-Text([string]$p) {
  if (-not (Test-Path -LiteralPath $p)) { throw "File not found: $p" }
  return (Get-Content -LiteralPath $p -Raw -Encoding UTF8)
}

function Extract-PortalTables([string]$sql) {
  $rx = [regex]::new('(?im)^\s*CREATE\s+TABLE\s+PORTAL\.(?<name>[A-Z0-9_]+)\s*\(', [System.Text.RegularExpressions.RegexOptions]::None)
  return @($rx.Matches($sql) | ForEach-Object { $_.Groups['name'].Value } | Sort-Object -Unique)
}

function Extract-PortalProcedures([string]$sql) {
  $rx = [regex]::new('(?im)^\s*CREATE\s+OR\s+ALTER\s+PROCEDURE\s+PORTAL\.(?<name>[A-Za-z0-9_]+)\b', [System.Text.RegularExpressions.RegexOptions]::None)
  return @($rx.Matches($sql) | ForEach-Object { $_.Groups['name'].Value } | Sort-Object -Unique)
}

function Build-Wiki {
  param(
    [string[]]$Tables,
    [string[]]$Procedures,
    [string[]]$StatlogProcedures
  )

  $today = (Get-Date).ToString('yyyy-MM-dd')

  $lines = New-Object System.Collections.Generic.List[string]
  $lines.Add('---')
  $lines.Add('id: ew-db-ddl-inventory')
  $lines.Add('title: DB PORTAL - Inventario DDL (source-of-truth)')
  $lines.Add('summary: Elenco tabelle e stored procedure estratto dai DDL sotto DataBase/, per mantenere allineata la Wiki 01_database_architecture.')
  $lines.Add('status: draft')
  $lines.Add('owner: team-data')
  $lines.Add('tags: [domain/db, layer/reference, audience/dev, audience/dba, privacy/internal, language/it]')
  $lines.Add('llm:')
  $lines.Add('  include: true')
  $lines.Add('  pii: none')
  $lines.Add('  chunk_hint: 250-400')
  $lines.Add('  redaction: [email, phone]')
  $lines.Add('entities: []')
  $lines.Add(("updated: '{0}'" -f $today))
  $lines.Add("next: TODO - validare quale file DDL e' canonico (DataBase/ vs db/flyway/sql/) e automatizzare il sync.")
  $lines.Add('---')
  $lines.Add('')
  $lines.Add('# DB PORTAL - Inventario DDL (source-of-truth)')
  $lines.Add('')
  $lines.Add('## Obiettivo')
  $lines.Add("- Rendere esplicito l'elenco corretto di tabelle e stored procedure del PORTAL DB usando come fonte i DDL sotto `DataBase/`.")
  $lines.Add("- Ridurre ambiguita: un agente (o un umano) puo verificare rapidamente cosa esiste e dove e documentato.")
  $lines.Add('')
  $lines.Add('## Domande a cui risponde')
  $lines.Add("- Quali tabelle esistono nello schema `PORTAL` secondo i DDL del repo?")
  $lines.Add("- Quali stored procedure esistono nello schema `PORTAL` secondo i DDL del repo?")
  $lines.Add("- Quali file DDL sono la fonte e come posso rigenerare questo inventario?")
  $lines.Add("- Dove trovo la documentazione umana (01_database_architecture) per ciascun gruppo di SP?")
  $lines.Add('')
  $lines.Add('## Source of truth (repo)')
  $lines.Add('- Tabelle: `DataBase/DDL_PORTAL_TABLE_EASYWAY_DATAPORTAL.sql`')
  $lines.Add('- Stored procedure: `DataBase/DDL_PORTAL_STOREPROCES_EASYWAY_DATAPORTAL.sql`')
  $lines.Add('- Logging SP: `DataBase/DDL_STATLOG_STOREPROCES_EASYWAY_DATAPORTAL.sql`')
  $lines.Add('')
  $lines.Add("Nota: la deploy operativa tende a usare migrazioni Flyway in `db/flyway/sql/`. Questo inventario serve a mantenere la Wiki allineata alla lista dichiarata in `DataBase/`.")
  $lines.Add('')
  $lines.Add('## Tabelle (PORTAL)')
  foreach ($t in $Tables) {
    $lines.Add(('- `PORTAL.{0}`' -f $t))
  }
  $lines.Add('')
  $lines.Add('## Stored procedure (PORTAL)')
  foreach ($p in $Procedures) {
    $lines.Add(('- `PORTAL.{0}`' -f $p))
  }
  foreach ($p in $StatlogProcedures) {
    if ($Procedures -contains $p) { continue }
    $lines.Add(('- `PORTAL.{0}`' -f $p))
  }
  $lines.Add('')
  $lines.Add("## Dove e' documentato (Wiki)")
  $lines.Add('- Overview schema/tabelle: `easyway-webapp/01_database_architecture/portal.md`')
  $lines.Add('- Overview SP: `easyway-webapp/01_database_architecture/storeprocess.md`')
  $lines.Add('- SP per area: `easyway-webapp/01_database_architecture/01b_schema_structure/PORTAL/programmability/stored-procedure/index.md`')
  $lines.Add('- Logging: `easyway-webapp/01_database_architecture/01b_schema_structure/PORTAL/programmability/stored-procedure/stats-execution-log.md`')
  $lines.Add('')
  $lines.Add('## Rigenerazione (idempotente)')
  $lines.Add('- `pwsh scripts/db-ddl-inventory.ps1 -WriteWiki`')
  $lines.Add('')
  return ($lines -join "`n") + "`n"
}

$tablesPath = Join-Path $DbDir $PortalTablesFile
$procsPath = Join-Path $DbDir $PortalProceduresFile
$statPath = Join-Path $DbDir $StatlogProceduresFile

$tablesSql = Read-Text $tablesPath
$procsSql = Read-Text $procsPath
$statSql = Read-Text $statPath

$tables = Extract-PortalTables $tablesSql
$procs = Extract-PortalProcedures $procsSql
$statProcs = Extract-PortalProcedures $statSql

$tables = @($tables | Where-Object { $_ })
$procs = @($procs | Where-Object { $_ })
$statProcs = @($statProcs | Where-Object { $_ })

$summary = [pscustomobject]@{
  ok = $true
  dbDir = $DbDir
  inputs = [pscustomobject]@{
    portalTables = $tablesPath.Replace([char]92,'/')
    portalProcedures = $procsPath.Replace([char]92,'/')
    statlogProcedures = $statPath.Replace([char]92,'/')
  }
  counts = [pscustomobject]@{
    tables = $tables.Count
    procedures = $procs.Count
    statlogProcedures = $statProcs.Count
  }
  portal = [pscustomobject]@{
    tables = $tables
    procedures = $procs
    statlogProcedures = $statProcs
  }
  wiki = [pscustomobject]@{
    wrote = [bool]$WriteWiki
    path = $WikiOut.Replace([char]92,'/')
  }
}

if ($WriteWiki) {
  $md = Build-Wiki -Tables $tables -Procedures $procs -StatlogProcedures $statProcs
  Set-Content -LiteralPath $WikiOut -Value $md -Encoding utf8
}

$json = $summary | ConvertTo-Json -Depth 6
Set-Content -LiteralPath $SummaryOut -Value $json -Encoding utf8
Write-Output $json
