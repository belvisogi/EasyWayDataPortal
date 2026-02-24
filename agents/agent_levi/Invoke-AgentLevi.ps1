#Requires -Version 5.1
<#
.SYNOPSIS
    Level 3 runner for agent_levi (The Sovereign Cleaner).

.DESCRIPTION
    Implements the L3 pattern: Evaluator-Optimizer + Working Memory + structured JSON output.

    Gap 1 - Evaluator-Optimizer: activated on handoff:update (next_steps traceability)
            and md:fix (zero false-positive synthesis) via AC predicates.
    Gap 2 - Working Memory: session.json tracks state within a run.
    Gap 4 - Structured output: contractId, confidence, meta (vs free-form in L2).

    Actions:
      handoff:update  - Aggiorna HANDOFF_LATEST.md via LLM+RAG+Evaluator
      md:fix          - Scansiona .md files, LLM+Evaluator verifica zero false-positive

.PARAMETER Action
    Action to perform. Default: handoff:update.

.PARAMETER Scope
    Per md:fix: directory da scansionare. Default: 'docs/'

.PARAMETER SessionNumber
    Per handoff:update: numero sessione. Default: auto-detect (prev + 1).

.PARAMETER NoEvaluator
    Disable Evaluator-Optimizer (single-shot generation).

.PARAMETER MaxIterations
    Max Evaluator-Optimizer iterations. Default: 2.

.PARAMETER DryRun
    Show output without writing files.

.EXAMPLE
    pwsh agents/agent_levi/Invoke-AgentLevi.ps1 -Action handoff:update -SessionNumber 20
    pwsh agents/agent_levi/Invoke-AgentLevi.ps1 -Action md:fix -Scope docs/ -DryRun
    pwsh agents/agent_levi/Invoke-AgentLevi.ps1 -Action handoff:update -NoEvaluator

.NOTES
    Evolution Level: 3 (LLM + RAG + Evaluator-Optimizer + Working Memory)
    Confidence threshold: 0.80 (below => requires_human_review = true)
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [ValidateSet('handoff:update', 'md:fix')]
    [string]$Action = 'handoff:update',

    [Parameter(Mandatory = $false)] [string]$Scope = 'docs/',
    [Parameter(Mandatory = $false)] [int]$SessionNumber = 0,
    [Parameter(Mandatory = $false)] [string]$SessionFile = '',
    [Parameter(Mandatory = $false)] [switch]$NoEvaluator,
    [Parameter(Mandatory = $false)] [ValidateRange(1, 5)] [int]$MaxIterations = 2,
    [Parameter(Mandatory = $false)] [int]$TopK = 5,
    [Parameter(Mandatory = $false)] [string]$ApiKey = $env:DEEPSEEK_API_KEY,
    [Parameter(Mandatory = $false)] [switch]$DryRun,
    [Parameter(Mandatory = $false)] [bool]$LogEvent = $true
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# --- Constants ------------------------------------------------------------------
$CONFIDENCE_THRESHOLD = 0.80

# --- Paths ----------------------------------------------------------------------
$AgentDir   = $PSScriptRoot
$SkillsDir  = Join-Path $AgentDir '..' 'skills'
$LLMWithRAG = Join-Path $SkillsDir 'retrieval' 'Invoke-LLMWithRAG.ps1'
$SessionSkill = Join-Path $SkillsDir 'session' 'Manage-AgentSession.ps1'
$PromptsFile  = Join-Path $AgentDir 'PROMPTS.md'
$HandoffPath  = Join-Path $AgentDir '..' '..' 'docs' 'HANDOFF_LATEST.md'

foreach ($required in @($LLMWithRAG, $PromptsFile)) {
    if (-not (Test-Path $required)) {
        Write-Error "Required file not found: $required"
        exit 1
    }
}

# --- Bootstrap: load platform secrets -------------------------------------------
$importSecretsSkill = Join-Path $SkillsDir 'utilities' 'Import-AgentSecrets.ps1'
if (Test-Path $importSecretsSkill) {
    . $importSecretsSkill
    Import-AgentSecrets -AgentId 'agent_levi' | Out-Null
}
if (-not $ApiKey) { $ApiKey = $env:DEEPSEEK_API_KEY }
if (-not $ApiKey) {
    Write-Error 'DEEPSEEK_API_KEY not set. Add to /opt/easyway/.env.secrets or pass -ApiKey.'
    exit 1
}

# --- Injection patterns ---------------------------------------------------------
$InjectionPatterns = @(
    '(?i)ignore\s+(all\s+)?(previous\s+)?instructions?',
    '(?i)override\s+(rules?|system|prompt)',
    '(?i)you\s+are\s+now\s+',
    '(?i)forget\s+(everything|all(\s+previous)?)',
    '(?i)new\s+(mission|instructions?)\s*:',
    '(?i)pretend\s+you\s+are',
    '(?i)disregard\s+(previous|instructions?)'
)

# --- Helper functions -----------------------------------------------------------
function Test-Injection([string]$text) {
    foreach ($pattern in $InjectionPatterns) {
        if ($text -match $pattern) { return $Matches[0] }
    }
    return $null
}

function Get-ParsedOutput([string]$raw) {
    $json = ($raw -replace '(?s)```json\s*', '' -replace '(?s)```\s*', '').Trim()
    try   { return $json | ConvertFrom-Json }
    catch {
        return [PSCustomObject]@{
            ok         = $false
            confidence = 0.5
            parse_error = $true
            raw_summary = $raw.Substring(0, [Math]::Min(400, $raw.Length))
        }
    }
}

function Write-AgentLog {
    param($EventData)
    if (-not $LogEvent) { return }
    $logDir = Join-Path $AgentDir '..' 'logs'
    if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir -Force | Out-Null }
    $entry = [ordered]@{ timestamp = (Get-Date).ToString('o'); agent = 'agent_levi'; data = $EventData }
    ($entry | ConvertTo-Json -Depth 5) | Out-File (Join-Path $logDir 'agent-history.jsonl') -Append -Encoding utf8
}

# --- Header ---------------------------------------------------------------------
$startTime = Get-Date
$now = (Get-Date).ToUniversalTime().ToString('o')

Write-Host ''
Write-Host '=============================================' -ForegroundColor Cyan
Write-Host ' Agent Levi (The Sovereign Cleaner) L3'      -ForegroundColor Cyan
Write-Host " Action   : $Action"                          -ForegroundColor Cyan
Write-Host " Evaluator: $(-not $NoEvaluator) | MaxIter: $MaxIterations" -ForegroundColor Cyan
Write-Host '=============================================' -ForegroundColor Cyan
Write-Host ''

# --- Execution ------------------------------------------------------------------
try {
    $Result = $null

    . $LLMWithRAG

    # Session start (non-blocking)
    $sessionCreated = $false
    $activeSession  = $SessionFile
    if (Test-Path $SessionSkill) {
        try {
            $sessionResult  = & $SessionSkill -Operation New -AgentId 'agent_levi' -Intent $Action
            $activeSession  = $sessionResult.SessionFile
            $sessionCreated = $true
            Write-Host "[Session] Started: $activeSession" -ForegroundColor DarkGray
        } catch {
            Write-Warning "[Session] Could not start (non-blocking): $_"
        }
    }

    # AC predicates by action
    $acPredicates = @{
        'handoff:update' = @(
            "AC-01: output JSON must contain 'session_number' as a positive integer",
            "AC-02: output JSON must contain 'next_steps' as a non-empty array with at least 2 items",
            "AC-03: output JSON must contain 'confidence' between 0.0 and 1.0",
            "AC-04: output JSON 'platform_state' must have all 4 fields: agents_formalized, qdrant_chunks, last_release_pr, server_commit",
            "AC-05: output JSON must contain 'completed' as a non-empty array"
        )
        'md:fix' = @(
            "AC-01: output JSON must contain 'action' equal to 'md:fix'",
            "AC-02: output JSON must contain 'issues' as an array (can be empty)",
            "AC-03: each issue in 'issues' must have file, type, description, fix, auto_fixable fields",
            "AC-04: output JSON must contain 'confidence' between 0.0 and 1.0"
        )
    }

    switch ($Action) {

        # ==========================================================================
        # ACTION: handoff:update
        # ==========================================================================
        'handoff:update' {
            # Injection check on branch name (paranoia)
            $branch = (git branch --show-current 2>$null).Trim()
            $injMatch = Test-Injection -text $branch
            if ($injMatch) {
                $Result = [ordered]@{ action = $Action; ok = $false; status = 'SECURITY_VIOLATION'; reason = "Injection in branch: '$injMatch'" }
                Write-AgentLog -EventData @{ success = $false; security_violation = $true }
                $Result | ConvertTo-Json | Write-Output
                exit 0
            }

            # Gather git context
            $gitLog       = (git log origin/main..HEAD --oneline 2>$null) -join "`n"
            $recentMerges = (git log origin/main --merges --oneline -5 2>$null) -join "`n"
            $serverCommit = (git rev-parse --short origin/main 2>$null).Trim()

            # Qdrant count (best-effort, only works from server)
            $qdrantChunks = 'unknown'
            try {
                $qdrantKey = $env:QDRANT_API_KEY
                if ($qdrantKey) {
                    $r = Invoke-RestMethod 'http://localhost:6333/collections/easyway_wiki' `
                        -Headers @{ 'api-key' = $qdrantKey } -ErrorAction SilentlyContinue
                    $qdrantChunks = $r.result.points_count
                }
            } catch { $qdrantChunks = 'unavailable (run from server)' }

            # Auto-detect session number
            $prevHandoff = if (Test-Path $HandoffPath) { Get-Content $HandoffPath -Raw } else { '' }
            if ($SessionNumber -eq 0) {
                if ($prevHandoff -match '>\s*\*\*Sessione\*\*:\s*(\d+)') {
                    $SessionNumber = [int]$Matches[1] + 1
                } else { $SessionNumber = 20 }
            }

            $query = @"
Aggiorna HANDOFF_LATEST.md per la sessione $SessionNumber.

Dati correnti (VERIFICATI — usa solo questi per 'completed' e 'next_steps'):
- Branch: $branch
- Commit non ancora in main: $gitLog
- Ultimi merge in main: $recentMerges
- Server commit (main): $serverCommit
- Qdrant chunks: $qdrantChunks
- Data oggi: $(Get-Date -Format 'yyyy-MM-dd')

Sezione variabile precedente di HANDOFF_LATEST:
$($prevHandoff -replace '(?s)(## File chiave.*)', '')

Genera il JSON handoff:update. I 'next_steps' devono essere tracciabili ai dati sopra.
"@

            Write-Host '[1/2] Calling Invoke-LLMWithRAG (Evaluator-Optimizer)...' -ForegroundColor Yellow

            if ($sessionCreated -and $activeSession) {
                try { & $SessionSkill -Operation SetStep -SessionFile $activeSession -StepName 'llm-handoff' | Out-Null } catch {}
            }

            $invokeParams = @{
                Query        = $query
                AgentId      = 'agent_levi'
                SystemPrompt = (Get-Content $PromptsFile -Raw -Encoding UTF8)
                TopK         = $TopK
                SecureMode   = $true
                MaxTokens    = 2000
            }
            if (-not $NoEvaluator) {
                $invokeParams['EnableEvaluator']     = $true
                $invokeParams['AcceptanceCriteria']  = $acPredicates['handoff:update']
                $invokeParams['MaxIterations']       = $MaxIterations
            }
            if ($activeSession -and (Test-Path $activeSession)) {
                $invokeParams['SessionFile'] = $activeSession
            }

            $llmResult = Invoke-LLMWithRAG @invokeParams
            if (-not $llmResult.Success) { throw "LLM call failed: $($llmResult.Error)" }

            $parsed     = Get-ParsedOutput -raw $llmResult.Answer
            $confidence = if ($parsed.PSObject.Properties['confidence']) { [double]$parsed.confidence } else { 0.5 }
            $requiresHumanReview = $confidence -lt $CONFIDENCE_THRESHOLD

            if ($requiresHumanReview) {
                Write-Host "  [!] Confidence $confidence < $CONFIDENCE_THRESHOLD — human review required" -ForegroundColor Yellow
            }

            if ($parsed.PSObject.Properties['ok'] -and $parsed.ok -eq $false) {
                $Result = [ordered]@{ action = $Action; ok = $false; status = $parsed.status; reason = $parsed.reason }
                Write-AgentLog -EventData @{ success = $false; reason = $parsed.reason }
                $Result | ConvertTo-Json | Write-Output
                exit 0
            }

            # Build HANDOFF content
            $completedMd = ($parsed.completed | ForEach-Object { "- $_" }) -join "`n"
            $stepIdx = 1
            $nextStepsMd = ($parsed.next_steps | ForEach-Object { "$stepIdx. $_"; $stepIdx++ }) -join "`n"
            $state = $parsed.platform_state

            $newVariableSection = @"
## Sessione corrente

> **Sessione**: $($parsed.session_number)
> **Data**: $($parsed.date)
> **Branch attivo**: ``$($parsed.branch)``

### Completato

$completedMd

### Stato piattaforma

| Metrica | Valore |
|---|---|
| Agenti formalizzati | **$($state.agents_formalized)** |
| Qdrant chunk | $($state.qdrant_chunks) |
| Ultima release | $($state.last_release_pr) |
| Server commit | ``$($state.server_commit)`` |

### Prossimi step

$nextStepsMd

"@
            $header = @"
# HANDOFF LATEST — EasyWayDataPortal

> **Documento canonico di sessione.**
> Aggiornalo in-place a fine sessione, poi archivia con:
> ``cp docs/HANDOFF_LATEST.md docs/HANDOFF_SESSION_<N>.md``

---

<!-- ═══════════════════════════════════════════════════════════
     SEZIONE VARIABILE — aggiornare ad ogni sessione
     ═══════════════════════════════════════════════════════════ -->

"@
            $separator = @"

---

<!-- ═══════════════════════════════════════════════════════════
     SEZIONE STABILE — modifica solo se cambiano le regole
     ═══════════════════════════════════════════════════════════ -->

"@
            $stableSection = if ($prevHandoff -match '(?s)(.*?)(## File chiave.*)') { $Matches[2] } else { $prevHandoff }
            $newContent = $header + $newVariableSection + $separator + $stableSection

            if ($DryRun) {
                Write-Host '[Levi] DRY RUN — variable section preview:' -ForegroundColor DarkYellow
                Write-Host $newVariableSection
            } else {
                $newContent | Set-Content $HandoffPath -Encoding UTF8
                Write-Host "[Levi] HANDOFF_LATEST.md updated (session $($parsed.session_number))" -ForegroundColor Green
                $archivePath = Join-Path $AgentDir '..' '..' "docs/HANDOFF_SESSION_$($parsed.session_number).md"
                if (-not (Test-Path $archivePath)) {
                    Copy-Item $HandoffPath $archivePath
                    Write-Host "[Levi] Archived to HANDOFF_SESSION_$($parsed.session_number).md" -ForegroundColor Green
                }
            }

            $durationSec = [Math]::Round(((Get-Date) - $startTime).TotalSeconds, 2)
            Write-Host "[2/2] Done. Session: $($parsed.session_number) | Confidence: $confidence" -ForegroundColor Green

            $Result = [ordered]@{
                action                = $Action
                ok                    = $true
                session               = $parsed.session_number
                confidence            = $confidence
                requires_human_review = $requiresHumanReview
                dryRun                = $DryRun.IsPresent
                meta                  = [ordered]@{
                    evaluator_enabled    = (-not $NoEvaluator)
                    evaluator_iterations = if ($llmResult.PSObject.Properties['EvaluatorIterations']) { $llmResult.EvaluatorIterations } else { 1 }
                    evaluator_passed     = if ($llmResult.PSObject.Properties['EvaluatorPassed'])     { $llmResult.EvaluatorPassed }     else { $true }
                    rag_chunks           = $llmResult.RAGChunks
                    tokens_in            = $llmResult.TokensIn
                    tokens_out           = $llmResult.TokensOut
                    cost_usd             = $llmResult.CostUSD
                    duration_sec         = $durationSec
                }
                startedAt             = $now
                finishedAt            = (Get-Date).ToUniversalTime().ToString('o')
                contractId            = 'action-result'
                contractVersion       = '1.0'
            }
        }

        # ==========================================================================
        # ACTION: md:fix
        # ==========================================================================
        'md:fix' {
            $scopePath = Join-Path $AgentDir '..' '..' $Scope
            $mdFiles   = Get-ChildItem $scopePath -Recurse -Filter '*.md' -ErrorAction SilentlyContinue
            Write-Host "[Levi] Scanning $($mdFiles.Count) .md files in: $Scope" -ForegroundColor Yellow

            # Deterministic scan
            $issueList = [System.Collections.Generic.List[PSCustomObject]]::new()
            foreach ($file in $mdFiles) {
                $content = Get-Content $file.FullName -Raw -ErrorAction SilentlyContinue
                if (-not $content) { continue }

                $relPath = $file.FullName.Replace((Resolve-Path (Join-Path $AgentDir '..' '..')).Path + '\', '')

                # Missing frontmatter block
                if ($content -notmatch '^---') {
                    $issueList.Add([PSCustomObject]@{
                        file = $relPath; type = 'missing_frontmatter'; line = 1
                        description = 'File manca di YAML frontmatter'
                        fix = 'Aggiungere blocco --- title/status/owner/tags ---'
                        auto_fixable = $false
                    })
                } elseif ($content -match '^---(?s)(.*?)---') {
                    $fm = $Matches[1]
                    foreach ($field in @('title', 'status', 'owner', 'tags')) {
                        if ($fm -notmatch "$($field)\s*:") {
                            $issueList.Add([PSCustomObject]@{
                                file = $relPath; type = 'missing_frontmatter'; line = 1
                                description = "Campo frontmatter mancante: $($field)"
                                fix = "Aggiungere '$($field): <valore>' nel blocco frontmatter"
                                auto_fixable = $false
                            })
                        }
                    }
                }

                # Empty sections
                $lines = $content -split "`n"
                for ($idx = 0; $idx -lt $lines.Count - 1; $idx++) {
                    if ($lines[$idx] -match '^#{1,3} ' -and ($idx + 1) -lt $lines.Count) {
                        $nextLine = $lines[$idx + 1].Trim()
                        if ($nextLine -eq '' -and (($idx + 2) -ge $lines.Count -or $lines[$idx + 2] -match '^#{1,3} ')) {
                            $issueList.Add([PSCustomObject]@{
                                file = $relPath; type = 'empty_section'; line = $idx + 1
                                description = "Sezione vuota: $($lines[$idx].Trim())"
                                fix = 'Aggiungere contenuto o rimuovere la sezione'
                                auto_fixable = $false
                            })
                        }
                    }
                }
            }

            # LLM+Evaluator synthesis
            Write-Host '[1/2] Calling Invoke-LLMWithRAG for synthesis (Evaluator-Optimizer)...' -ForegroundColor Yellow

            $issuesSample = ($issueList | Select-Object -First 15 | ConvertTo-Json -Depth 3)
            $synthQuery = "Analizza $($issueList.Count) problemi trovati in $($mdFiles.Count) file Markdown. " +
                          "Produci il JSON md:fix con 'issues' (solo quelli confermati), 'summary' (3 punti priorita'), 'confidence'. " +
                          "Issues rilevati deterministicamente (campione): $issuesSample"

            if ($sessionCreated -and $activeSession) {
                try { & $SessionSkill -Operation SetStep -SessionFile $activeSession -StepName 'llm-mdfix' | Out-Null } catch {}
            }

            $invokeParams = @{
                Query        = $synthQuery
                AgentId      = 'agent_levi'
                SystemPrompt = (Get-Content $PromptsFile -Raw -Encoding UTF8)
                TopK         = $TopK
                SecureMode   = $true
                MaxTokens    = 1200
            }
            if (-not $NoEvaluator) {
                $invokeParams['EnableEvaluator']    = $true
                $invokeParams['AcceptanceCriteria'] = $acPredicates['md:fix']
                $invokeParams['MaxIterations']      = $MaxIterations
            }
            if ($activeSession -and (Test-Path $activeSession)) {
                $invokeParams['SessionFile'] = $activeSession
            }

            $llmResult  = Invoke-LLMWithRAG @invokeParams
            if (-not $llmResult.Success) { throw "LLM call failed: $($llmResult.Error)" }

            $parsed     = Get-ParsedOutput -raw $llmResult.Answer
            $confidence = if ($parsed.PSObject.Properties['confidence']) { [double]$parsed.confidence } else { 0.7 }
            $summary    = if ($parsed.PSObject.Properties['summary'])    { $parsed.summary }            else { "Scansionati $($mdFiles.Count) file, $($issueList.Count) problemi rilevati." }

            # Save report
            if (-not $DryRun -and $issueList.Count -gt 0) {
                $memDir = Join-Path $AgentDir 'memory'
                if (-not (Test-Path $memDir)) { New-Item -ItemType Directory -Path $memDir -Force | Out-Null }
                $reportPath = Join-Path $memDir "md-fix-$(Get-Date -Format 'yyyyMMdd-HHmm').json"
                $issueList | ConvertTo-Json -Depth 5 | Set-Content $reportPath -Encoding UTF8
                Write-Host "[Levi] Report: $reportPath" -ForegroundColor Green
            }

            $durationSec = [Math]::Round(((Get-Date) - $startTime).TotalSeconds, 2)
            Write-Host "[2/2] Done. Files: $($mdFiles.Count) | Issues: $($issueList.Count) | Confidence: $confidence" -ForegroundColor Green

            $Result = [ordered]@{
                action                = $Action
                ok                    = $true
                files_scanned         = $mdFiles.Count
                issues_found          = $issueList.Count
                confidence            = $confidence
                requires_human_review = ($confidence -lt $CONFIDENCE_THRESHOLD)
                summary               = $summary
                dryRun                = $DryRun.IsPresent
                meta                  = [ordered]@{
                    evaluator_enabled    = (-not $NoEvaluator)
                    evaluator_iterations = if ($llmResult.PSObject.Properties['EvaluatorIterations']) { $llmResult.EvaluatorIterations } else { 1 }
                    evaluator_passed     = if ($llmResult.PSObject.Properties['EvaluatorPassed'])     { $llmResult.EvaluatorPassed }     else { $true }
                    rag_chunks           = $llmResult.RAGChunks
                    tokens_in            = $llmResult.TokensIn
                    tokens_out           = $llmResult.TokensOut
                    cost_usd             = $llmResult.CostUSD
                    duration_sec         = $durationSec
                }
                startedAt             = $now
                finishedAt            = (Get-Date).ToUniversalTime().ToString('o')
                contractId            = 'action-result'
                contractVersion       = '1.0'
            }
        }

        default { throw "Action '$Action' not implemented." }
    }

    # Session close (non-blocking)
    if ($sessionCreated -and $activeSession) {
        try {
            & $SessionSkill -Operation Update -SessionFile $activeSession `
                -CompletedStep $Action `
                -StepResult @{ ok = $Result.ok; confidence = $Result.confidence } `
                -Confidence $Result.confidence | Out-Null
            & $SessionSkill -Operation Close -SessionFile $activeSession | Out-Null
        } catch { Write-Warning '[Session] Close failed (non-blocking).' }
    }

    Write-AgentLog -EventData @{ success = $true; agent = 'agent_levi'; action = $Action; result = $Result }
    $Result | ConvertTo-Json -Depth 10 | Write-Output

} catch {
    $errMsg = $_.Exception.Message
    Write-Error "Levi Error: $errMsg"
    Write-AgentLog -EventData @{ success = $false; error = $errMsg }
    exit 1
}
