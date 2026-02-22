#Requires -Version 5.1
<#
.SYNOPSIS
    Level 3 runner for agent_infra (The Cloud Engineer).

.DESCRIPTION
    Implements the L3 pattern: Evaluator-Optimizer + Working Memory + structured JSON output.

    Gap 1 - Evaluator-Optimizer: activated on infra:drift-check and infra:compliance-check
            via -EnableEvaluator with AC-04/05/07 predicates.
    Gap 2 - Working Memory: session.json tracks audit state across steps.
    Gap 4 - Structured output: risk_level, confidence, findings[] (vs free-form markdown in L2).

    Actions:
      infra:terraform-plan    - Execute terraform init/validate/plan (no apply). Scripted.
      infra:drift-check       - AI drift assessment (L3: Evaluator-Optimizer + structured JSON)
      infra:compliance-check  - AI compliance check against platform policies (L3: new)

.PARAMETER Action
    Action to perform. Default: infra:drift-check.

.PARAMETER Query
    Analysis context for LLM-based actions.

.PARAMETER IntentPath
    Path to a JSON intent file (alternative to inline params).

.PARAMETER Workdir
    Terraform working directory (infra:terraform-plan only). Default: infra/terraform.

.PARAMETER SessionFile
    Optional path to an existing session JSON. If empty, a new session is created.

.PARAMETER NoEvaluator
    Disable the Evaluator-Optimizer loop (single-shot generation).

.PARAMETER MaxIterations
    Max Evaluator-Optimizer iterations. Default: 2.

.EXAMPLE
    pwsh agents/agent_infra/Invoke-AgentInfra.ps1 -Query "Verifica drift: porta 9000 esposta"
    pwsh agents/agent_infra/Invoke-AgentInfra.ps1 -Action infra:compliance-check -Query "Porte esposte: 80, 443, 22"
    pwsh agents/agent_infra/Invoke-AgentInfra.ps1 -Action infra:terraform-plan -WhatIf -JsonOutput

.NOTES
    Evolution Level: 3 (LLM + RAG + Evaluator-Optimizer + Working Memory)
    Session 15 - agent_infra L3 promotion
    Confidence threshold: 0.70 (below => requires_human_review = true)
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [ValidateSet('infra:terraform-plan', 'infra:drift-check', 'infra:compliance-check')]
    [string]$Action = 'infra:drift-check',

    [Parameter(Mandatory = $false)] [string]$Query,
    [Parameter(Mandatory = $false)] [string]$IntentPath,
    [Parameter(Mandatory = $false)] [string]$Workdir,

    # L3 controls
    [Parameter(Mandatory = $false)] [string]$SessionFile = '',
    [Parameter(Mandatory = $false)] [switch]$NoEvaluator,
    [Parameter(Mandatory = $false)] [ValidateRange(1, 5)] [int]$MaxIterations = 2,
    [Parameter(Mandatory = $false)] [int]$TopK = 5,

    # Operational flags
    [Parameter(Mandatory = $false)] [string]$ApiKey = $env:DEEPSEEK_API_KEY,
    [switch]$WhatIf,
    [bool]$LogEvent = $true,
    [switch]$JsonOutput
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# --- Constants ------------------------------------------------------------------
$CONFIDENCE_THRESHOLD = 0.70

# --- Paths ----------------------------------------------------------------------
$AgentDir = $PSScriptRoot
$SkillsDir = Join-Path $AgentDir '..' 'skills'
$LLMWithRAG = Join-Path $SkillsDir 'retrieval' 'Invoke-LLMWithRAG.ps1'
$SessionSkill = Join-Path $SkillsDir 'session'   'Manage-AgentSession.ps1'
$PromptsFile = Join-Path $AgentDir  'PROMPTS.md'

foreach ($required in @($LLMWithRAG, $PromptsFile)) {
    if (-not (Test-Path $required)) {
        Write-Error "Required file not found: $required"
        exit 1
    }
}

# --- Bootstrap: load platform secrets (idempotent, non-destructive) ------------
# Ensures DEEPSEEK_API_KEY, QDRANT_API_KEY, GITEA_API_TOKEN are available.
$importSecretsSkill = Join-Path $SkillsDir 'utilities' 'Import-AgentSecrets.ps1'
if (Test-Path $importSecretsSkill) {
    . $importSecretsSkill
    Import-AgentSecrets -AgentId "agent_infra" | Out-Null
}
# Resolve ApiKey after secrets are loaded (param default evaluated before load)
if (-not $ApiKey) { $ApiKey = $env:DEEPSEEK_API_KEY }
if (-not $ApiKey) {
    Write-Error "DEEPSEEK_API_KEY not set. Add to /opt/easyway/.env.secrets or pass -ApiKey."
    exit 1
}

# --- Injection patterns (PS-level defense in depth) ----------------------------
$InjectionPatterns = @(
    '(?i)ignore\s+(all\s+)?(previous\s+)?instructions?',
    '(?i)override\s+(rules?|system|prompt)',
    '(?i)you\s+are\s+now\s+',
    '(?i)forget\s+(everything|all(\s+previous)?)',
    '(?i)new\s+(mission|instructions?)\s*:',
    '(?i)pretend\s+you\s+are',
    '(?i)disregard\s+(previous|instructions?)'
)

# --- Helper functions ----------------------------------------------------------
function Read-Intent($path) {
    if (-not $path) { return $null }
    if (-not (Test-Path $path)) { throw "Intent file not found: $path" }
    (Get-Content -Raw -Path $path) | ConvertFrom-Json
}

function Test-Injection([string]$text) {
    foreach ($pattern in $InjectionPatterns) {
        if ($text -match $pattern) { return $Matches[0] }
    }
    return $null
}

function Get-InfraOutput([string]$raw) {
    $json = ($raw -replace '(?s)```json\s*', '' -replace '(?s)```\s*', '').Trim()
    try {
        return $json | ConvertFrom-Json
    }
    catch {
        return [PSCustomObject]@{
            status                = 'WARNING'
            risk_level            = 'MEDIUM'
            confidence            = 0.5
            requires_human_review = $true
            findings              = @()
            summary               = $raw.Substring(0, [Math]::Min(500, $raw.Length))
            parse_error           = $true
        }
    }
}

function Write-AgentLog {
    param($EventData)
    if (-not $LogEvent) { return }
    $logDir = Join-Path $AgentDir '..' 'logs'
    if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir -Force | Out-Null }
    $entry = [ordered]@{ timestamp = (Get-Date).ToString('o'); agent = 'agent_infra'; data = $EventData }
    ($entry | ConvertTo-Json -Depth 5) | Out-File (Join-Path $logDir 'agent-history.jsonl') -Append -Encoding utf8
}

function Out-Result($obj) {
    if ($JsonOutput) { $obj | ConvertTo-Json -Depth 10 | Write-Output }
    else { $obj | ConvertTo-Json -Depth 5 | Write-Output }
}

# --- Init ----------------------------------------------------------------------
$intent = Read-Intent $IntentPath
if ($intent) {
    if ($intent.PSObject.Properties['action'] -and -not $PSBoundParameters.ContainsKey('Action')) { $Action = $intent.action }
    $p = if ($intent.PSObject.Properties['params']) { $intent.params } else { [PSCustomObject]@{} }
    if (-not $Query -and $p.PSObject.Properties['query']) { $Query = $p.query }
    if (-not $Workdir -and $p.PSObject.Properties['workdir']) { $Workdir = $p.workdir }
}

$now = (Get-Date).ToUniversalTime().ToString('o')
$startTime = Get-Date
$llmActions = @('infra:drift-check', 'infra:compliance-check')

# --- Header --------------------------------------------------------------------
Write-Host ''
Write-Host '=============================================' -ForegroundColor Cyan
Write-Host ' Agent Infra (The Cloud Engineer) L3'        -ForegroundColor Cyan
Write-Host " Action   : $Action"                          -ForegroundColor Cyan
if ($Action -in $llmActions) {
    Write-Host " Evaluator: $(-not $NoEvaluator) | MaxIter: $MaxIterations" -ForegroundColor Cyan
}
Write-Host '=============================================' -ForegroundColor Cyan
Write-Host ''

# --- Execution -----------------------------------------------------------------
try {
    $Result = $null

    switch ($Action) {

        # -- Scripted: infra:terraform-plan -------------------------------------
        'infra:terraform-plan' {
            $wd = if ($Workdir) { $Workdir } else { 'infra/terraform' }
            $executed = $false
            $errorMsg = $null

            if (-not (Test-Path $wd)) {
                $errorMsg = "Terraform dir not found: $wd"
            }
            if (-not $errorMsg -and -not $WhatIf) {
                if (-not (Get-Command terraform -ErrorAction SilentlyContinue)) {
                    $errorMsg = 'terraform not found in PATH'
                }
                else {
                    try {
                        Push-Location $wd
                        terraform init -input=false | Out-Host
                        terraform validate | Out-Host
                        terraform plan -input=false | Out-Host
                        $executed = $true
                    }
                    catch {
                        $errorMsg = $_.Exception.Message
                    }
                    finally {
                        Pop-Location
                    }
                }
            }

            $Result = [ordered]@{
                action          = $Action
                ok              = ($null -eq $errorMsg)
                whatIf          = [bool]$WhatIf
                startedAt       = $now
                finishedAt      = (Get-Date).ToUniversalTime().ToString('o')
                output          = [ordered]@{
                    workdir        = $wd
                    executed       = $executed
                    executed_apply = $false
                    hint           = 'Apply non implementato: richiede Human_Governance_Approval.'
                }
                error           = $errorMsg
                contractId      = 'action-result'
                contractVersion = '1.0'
            }
        }

        # -- L3 LLM actions: drift-check + compliance-check --------------------
        { $_ -in $llmActions } {

            # 0. Injection check
            if ($Query) {
                $injMatch = Test-Injection -text $Query
                if ($injMatch) {
                    $Result = [ordered]@{
                        action       = $Action
                        ok           = $false
                        status       = 'SECURITY_VIOLATION'
                        reason       = "Injection pattern detected: '$injMatch'"
                        action_taken = 'REJECT'
                    }
                    Write-AgentLog -EventData @{ success = $false; security_violation = $true; pattern = $injMatch }
                    Out-Result $Result
                    exit 0
                }
            }
            if ([string]::IsNullOrWhiteSpace($Query)) { throw "Query required for action '$Action'" }

            # 1. Load system prompt
            $systemPrompt = Get-Content $PromptsFile -Raw -Encoding UTF8

            # 2. Session start (non-blocking)
            $sessionCreated = $false
            $activeSession = $SessionFile
            if (Test-Path $SessionSkill) {
                try {
                    $sessionResult = & $SessionSkill -Operation New -AgentId 'agent_infra' -Intent $Action
                    $activeSession = $sessionResult.SessionFile
                    $sessionCreated = $true
                    Write-Host "[Session] Started: $activeSession" -ForegroundColor DarkGray
                }
                catch {
                    Write-Warning "[Session] Could not start (non-blocking): $_"
                }
            }

            # 3. LLM + RAG with Evaluator-Optimizer
            Write-Host "[1/2] Calling Invoke-LLMWithRAG (Evaluator-Optimizer)..." -ForegroundColor Yellow

            if ($sessionCreated -and $activeSession) {
                try { & $SessionSkill -Operation SetStep -SessionFile $activeSession -StepName 'llm-analysis' | Out-Null } catch { Write-Verbose "Session step tracking failed (non-critical): $_" }
            }

            . $LLMWithRAG

            $acPredicates = @(
                "AC-04: The output JSON must contain 'risk_level' with exactly one of: CRITICAL, HIGH, MEDIUM, LOW, INFO",
                "AC-05: The output JSON must contain a numeric 'confidence' field between 0.0 and 1.0",
                "AC-07: If risk_level is CRITICAL, HIGH, or MEDIUM, 'findings' must be a non-empty array where each entry has 'severity', 'resource', and 'drift' fields"
            )

            $invokeParams = @{
                Query        = $Query
                AgentId      = 'agent_infra'
                SystemPrompt = $systemPrompt
                TopK         = $TopK
                SecureMode   = $true
                MaxTokens    = 1500
            }
            if (-not $NoEvaluator) {
                $invokeParams['EnableEvaluator'] = $true
                $invokeParams['AcceptanceCriteria'] = $acPredicates
                $invokeParams['MaxIterations'] = $MaxIterations
            }
            if ($activeSession -and (Test-Path $activeSession)) {
                $invokeParams['SessionFile'] = $activeSession
            }

            $llmResult = Invoke-LLMWithRAG @invokeParams
            if (-not $llmResult.Success) { throw "LLM call failed: $($llmResult.Error)" }

            # 4. Parse output + confidence gating
            $parsed = Get-InfraOutput -raw $llmResult.Answer
            $riskLevel = if ($parsed.PSObject.Properties['risk_level']) { [string]$parsed.risk_level } else { 'UNKNOWN' }
            $confidence = if ($parsed.PSObject.Properties['confidence']) { [double]$parsed.confidence } else { 0.5 }
            $findings = if ($parsed.PSObject.Properties['findings']) { $parsed.findings }           else { @() }
            $llmStatus = if ($parsed.PSObject.Properties['status']) { [string]$parsed.status }     else { 'WARNING' }
            $summary = if ($parsed.PSObject.Properties['summary']) { [string]$parsed.summary }    else { $llmResult.Answer.Substring(0, [Math]::Min(300, $llmResult.Answer.Length)) }

            $requiresHumanReview = $confidence -lt $CONFIDENCE_THRESHOLD
            if ($requiresHumanReview) {
                Write-Host "  [!] Confidence $confidence < $CONFIDENCE_THRESHOLD - escalating to human review" -ForegroundColor Yellow
            }

            # 5. Session close
            if ($sessionCreated -and $activeSession) {
                try {
                    & $SessionSkill -Operation Update -SessionFile $activeSession `
                        -CompletedStep 'llm-analysis' `
                        -StepResult @{ risk_level = $riskLevel; confidence = $confidence; escalated = $requiresHumanReview } `
                        -Confidence $confidence | Out-Null
                    & $SessionSkill -Operation Close -SessionFile $activeSession | Out-Null
                }
                catch { Write-Warning '[Session] Close failed (non-blocking): $_' }
            }

            $durationSec = [Math]::Round(((Get-Date) - $startTime).TotalSeconds, 2)
            Write-Host "[2/2] Analysis complete. Risk: $riskLevel | Confidence: $confidence" -ForegroundColor Green

            $Result = [ordered]@{
                action                = $Action
                ok                    = $true
                status                = $llmStatus
                risk_level            = $riskLevel
                confidence            = $confidence
                requires_human_review = $requiresHumanReview
                findings              = $findings
                summary               = $summary
                meta                  = [ordered]@{
                    evaluator_enabled    = (-not $NoEvaluator)
                    evaluator_iterations = if ($llmResult.PSObject.Properties['EvaluatorIterations']) { $llmResult.EvaluatorIterations } else { 1 }
                    evaluator_passed     = if ($llmResult.PSObject.Properties['EvaluatorPassed']) { $llmResult.EvaluatorPassed }    else { $true }
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

    Write-AgentLog -EventData @{ success = $true; agent = 'agent_infra'; action = $Action; result = $Result }
    Out-Result $Result

}
catch {
    $errMsg = $_.Exception.Message
    Write-Error "Infra Error: $errMsg"
    Write-AgentLog -EventData @{ success = $false; error = $errMsg }
    exit 1
}
