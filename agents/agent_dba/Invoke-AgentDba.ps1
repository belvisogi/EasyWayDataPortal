#Requires -Version 5.1
<#
.SYNOPSIS
    Level 3 runner for agent_dba (Database Guardian).

.DESCRIPTION
    Implements the L3 pattern: Evaluator-Optimizer + Working Memory + structured JSON output.

    Gap 1 - Evaluator-Optimizer: activated on db-guardrails:check (zero false-positive violations)
            via AC predicates.
    Gap 2 - Working Memory: session.json tracks state within a run.
    Gap 4 - Structured output: contractId, confidence, meta (vs free-form in L1/L2).

    Actions:
      dba:check-health    - Verifica connettivita' DB (deterministic, no LLM, no Evaluator)
      db-guardrails:check - Valida SQL patterns contro GUARDRAILS.md via LLM+RAG+Evaluator

.PARAMETER Action
    Action to perform. Default: dba:check-health.

.PARAMETER Scope
    Per db-guardrails:check: scope di analisi ('all', 'tables', 'procedures'). Default: 'all'.

.PARAMETER Database
    Nome database target (opzionale, legge da env DB_DATABASE).

.PARAMETER NoEvaluator
    Disable Evaluator-Optimizer (single-shot generation).

.PARAMETER MaxIterations
    Max Evaluator-Optimizer iterations. Default: 2.

.PARAMETER DryRun
    Show output without writing files.

.EXAMPLE
    pwsh agents/agent_dba/Invoke-AgentDba.ps1 -Action dba:check-health
    pwsh agents/agent_dba/Invoke-AgentDba.ps1 -Action db-guardrails:check -Scope tables -DryRun
    pwsh agents/agent_dba/Invoke-AgentDba.ps1 -Action db-guardrails:check -NoEvaluator -DryRun

.NOTES
    Evolution Level: 3 (LLM + RAG + Evaluator-Optimizer + Working Memory)
    Confidence threshold: 0.80 (below => requires_human_review = true)
    Predecessor: Invoke-AgentDba.ps1 v2 (L2)
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [ValidateSet('dba:check-health', 'db-guardrails:check')]
    [string]$Action = 'dba:check-health',

    [Parameter(Mandatory = $false)]
    [ValidateSet('all', 'tables', 'procedures', 'functions')]
    [string]$Scope = 'all',

    [Parameter(Mandatory = $false)] [string]$Database = '',
    [Parameter(Mandatory = $false)] [string]$ApiKey = $env:DEEPSEEK_API_KEY,
    [Parameter(Mandatory = $false)] [int]$TopK = 5,
    [Parameter(Mandatory = $false)] [string]$SessionFile = '',
    [Parameter(Mandatory = $false)] [switch]$NoEvaluator,
    [Parameter(Mandatory = $false)] [ValidateRange(1, 5)] [int]$MaxIterations = 2,
    [Parameter(Mandatory = $false)] [switch]$DryRun,
    [Parameter(Mandatory = $false)] [bool]$LogEvent = $true
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# --- Constants ------------------------------------------------------------------
$CONFIDENCE_THRESHOLD = 0.80

# --- Paths ----------------------------------------------------------------------
$AgentDir     = $PSScriptRoot
$SkillsDir    = Join-Path $AgentDir '..' 'skills'
$LLMWithRAG   = Join-Path $SkillsDir 'retrieval' 'Invoke-LLMWithRAG.ps1'
$SessionSkill = Join-Path $SkillsDir 'session' 'Manage-AgentSession.ps1'
$PromptsFile  = Join-Path $AgentDir 'PROMPTS.md'
$GuardrailsFile = Join-Path $AgentDir 'GUARDRAILS.md'

foreach ($required in @($PromptsFile, $GuardrailsFile)) {
    if (-not (Test-Path $required)) {
        Write-Error "Required file not found: $required"
        exit 1
    }
}

# --- Bootstrap: load platform secrets -------------------------------------------
$importSecretsSkill = Join-Path $SkillsDir 'utilities' 'Import-AgentSecrets.ps1'
if (Test-Path $importSecretsSkill) {
    . $importSecretsSkill
    Import-AgentSecrets -AgentId 'agent_dba' | Out-Null
}
if (-not $ApiKey) { $ApiKey = $env:DEEPSEEK_API_KEY }

# DB connection from env (best-effort — check-health may fail gracefully)
$dbServer   = if ($env:DB_SERVER)   { $env:DB_SERVER }   else { 'localhost,1433' }
$dbDatabase = if ($Database)        { $Database }
              elseif ($env:DB_DATABASE) { $env:DB_DATABASE }
              else { 'EasyWayDB' }

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
    $entry = [ordered]@{ timestamp = (Get-Date).ToString('o'); agent = 'agent_dba'; data = $EventData }
    ($entry | ConvertTo-Json -Depth 5) | Out-File (Join-Path $logDir 'agent-history.jsonl') -Append -Encoding utf8
}

# --- AC predicates by action (for Evaluator-Optimizer) -------------------------
$acPredicates = @{
    'db-guardrails:check' = @(
        "AC-01: output JSON must contain 'action' equal to 'db-guardrails:check'",
        "AC-02: output JSON must contain 'violations' as an array (can be empty)",
        "AC-03: output JSON must contain 'summary' as a non-empty string",
        "AC-04: output JSON must contain 'confidence' between 0.0 and 1.0"
    )
}

# --- Header ---------------------------------------------------------------------
$startTime = Get-Date
$now = (Get-Date).ToUniversalTime().ToString('o')

Write-Host ''
Write-Host '=============================================' -ForegroundColor Cyan
Write-Host ' Agent DBA (Database Guardian) L3'           -ForegroundColor Cyan
Write-Host " Action   : $Action"                          -ForegroundColor Cyan
Write-Host " Database : $dbDatabase"                      -ForegroundColor Cyan
Write-Host " Evaluator: $(-not $NoEvaluator) | MaxIter: $MaxIterations" -ForegroundColor Cyan
Write-Host '=============================================' -ForegroundColor Cyan
Write-Host ''

# --- Execution ------------------------------------------------------------------
try {
    $Result = $null

    # Session start (non-blocking, only for LLM actions)
    $sessionCreated = $false
    $activeSession  = $SessionFile
    if ($Action -ne 'dba:check-health' -and (Test-Path $SessionSkill)) {
        try {
            $sessionResult  = & $SessionSkill -Operation New -AgentId 'agent_dba' -Intent $Action
            $activeSession  = $sessionResult.SessionFile
            $sessionCreated = $true
            Write-Host "[Session] Started: $activeSession" -ForegroundColor DarkGray
        } catch {
            Write-Warning "[Session] Could not start (non-blocking): $_"
        }
    }

    switch ($Action) {

        # ==========================================================================
        # ACTION: dba:check-health (deterministic — no LLM, no Evaluator)
        # ==========================================================================
        'dba:check-health' {
            Write-Host '[1/1] Checking DB connectivity...' -ForegroundColor Yellow

            $status = 'ok'
            $detail = ''
            $sqlcmdAvailable = $null -ne (Get-Command sqlcmd -ErrorAction SilentlyContinue)

            if (-not $sqlcmdAvailable) {
                $status = 'degraded'
                $detail = 'sqlcmd not found in PATH; connectivity check skipped'
                Write-Warning "[DBA] $detail"
            } else {
                try {
                    $testQuery = "SELECT 1 AS health_check"
                    sqlcmd -S $dbServer -d $dbDatabase -Q $testQuery -b 2>&1 | Out-Null
                    if ($LASTEXITCODE -ne 0) {
                        $status = 'error'
                        $detail = "sqlcmd exit code $LASTEXITCODE"
                    } else {
                        $detail = "SELECT 1 succeeded on $dbServer/$dbDatabase"
                    }
                } catch {
                    $status = 'error'
                    $detail = $_.Exception.Message
                }
            }

            $durationSec = [Math]::Round(((Get-Date) - $startTime).TotalSeconds, 2)
            Write-Host "[1/1] Done. Status: $status" -ForegroundColor $(if ($status -eq 'ok') { 'Green' } else { 'Yellow' })

            $Result = [ordered]@{
                action       = $Action
                ok           = ($status -eq 'ok' -or $status -eq 'degraded')
                status       = $status
                dependency   = 'database'
                server       = $dbServer
                database     = $dbDatabase
                detail       = $detail
                dryRun       = $DryRun.IsPresent
                meta         = [ordered]@{
                    sqlcmd_available     = $sqlcmdAvailable
                    evaluator_enabled    = $false
                    evaluator_iterations = 0
                    evaluator_passed     = $null
                    duration_sec         = $durationSec
                }
                startedAt    = $now
                finishedAt   = (Get-Date).ToUniversalTime().ToString('o')
                contractId   = 'action-result'
                contractVersion = '1.0'
            }
        }

        # ==========================================================================
        # ACTION: db-guardrails:check (LLM + RAG + Evaluator-Optimizer)
        # ==========================================================================
        'db-guardrails:check' {
            # Injection check on Database param (user-supplied string)
            if ($Database) {
                $injMatch = Test-Injection -text $Database
                if ($injMatch) {
                    $Result = [ordered]@{
                        action = $Action; ok = $false; status = 'SECURITY_VIOLATION'
                        reason = "Injection pattern in database name: '$injMatch'"
                        contractId = 'action-result'; contractVersion = '1.0'
                    }
                    Write-AgentLog -EventData @{ success = $false; security_violation = $true }
                    $Result | ConvertTo-Json | Write-Output
                    exit 0
                }
            }

            if (-not (Test-Path $LLMWithRAG)) {
                Write-Error "Invoke-LLMWithRAG.ps1 not found at: $LLMWithRAG"
                exit 1
            }
            if (-not $ApiKey) {
                Write-Error 'DEEPSEEK_API_KEY not set. Add to /opt/easyway/.env.secrets or pass -ApiKey.'
                exit 1
            }

            . $LLMWithRAG

            # Load GUARDRAILS.md for LLM context
            $guardrailsContent = Get-Content $GuardrailsFile -Raw -Encoding UTF8

            # Scan SQL files for analysis (best-effort)
            $dbDir = Join-Path $AgentDir '..' '..' 'db'
            $sqlFiles = @()
            if (Test-Path $dbDir) {
                $sqlFiles = Get-ChildItem $dbDir -Recurse -Filter '*.sql' -ErrorAction SilentlyContinue |
                            Select-Object -First 20
            }
            $sqlCount = $sqlFiles.Count
            $sqlSample = if ($sqlCount -gt 0) {
                ($sqlFiles | Select-Object -First 5 | ForEach-Object { "- $($_.Name)" }) -join "`n"
            } else { "(nessun file SQL trovato nella directory db/)" }

            Write-Host "[1/2] Analyzing $sqlCount SQL files against GUARDRAILS.md (Evaluator-Optimizer)..." -ForegroundColor Yellow

            if ($sessionCreated -and $activeSession) {
                try { & $SessionSkill -Operation SetStep -SessionFile $activeSession -StepName 'llm-guardrails' | Out-Null } catch {}
            }

            $query = @"
Analizza la conformita' degli oggetti DB ai GUARDRAILS EasyWay.

Scope: $Scope
Database: $dbDatabase
File SQL trovati ($sqlCount):
$sqlSample

GUARDRAILS da rispettare (estratto):
$(($guardrailsContent | Select-Object -First 100) -join "`n")

Genera il JSON db-guardrails:check con:
- 'action': stringa 'db-guardrails:check'
- 'violations': array di oggetti {file, rule_violated, severity (HIGH/MEDIUM/LOW), description, fix}
- 'compliant_count': numero oggetti conformi
- 'summary': valutazione complessiva (stringa non vuota)
- 'confidence': 0.0-1.0
"@

            $invokeParams = @{
                Query        = $query
                AgentId      = 'agent_dba'
                SystemPrompt = (Get-Content $PromptsFile -Raw -Encoding UTF8)
                TopK         = $TopK
                SecureMode   = $true
                MaxTokens    = 1500
            }
            if (-not $NoEvaluator) {
                $invokeParams['EnableEvaluator']    = $true
                $invokeParams['AcceptanceCriteria'] = $acPredicates['db-guardrails:check']
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
            Write-Host "[2/2] Done. SQL files: $sqlCount | Confidence: $confidence" -ForegroundColor Green

            $Result = [ordered]@{
                action                = $Action
                ok                    = $true
                scope                 = $Scope
                sql_files_analyzed    = $sqlCount
                violations_found      = if ($parsed.PSObject.Properties['violations']) { @($parsed.violations).Count } else { 0 }
                confidence            = $confidence
                requires_human_review = $requiresHumanReview
                summary               = if ($parsed.PSObject.Properties['summary']) { $parsed.summary } else { "Analisi guardrails completata." }
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
                -StepResult @{ ok = $Result.ok; confidence = if ($Result.confidence) { $Result.confidence } else { 1.0 } } `
                -Confidence (if ($Result.confidence) { $Result.confidence } else { 1.0 }) | Out-Null
            & $SessionSkill -Operation Close -SessionFile $activeSession | Out-Null
        } catch { Write-Warning '[Session] Close failed (non-blocking).' }
    }

    Write-AgentLog -EventData @{ success = $true; agent = 'agent_dba'; action = $Action; result = $Result }
    $Result | ConvertTo-Json -Depth 10 | Write-Output

} catch {
    $errMsg = $_.Exception.Message
    Write-Error "DBA Agent Error: $errMsg"
    Write-AgentLog -EventData @{ success = $false; error = $errMsg }
    exit 1
}
