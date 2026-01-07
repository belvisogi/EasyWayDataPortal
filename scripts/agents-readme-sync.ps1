Param(
  [string]$AgentsDir = 'agents',
  [string]$ReadmePath = 'agents/README.md',
  [ValidateSet('check','fix')]
  [string]$Mode = 'check'
)

$ErrorActionPreference = 'Stop'

if (-not (Test-Path $AgentsDir)) { throw "AgentsDir not found: $AgentsDir" }
if (-not (Test-Path $ReadmePath)) { throw "README not found: $ReadmePath" }

$folders = Get-ChildItem $AgentsDir -Directory | Where-Object { $_.Name -notin @('kb','logs','core') } | Sort-Object Name
$rows = @()
foreach ($f in $folders) {
  $manifest = Join-Path $f.FullName 'manifest.json'
  $desc = ''
  if (Test-Path $manifest) {
    try {
      $json = Get-Content $manifest -Raw | ConvertFrom-Json
      $desc = $json.description
      if (-not $desc) { $desc = $json.role }
      if (-not $desc) { $desc = $json.name }
    } catch { $desc = '' }
  }
  if (-not $desc) { $desc = 'TODO - aggiungere descrizione in manifest.json' }
  $rows += [pscustomobject]@{
    name = $f.Name
    desc = $desc
    manifest = if (Test-Path $manifest) { 'manifest.json' } else { '' }
  }
}

$table = @()
$table += '| Agent                    | Manifest      | Descrizione breve                                 | Template/Ricetta demo       |'
$table += '|--------------------------|--------------|--------------------------------------------------|-----------------------------|'
foreach ($r in $rows) {
  $agent = $r.name.PadRight(24)
  $manifest = ($r.manifest).PadRight(12)
  $desc = $r.desc
  $table += ('| {0} | {1} | {2} | templates/, doc/ |' -f $agent, $manifest, $desc)
}

$readme = Get-Content -Raw -Path $ReadmePath
$pattern = '(?s)\| Agent\s+\| Manifest\s+\| Descrizione breve\s+\| Template/Ricetta demo\s+\|.*?\r?\n\r?\n'
if ($readme -notmatch $pattern) { throw "Tabella non trovata in README" }
$replacement = ($table -join "`n") + "`n`n"
$expected = [regex]::Replace($readme, $pattern, $replacement)

if ($expected -eq $readme) {
  Write-Output "OK: $ReadmePath gia' allineato"
  exit 0
}

if ($Mode -eq 'check') {
  $names = ($rows | ForEach-Object { $_.name }) -join ', '
  Write-Host ("Agent rilevati: {0}" -f $names)
  Write-Error "DRIFT: $ReadmePath non e' allineato con agents/*/manifest.json. Proposta fix: pwsh scripts/agents-readme-sync.ps1 -Mode fix"
  exit 2
}

Set-Content -Path $ReadmePath -Value $expected -Encoding UTF8
Write-Output "Updated $ReadmePath"
