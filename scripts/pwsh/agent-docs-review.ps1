Param(
  [switch]$Interactive = $true,
  [switch]$All,
  [switch]$Wiki,
  [switch]$KbConsistency,
  [switch]$AddKbRecipe,
  [switch]$SyncAgentsReadme,
  [switch]$AgentsManifestAudit,
  [switch]$WhatIf,
  [switch]$LogEvent
)

$ErrorActionPreference = 'Stop'

# Remind agentic goals (if present)
try {
  $goalsPath = 'agents/goals.json'
  if (Test-Path $goalsPath) {
    $goals = Get-Content $goalsPath -Raw | ConvertFrom-Json
    if ($goals.vision) { Write-Host ("[Goal] " + $goals.vision) -ForegroundColor Green }
  }
}
catch {}

# Read wikiRoot from manifest
$manifestPath = Join-Path $PSScriptRoot '../../../../Rules/manifest.json'
$wikiRoot = 'Wiki/AdaDataProject.wiki' # Fallback
if (Test-Path $manifestPath) {
  try {
    $m = Get-Content $manifestPath -Raw | ConvertFrom-Json
    if ($m.wikiRoot) { $wikiRoot = $m.wikiRoot }
  }
  catch { Write-Warning "Failed to read manifest for wikiRoot" }
}

$wikiScripts = Join-Path $wikiRoot 'scripts'
$kbFile = 'agents/kb/recipes.jsonl'
$kbAddScript = 'scripts/agent-kb-add.ps1'

function Invoke-Task($task) {
  Write-Host ("`n==> {0}" -f $task.Name) -ForegroundColor Cyan
  Write-Host ($task.Description)
  if ($WhatIf) { Write-Host 'WhatIf: skipped execution' -ForegroundColor Yellow; return }
  & $task.Action
}

function Has-Git {
  try { $null = git --version 2>$null; return $LASTEXITCODE -eq 0 } catch { return $false }
}

$hasWiki = Test-Path $wikiScripts
$hasGit = Has-Git

# Determine changes (for advisory KB consistency)
$changedDbApi = $false; $changedAdoScripts = $false; $changedAgentsDocs = $false
if ($hasGit) {
  try {
    $base = (git rev-parse HEAD~1 2>$null)
    if ($LASTEXITCODE -eq 0 -and $base) {
      $changed = git diff --name-only $base HEAD
      foreach ($f in $changed) {
        if ($f -like 'db/*' -or $f -like '<ApiPath>/src/*') { $changedDbApi = $true }
        if ($f -like 'scripts/ado/*') { $changedAdoScripts = $true }
        if ($f -like 'Wiki/<NomeWiki>.wiki/agents-*.md') { $changedAgentsDocs = $true }
      }
    }
  }
  catch {}
}

$tasks = @()

# Conditional documentation checklist via priority rules
try {
  $prioJson = pwsh 'scripts/agent-priority.ps1' -Agent agent_docs_review -UseGitDiff -Env ($env:ENVIRONMENT ?? 'local')
  $prio = $null; try { $prio = $prioJson | ConvertFrom-Json } catch {}
  if ($prio.showChecklist -eq $true) {
    $label = if ($prio.severity -eq 'mandatory') { 'Docs Checklist (mandatory)' } else { 'Docs Checklist (advisory)' }
    $items = @(); if ($prio.items) { $items = $prio.items } else {
      $items = @('Normalize + Review + Indici', 'Anchors/index/chunks aggiornati', 'KB + pagina Wiki pertinenti aggiornate')
    }
    $tasks += [pscustomobject]@{
      Id          = 0
      Name        = $label
      Description = 'Checklist documentazione generata da regole priority; l''utente approva.'
      Recommended = $true
      Enabled     = $true
      Action      = {
        Write-Host ""; Write-Host '== Docs Checklist ==' -ForegroundColor Cyan
        foreach ($i in $items) { Write-Host ("- {0}" -f $i) }
        if ($Interactive) {
          $ans = Read-Host "Confermi la checklist? [Invio=SI / n=No]"
          if ($ans.Trim().ToLower() -eq 'n') { Write-Host 'Checklist docs non approvata (rimandata).'; return }
          Write-Host 'Checklist docs approvata.' -ForegroundColor Green
        }
        else {
          Write-Host 'Checklist proposta (modalità non interattiva)'
        }
      }
    }
  }
}
catch { Write-Warning ("Priority rules (docs) non applicabili: {0}" -f $_.Exception.Message) }
if ($hasWiki) {
  $tasks += [pscustomobject]@{
    Id          = 1
    Name        = 'Wiki Normalize & Review'
    Description = 'Normalizza la Wiki (naming/front‑matter/ancore) e rigenera indici/chunk.'
    Recommended = $true
    Enabled     = $true
    Action      = {
      if (Test-Path (Join-Path $wikiScripts 'normalize-project.ps1')) {
        pwsh (Join-Path $wikiScripts 'normalize-project.ps1') -Root $wikiRoot -EnsureFrontMatter | Out-Host
      }
      if (Test-Path (Join-Path $wikiScripts 'review-run.ps1')) {
        pwsh (Join-Path $wikiScripts 'review-run.ps1') -Root $wikiRoot -Mode kebab -CheckAnchors | Out-Host
      }
      if (Test-Path (Join-Path $wikiScripts 'generate-entities-index.ps1')) {
        pwsh (Join-Path $wikiScripts 'generate-entities-index.ps1') -Root $wikiRoot | Out-Host
      }
      if (Test-Path (Join-Path $wikiScripts 'generate-master-index.ps1')) {
        pwsh (Join-Path $wikiScripts 'generate-master-index.ps1') -Root $wikiRoot | Out-Host
      }
      if (Test-Path (Join-Path $wikiScripts 'export-chunks-jsonl.ps1')) {
        pwsh (Join-Path $wikiScripts 'export-chunks-jsonl.ps1') -Root $wikiRoot | Out-Host
      }
      if (Test-Path (Join-Path $wikiScripts 'lint-atomicity.ps1')) {
        pwsh (Join-Path $wikiScripts 'lint-atomicity.ps1') -Root $wikiRoot | Out-Host
      }
    }
  }
}

if ($SyncAgentsReadme -or $All) {
  if (Test-Path 'scripts/agents-readme-sync.ps1') {
    $tasks += [pscustomobject]@{
      Id          = 4
      Name        = 'Sync Agents README'
      Description = 'Allinea agents/README.md con le cartelle e i manifest attuali.'
      Recommended = $true
      Enabled     = $true
      Action      = {
        $out = & pwsh 'scripts/agents-readme-sync.ps1' -Mode check 2>&1 | Out-String
        if ($LASTEXITCODE -eq 0) { Write-Host $out; return }

        Write-Host $out
        if (-not $Interactive) {
          throw 'Agents README drift (non-interactive): esegui pwsh scripts/agents-readme-sync.ps1 -Mode fix e riprova.'
        }

        $ans = Read-Host "Vuoi applicare ora il fix a agents/README.md? [Invio=SI / n=No]"
        if ($ans.Trim().ToLower() -eq 'n') {
          throw "Fix rimandato dall'utente. TODO: esegui pwsh scripts/agents-readme-sync.ps1 -Mode fix"
        }

        $fixOut = & pwsh 'scripts/agents-readme-sync.ps1' -Mode fix 2>&1 | Out-String
        Write-Host $fixOut
        $recheck = & pwsh 'scripts/agents-readme-sync.ps1' -Mode check 2>&1 | Out-String
        if ($LASTEXITCODE -ne 0) {
          Write-Host $recheck
          throw 'Fix applicato ma drift ancora presente: verificare agents/README.md'
        }
        Write-Host $recheck
      }
    }
  }
}

if ($AgentsManifestAudit -or $All) {
  if (Test-Path 'scripts/agents-manifest-audit.ps1') {
    $tasks += [pscustomobject]@{
      Id          = 5
      Name        = 'Agents Manifest Audit (advisory)'
      Description = 'Analizza agents/*/manifest.json e produce lista gap per agente (RAG-ready).'
      Recommended = $true
      Enabled     = $true
      Action      = { pwsh 'scripts/agents-manifest-audit.ps1' | Out-Host }
    }
  }
}

$kbRecommended = ($changedDbApi -or $changedAdoScripts -or $changedAgentsDocs)
$tasks += [pscustomobject]@{
  Id          = 2
  Name        = 'KB Consistency (advisory)'
  Description = 'Suggerisce aggiornamento KB/Wiki quando cambiano DB/API/agents docs (controllo basato su git diff).'
  Recommended = $kbRecommended
  Enabled     = $hasGit
  Action      = {
    if (-not $hasGit) { Write-Warning 'git non disponibile, salto controllo'; return }
    try { $base = (git rev-parse HEAD~1) } catch { Write-Host 'Repo shallow o prima commit: skip'; return }
    $changed = git diff --name-only $base HEAD
    $changedDbApi = $false; $changedAdoScripts = $false; $changedAgentsDocs = $false
    foreach ($f in $changed) {
      if ($f -like 'db/*' -or $f -like '<ApiPath>/src/*' -or $f -like '<ApiPath>/src/*') { $changedDbApi = $true }
      if ($f -like 'scripts/ado/*') { $changedAdoScripts = $true }
      if ($f -like 'Wiki/<NomeWiki>.wiki/agents-*.md') { $changedAgentsDocs = $true }
    }
    $kbChanged = $false; $wikiChanged = $false
    foreach ($f in $changed) {
      if ($f -eq 'agents/kb/recipes.jsonl') { $kbChanged = $true }
      if ($f -like 'Wiki/*') { $wikiChanged = $true }
    }
    if ($changedDbApi -and (-not $kbChanged -or -not $wikiChanged)) {
      Write-Host 'KB Consistency: DA FARE -> aggiorna agents/kb/recipes.jsonl e almeno una pagina Wiki' -ForegroundColor Yellow
    }
    elseif (($changedAdoScripts -or $changedAgentsDocs) -and (-not $kbChanged)) {
      Write-Host 'KB Consistency: DA FARE -> aggiorna agents/kb/recipes.jsonl (cambi ADO/agents)' -ForegroundColor Yellow
    }
    else {
      Write-Host 'KB Consistency: OK o non rilevante'
    }
  }
}

if ((Test-Path $kbAddScript) -and (Test-Path $kbFile)) {
  $tasks += [pscustomobject]@{
    Id          = 3
    Name        = 'Aggiungi Ricetta KB (guidata)'
    Description = 'Aggiunge una nuova riga in agents/kb/recipes.jsonl con parametri minimi.'
    Recommended = $false
    Enabled     = $true
    Action      = {
      $id = Read-Host 'ID ricetta (es. kb-docs-001)'
      if ([string]::IsNullOrWhiteSpace($id)) { Write-Warning 'ID richiesto'; return }
      $intent = Read-Host 'Intent (es. wiki-normalize)'
      if ([string]::IsNullOrWhiteSpace($intent)) { Write-Warning 'Intent richiesto'; return }
      $question = Read-Host 'Domanda (es. Come normalizzare la wiki?)'
      if ([string]::IsNullOrWhiteSpace($question)) { Write-Warning 'Domanda richiesta'; return }
      $tags = Read-Host 'Tags (csv, opzionale es. docs,wiki)'
      $steps = Read-Host 'Steps (csv, opzionale)'
      $verify = Read-Host 'Verify (csv, opzionale)'
      $refs = Read-Host 'References (csv, opzionale)'
      $TagsArr = if ($tags) { $tags.Split(',').ForEach{ $_.Trim() } } else { @() }
      $StepsArr = if ($steps) { $steps.Split(',').ForEach{ $_.Trim() } } else { @() }
      $VerifyArr = if ($verify) { $verify.Split(',').ForEach{ $_.Trim() } } else { @() }
      $RefsArr = if ($refs) { $refs.Split(',').ForEach{ $_.Trim() } } else { @() }
      pwsh $kbAddScript -Id $id -Intent $intent -Question $question -Tags $TagsArr -Steps $StepsArr -Verify $VerifyArr -References $RefsArr
      Write-Host 'KB aggiornata.' -ForegroundColor Green
    }
  }
}

function Select-Tasks($tasks) {
  if ($All) { return $tasks | Where-Object Enabled }
  $explicit = @()
  if ($Wiki) { $explicit += 1 }
  if ($KbConsistency) { $explicit += 2 }
  if ($AddKbRecipe) { $explicit += 3 }
  if ($SyncAgentsReadme) { $explicit += 4 }
  if ($AgentsManifestAudit) { $explicit += 5 }
  if ($explicit.Count -gt 0) { return $tasks | Where-Object { $_.Enabled -and ($explicit -contains $_.Id) } }
  if (-not $Interactive) { return $tasks | Where-Object { $_.Enabled -and $_.Recommended } }

  Write-Host 'Proposte agente documentazione:' -ForegroundColor Green
  foreach ($t in $tasks) {
    $flag = if ($t.Recommended) { '[R]' } else { '   ' }
    $en = if ($t.Enabled) { '' } else { '(disabilitato)' }
    Write-Host (" { 0 }) { 1 } { 2 } { 3 }" -f $t.Id, $flag, $t.Name, $en)
    Write-Host ("     - { 0 }" -f $t.Description)
  }
  Write-Host ''
  $ans = Read-Host "Seleziona attività (es: 1, 3) - Invio = solo consigliate - 'all' = tutte"
  if ([string]::IsNullOrWhiteSpace($ans)) { return $tasks | Where-Object { $_.Enabled -and $_.Recommended } }
  if ($ans.Trim().ToLower() -in @('all', 'tutte', 'tutto')) { return $tasks | Where-Object Enabled }
  $nums = $ans -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ -match '^\d+$' } | ForEach-Object { [int]$_ }
  return $tasks | Where-Object { $_.Enabled -and ($nums -contains $_.Id) }
}

$selected = Select-Tasks $tasks
if (-not $selected -or $selected.Count -eq 0) { Write-Host 'Nessuna attività selezionata/applicabile.'; exit 0 }

# Esecuzione con raccolta esito
$script:EW_TaskError = $false
foreach ($t in $selected) {
  try { Invoke-Task $t } catch { $script:EW_TaskError = $true; Write-Error $_ }
}

# Logging strutturato opzionale
if ($LogEvent) {
  try {
    $artifacts = @()
    $maybe = @(
      'Wiki/<NomeWiki>.wiki/entities-index.md',
      'Wiki/<NomeWiki>.wiki/index_master.csv',
      'Wiki/<NomeWiki>.wiki/index_master.jsonl',
      'Wiki/<NomeWiki>.wiki/anchors_master.csv',
      'Wiki/<NomeWiki>.wiki/chunks_master.jsonl'
    )
    foreach ($p in $maybe) { if (Test-Path $p) { $artifacts += $p } }
    $intent = 'docs-review'
    $actor = 'agent_docs_review'
    $envName = $env:ENVIRONMENT; if ([string]::IsNullOrWhiteSpace($envName)) { $envName = 'local' }
    $outcome = 'success'; if ($script:EW_TaskError) { $outcome = 'error' }
    $notes = 'Wiki Normalize & Review'
    pwsh 'scripts/activity-log.ps1' -Intent $intent -Actor $actor -Env $envName -Outcome $outcome -Artifacts $artifacts -Notes $notes | Out-Host
  }
  catch { Write-Warning "Activity log failed: $($_.Exception.Message)" }
}

Write-Host "`nDocumentazione: attività completate." -ForegroundColor Green





$enforcerApplied = $false
try {
  pwsh 'scripts/enforcer.ps1' -Agent agent_docs_review -GitDiff -Quiet | Out-Null
  if ($LASTEXITCODE -eq 2) { Write-Error 'Enforcer: violazioni allowed_paths per agent_docs_review'; exit 2 }
  $enforcerApplied = $true
}
catch { Write-Warning ("Enforcer preflight (docs) non applicabile: { 0 }" -f $_.Exception.Message) }

