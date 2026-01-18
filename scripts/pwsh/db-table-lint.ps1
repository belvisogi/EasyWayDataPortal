<#
Lint semantico per la creazione tabella (intent `db-table:create` / `db.table.create`).

Obiettivo:
- Errori "actionable" prima di generare DDL (naming, tipi, PII, tenanting/RLS).
- Output machine-readable (JSON) sotto `out/`.

Uso:
  pwsh scripts/db-table-lint.ps1 -IntentPath out/intents/intent.db-table-create.generated.json
#>

[CmdletBinding()]
param(
  [Parameter(Mandatory=$true)][string]$IntentPath,
  [string]$OutJson = 'out/db/db-table-lint.json',
  [switch]$FailOnError
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

function Ensure-Dir([string]$p) {
  if (-not $p) { return }
  if (-not (Test-Path -LiteralPath $p)) { New-Item -ItemType Directory -Force -Path $p | Out-Null }
}

function Read-Json($p) {
  if (-not (Test-Path -LiteralPath $p)) { throw "Intent not found: $p" }
  return (Get-Content -LiteralPath $p -Raw | ConvertFrom-Json)
}

function Add-Issue([System.Collections.Generic.List[object]]$list, [string]$severity, [string]$code, [string]$message, [string]$field = '', [string]$suggestion = '') {
  $list.Add([ordered]@{
    severity = $severity
    code = $code
    field = $field
    message = $message
    suggestion = $suggestion
  }) | Out-Null
}

function Is-SnakeLower([string]$s) {
  if (-not $s) { return $false }
  return ($s -match '^[a-z][a-z0-9_]*$')
}

function Is-UpperIdent([string]$s) {
  if (-not $s) { return $false }
  return ($s -match '^[A-Z][A-Z0-9_]*$')
}

function Is-SqlTypeAllowed([string]$t) {
  if (-not $t) { return $false }
  $x = ($t.Trim().ToLowerInvariant() -replace '\s+','')
  if ($x -match '^(int|bigint|bit|date|datetime|datetime2(\(\d+\))?|uniqueidentifier|float|real|money|smallmoney)$') { return $true }
  if ($x -match '^(nvarchar|varchar|nchar|char)\((max|\d{1,4})\)$') { return $true }
  if ($x -match '^decimal\(\d{1,2},\d{1,2}\)$') { return $true }
  if ($x -match '^varbinary\((max|\d{1,4})\)$') { return $true }
  return $false
}

function Normalize-SqlTypeKey([string]$t) {
  if (-not $t) { return '' }
  return (($t.Trim().ToLowerInvariant()) -replace '\s+','')
}

function Normalize-DefaultKey([string]$d) {
  if ($null -eq $d) { return '' }
  $x = ('' + $d).Trim()
  if (-not $x) { return '' }
  $x = ($x -replace '\s+','').ToUpperInvariant()
  if ($x.StartsWith('(') -and $x.EndsWith(')') -and $x.Length -gt 2) {
    $x = $x.Substring(1, $x.Length - 2)
  }
  return $x
}

function Find-Col([object[]]$cols, [string]$name) {
  foreach ($c in @($cols)) {
    if (-not $c) { continue }
    $n = [string]$c.name
    if ($n -and $name -and ($n.ToLowerInvariant() -eq $name.ToLowerInvariant())) { return $c }
  }
  return $null
}

$errors = [System.Collections.Generic.List[object]]::new()
$warnings = [System.Collections.Generic.List[object]]::new()

$intent = Read-Json $IntentPath
$action = [string]$intent.action
if (-not $action) { throw "Intent missing action" }
if ($action -ne 'db-table:create' -and $action -ne 'db.table.create') {
  Add-Issue $errors 'error' 'intent.action.invalid' "Unsupported action: $action" 'action' "Use action 'db-table:create'."
}

$p = $intent.params
if (-not $p) { Add-Issue $errors 'error' 'intent.params.missing' 'Intent params missing' 'params' '' }

$schema = if ($p) { Get-StringProp $p 'schema' '' } else { '' }
$table  = if ($p) { Get-StringProp $p 'table' '' } else { '' }

if (-not $schema) { Add-Issue $errors 'error' 'schema.missing' 'schema is required' 'params.schema' 'Use e.g. PORTAL.' }
elseif (-not (Is-UpperIdent $schema)) {
  Add-Issue $warnings 'warning' 'schema.naming' "Schema '$schema' non rispetta lo standard (MAIUSCOLO + underscore)." 'params.schema' "Esempio: PORTAL."
}

if (-not $table) { Add-Issue $errors 'error' 'table.missing' 'table is required' 'params.table' 'Use snake_case (es. user_notification_settings).' }
elseif (-not (Is-SnakeLower $table)) {
  Add-Issue $warnings 'warning' 'table.naming' "Table '$table' non rispetta lo standard (snake_case minuscolo)." 'params.table' "Esempio: user_notification_settings."
}

$cols = @()
$colsProp = if ($p) { Get-Prop $p 'columns' } else { $null }
if ($colsProp) { $cols = @($colsProp) }
if ($cols.Count -eq 0) { Add-Issue $errors 'error' 'columns.empty' 'columns[] is required' 'params.columns' 'Aggiungi almeno 1 colonna.' }

# Column checks
$seen = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
$pkCount = 0
foreach ($c in @($cols)) {
  $name = Get-StringProp $c 'name' ''
  $type = Get-StringProp $c 'sql_type' ''
  if (-not $name) { Add-Issue $errors 'error' 'column.name.missing' 'Column name missing' 'params.columns[].name' ''; continue }

  if (-not $seen.Add($name)) {
    Add-Issue $errors 'error' 'column.name.duplicate' "Duplicate column name: $name" ("params.columns[$name].name") 'Rimuovi/rinomina una delle colonne duplicate.'
  }

  if (-not (Is-SnakeLower $name)) {
    Add-Issue $warnings 'warning' 'column.naming' "Column '$name' non rispetta lo standard (snake_case minuscolo)." ("params.columns[$name].name") ''
  }

  if (-not $type) { Add-Issue $errors 'error' 'column.type.missing' "sql_type missing for column '$name'" ("params.columns[$name].sql_type") ''; continue }
  if (-not (Is-SqlTypeAllowed $type)) {
    Add-Issue $warnings 'warning' 'column.type.unusual' "sql_type '$type' per '$name' non è nella allowlist (verificare)." ("params.columns[$name].sql_type") 'Usa tipi standard (int/nvarchar(n)/datetime2/uniqueidentifier/decimal(p,s)/...).'
  }

  $pii = Get-StringProp $c 'pii' 'none'
  if ($pii -notin @('none','low','high')) {
    Add-Issue $warnings 'warning' 'column.pii.invalid' "PII value '$pii' per '$name' non valida (none|low|high)." ("params.columns[$name].pii") 'Imposta none/low/high.'
  }

  $n = $name.ToLowerInvariant()
  if ($n -match '(email|phone|mobile|pec|cf|codice_fiscale|piva|vat|address|indirizzo)') {
    if ($pii -eq 'none') {
      Add-Issue $warnings 'warning' 'column.pii.suspect' "La colonna '$name' sembra PII ma pii=none." ("params.columns[$name].pii") 'Valuta pii=low/high e masking/RLS.'
    }
  }

  if (Get-BoolProp $c 'pk' $false) { $pkCount++ }
  if ((Get-BoolProp $c 'identity' $false) -and ($type.Trim().ToLowerInvariant() -notmatch '^int|^bigint')) {
    Add-Issue $warnings 'warning' 'column.identity.type' "IDENTITY su '$name' con tipo '$type' (di solito int/bigint)." ("params.columns[$name]") 'Valuta int IDENTITY oppure rimuovi identity.'
  }
}

if ($pkCount -eq 0) {
  Add-Issue $warnings 'warning' 'table.pk.missing' 'Nessuna colonna marcata pk=true (consigliato avere una PK).' 'params.columns' 'Marca una colonna pk=true (tipicamente id int identity).'
}

# Tenanting / RLS checks
$tenantColumn = ''
$rlsRequired = $false
$tenanting = if ($p) { Get-Prop $p 'tenanting' } else { $null }
if ($tenanting) {
  $tenantColumn = Get-StringProp $tenanting 'tenant_column' ''
  $rlsRequired = Get-BoolProp $tenanting 'rls_required' $false
}
if ($rlsRequired -and -not $tenantColumn) {
  Add-Issue $errors 'error' 'rls.tenant_column.missing' 'tenanting.tenant_column è richiesto quando rls_required=true.' 'params.tenanting.tenant_column' 'Imposta tenant_id (o equivalente).'
}
if ($tenantColumn) {
  if (-not $seen.Contains($tenantColumn)) {
    Add-Issue $errors 'error' 'tenant.column.missing' "tenant_column '$tenantColumn' non esiste tra le colonne." 'params.tenanting.tenant_column' 'Aggiungi la colonna oppure correggi il nome.'
  }
  $hasTenantInIndex = $false
  $indexesProp = if ($p) { Get-Prop $p 'indexes' } else { $null }
  foreach ($ix in @($indexesProp)) {
    $c0 = @((Get-Prop $ix 'columns'))
    if ($c0.Count -gt 0 -and ([string]$c0[0]).ToLowerInvariant() -eq $tenantColumn.ToLowerInvariant()) {
      $hasTenantInIndex = $true
      break
    }
  }
  if (-not $hasTenantInIndex) {
    Add-Issue $warnings 'warning' 'tenant.index.missing' "Manca un indice che inizi con '$tenantColumn' (consigliato per query multi-tenant)." 'params.indexes' "Aggiungi index su ${tenantColumn};<chiave> (unique o non-unique)."
  }
}

# includeAudit / includeSoftDelete semantics (generator adds standard columns)
$includeAudit = $false
$includeSoftDelete = $false
if ($p) {
  $includeAudit = Get-BoolProp $p 'includeAudit' $false
  $includeSoftDelete = Get-BoolProp $p 'includeSoftDelete' $false
}

function Check-StandardCol([string]$flagName, [string]$colName, [string]$expectedTypeRegex, [bool]$expectedNullable, [string]$expectedDefaultRegex = '') {
  $col = Find-Col -cols $cols -name $colName
  if (-not $col) {
    Add-Issue $warnings 'warning' "$flagName.column.autogen" "Con $flagName=true la colonna standard '$colName' verra generata automaticamente (non inserirla a mano salvo necessita)." "params.columns[$colName]" 'Lascia la colonna assente (oppure definiscila uguale allo standard).'
    return
  }

  $t = Normalize-SqlTypeKey (Get-StringProp $col 'sql_type' '')
  if (-not $t -or ($t -notmatch $expectedTypeRegex)) {
    Add-Issue $errors 'error' "$flagName.column.type" "La colonna standard '$colName' ha sql_type='$(Get-StringProp $col 'sql_type' '')' (atteso ~ /$expectedTypeRegex/)." "params.columns[$colName].sql_type" "Allinea il tipo allo standard o rimuovi la colonna e lascia che l'agente la generi."
  }

  $nullable = $true
  if ($null -ne (Get-Prop $col 'nullable')) { $nullable = Get-BoolProp $col 'nullable' $true }
  if ($nullable -ne $expectedNullable) {
    Add-Issue $errors 'error' "$flagName.column.nullable" "La colonna standard '$colName' ha nullable=$nullable (atteso $expectedNullable)." "params.columns[$colName].nullable" "Allinea nullable allo standard o rimuovi la colonna e lascia che l'agente la generi."
  }

  if ($expectedDefaultRegex) {
    $d = Normalize-DefaultKey (Get-Prop $col 'default')
    if (-not $d -or ($d -notmatch $expectedDefaultRegex)) {
      Add-Issue $warnings 'warning' "$flagName.column.default" "La colonna standard '$colName' ha default='$(Get-StringProp $col 'default' '')' (atteso ~ /$expectedDefaultRegex/)." "params.columns[$colName].default" "Allinea il default allo standard (oppure rimuovi la colonna e lascia che l'agente la generi)."
    }
  }
}

if ($includeAudit) {
  Check-StandardCol -flagName 'includeAudit' -colName 'created_by' -expectedTypeRegex '^nvarchar\\(255\\)$' -expectedNullable:$false -expectedDefaultRegex "^(N)?'MANUAL'$"
  Check-StandardCol -flagName 'includeAudit' -colName 'created_at' -expectedTypeRegex '^datetime2(\\(\\d+\\))?$' -expectedNullable:$false -expectedDefaultRegex '^SYSUTCDATETIME\\(\\)$'
  Check-StandardCol -flagName 'includeAudit' -colName 'updated_at' -expectedTypeRegex '^datetime2(\\(\\d+\\))?$' -expectedNullable:$false -expectedDefaultRegex '^SYSUTCDATETIME\\(\\)$'
}
if ($includeSoftDelete) {
  Check-StandardCol -flagName 'includeSoftDelete' -colName 'is_deleted' -expectedTypeRegex '^bit$' -expectedNullable:$false -expectedDefaultRegex '^0$'
  Check-StandardCol -flagName 'includeSoftDelete' -colName 'deleted_at' -expectedTypeRegex '^datetime2(\\(\\d+\\))?$' -expectedNullable:$true
  Check-StandardCol -flagName 'includeSoftDelete' -colName 'deleted_by' -expectedTypeRegex '^nvarchar\\(255\\)$' -expectedNullable:$true
}

# Outputs
$report = [ordered]@{
  ok = ($errors.Count -eq 0)
  action = $action
  input = [ordered]@{
    intentPath = $IntentPath.Replace([char]92,'/')
    schema = $schema
    table = $table
  }
  summary = [ordered]@{
    errors = $errors.Count
    warnings = $warnings.Count
  }
  errors = @($errors)
  warnings = @($warnings)
}

$outDir = Split-Path -Parent $OutJson
if ($outDir) { Ensure-Dir $outDir }
$json = $report | ConvertTo-Json -Depth 10
Set-Content -LiteralPath $OutJson -Value $json -Encoding UTF8
Write-Output $json
if ($FailOnError -and -not $report.ok) { exit 1 }
