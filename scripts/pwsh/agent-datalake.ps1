<#
.SYNOPSIS
  Agent Datalake – Gestione operativa e compliance del Datalake EasyWayDataPortal

.DESCRIPTION
  Automatizza naming, ACL, audit, retention, export log e policy del Datalake secondo le regole definite in agents/agent_datalake/priority.json.

.PARAMETER Naming
  Esegue controlli e provisioning naming/struttura cartelle.

.PARAMETER ACL
  Verifica e applica policy IAM/ACL.

.PARAMETER Retention
  Applica e verifica policy di retention.

.PARAMETER ExportLog
  Automatizza export log e audit trail.

.PARAMETER All
  Esegue tutte le attività.

.PARAMETER WhatIf
  Simula le operazioni senza eseguirle.

.EXAMPLE
  pwsh scripts/agent-datalake.ps1 -All

.NOTES
  Da estendere con logica operativa. Richiede permessi su Azure Storage/Datalake, azcopy, Terraform.
#>

param(
  [switch]$Naming,
  [switch]$ACL,
  [switch]$Retention,
  [switch]$ExportLog,
  [switch]$All,
  [switch]$WhatIf,
  [string]$IntentPath,
  [switch]$NonInteractive,
  [switch]$LogEvent
)

$ErrorActionPreference = 'Stop'

function Read-Intent($path) {
  if (-not $path) { return $null }
  if (-not (Test-Path $path)) { throw "Intent file not found: $path" }
  (Get-Content -Path $path -Raw) | ConvertFrom-Json
}

function Write-Event($obj) {
  $logDir = Join-Path 'agents' 'logs'
  if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Force -Path $logDir | Out-Null }
  $logPath = Join-Path $logDir 'events.jsonl'
  ($obj | ConvertTo-Json -Depth 6) | Out-File -FilePath $logPath -Append -Encoding utf8
}

function Out-Result($result) { $result | ConvertTo-Json -Depth 8 | Write-Output }

function Compute-ExpectedPaths([string]$tenant) {
  $areas = @('landing','staging','official','invalidrows','technical')
  return $areas | ForEach-Object { "$_/$tenant/" }
}

function Diff-Paths($expected, $current) {
  $curSet = New-Object System.Collections.Generic.HashSet[string]
  foreach ($p in $current) { [void]$curSet.Add(($p.Trim('/')).ToLower()) }
  $changes = @()
  foreach ($e in $expected) {
    $key = ($e.Trim('/')).ToLower()
    if (-not $curSet.Contains($key)) {
      $changes += @{ type='create-path'; path=$e }
    }
  }
  return $changes
}

$intent = Read-Intent $IntentPath
$now = (Get-Date).ToUniversalTime().ToString('o')

if ($All -or $Naming) {
  $p = $intent?.params
  $tenant = $p?.tenantId
  $filesystem = $p?.filesystem
  $current = @($p?.currentPaths)
  if ((-not $current) -or $current.Count -eq 0) {
    $current = & $function:Read-PathsFromFile $p?.currentPathsFile
  }
  if (-not $tenant) { $tenant = 'tenant01' }
  $expected = Compute-ExpectedPaths -tenant $tenant
  $changes = if ($current -and $current.Count -gt 0) { Diff-Paths -expected $expected -current $current } else { $expected | ForEach-Object { @{ type='create-path'; path=$_ } } }

  $result = [ordered]@{
    action = 'dlk-ensure-structure'
    ok = $true
    whatIf = $true
    nonInteractive = [bool]$NonInteractive
    correlationId = $intent?.correlationId
    startedAt = $now
    finishedAt = (Get-Date).ToUniversalTime().ToString('o')
    output = [ordered]@{
      filesystem = $filesystem
      tenantId = $tenant
      expectedPaths = $expected
      changesPreview = $changes
      summary = ("ensure-structure tenant " + $tenant + ": expected=" + $expected.Count + ", missing=" + $changes.Count)
    }
  }
  $result.contractId = 'action-result'
  $result.contractVersion = '1.0'
  if ($LogEvent) { Write-Event ($result + @{ event='agent-datalake'; govApproved=$false }) }
  Out-Result $result
  exit 0
}

if ($ACL) {
  $p = $intent?.params
  $path = $p?.path
  $acl = @($p?.acl)
  # Stub diff-only
  $result = [ordered]@{
    action = 'dlk-apply-acl'
    ok = $true
    whatIf = $true
    nonInteractive = [bool]$NonInteractive
    correlationId = $intent?.correlationId
    startedAt = $now
    finishedAt = (Get-Date).ToUniversalTime().ToString('o')
    output = [ordered]@{
      path = $path
      proposedAcl = $acl
      diff = @(@{ path=$path; current='unknown'; proposed=($acl|ConvertTo-Json -Compress); principal='various' })
      summary = ("apply-acl path " + $path + ": entries=" + ($acl.Count))
    }
  }
  $result.contractId = 'action-result'
  $result.contractVersion = '1.0'
  if ($LogEvent) { Write-Event ($result + @{ event='agent-datalake'; govApproved=$false }) }
  Out-Result $result
  exit 0
}

if ($Retention) {
  $p = $intent?.params
  $rules = @($p?.rules)
  $result = [ordered]@{
    action = 'dlk-set-retention'
    ok = $true
    whatIf = $true
    nonInteractive = [bool]$NonInteractive
    correlationId = $intent?.correlationId
    startedAt = $now
    finishedAt = (Get-Date).ToUniversalTime().ToString('o')
    output = [ordered]@{
      policies = $rules
      summary = ("set-retention policies=" + ($rules.Count))
    }
  }
  $result.contractId = 'action-result'
  $result.contractVersion = '1.0'
  if ($LogEvent) { Write-Event ($result + @{ event='agent-datalake'; govApproved=$false }) }
  Out-Result $result
  exit 0
}

if ($ExportLog) {
  $p = $intent?.params
  $result = [ordered]@{
    action = 'dlk-export-log'
    ok = $true
    whatIf = $true
    nonInteractive = [bool]$NonInteractive
    correlationId = $intent?.correlationId
    startedAt = $now
    finishedAt = (Get-Date).ToUniversalTime().ToString('o')
    output = [ordered]@{
      plan = [ordered]@{
        source = $p?.source
        targetPath = $p?.targetPath
        schedule = $p?.schedule
      }
      summary = ("export-log " + ($p?.source) + " -> " + ($p?.targetPath))
    }
  }
  $result.contractId = 'action-result'
  $result.contractVersion = '1.0'
  if ($LogEvent) { Write-Event ($result + @{ event='agent-datalake'; govApproved=$false }) }
  Out-Result $result
  exit 0
}

$actionFromIntent = $intent?.action
if ($actionFromIntent -eq 'etl-slo:validate' -or $PSBoundParameters['Action'] -eq 'etl-slo:validate') {
  $p = $intent?.params
  $specPath = $p?.specPath
  $ok = $false; $missing = @(); $spec = $null; $fmt = 'unknown'
  try {
    if (-not (Test-Path $specPath)) { throw "SLO spec non trovata: $specPath" }
    $txt = Get-Content -Raw -Path $specPath
    if ($specPath.ToLower().EndsWith('.json')) {
      $spec = $txt | ConvertFrom-Json; $fmt = 'json'
    } else { $fmt = 'yaml' }
  } catch {}
  # Validazione minima
  if ($fmt -eq 'json' -and $spec) {
    if (-not $spec.pipeline_key) { $missing += 'pipeline_key' }
    if (-not $spec.tier) { $missing += 'tier' }
    if (-not $spec.slos -or $spec.slos.Count -eq 0) { $missing += 'slos' }
    if (-not $spec.runbook_url) { $missing += 'runbook_url' }
    $ok = ($missing.Count -eq 0)
  }
  $result = [ordered]@{
    action = 'etl-slo:validate'
    ok = $ok
    whatIf = $true
    nonInteractive = [bool]$NonInteractive
    correlationId = $intent?.correlationId
    startedAt = $now
    finishedAt = (Get-Date).ToUniversalTime().ToString('o')
    output = [ordered]@{
      specPath = $specPath
      format = $fmt
      missing = $missing
      summary = (if ($ok) { 'SLO spec valida (minimi presenti)' } else { 'SLO spec incompleta: ' + ($missing -join ', ') })
    }
    contractId = 'action-result'
    contractVersion = '1.0'
  }
  if ($LogEvent) { Write-Event ($result + @{ event='agent-datalake'; govApproved=$false }) }
  Out-Result $result
  exit 0
}

Write-Output '{"ok":true,"message":"Agent Datalake stub: specificare un intent/azione"}'
$function:Read-PathsFromFile = {
  param([string]$filePath)
  if (-not $filePath) { return @() }
  if (-not (Test-Path $filePath)) { return @() }
  try {
    $txt = Get-Content -Path $filePath -Raw
    $obj = $null
    try { $obj = $txt | ConvertFrom-Json } catch { $obj = $null }
    if ($obj -and $obj.paths) { return @($obj.paths | ForEach-Object { [string]$_ }) }
    if ($obj -and $obj.currentPaths) { return @($obj.currentPaths | ForEach-Object { [string]$_ }) }
    # Fallback: treat file as newline-separated list
    return @($txt -split "\r?\n" | Where-Object { $_ -and $_.Trim() -ne '' } | ForEach-Object { $_.Trim() })
  } catch { return @() }
}
