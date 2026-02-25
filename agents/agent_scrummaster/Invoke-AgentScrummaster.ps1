#Requires -Version 5.1
<#
.SYNOPSIS
    Level 3 runner for agent_scrummaster (The Agile Facilitator).

.DESCRIPTION
    Implements the L3 pattern: Evaluator-Optimizer + Working Memory + structured JSON output.

    Gap 1 - Evaluator-Optimizer: activated on sprint:report (next_actions traceability)
            and backlog:health (zero false-positive issues) via AC predicates.
    Gap 2 - Working Memory: session.json tracks state within a run.
    Gap 4 - Structured output: contractId, confidence, meta (vs free-form in L1).

    Actions:
      sprint:report   - Genera report sprint strutturato via LLM+RAG+Evaluator
      backlog:health  - Analizza qualita' backlog via LLM+Evaluator

.PARAMETER Action
    Action to perform. Default: sprint:report.

.PARAMETER SprintName
    Nome/numero sprint (opzionale, auto-detect da context).

.PARAMETER NoEvaluator
    Disable Evaluator-Optimizer (single-shot generation).

.PARAMETER MaxIterations
    Max Evaluator-Optimizer iterations. Default: 2.

.PARAMETER DryRun
    Show output without writing files.

.EXAMPLE
    pwsh agents/agent_scrummaster/Invoke-AgentScrummaster.ps1 -Action sprint:report
    pwsh agents/agent_scrummaster/Invoke-AgentScrummaster.ps1 -Action backlog:health -DryRun
    pwsh agents/agent_scrummaster/Invoke-AgentScrummaster.ps1 -Action sprint:report -NoEvaluator

.NOTES
    Evolution Level: 3 (LLM + RAG + Evaluator-Optimizer + Working Memory)
    Confidence threshold: 0.80 (below => requires_human_review = true)
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [ValidateSet('sprint:report', 'backlog:health')]
    [string]$Action = 'sprint:report',

    [Parameter(Mandatory = $false)] [string]$SprintName = '',
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
$AgentDir    = $PSScriptRoot
$SkillsDir   = Join-Path $AgentDir '..' 'skills'
$LLMWithRAG  = Join-Path $SkillsDir 'retrieval' 'Invoke-LLMWithRAG.ps1'
$SessionSkill = Join-Path $SkillsDir 'session' 'Manage-AgentSession.ps1'
$PromptsFile  = Join-Path $AgentDir 'PROMPTS.md'

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
    Import-AgentSecrets -AgentId 'agent_scrummaster' | Out-Null
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
            ok          = $false
            confidence  = 0.5
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
    $entry = [ordered]@{ timestamp = (Get-Date).ToString('o'); agent = 'agent_scrummaster'; data = $EventData }
    ($entry | ConvertTo-Json -Depth 5) | Out-File (Join-Path $logDir 'agent-history.jsonl') -Append -Encoding utf8
}

# --- Header ---------------------------------------------------------------------
$startTime = Get-Date
$now = (Get-Date).ToUniversalTime().ToString('o')

Write-Host ''
Write-Host '=============================================' -ForegroundColor Cyan
Write-Host ' Agent ScrumMaster (Agile Facilitator) L3'   -ForegroundColor Cyan
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
            $sessionResult  = & $SessionSkill -Operation New -AgentId 'agent_scrummaster' -Intent $Action
            $activeSession  = $sessionResult.SessionFile
            $sessionCreated = $true
            Write-Host "[Session] Started: $activeSession" -ForegroundColor DarkGray
        } catch {
            Write-Warning "[Session] Could not start (non-blocking): $_"
        }
    }

    # AC predicates by action
    $acPredicates = @{
        'sprint:report' = @(
            "AC-01: output JSON must contain 'action' equal to 'sprint:report'",
            "AC-02: output JSON must contain 'sprint_status' object with fields: total_items, completed, in_progress, blocked, not_started",
            "AC-03: output JSON must contain 'blockers' as an array (can be empty)",
            "AC-04: output JSON must contain 'next_actions' as non-empty array with >= 2 items",
            "AC-05: output JSON must contain 'confidence' between 0.0 and 1.0"
        )
        'backlog:health' = @(
            "AC-01: output JSON must contain 'action' equal to 'backlog:health'",
            "AC-02: output JSON must contain 'issues' as an array (can be empty)",
            "AC-03: output JSON must contain 'health_score' between 0.0 and 1.0",
            "AC-04: output JSON must contain 'confidence' between 0.0 and 1.0"
        )
    }

    switch ($Action) {

        # ==========================================================================
        # ACTION: sprint:report
        # ==========================================================================
        'sprint:report' {
            # Injection check on sprint name
            if ($SprintName) {
                $injMatch = Test-Injection -text $SprintName
                if ($injMatch) {
                    $Result = [ordered]@{ action = $Action; ok = $false; status = 'SECURITY_VIOLATION'; reason = "Injection in sprint name: '$injMatch'" }
                    Write-AgentLog -EventData @{ success = $false; security_violation = $true }
                    $Result | ConvertTo-Json | Write-Output
                    exit 0
                }
            }

            # Gather git/platform context
            $branch       = (git branch --show-current 2>$null).Trim()
            $recentMerges = (git log origin/main --merges --oneline -5 2>$null) -join "`n"
            $openPRs      = (git log origin/develop..HEAD --oneline 2>$null) -join "`n"
            $today        = (Get-Date -Format 'yyyy-MM-dd')
            $sprintLabel  = if ($SprintName) { $SprintName } else { "Sprint corrente (auto)" }

            $query = @"
Genera il report sprint strutturato per '$sprintLabel'.

Contesto piattaforma:
- Branch attivo: $branch
- Data: $today
- Commit non ancora in main: $openPRs
- Ultimi merge in main: $recentMerges

Il report deve coprire:
1. Stato items (stima da git context e RAG knowledge)
2. Blockers noti (items stale o esplicitamente bloccati)
3. Compliance DoD per gli items completati
4. Prossime azioni prioritarie (>= 2, con owner e timeline)

Genera il JSON sprint:report con tutti i campi richiesti.
"@

            Write-Host '[1/2] Calling Invoke-LLMWithRAG (Evaluator-Optimizer)...' -ForegroundColor Yellow

            if ($sessionCreated -and $activeSession) {
                try { & $SessionSkill -Operation SetStep -SessionFile $activeSession -StepName 'llm-sprint' | Out-Null } catch {}
            }

            $invokeParams = @{
                Query        = $query
                AgentId      = 'agent_scrummaster'
                SystemPrompt = (Get-Content $PromptsFile -Raw -Encoding UTF8)
                TopK         = $TopK
                SecureMode   = $true
                MaxTokens    = 1500
            }
            if (-not $NoEvaluator) {
                $invokeParams['EnableEvaluator']    = $true
                $invokeParams['AcceptanceCriteria'] = $acPredicates['sprint:report']
                $invokeParams['MaxIterations']      = $MaxIterations
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

            $durationSec = [Math]::Round(((Get-Date) - $startTime).TotalSeconds, 2)
            Write-Host "[2/2] Done. Sprint: $sprintLabel | Confidence: $confidence" -ForegroundColor Green

            $Result = [ordered]@{
                action                = $Action
                ok                    = $true
                sprint_name           = $sprintLabel
                confidence            = $confidence
                requires_human_review = $requiresHumanReview
                sprint_status         = if ($parsed.PSObject.Properties['sprint_status']) { $parsed.sprint_status } else { $null }
                blockers              = if ($parsed.PSObject.Properties['blockers'])      { $parsed.blockers }      else { @() }
                next_actions          = if ($parsed.PSObject.Properties['next_actions']) { $parsed.next_actions }  else { @() }
                summary               = if ($parsed.PSObject.Properties['summary'])      { $parsed.summary }       else { "Report generato." }
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
        # ACTION: backlog:health
        # ==========================================================================
        'backlog:health' {
            $branch = (git branch --show-current 2>$null).Trim()
            $today  = (Get-Date -Format 'yyyy-MM-dd')

            $query = @"
Analizza la salute del backlog EasyWay DataPortal.

Contesto:
- Branch attivo: $branch
- Data: $today

Valuta:
1. Items senza acceptance criteria
2. Items stale (non aggiornati > 5 giorni)
3. Items senza traceabilita' Epic/Feature
4. Sprint sovraccarico (commitment > capacity)

Genera il JSON backlog:health con health_score, issues, summary e confidence.
"@

            Write-Host '[1/2] Calling Invoke-LLMWithRAG (backlog:health)...' -ForegroundColor Yellow

            if ($sessionCreated -and $activeSession) {
                try { & $SessionSkill -Operation SetStep -SessionFile $activeSession -StepName 'llm-backlog' | Out-Null } catch {}
            }

            $invokeParams = @{
                Query        = $query
                AgentId      = 'agent_scrummaster'
                SystemPrompt = (Get-Content $PromptsFile -Raw -Encoding UTF8)
                TopK         = $TopK
                SecureMode   = $true
                MaxTokens    = 1200
            }
            if (-not $NoEvaluator) {
                $invokeParams['EnableEvaluator']    = $true
                $invokeParams['AcceptanceCriteria'] = $acPredicates['backlog:health']
                $invokeParams['MaxIterations']      = $MaxIterations
            }
            if ($activeSession -and (Test-Path $activeSession)) {
                $invokeParams['SessionFile'] = $activeSession
            }

            $llmResult = Invoke-LLMWithRAG @invokeParams
            if (-not $llmResult.Success) { throw "LLM call failed: $($llmResult.Error)" }

            $parsed      = Get-ParsedOutput -raw $llmResult.Answer
            $confidence  = if ($parsed.PSObject.Properties['confidence'])   { [double]$parsed.confidence }  else { 0.5 }
            $healthScore = if ($parsed.PSObject.Properties['health_score']) { [double]$parsed.health_score } else { 0.5 }

            $durationSec = [Math]::Round(((Get-Date) - $startTime).TotalSeconds, 2)
            Write-Host "[2/2] Done. Health: $healthScore | Confidence: $confidence" -ForegroundColor Green

            $Result = [ordered]@{
                action                = $Action
                ok                    = $true
                health_score          = $healthScore
                confidence            = $confidence
                requires_human_review = ($confidence -lt $CONFIDENCE_THRESHOLD)
                issues                = if ($parsed.PSObject.Properties['issues'])  { $parsed.issues }  else { @() }
                summary               = if ($parsed.PSObject.Properties['summary']) { $parsed.summary } else { "Analisi backlog completata." }
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

    Write-AgentLog -EventData @{ success = $true; agent = 'agent_scrummaster'; action = $Action; result = $Result }
    $Result | ConvertTo-Json -Depth 10 | Write-Output

} catch {
    $errMsg = $_.Exception.Message
    Write-Error "ScrumMaster Error: $errMsg"
    Write-AgentLog -EventData @{ success = $false; error = $errMsg }
    exit 1
}
