Param(
  [string]$ApiPath = "EasyWay-DataPortal/easyway-portal-api",
  [switch]$Interactive = $true,
  [switch]$All,
  [switch]$Wiki,
  [switch]$Checklist,
  [switch]$DbDrift,
  [switch]$KbConsistency,
  [switch]$GenAppSettings,
  [switch]$TerraformPlan,
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
} catch {}

function Test-Cmd($name) {
  try { $null = & $name --version 2>$null; return $true } catch { return $false }
}

function Read-EnvLocal($path) {
  $envFile = Join-Path $path '.env.local'
  if (-not (Test-Path $envFile)) { return @{} }
  $map = @{}
  Get-Content $envFile | ForEach-Object {
    if ($_ -match '^\s*#') { return }
    if ($_ -match '^(?<k>[A-Za-z0-9_]+)=(?<v>.*)$') {
      $k = $Matches['k']; $v = $Matches['v']
      $map[$k] = $v
    }
  }
  return $map
}

function Invoke-Task($task) {
  Write-Host ("`n==> {0}" -f $task.Name) -ForegroundColor Cyan
  Write-Host ($task.Description)
  if ($WhatIf) { Write-Host "WhatIf: skipped execution" -ForegroundColor Yellow; return }
  try { & $task.Action } catch { $script:EW_TaskError = $true; throw }
}

# Discover repo state
$repoRoot = (Resolve-Path '.').Path
$wikiScripts = "Wiki/EasyWayData.wiki/scripts"
$hasWiki = Test-Path $wikiScripts
$hasNode = Test-Cmd 'node'
$hasNpm  = Test-Cmd 'npm'
$hasTerraform = Test-Cmd 'terraform'

$apiExists = Test-Path $ApiPath
$envLocal = Read-EnvLocal $ApiPath
$hasEnvLocal = $envLocal.Count -gt 0
$hasDbConn = $envLocal['DB_CONN_STRING'] -or $env:DB_CONN_STRING

# git availability and diff
$hasGit = $false
try { $null = git rev-parse --is-inside-work-tree 2>$null; if ($LASTEXITCODE -eq 0) { $hasGit = $true } } catch {}

$changedDbApi = $false; $changedAdoScripts = $false; $changedAgentsDocs = $false
if ($hasGit) {
  try {
    $base = (git rev-parse HEAD~1 2>$null)
    if ($LASTEXITCODE -eq 0 -and $base) {
      $changed = git diff --name-only $base HEAD
      foreach ($f in $changed) {
        if ($f -like 'db/*' -or $f -like 'EasyWay-DataPortal/easyway-portal-api/src/*') { $changedDbApi = $true }
        if ($f -like 'scripts/ado/*') { $changedAdoScripts = $true }
        if ($f -like 'Wiki/EasyWayData.wiki/agents-*.md') { $changedAgentsDocs = $true }
      }
    }
  } catch {}
}

# Build task catalog
$tasks = @()

# Conditional governance checklist via priority rules
try {
  $prioJson = pwsh 'scripts/agent-priority.ps1' -Agent agent_governance -UseGitDiff -Env ($env:ENVIRONMENT ?? 'local') -Intent ($Intent ?? $null)
  $prio = $null; try { $prio = $prioJson | ConvertFrom-Json } catch {}
  if ($prio.showChecklist -eq $true) {
    $label = if ($prio.severity -eq 'mandatory') { 'Governance Checklist (mandatory)' } else { 'Governance Checklist (advisory)' }
    $desc = 'Checklist di governance generata da regole priority; l’utente rivede e approva.'
    $items = @(); if ($prio.items) { $items = $prio.items } else {
      $items = @(
        'EnforcerCheck Required su develop/main',
        'USE_EWCTL_GATES=true attivo',
        'Strategia Flyway: validate sempre; migrate solo develop; DBProd con approvazioni',
        "Variable Group 'EasyWay-Secrets' collegato",
        'Environment prod con approvazioni',
        'KB+Wiki aggiornate; Activity Log aggiornato'
      )
    }
    $tasks += [pscustomobject]@{
      Id = 0
      Name = $label
      Description = $desc
      Recommended = $true
      Enabled = $true
      Action = {
        Write-Host ""; Write-Host '== Governance Checklist ==' -ForegroundColor Cyan
        foreach ($i in $items) { Write-Host ("- {0}" -f $i) }
        if ($Interactive) {
          $ans = Read-Host "Confermi la checklist? [Invio=SI / n=No]"
          if ($ans.Trim().ToLower() -eq 'n') { Write-Host 'Checklist non approvata (rimandata dall’utente).'; return }
          Write-Host 'Checklist approvata dall’utente.' -ForegroundColor Green
        } else {
          Write-Host 'Checklist proposta (modalità non interattiva): vedere i riferimenti per approvare.' -ForegroundColor Yellow
        }
      }
    }
  }
} catch { Write-Warning ("Priority rules (governance) non applicabili: {0}" -f $_.Exception.Message) }

if ($hasWiki) {
  $tasks += [pscustomobject]@{
    Id = 1
    Name = 'Wiki Normalize & Review'
    Description = 'Normalizza progetto Wiki (naming/front‑matter/ancore) e ricostruisce indici/chunk.'
    Recommended = $true
    Enabled = $true
    Action = {
      if (Test-Path "$wikiScripts/normalize-project.ps1") {
        pwsh "$wikiScripts/normalize-project.ps1" -Root "Wiki/EasyWayData.wiki" -EnsureFrontMatter | Out-Host
      }
      if (Test-Path "$wikiScripts/review-run.ps1") {
        pwsh "$wikiScripts/review-run.ps1" -Root "Wiki/EasyWayData.wiki" -Mode kebab -CheckAnchors | Out-Host
      }
      if (Test-Path "$wikiScripts/generate-entities-index.ps1") {
        pwsh "$wikiScripts/generate-entities-index.ps1" -Root "Wiki/EasyWayData.wiki" | Out-Host
      }
      if (Test-Path "$wikiScripts/generate-master-index.ps1") {
        pwsh "$wikiScripts/generate-master-index.ps1" -Root "Wiki/EasyWayData.wiki" | Out-Host
      }
      if (Test-Path "$wikiScripts/export-chunks-jsonl.ps1") {
        pwsh "$wikiScripts/export-chunks-jsonl.ps1" -Root "Wiki/EasyWayData.wiki" | Out-Host
      }
      if (Test-Path "$wikiScripts/lint-atomicity.ps1") {
        pwsh "$wikiScripts/lint-atomicity.ps1" -Root "Wiki/EasyWayData.wiki" | Out-Host
      }
    }
  }
}

if ($apiExists -and $hasNode -and $hasNpm) {
  $tasks += [pscustomobject]@{
    Id = 2
    Name = 'Pre‑Deploy Checklist (API)'
    Description = 'Esegue i check su env/Auth/DB/Blob/OpenAPI (richiede Node e variabili corrette).'
    Recommended = $hasEnvLocal
    Enabled = $true
    Action = {
      Push-Location $ApiPath
      try {
        $env:CHECKLIST_OUTPUT = 'both'
        if (-not (Test-Path 'node_modules')) { npm ci }
        $out = npm run -s check:predeploy
        $out | Out-File -FilePath checklist.json -Encoding utf8
        Write-Host "Checklist scritto in $(Join-Path (Get-Location) 'checklist.json')"
      } finally { Pop-Location }
    }
  }

  $tasks += [pscustomobject]@{
    Id = 3
    Name = 'DB Drift Check'
    Description = 'Verifica oggetti minimi DB presenti (richiede connessione DB).'
    Recommended = [bool]$hasDbConn
    Enabled = $true
    Action = {
      Push-Location $ApiPath
      try {
        if (-not (Test-Path 'node_modules')) { npm ci }
        $out = npm run -s db:drift
        $out | Out-File -FilePath drift.json -Encoding utf8
        Write-Host "Drift report in $(Join-Path (Get-Location) 'drift.json')"
      } finally { Pop-Location }
    }
  }
}

$kbRecommended = ($changedDbApi -or $changedAdoScripts -or $changedAgentsDocs)
$tasks += [pscustomobject]@{
  Id = 4
  Name = 'KB Consistency (advisory)'
  Description = 'Controlla che KB (recipes.jsonl) e almeno una pagina Wiki siano aggiornate quando cambiano DB/API/agent docs.'
  Recommended = $kbRecommended
  Enabled = $hasGit
  Action = {
    if (-not $hasGit) { Write-Warning 'git non disponibile, salto controllo'; return }
    try { $base = (git rev-parse HEAD~1) } catch { Write-Host 'Repo shallow o prima commit: skip'; return }
    $changed = git diff --name-only $base HEAD
    $changedDbApi = $false; $changedAdoScripts = $false; $changedAgentsDocs = $false
    foreach ($f in $changed) {
      if ($f -like 'db/*' -or $f -like 'EasyWay-DataPortal/easyway-portal-api/src/*') { $changedDbApi = $true }
      if ($f -like 'scripts/ado/*') { $changedAdoScripts = $true }
      if ($f -like 'Wiki/EasyWayData.wiki/agents-*.md') { $changedAgentsDocs = $true }
    }
    $kbChanged = $false; $wikiChanged = $false
    foreach ($f in $changed) {
      if ($f -eq 'agents/kb/recipes.jsonl') { $kbChanged = $true }
      if ($f -like 'Wiki/*') { $wikiChanged = $true }
    }
    if ($changedDbApi -and (-not $kbChanged -or -not $wikiChanged)) {
      Write-Host 'KB Consistency: DA FARE -> aggiorna agents/kb/recipes.jsonl e almeno una pagina Wiki' -ForegroundColor Yellow
    } elseif (($changedAdoScripts -or $changedAgentsDocs) -and (-not $kbChanged)) {
      Write-Host 'KB Consistency: DA FARE -> aggiorna agents/kb/recipes.jsonl (ricetta collegata ai cambi ADO/agents)' -ForegroundColor Yellow
    } else {
      Write-Host 'KB Consistency: OK o non rilevante'
    }
  }
}

if ($apiExists -and (Test-Path (Join-Path $ApiPath '.env.local'))) {
  $tasks += [pscustomobject]@{
    Id = 5
    Name = 'Genera App Settings da .env.local'
    Description = 'Crea out/appsettings.cli.json e out/appsettings.task.json a partire dal file .env.local.'
    Recommended = $true
    Enabled = $true
    Action = {
      pwsh 'scripts/generate-appsettings.ps1' -ApiPath $ApiPath -OutDir './out'
      Get-ChildItem -Path './out' -Filter 'appsettings*.json' -ErrorAction SilentlyContinue | ForEach-Object { Write-Host "Creato: $($_.FullName)" }
    }
  }
}

if (Test-Path 'infra/terraform') {
  $tasks += [pscustomobject]@{
    Id = 6
    Name = 'Terraform Plan (infra)'
    Description = 'Esegue init/validate/plan su infra/terraform (richiede terraform).'
    Recommended = $false
    Enabled = $hasTerraform
    Action = {
      Push-Location 'infra/terraform'
      try {
        terraform init -input=false
        terraform validate
        Write-Host 'Eseguo terraform plan (variabili richieste: project_name, resource_group_name, storage_account_name, tenants)'
        terraform plan -input=false -out=tfplan | Out-Host
      } finally { Pop-Location }
    }
  }
}

# Selection logic
function Select-Tasks($tasks) {
  if ($All) { return $tasks | Where-Object Enabled }
  $explicit = @()
  if ($Wiki) { $explicit += 1 }
  if ($Checklist) { $explicit += 2 }
  if ($DbDrift) { $explicit += 3 }
  if ($KbConsistency) { $explicit += 4 }
  if ($GenAppSettings) { $explicit += 5 }
  if ($TerraformPlan) { $explicit += 6 }
  if ($explicit.Count -gt 0) { return $tasks | Where-Object { $_.Enabled -and ($explicit -contains $_.Id) } }
  if (-not $Interactive) { return $tasks | Where-Object { $_.Enabled -and $_.Recommended } }

  Write-Host "Proposte dell'agente di governance:" -ForegroundColor Green
  foreach ($t in $tasks) {
    $flag = if ($t.Recommended) { '[R]' } else { '   ' }
    $en = if ($t.Enabled) { '' } else { '(disabilitato)' }
    Write-Host (" {0}) {1} {2} {3}" -f $t.Id, $flag, $t.Name, $en)
    Write-Host ("     - {0}" -f $t.Description)
  }
  Write-Host ""
  $ans = Read-Host "Seleziona attività (es: 1,2,5) — Invio = solo consigliate — 'all' = tutte"
  if ([string]::IsNullOrWhiteSpace($ans)) {
    return $tasks | Where-Object { $_.Enabled -and $_.Recommended }
  }
  if ($ans.Trim().ToLower() -in @('all','tutte','tutto')) { return $tasks | Where-Object Enabled }
  $nums = $ans -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ -match '^\d+$' } | ForEach-Object { [int]$_ }
  return $tasks | Where-Object { $_.Enabled -and ($nums -contains $_.Id) }
}

$selected = Select-Tasks $tasks
if (-not $selected -or $selected.Count -eq 0) { Write-Host 'Nessuna attività selezionata/applicabile.'; exit 0 }

$script:EW_TaskError = $false
foreach ($t in $selected) { try { Invoke-Task $t } catch { Write-Error $_ } }

# Logging strutturato opzionale
if ($LogEvent) {
  try {
    $artifacts = @()
    $maybe = @(
      (Join-Path $ApiPath 'checklist.json'),
      (Join-Path $ApiPath 'drift.json'),
      'orchestrator-plan.json',
      'versions-report.txt'
    )
    foreach ($p in $maybe) { if (Test-Path $p) { $artifacts += $p } }
    $intent = 'governance-gates'
    $actor = 'agent_governance'
    $envName = $env:ENVIRONMENT; if ([string]::IsNullOrWhiteSpace($envName)) { $envName = 'local' }
    $outcome = 'success'; if ($script:EW_TaskError) { $outcome = 'error' }
    $notes = "Gates eseguiti: " + (@(
      ($Checklist ? 'Checklist' : $null),
      ($DbDrift ? 'DBDrift' : $null),
      ($KbConsistency ? 'KBConsistency' : $null),
      ($TerraformPlan ? 'TerraformPlan' : $null),
      ($GenAppSettings ? 'GenAppSettings' : $null)
    ) | Where-Object { $_ } -join ', ')
    pwsh 'scripts/activity-log.ps1' -Intent $intent -Actor $actor -Env $envName -Outcome $outcome -Artifacts $artifacts -Notes $notes | Out-Host
  } catch { Write-Warning "Activity log failed: $($_.Exception.Message)" }
}

Write-Host "`nTutte le attività selezionate sono state elaborate." -ForegroundColor Green


$enforcerApplied = $false
try {
  pwsh 'scripts/enforcer.ps1' -Agent agent_governance -GitDiff -Quiet | Out-Null
  if ($LASTEXITCODE -eq 2) { Write-Error 'Enforcer: violazioni allowed_paths per agent_governance'; exit 2 }
  $enforcerApplied = $true
} catch { Write-Warning ("Enforcer preflight (governance) non applicabile: {0}" -f $_.Exception.Message) }
