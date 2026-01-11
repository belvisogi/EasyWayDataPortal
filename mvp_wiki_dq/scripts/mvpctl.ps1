param(
  [ValidateSet('azuredevops','confluence')]
  [string]$Target,

  [ValidateSet('plan','apply')]
  [string]$Mode = 'plan',

  [string]$WikiPath,

  [switch]$OpenGraph,

  [switch]$NonInteractive
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Step([string]$stage, [string]$outcome, [string]$reason, [string]$next, [string[]]$artifacts) {
  return [pscustomobject]@{
    timestamp = (Get-Date).ToString('o')
    stage = $stage
    outcome = $outcome
    reason = $reason
    next = $next
    decision_trace_id = $global:decisionTraceId
    artifacts = @($artifacts | Where-Object { $_ })
  }
}

function Require([bool]$cond, [string]$message) { if (-not $cond) { throw $message } }

function Prompt-Choice([string]$message, [string[]]$choices) {
  Write-Host $message
  for ($i=0; $i -lt $choices.Count; $i++) { Write-Host ("  [{0}] {1}" -f ($i+1), $choices[$i]) }
  while ($true) {
    $raw = Read-Host "Seleziona (1-$($choices.Count))"
    $n = 0
    if ([int]::TryParse($raw, [ref]$n) -and $n -ge 1 -and $n -le $choices.Count) { return $choices[$n-1] }
    Write-Host "Input non valido."
  }
}

function Normalize-RepoPath([string]$p) {
  if ([string]::IsNullOrWhiteSpace($p)) { return $null }
  $rp = Resolve-Path -LiteralPath $p -ErrorAction Stop
  return $rp.Path
}

function Ensure-WikiPath([string]$p) {
  $full = Normalize-RepoPath $p
  Require (-not [string]::IsNullOrWhiteSpace($full)) "WikiPath mancante."
  Require (Test-Path -LiteralPath $full) "WikiPath non esiste: $full"
  $md = Get-ChildItem -LiteralPath $full -Recurse -Filter *.md -File -ErrorAction SilentlyContinue | Select-Object -First 1
  Require ($null -ne $md) "Nessun file .md trovato sotto: $full"
  return $full
}

function Print-Ado-Guidance() {
  @"
Azure DevOps supportato nel MVP in due modalita':

1) ADO Wiki (Git) -> consigliato (offline)
   - Clona il repo wiki sul PC (oppure scaricalo).
   - Passa la cartella locale come WikiPath (root che contiene i .md).

2) ADO via REST API (senza clone)
   - Non implementato nel MVP (richiederebbe PAT + network).

"@ | Write-Host
}

$global:decisionTraceId = [Guid]::NewGuid().ToString('N').Substring(0, 12)
$timeline = New-Object System.Collections.Generic.List[object]

try {
  if (-not $Target) {
    if ($NonInteractive) { throw "Target mancante (usa -Target azuredevops|confluence)." }
    $Target = Prompt-Choice "Dove vuoi lavorare con il MVP Wiki DQ?" @('azuredevops','confluence')
  }

  if ($Target -eq 'azuredevops') {
    $timeline.Add((Step -stage 'select-target' -outcome 'ok' -reason 'Target scelto' -next 'Raccogliere wiki locale' -artifacts @())) | Out-Null
    Print-Ado-Guidance

    if (-not $WikiPath) {
      if ($NonInteractive) { throw "WikiPath mancante (per ADO serve una cartella locale con .md)." }
      $WikiPath = Read-Host "Inserisci path locale della wiki (cartella con .md)"
    }
    $resolvedWiki = Ensure-WikiPath $WikiPath
    $relWiki = [IO.Path]::GetRelativePath((Get-Location).Path, $resolvedWiki).Replace([char]92,'/')

    $timeline.Add((Step -stage 'resolve-wiki' -outcome 'ok' -reason "WikiPath valido: $relWiki" -next 'Eseguire scorecard DQ' -artifacts @($relWiki))) | Out-Null

    $scoreCmd = "pwsh scripts/docs-dq-scorecard.ps1 -WikiPath `"$relWiki`""
    if ($Mode -eq 'apply') { $scoreCmd = $scoreCmd + " -UpdateBoard -WhatIf`:$false" }

    $timeline.Add((Step -stage 'run-scorecard' -outcome 'running' -reason $Mode -next 'Aprire artifact in out/ e board wiki' -artifacts @())) | Out-Null
    Invoke-Expression $scoreCmd | Out-Null
    $timeline.Add((Step -stage 'run-scorecard' -outcome 'ok' -reason 'Completato' -next 'Aprire board e (opz.) graph view' -artifacts @("out/scorecard.wiki.json","out/backlog.wiki.json","out/board.preview.md"))) | Out-Null

    if ($OpenGraph) {
      $graphCmd = "pwsh scripts/wiki-graph-view.ps1 -WikiPath `"$relWiki`" -Open"
      $timeline.Add((Step -stage 'graph-view' -outcome 'running' -reason 'OpenGraph' -next 'Usare hover/click per esplorare legami' -artifacts @("out/graph-view.html"))) | Out-Null
      Invoke-Expression $graphCmd | Out-Null
      $timeline.Add((Step -stage 'graph-view' -outcome 'ok' -reason 'Creato e aperto' -next 'Triage orfani e link rotti' -artifacts @("out/graph-view.html"))) | Out-Null
    }

    $result = [pscustomobject]@{
      ok = $true
      target = $Target
      mode = $Mode
      wikiPath = $relWiki
      decision_trace_id = $global:decisionTraceId
      next = @(
        "Apri: $relWiki/board.wiki.md"
        "Se vuoi solo lint: pwsh scripts/wiki-links.ps1 -Path `"$relWiki`" -FailOnError"
        "Per orfani: pwsh scripts/wiki-orphans.ps1 -WikiPath `"$relWiki`""
      )
      timeline = @($timeline.ToArray())
    }
    Write-Output ($result | ConvertTo-Json -Depth 6)
    exit 0
  }

  if ($Target -eq 'confluence') {
    $timeline.Add((Step -stage 'select-target' -outcome 'ok' -reason 'Target scelto' -next 'Validare intent Confluence' -artifacts @())) | Out-Null
    $intentPath = "intents/confluence.params.json"
    Require (Test-Path -LiteralPath $intentPath) "Intent Confluence mancante: $intentPath"

    $timeline.Add((Step -stage 'intent' -outcome 'ok' -reason "Trovato: $intentPath" -next 'Eseguire PlanOnly (no network)' -artifacts @($intentPath))) | Out-Null

    $cmd = "pwsh scripts/confluence-board.ps1 -IntentPath `"$intentPath`" -PlanOnly"
    if ($Mode -eq 'apply') {
      $cmd = "pwsh scripts/confluence-board.ps1 -IntentPath `"$intentPath`" -Export -UpdateBoard -WhatIf"
    }

    $timeline.Add((Step -stage 'run' -outcome 'running' -reason $Mode -next 'Rivedere piano/output e poi (opz.) apply con WhatIf:$false' -artifacts @())) | Out-Null
    Invoke-Expression $cmd | Out-Null
    $timeline.Add((Step -stage 'run' -outcome 'ok' -reason 'Completato' -next 'Se serve scrivere su Confluence: rieseguire con -WhatIf:$false (HITL)' -artifacts @("out/confluence"))) | Out-Null

    $result = [pscustomobject]@{
      ok = $true
      target = $Target
      mode = $Mode
      decision_trace_id = $global:decisionTraceId
      next = @(
        "Configura: mvp_wiki_dq/intents/confluence.params.json (baseUrl/spaceKey/pageId)"
        "Imposta env: CONFLUENCE_EMAIL, CONFLUENCE_API_TOKEN"
        "Esegui apply (HITL): pwsh scripts/confluence-board.ps1 -IntentPath `"$intentPath`" -Export -UpdateBoard -WhatIf`:$false"
      )
      timeline = @($timeline.ToArray())
    }
    Write-Output ($result | ConvertTo-Json -Depth 6)
    exit 0
  }

  throw "Target non supportato: $Target"
} catch {
  $timeline.Add((Step -stage 'error' -outcome 'error' -reason $_.Exception.Message -next 'Correggere input e riprovare' -artifacts @())) | Out-Null
  $result = [pscustomobject]@{
    ok = $false
    target = $Target
    mode = $Mode
    decision_trace_id = $global:decisionTraceId
    error = $_.Exception.Message
    timeline = @($timeline.ToArray())
  }
  Write-Output ($result | ConvertTo-Json -Depth 6)
  exit 1
}

