<#
  Resolve-PRConflicts.ps1 — agent_pr_conflict_resolver core skill

  Risolve automaticamente i conflitti di merge per PR ADO note.
  Applica strategie per file predefiniti; per file sconosciuti: escalate (non tocca nulla).

  Principio: "Misura due, taglia uno" — il sistema risolve solo cio' che conosce,
  segnala tutto il resto all'umano. MAI sovrascrivere file non in lista senza approvazione.

  Strategie per file noti:
    .cursorrules                          -> --theirs (source/develop) + Sync-PlatformMemory
    platform-operational-memory.md       -> --theirs (source/develop, piu' recente)
    azure-pipelines.yml                  -> --theirs + fix duplicate pr: blocks

  Uso:
    # Dry-run (mostra cosa farebbe, non committa)
    pwsh agents/skills/git/Resolve-PRConflicts.ps1 -PRId 197 -DryRun

    # Risoluzione reale (crea branch, risolve, push, PR ADO)
    pwsh agents/skills/git/Resolve-PRConflicts.ps1 -PRId 197

    # Da n8n (payload JSON in stdin o parametri)
    pwsh agents/skills/git/Resolve-PRConflicts.ps1 -SourceBranch develop -TargetBranch main

  Future trigger: ADO Service Hook (PR Updated/Created) -> n8n -> questo script
  Riferimento: agents/agent_pr_conflict_resolver/README.md
#>

Param(
    [string]  $PRId,
    [string]  $SourceBranch,
    [string]  $TargetBranch,
    [string]  $Pat          = $env:AZURE_DEVOPS_EXT_PAT,
    [string]  $OrgUrl       = 'https://dev.azure.com/EasyWayData',
    [string]  $Project      = 'EasyWay-DataPortal',
    [string]  $Repo         = 'EasyWayDataPortal',
    [switch]  $DryRun,
    [switch]  $Json
)

$ErrorActionPreference = 'Stop'

# ── Load PAT ──────────────────────────────────────────────────────────────────
if (-not $Pat) {
    $envFile = 'C:\old\.env.local'
    if (Test-Path $envFile) {
        Get-Content $envFile | Where-Object { $_ -match '^AZURE_DEVOPS_EXT_PAT=' } | ForEach-Object {
            $Pat = ($_ -split '=', 2)[1].Trim().Trim('"')
        }
    }
}
if (-not $Pat) { throw "PAT non trovato. Impostare AZURE_DEVOPS_EXT_PAT." }

$bytes   = [System.Text.Encoding]::UTF8.GetBytes(":$Pat")
$b64     = [System.Convert]::ToBase64String($bytes)
$headers = @{ Authorization = "Basic $b64"; 'Content-Type' = 'application/json' }

# ── Ottieni info PR da ADO se PRId passato ────────────────────────────────────
if ($PRId -and (-not $SourceBranch)) {
    $prUrl = "$OrgUrl/$Project/_apis/git/repositories/$Repo/pullrequests/$PRId`?api-version=7.1"
    $pr = Invoke-RestMethod -Uri $prUrl -Headers $headers -Method Get
    $SourceBranch = $pr.sourceRefName -replace 'refs/heads/', ''
    $TargetBranch = $pr.targetRefName -replace 'refs/heads/', ''
    Write-Host "PR #$PRId : $SourceBranch -> $TargetBranch"
}

if (-not $SourceBranch -or -not $TargetBranch) {
    throw "Specificare -PRId oppure -SourceBranch e -TargetBranch."
}

# ── Strategie per file noti ────────────────────────────────────────────────────
# theirs = source branch (develop/feature — piu' recente)
# ours   = target branch (main)
$knownStrategies = @{
    '.cursorrules'                                                         = 'theirs+sync'
    'Wiki/EasyWayData.wiki/agents/platform-operational-memory.md'         = 'theirs'
    'azure-pipelines.yml'                                                  = 'theirs+fix-yaml'
}

# ── Trova conflitti: tenta merge in sandbox ────────────────────────────────────
$resolutionBranch = "fix/conflict-resolution-$(Get-Date -Format 'yyyyMMdd-HHmm')"
$repoRoot = git rev-parse --show-toplevel 2>/dev/null
if (-not $repoRoot) { throw "Non sei in una git repo." }
Set-Location $repoRoot

git fetch origin --quiet 2>&1 | Out-Null

# Crea branch di risoluzione da target (main)
if (-not $DryRun) {
    git checkout -b $resolutionBranch "origin/$TargetBranch" 2>&1 | Out-Null
    Write-Host "Branch creato: $resolutionBranch (da origin/$TargetBranch)"
}

# Tenta merge senza commit per individuare i conflitti
$mergeOut = git merge "origin/$SourceBranch" --no-ff --no-commit 2>&1
$conflicted = @(git diff --name-only --diff-filter=U 2>/dev/null)

$report = [ordered]@{
    prId             = $PRId
    sourceBranch     = $SourceBranch
    targetBranch     = $TargetBranch
    resolutionBranch = $resolutionBranch
    dryRun           = [bool]$DryRun
    conflictedFiles  = $conflicted
    resolved         = @()
    escalated        = @()
    actions          = @()
}

if ($conflicted.Count -eq 0) {
    Write-Host "Nessun conflitto trovato — merge pulito."
    if (-not $DryRun) {
        git merge --abort 2>&1 | Out-Null
        git checkout - 2>&1 | Out-Null
        git branch -D $resolutionBranch 2>&1 | Out-Null
    }
    if ($Json) { $report | ConvertTo-Json -Depth 5 }
    exit 0
}

Write-Host "File in conflitto ($($conflicted.Count)):"
$conflicted | ForEach-Object { Write-Host "  - $_" }

# ── Risolvi file noti, escalate gli altri ─────────────────────────────────────
foreach ($file in $conflicted) {
    $normalizedFile = $file -replace '\\', '/'

    if ($knownStrategies.ContainsKey($normalizedFile)) {
        $strategy = $knownStrategies[$normalizedFile]
        Write-Host "  RESOLVE [$strategy] : $file"

        if (-not $DryRun) {
            switch -Wildcard ($strategy) {
                'theirs*' {
                    # Prendi la versione del source branch (develop)
                    git checkout --theirs $file 2>&1 | Out-Null
                    git add $file 2>&1 | Out-Null
                }
            }

            if ($strategy -eq 'theirs+sync') {
                # .cursorrules: dopo aver preso theirs, riesegui Sync-PlatformMemory
                $syncScript = Join-Path $repoRoot 'scripts/pwsh/Sync-PlatformMemory.ps1'
                if (Test-Path $syncScript) {
                    Write-Host "    Eseguendo Sync-PlatformMemory..."
                    pwsh $syncScript 2>&1 | ForEach-Object { Write-Host "    $_" }
                    git add $file 2>&1 | Out-Null
                }
            }

            if ($strategy -eq 'theirs+fix-yaml') {
                # azure-pipelines.yml: dopo theirs, rimuovi eventuali pr: duplicati
                $content = Get-Content $file -Raw
                $prBlockPattern = '(?ms)(^pr:\r?\n\s+branches:\r?\n\s+include:\r?\n(?:\s+-\s+\S+\r?\n)+)'
                $matches = [regex]::Matches($content, $prBlockPattern)
                if ($matches.Count -gt 1) {
                    Write-Host "    Fix: $($matches.Count) pr: blocks trovati, mantengo solo il primo"
                    for ($i = $matches.Count - 1; $i -gt 0; $i--) {
                        $content = $content.Remove($matches[$i].Index, $matches[$i].Length)
                    }
                    $content | Set-Content $file -NoNewline -Encoding UTF8
                    git add $file 2>&1 | Out-Null
                }
                # Verifica YAML
                $yamlCheck = python3 -c "import sys,yaml; yaml.safe_load(open('$file'))" 2>&1
                if ($LASTEXITCODE -ne 0) {
                    Write-Warning "YAML non valido dopo fix: $yamlCheck"
                    $report.escalated += $file
                    $report.actions += "YAML fix fallito su $file - richiede intervento manuale"
                    continue
                }
            }
        }

        $report.resolved += $file
        $report.actions += "RESOLVED [$strategy]: $file"

    } else {
        # File sconosciuto — escalate, NON toccare
        Write-Host "  ESCALATE (unknown): $file" -ForegroundColor Yellow
        $report.escalated += $file
        $report.actions += "ESCALATE (strategy unknown): $file - richiede intervento umano"
    }
}

# ── Commit risoluzione (solo se tutti risolti) ────────────────────────────────
if ($report.escalated.Count -gt 0) {
    Write-Host ""
    Write-Host "ATTENZIONE: $($report.escalated.Count) file non risolti automaticamente:" -ForegroundColor Yellow
    $report.escalated | ForEach-Object { Write-Host "  - $_" -ForegroundColor Yellow }
    Write-Host "Intervento manuale richiesto prima del commit."

    if (-not $DryRun) {
        git merge --abort 2>&1 | Out-Null
        git checkout - 2>&1 | Out-Null
        git branch -D $resolutionBranch 2>&1 | Out-Null
    }
} elseif (-not $DryRun) {
    # Tutti risolti — commit
    $msg = "fix(conflict): auto-resolve PR#$PRId ($SourceBranch->$TargetBranch)`n`nResolved: $($report.resolved -join ', ')`nStrategy: theirs (develop wins) + yaml-fix`n`nCo-Authored-By: agent_pr_conflict_resolver <noreply@easyway.local>"
    git commit -m $msg 2>&1 | Out-Null

    # Push branch
    git push origin $resolutionBranch 2>&1 | Out-Null
    Write-Host "Branch pushato: $resolutionBranch"
    Write-Host "Creare PR: $resolutionBranch -> $TargetBranch su ADO e assegnare a giuseppe.belviso per approvazione."
    $report.actions += "PUSH: $resolutionBranch"

    # Torna al branch originale
    git checkout - 2>&1 | Out-Null
}

# ── Output ────────────────────────────────────────────────────────────────────
if ($Json) {
    $report | ConvertTo-Json -Depth 5
} else {
    Write-Host ""
    Write-Host "--- REPORT ---"
    Write-Host "Risolti  : $($report.resolved.Count) file"
    Write-Host "Escalated: $($report.escalated.Count) file"
    if (-not $DryRun -and $report.escalated.Count -eq 0) {
        Write-Host "Branch   : $resolutionBranch (pushato su ADO)"
    }
}

exit $(if ($report.escalated.Count -gt 0) { 1 } else { 0 })
