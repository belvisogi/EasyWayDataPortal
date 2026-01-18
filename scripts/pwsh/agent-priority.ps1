Param(
  [Parameter(Mandatory=$true)][string]$Agent,
  [string]$Intent,
  [string]$Env = ($env:ENVIRONMENT ?? 'local'),
  [string]$Branch,
  [switch]$UseGitDiff,
  [string[]]$ChangedPaths
)

$ErrorActionPreference = 'Stop'

function Detect-Branch {
  try { $b = git rev-parse --abbrev-ref HEAD 2>$null; if ($LASTEXITCODE -eq 0 -and $b) { return $b.Trim() } } catch {}
  return $null
}

function Get-GitChangedPaths {
  try {
    $null = git rev-parse --is-inside-work-tree 2>$null; if ($LASTEXITCODE -ne 0) { return @() }
    $base = (git rev-parse HEAD~1 2>$null)
    if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($base)) {
      return (git ls-files -m -o --exclude-standard)
    }
    return (git diff --name-only $base HEAD)
  } catch { return @() }
}

function Glob-Match($pattern,$path){
  $p = ($pattern -replace '\\','/')
  $p = [Regex]::Escape($p)
  $p = $p -replace '\*\*', '.*'
  $p = $p -replace '(?<!\.)\*', '[^/]*'
  $rx = "^$p$"
  $n = ($path -replace '\\','/')
  return ($n -match $rx)
}

function Rule-Matches($rule,$ctx){
  $w = $rule.when
  if ($w -eq $null) { return $true }
  if ($w.intents -and $ctx.Intent) {
    $ok = $false
    foreach ($re in $w.intents) { if ($ctx.Intent -match $re) { $ok = $true; break } }
    if (-not $ok) { return $false }
  }
  if ($w.branch -and $ctx.Branch) {
    if (-not ($w.branch -contains $ctx.Branch)) { return $false }
  }
  if ($w.env -and $ctx.Env) {
    if (-not ($w.env -contains $ctx.Env)) { return $false }
  }
  if ($w.changedPaths -and $ctx.ChangedPaths) {
    $hit = $false
    foreach ($pat in $w.changedPaths) {
      foreach ($fp in $ctx.ChangedPaths) { if (Glob-Match $pat $fp) { $hit = $true; break } }
      if ($hit) { break }
    }
    if (-not $hit) { return $false }
  }
  if ($w.varEquals) {
    foreach ($k in $w.varEquals.Keys) {
      $expected = [string]$w.varEquals[$k]
      $actual = [string]([Environment]::GetEnvironmentVariable($k))
      if ($actual -ne $expected) { return $false }
    }
  }
  return $true
}

try {
  $prioPath = Join-Path (Join-Path 'agents' $Agent) 'priority.json'
  if (-not (Test-Path $prioPath)) { Write-Output (@{ showChecklist=$false } | ConvertTo-Json -Compress); exit 0 }
  $rules = (Get-Content $prioPath -Raw | ConvertFrom-Json).rules
  if (-not $rules) { Write-Output (@{ showChecklist=$false } | ConvertTo-Json -Compress); exit 0 }

  $ctx = [ordered]@{}
  $ctx.Intent = $Intent
  $ctx.Env = $Env
  $ctx.Branch = if ($Branch) { $Branch } else { Detect-Branch }
  $paths = @()
  if ($ChangedPaths) { $paths += $ChangedPaths }
  if ($UseGitDiff) { $paths += (Get-GitChangedPaths) }
  $ctx.ChangedPaths = $paths | Sort-Object -Unique

  $matched = @()
  foreach ($r in $rules) { if (Rule-Matches $r $ctx) { $matched += $r } }
  if ($matched.Count -eq 0) { Write-Output (@{ showChecklist=$false } | ConvertTo-Json -Compress); exit 0 }

  # pick highest severity
  $sevOrder = @{ mandatory=2; advisory=1 }
  $top = ($matched | Sort-Object { -$sevOrder[$_.severity] } | Select-Object -First 1).severity
  $items = @()
  $ids = @()
  foreach ($m in $matched) { if ($m.checklist) { $items += $m.checklist }; $ids += $m.id }
  $items = $items | Where-Object { $_ } | Sort-Object -Unique

  $out = [ordered]@{
    showChecklist = $true
    severity = $top
    items = $items
    matchedRules = $ids
    context = $ctx
  }
  Write-Output ($out | ConvertTo-Json -Depth 6)
} catch {
  Write-Output (@{ showChecklist=$false; error=$_.Exception.Message } | ConvertTo-Json -Compress)
  exit 0
}

