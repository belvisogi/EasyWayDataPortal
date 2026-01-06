param(
  [string]$DbDir = "old/db/DataBase_legacy",
  [string]$CanonicalDdlFile = "DDL_EASYWAY_DATAPORTAL.sql",
  [switch]$IncludeSnapshot,
  [string]$ProvisioningDir = "old/db/DataBase_legacy/provisioning",
  [switch]$IncludeProvisioning,
  [string]$FlywayDir = "db/flyway/sql",
  [string]$PortalSchema = "PORTAL",
  [switch]$IncludeLegacy,
  [string]$LegacyDir = "old/db/ddl_portal_exports",
  [string]$LegacyPortalTablesFile = "DDL_PORTAL_TABLE_EASYWAY_DATAPORTAL.sql",
  [string]$LegacyPortalProceduresFile = "DDL_PORTAL_STOREPROCES_EASYWAY_DATAPORTAL.sql",
  [string]$LegacyStatlogProceduresFile = "DDL_STATLOG_STOREPROCES_EASYWAY_DATAPORTAL.sql",
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

function Resolve-ExistingPath([string[]]$candidates) {
  foreach ($p in $candidates) { if ($p -and (Test-Path -LiteralPath $p)) { return $p } }
  return $null
}

function Extract-Tables([string]$sql) {
  $rxBracketed = [regex]::new('(?im)^\s*CREATE\s+TABLE\s+\[(?<schema>[A-Za-z0-9_]+)\]\.\[(?<name>[A-Za-z0-9_]+)\]\s*\(', [System.Text.RegularExpressions.RegexOptions]::None)
  $rxPlain = [regex]::new('(?im)^\s*CREATE\s+TABLE\s+(?<schema>[A-Za-z0-9_]+)\.(?<name>[A-Za-z0-9_]+)\s*\(', [System.Text.RegularExpressions.RegexOptions]::None)

  $items = New-Object System.Collections.Generic.List[object]
  foreach ($m in $rxBracketed.Matches($sql)) { $items.Add(@{ schema = $m.Groups['schema'].Value; name = $m.Groups['name'].Value }) }
  foreach ($m in $rxPlain.Matches($sql)) { $items.Add(@{ schema = $m.Groups['schema'].Value; name = $m.Groups['name'].Value }) }
  return $items.ToArray()
}

function Extract-Procedures([string]$sql) {
  $rxBracketed = [regex]::new('(?im)^\s*CREATE\s+(?:OR\s+ALTER\s+)?PROCEDURE\s+\[(?<schema>[A-Za-z0-9_]+)\]\.\[(?<name>[A-Za-z0-9_]+)\]\b', [System.Text.RegularExpressions.RegexOptions]::None)
  $rxPlain = [regex]::new('(?im)^\s*CREATE\s+(?:OR\s+ALTER\s+)?PROCEDURE\s+(?<schema>[A-Za-z0-9_]+)\.(?<name>[A-Za-z0-9_]+)\b', [System.Text.RegularExpressions.RegexOptions]::None)

  $items = New-Object System.Collections.Generic.List[object]
  foreach ($m in $rxBracketed.Matches($sql)) { $items.Add(@{ schema = $m.Groups['schema'].Value; name = $m.Groups['name'].Value }) }
  foreach ($m in $rxPlain.Matches($sql)) { $items.Add(@{ schema = $m.Groups['schema'].Value; name = $m.Groups['name'].Value }) }
  return $items.ToArray()
}

function Normalize-FullName([string]$schema, [string]$name) {
  $s = ($schema ?? '').Trim()
  $n = ($name ?? '').Trim()
  if ($s -eq '' -or $n -eq '') { return $null }
  return ("{0}.{1}" -f $s.ToUpperInvariant(), $n.ToUpperInvariant())
}

function Collect-CanonicalSql {
  param(
    [string]$CanonicalPath,
    [string]$ProvisioningDir,
    [string]$FlywayDir,
    [bool]$IncludeSnapshot,
    [bool]$IncludeProvisioning
  )

  $canonicalSql = ''
  $provisioningFiles = @()
  $flywayFiles = @()

  if ($IncludeSnapshot -and $CanonicalPath -and (Test-Path -LiteralPath $CanonicalPath)) {
    $canonicalSql = Read-Text $CanonicalPath
  }

  if ($IncludeProvisioning -and (Test-Path -LiteralPath $ProvisioningDir)) {
    $provisioningFiles = @(
      Get-ChildItem -LiteralPath $ProvisioningDir -File -Filter *.sql -ErrorAction Stop |
      Sort-Object -Property Name |
      ForEach-Object { $_.FullName }
    )
  }

  if (Test-Path -LiteralPath $FlywayDir) {
    $flywayFiles = @(
      Get-ChildItem -LiteralPath $FlywayDir -File -Filter *.sql -ErrorAction Stop |
      Sort-Object -Property Name |
      ForEach-Object { $_.FullName }
    )
  }

  $parts = New-Object System.Collections.Generic.List[string]
  if ($canonicalSql) { $parts.Add($canonicalSql) }
  foreach ($f in $provisioningFiles) {
    try { $parts.Add((Read-Text $f)) } catch { }
  }
  foreach ($f in $flywayFiles) {
    try { $parts.Add((Read-Text $f)) } catch { }
  }

  return [pscustomobject]@{
    combinedSql = ($parts -join "`n`n")
    provisioningFiles = $provisioningFiles
    flywayFiles = $flywayFiles
  }
}

function Build-Wiki {
  param(
    [string]$PortalSchema,
    [string]$CanonicalDdlRel,
    [string]$ProvisioningRel,
    [string]$FlywayRel,
    [bool]$IncludeSnapshot,
    [bool]$IncludeProvisioning,
    [string[]]$CanonicalTables,
    [string[]]$CanonicalProcedures,
    [bool]$IncludeLegacy,
    [string]$LegacyTablesRel,
    [string]$LegacyProceduresRel,
    [string]$LegacyStatlogRel,
    [string[]]$LegacyTables,
    [string[]]$LegacyProcedures,
    [string[]]$LegacyStatlogProcedures
  )

  $today = (Get-Date).ToString('yyyy-MM-dd')

  $lines = New-Object System.Collections.Generic.List[string]
  $lines.Add('---')
  $lines.Add('id: ew-db-ddl-inventory')
  $lines.Add('title: DB PORTAL - Inventario DDL (canonico)')
  $lines.Add('summary: Inventario DB (canonico) estratto dalle migrazioni Flyway (source-of-truth) per mantenere allineata la Wiki 01_database_architecture.')
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
  $lines.Add('next: Rendere Flyway (`db/flyway/`) la fonte incrementale e rigenerare periodicamente il DDL canonico (snapshot) se necessario; mantenere i legacy export fuori dal retrieval.')
  $lines.Add('---')
  $lines.Add('')
  $lines.Add('# DB PORTAL - Inventario DDL (canonico)')
  $lines.Add('')
  $lines.Add('## Obiettivo')
  $lines.Add("- Rendere esplicito l'elenco di tabelle e stored procedure usando **solo** le fonti canoniche del repo.")
  $lines.Add("- Ridurre ambiguita: un agente (o un umano) puo verificare rapidamente cosa esiste e dove e documentato.")
  $lines.Add('')
  $lines.Add('## Domande a cui risponde')
  $lines.Add(('- Quali tabelle/procedure esistono nello schema `{0}` secondo le fonti canoniche?' -f $PortalSchema))
  $lines.Add("- Quali file sono la fonte e come posso rigenerare questo inventario?")
  $lines.Add('')
  $lines.Add('## Source of truth (repo)')
  $lines.Add(('- Flyway migrations (canonico, corrente): `{0}`' -f $FlywayRel))
  if ($IncludeProvisioning) { $lines.Add(('- Provisioning (dev/local): `{0}`' -f $ProvisioningRel)) }
  if ($IncludeSnapshot) { $lines.Add(('- Snapshot DDL (legacy): `{0}`' -f $CanonicalDdlRel)) }
  $lines.Add('')
  if ($IncludeLegacy) {
    $lines.Add('## Legacy export (solo audit/diff)')
    $lines.Add('Nota: questi file non sono fonte primaria; servono solo per confronto durante la migrazione.')
    $lines.Add(('- Tabelle (legacy): `{0}`' -f $LegacyTablesRel))
    $lines.Add(('- Stored procedure (legacy): `{0}`' -f $LegacyProceduresRel))
    $lines.Add(('- Logging SP (legacy): `{0}`' -f $LegacyStatlogRel))
    $lines.Add('')
  }
  $lines.Add('Deploy operativa: usare migrazioni Flyway in `db/flyway/` (apply controllato).')
  $lines.Add('')

  $lines.Add("## Tabelle (${PortalSchema}) - canonico")
  if ($CanonicalTables.Count -eq 0) { $lines.Add('_Nessuna tabella trovata dal parser._') } else { foreach ($t in $CanonicalTables) { $lines.Add(('- `{0}`' -f $t)) } }
  $lines.Add('')

  $lines.Add("## Stored procedure (${PortalSchema}) - canonico")
  if ($CanonicalProcedures.Count -eq 0) { $lines.Add('_Nessuna stored procedure trovata dal parser._') } else { foreach ($p in $CanonicalProcedures) { $lines.Add(('- `{0}`' -f $p)) } }
  $lines.Add('')

  if ($IncludeLegacy) {
    $lines.Add("## Tabelle (${PortalSchema}) - legacy (audit)")
    foreach ($t in $LegacyTables) { $lines.Add(('- `{0}`' -f $t)) }
    $lines.Add('')

    $lines.Add("## Stored procedure (${PortalSchema}) - legacy (audit)")
    foreach ($p in $LegacyProcedures) { $lines.Add(('- `{0}`' -f $p)) }
    foreach ($p in $LegacyStatlogProcedures) {
      if ($LegacyProcedures -contains $p) { continue }
      $lines.Add(('- `{0}`' -f $p))
    }
    $lines.Add('')
  }

  $lines.Add("## Dove e' documentato (Wiki)")
  $lines.Add('- Overview schema/tabelle: `easyway-webapp/01_database_architecture/portal.md`')
  $lines.Add('- Overview SP: `easyway-webapp/01_database_architecture/storeprocess.md`')
  $lines.Add('- SP per area: `easyway-webapp/01_database_architecture/01b_schema_structure/PORTAL/programmability/stored-procedure/index.md`')
  $lines.Add('- Logging: `easyway-webapp/01_database_architecture/01b_schema_structure/PORTAL/programmability/stored-procedure/stats-execution-log.md`')
  $lines.Add('')

  $lines.Add('## Rigenerazione (idempotente)')
  $lines.Add('- Solo Flyway (canonico): `pwsh scripts/db-ddl-inventory.ps1 -WriteWiki`')
  $lines.Add('- Include provisioning (dev/local): `pwsh scripts/db-ddl-inventory.ps1 -IncludeProvisioning -WriteWiki`')
  $lines.Add('- Include snapshot DDL (legacy): `pwsh scripts/db-ddl-inventory.ps1 -IncludeSnapshot -WriteWiki`')
  $lines.Add('- Include legacy export (audit): `pwsh scripts/db-ddl-inventory.ps1 -IncludeLegacy -WriteWiki`')
  $lines.Add('')
  return ($lines -join "`n") + "`n"
}

$portalSchemaNorm = ($PortalSchema ?? 'PORTAL').Trim()
$canonicalPath = Join-Path $DbDir $CanonicalDdlFile

$collected = Collect-CanonicalSql -CanonicalPath $canonicalPath -ProvisioningDir $ProvisioningDir -FlywayDir $FlywayDir -IncludeSnapshot ([bool]$IncludeSnapshot) -IncludeProvisioning ([bool]$IncludeProvisioning)
$canonicalCombinedSql = $collected.combinedSql
$provisioningFiles = @($collected.provisioningFiles)
$flywayFiles = @($collected.flywayFiles)

$canonicalTables = @()
try {
  $canonicalTables = @(
    (Extract-Tables $canonicalCombinedSql) |
    Where-Object { $_.schema -and $_.name -and ($_.schema -ieq $portalSchemaNorm) } |
    ForEach-Object { Normalize-FullName $_.schema $_.name } |
    Where-Object { $_ } |
    Sort-Object -Unique
  )
} catch { $canonicalTables = @() }

$canonicalProcedures = @()
try {
  $canonicalProcedures = @(
    (Extract-Procedures $canonicalCombinedSql) |
    Where-Object { $_.schema -and $_.name -and ($_.schema -ieq $portalSchemaNorm) } |
    ForEach-Object { Normalize-FullName $_.schema $_.name } |
    Where-Object { $_ } |
    Sort-Object -Unique
  )
} catch { $canonicalProcedures = @() }

$legacyTablesPath = $null
$legacyProcsPath = $null
$legacyStatPath = $null
$legacyTablesFull = @()
$legacyProcsFull = @()
$legacyStatFull = @()

if ($IncludeLegacy) {
  $legacyTablesPath = Resolve-ExistingPath @(
    (Join-Path $LegacyDir $LegacyPortalTablesFile),
    (Join-Path $DbDir $LegacyPortalTablesFile)
  )
  $legacyProcsPath = Resolve-ExistingPath @(
    (Join-Path $LegacyDir $LegacyPortalProceduresFile),
    (Join-Path $DbDir $LegacyPortalProceduresFile)
  )
  $legacyStatPath = Resolve-ExistingPath @(
    (Join-Path $LegacyDir $LegacyStatlogProceduresFile),
    (Join-Path $DbDir $LegacyStatlogProceduresFile)
  )

  $legacyTablesSql = if ($legacyTablesPath) { Read-Text $legacyTablesPath } else { '' }
  $legacyProcsSql = if ($legacyProcsPath) { Read-Text $legacyProcsPath } else { '' }
  $legacyStatSql = if ($legacyStatPath) { Read-Text $legacyStatPath } else { '' }

  $legacyTablesFull = @(
    (Extract-Tables $legacyTablesSql) |
    Where-Object { $_.schema -and $_.name -and ($_.schema -ieq $portalSchemaNorm) } |
    ForEach-Object { Normalize-FullName $_.schema $_.name } |
    Where-Object { $_ } |
    Sort-Object -Unique
  )
  $legacyProcsFull = @(
    (Extract-Procedures $legacyProcsSql) |
    Where-Object { $_.schema -and $_.name -and ($_.schema -ieq $portalSchemaNorm) } |
    ForEach-Object { Normalize-FullName $_.schema $_.name } |
    Where-Object { $_ } |
    Sort-Object -Unique
  )
  $legacyStatFull = @(
    (Extract-Procedures $legacyStatSql) |
    Where-Object { $_.schema -and $_.name -and ($_.schema -ieq $portalSchemaNorm) } |
    ForEach-Object { Normalize-FullName $_.schema $_.name } |
    Where-Object { $_ } |
    Sort-Object -Unique
  )
}

$canonKey = @($canonicalTables | ForEach-Object { $_.ToLowerInvariant() })
$legacyKey = @($legacyTablesFull | ForEach-Object { $_.ToLowerInvariant() })
$legacyOnlyTables = @()
for ($i=0; $i -lt $legacyTablesFull.Count; $i++) {
  if ($canonKey -notcontains $legacyKey[$i]) { $legacyOnlyTables += $legacyTablesFull[$i] }
}

$summary = [pscustomobject]@{
  ok = $true
  inputs = [pscustomobject]@{
    portalSchema = $portalSchemaNorm
    includeSnapshot = [bool]$IncludeSnapshot
    canonicalDdl = if ($IncludeSnapshot) { $canonicalPath.Replace([char]92,'/') } else { $null }
    provisioningDir = $ProvisioningDir.Replace([char]92,'/')
    includeProvisioning = [bool]$IncludeProvisioning
    provisioningFiles = @($provisioningFiles | ForEach-Object { $_.Replace([char]92,'/') })
    flywayDir = $FlywayDir.Replace([char]92,'/')
    flywayFiles = @($flywayFiles | ForEach-Object { $_.Replace([char]92,'/') })
    includeLegacy = [bool]$IncludeLegacy
    legacyDir = $LegacyDir.Replace([char]92,'/')
    legacyPortalTables = if ($legacyTablesPath) { $legacyTablesPath.Replace([char]92,'/') } else { $null }
    legacyPortalProcedures = if ($legacyProcsPath) { $legacyProcsPath.Replace([char]92,'/') } else { $null }
    legacyStatlogProcedures = if ($legacyStatPath) { $legacyStatPath.Replace([char]92,'/') } else { $null }
  }
  counts = [pscustomobject]@{
    canonicalTables = $canonicalTables.Count
    canonicalProcedures = $canonicalProcedures.Count
    legacyTables = $legacyTablesFull.Count
    legacyProcedures = $legacyProcsFull.Count
    legacyStatlogProcedures = $legacyStatFull.Count
    legacyOnlyTables = $legacyOnlyTables.Count
  }
  canonical = [pscustomobject]@{
    tables = $canonicalTables
    procedures = $canonicalProcedures
  }
  legacy = [pscustomobject]@{
    tables = $legacyTablesFull
    procedures = $legacyProcsFull
    statlogProcedures = $legacyStatFull
  }
  delta = [pscustomobject]@{
    legacyOnlyTables = $legacyOnlyTables
  }
  wiki = [pscustomobject]@{
    wrote = [bool]$WriteWiki
    path = $WikiOut.Replace([char]92,'/')
  }
}

if ($WriteWiki) {
  $legacyTablesRel = if ($IncludeLegacy -and $legacyTablesPath) { $legacyTablesPath.Replace([char]92,'/') } else { '' }
  $legacyProcsRel = if ($IncludeLegacy -and $legacyProcsPath) { $legacyProcsPath.Replace([char]92,'/') } else { '' }
  $legacyStatRel = if ($IncludeLegacy -and $legacyStatPath) { $legacyStatPath.Replace([char]92,'/') } else { '' }

  $md = Build-Wiki `
    -PortalSchema $portalSchemaNorm `
    -CanonicalDdlRel ($canonicalPath.Replace([char]92,'/')) `
    -ProvisioningRel ($ProvisioningDir.Replace([char]92,'/')) `
    -FlywayRel ($FlywayDir.Replace([char]92,'/')) `
    -IncludeSnapshot ([bool]$IncludeSnapshot) `
    -IncludeProvisioning ([bool]$IncludeProvisioning) `
    -CanonicalTables $canonicalTables `
    -CanonicalProcedures $canonicalProcedures `
    -IncludeLegacy ([bool]$IncludeLegacy) `
    -LegacyTablesRel $legacyTablesRel `
    -LegacyProceduresRel $legacyProcsRel `
    -LegacyStatlogRel $legacyStatRel `
    -LegacyTables $legacyTablesFull `
    -LegacyProcedures $legacyProcsFull `
    -LegacyStatlogProcedures $legacyStatFull

  Set-Content -LiteralPath $WikiOut -Value $md -Encoding utf8
}

$json = $summary | ConvertTo-Json -Depth 7
Set-Content -LiteralPath $SummaryOut -Value $json -Encoding utf8
Write-Output $json
