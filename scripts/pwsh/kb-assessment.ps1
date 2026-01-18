<# 
  Script: kb-assessment.ps1
  Purpose: Validare e fare assessment della KB `agents/kb/recipes.jsonl` (JSONL, duplicati, references, campi minimi).
  Output: report JSON con summary + issues.
#>

[CmdletBinding()]
param(
  [string]$Path = "agents/kb/recipes.jsonl",
  [string]$Out = "",
  [switch]$FailOnError
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function New-Issue([string]$Kind, [string]$Id, [string]$Intent, [string]$Message, $Data) {
  return [pscustomobject]@{
    kind = $Kind
    id = $Id
    intent = $Intent
    message = $Message
    data = $Data
  }
}

$root = (Get-Location).Path
$lines = Get-Content -Path $Path
$items = New-Object System.Collections.Generic.List[object]
$issues = New-Object System.Collections.Generic.List[object]

for ($i = 0; $i -lt $lines.Count; $i++) {
  $raw = ($lines[$i] ?? "").Trim()
  if (-not $raw) { continue }
  try {
    $obj = $raw | ConvertFrom-Json -ErrorAction Stop
    $items.Add($obj)
  } catch {
    $issues.Add((New-Issue "json_parse" "" "" ("Invalid JSON at line {0}" -f ($i + 1)) @{ line = ($i + 1); error = $_.Exception.Message }))
  }
}

if ($issues.Count -eq 0) {
  $byId = $items | Group-Object id | Where-Object { $_.Count -gt 1 }
  foreach ($g in $byId) {
    $issues.Add((New-Issue "duplicate_id" $g.Name "" "Duplicate recipe id" @{ count = $g.Count }))
  }

  $required = @("id", "intent", "question", "steps", "verify", "references")
  foreach ($o in $items) {
    foreach ($k in $required) {
      if (-not ($o.PSObject.Properties.Name -contains $k)) {
        $issues.Add((New-Issue "missing_field" $o.id $o.intent ("Missing field: {0}" -f $k) @{ field = $k }))
      }
    }
    foreach ($r in @($o.references)) {
      if (-not $r) { continue }
      $p = ($r -replace "`"", "").Split("#")[0].Split(":")[0].Trim()
      if (-not $p) { continue }
      if ($p -match "^(https?://|mailto:)") { continue }
      $full = Join-Path $root $p
      if (-not (Test-Path $full)) {
        $issues.Add((New-Issue "missing_reference" $o.id $o.intent "Reference path not found" @{ reference = $r; normalized = $p }))
      }
    }
  }
}

$report = [pscustomobject]@{
  ok = ($issues.Count -eq 0)
  path = $Path
  summary = @{
    lines = $lines.Count
    items = $items.Count
    issues = $issues.Count
  }
  issues = $issues
}

$json = $report | ConvertTo-Json -Depth 8
if ($Out) {
  $outDir = Split-Path -Parent $Out
  if ($outDir -and -not (Test-Path $outDir)) { New-Item -ItemType Directory -Path $outDir -Force | Out-Null }
  Set-Content -Path $Out -Value $json -Encoding UTF8
} else {
  $json
}

if ($FailOnError -and -not $report.ok) {
  throw "KB assessment failed: $($issues.Count) issues"
}

