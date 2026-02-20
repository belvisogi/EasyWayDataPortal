#Requires -Version 5.1
<#
.SYNOPSIS
    Level 3 Orchestrator: agent_pr_gate (The PR Guardian).

.DESCRIPTION
    Orchestrates parallel execution of agent_review, agent_security, and agent_infra
    to produce a unified PR verdict: APPROVE, REQUEST_CHANGES, or ESCALATE.

    Architecture:
      - NO LLM calls (programmatic aggregation only)
      - Parallel execution via Invoke-ParallelAgents
      - Verdict based on worst-case risk and confidence across agents

    Verdict logic:
      ESCALATE        - any agent failed, CRITICAL risk, or requires_human_review = true
      REQUEST_CHANGES - HIGH or MEDIUM risk, or review verdict != APPROVE
      APPROVE         - all LOW/INFO + review APPROVE + confidence >= 0.70

.PARAMETER Query
    PR context: title, changed files, diff summary, PR number.

.PARAMETER PrNumber
    Pull Request number (optional, for logging and output metadata).

.PARAMETER GlobalTimeout
    Max seconds for all parallel agents. Default: 300.

.PARAMETER NoEvaluator
    Disable Evaluator-Optimizer in child agents (faster, less accurate).

.PARAMETER ApiKey
    DeepSeek API key. Defaults to $env:DEEPSEEK_API_KEY (loaded via Import-AgentSecrets).

.PARAMETER LogEvent
    Write event to agents/logs/agent-history.jsonl. Default: $true.

.PARAMETER JsonOutput
    Output result as JSON only (no console decorations).

.EXAMPLE
    pwsh agents/agent_pr_gate/Invoke-AgentPRGate.ps1 -Query "PR #99 feat(api): add /health. Files: api/routes/health.ts, Wiki/api.md"
    pwsh agents/agent_pr_gate/Invoke-AgentPRGate.ps1 -Query "..." -PrNumber 99 -JsonOutput
    pwsh agents/agent_pr_gate/Invoke-AgentPRGate.ps1 -Query "..." -NoEvaluator -GlobalTimeout 180

.NOTES
    Evolution Level: 3 (Orchestrator - no LLM, programmatic verdict aggregation)
    Session 15 - agent_pr_gate implementation
    Child agents: agent_review (L3), agent_security (L3), agent_infra (L3)
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$Query,

    [Parameter(Mandatory = $false)]
    [string]$PrNumber = '',

    [Parameter(Mandatory = $false)]
    [int]$GlobalTimeout = 300,

    [Parameter(Mandatory = $false)]
    [switch]$NoEvaluator,

    [Parameter(Mandatory = $false)]
    [string]$ApiKey = $env:DEEPSEEK_API_KEY,

    [Parameter(Mandatory = $false)]
    [bool]$LogEvent = $true,

    [switch]$JsonOutput
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# --- Paths ------------------------------------------------------------------
$AgentDir = $PSScriptRoot
$SkillsDir = Join-Path $AgentDir '..' 'skills'
$ParallelScript = Join-Path $SkillsDir 'orchestration' 'Invoke-ParallelAgents.ps1'

if (-not (Test-Path $ParallelScript)) {
    Write-Error "Invoke-ParallelAgents.ps1 not found: $ParallelScript"
    exit 1
}

# --- Bootstrap: load platform secrets (idempotent, non-destructive) ---------
# Child jobs inherit env vars from this process - load secrets once here.
$importSecretsSkill = Join-Path $SkillsDir 'utilities' 'Import-AgentSecrets.ps1'
if (Test-Path $importSecretsSkill) {
    . $importSecretsSkill
    Import-AgentSecrets | Out-Null
}
if (-not $ApiKey) { $ApiKey = $env:DEEPSEEK_API_KEY }
if (-not $ApiKey) {
    Write-Error "DEEPSEEK_API_KEY not set. Add to /opt/easyway/.env.secrets or pass -ApiKey."
    exit 1
}

# --- Injection patterns (PS-level defense in depth) -------------------------
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
    foreach ($p in $InjectionPatterns) {
        if ($text -match $p) { return $Matches[0] }
    }
    return $null
}

# --- Helper: risk score / label ---------------------------------------------
function Get-RiskScore([string]$risk) {
    switch ($risk.ToUpper()) {
        'CRITICAL' { return 4 }
        'HIGH' { return 3 }
        'MEDIUM' { return 2 }
        'LOW' { return 1 }
        'INFO' { return 0 }
        default { return 2 }  # UNKNOWN -> MEDIUM (safe default)
    }
}

function Get-RiskLabel([int]$score) {
    switch ($score) {
        4 { return 'CRITICAL' }
        3 { return 'HIGH' }
        2 { return 'MEDIUM' }
        1 { return 'LOW' }
        0 { return 'INFO' }
        default { return 'MEDIUM' }
    }
}

# --- Helper: parse agent output (JSON string or PS object) ------------------
function Get-ParsedOutput($rawOutput) {
    if ($null -eq $rawOutput) { return $null }
    # Already a structured PS object with risk_level
    if ($rawOutput -is [System.Management.Automation.PSCustomObject] -and
        $rawOutput.PSObject.Properties['risk_level']) {
        return $rawOutput
    }
    # JSON string (from Out-Result in security/infra agents)
    $json = if ($rawOutput -is [array]) { $rawOutput -join "`n" } else { [string]$rawOutput }
    $json = ($json -replace '(?s)```json\s*', '' -replace '(?s)```\s*', '').Trim()
    try { return $json | ConvertFrom-Json } catch { return $null }
}

# --- Helper: extract verdict keyword from agent_review Answer text ----------
function Get-ReviewVerdict($reviewOutput) {
    if ($null -eq $reviewOutput) { return 'UNKNOWN' }
    $answer = ''
    if ($reviewOutput -is [System.Management.Automation.PSCustomObject] -and
        $reviewOutput.PSObject.Properties['Answer']) {
        $answer = $reviewOutput.Answer
    }
    else {
        $answer = [string]$reviewOutput
    }
    # Check in order of severity (most restrictive first)
    if ($answer -match '\bREQUEST_CHANGES\b') { return 'REQUEST_CHANGES' }
    if ($answer -match '\bNEEDS_DISCUSSION\b') { return 'NEEDS_DISCUSSION' }
    if ($answer -match '\bAPPROVE\b') { return 'APPROVE' }
    return 'UNKNOWN'
}

# --- Helper: write gate log -------------------------------------------------
function Write-GateLog($data) {
    if (-not $LogEvent) { return }
    $logDir = Join-Path $AgentDir '..' 'logs'
    if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir -Force | Out-Null }
    $entry = [ordered]@{ timestamp = (Get-Date).ToString('o'); agent = 'agent_pr_gate'; data = $data }
    ($entry | ConvertTo-Json -Depth 5) | Out-File (Join-Path $logDir 'agent-history.jsonl') -Append -Encoding utf8
}

function Out-GateResult($obj) {
    if ($JsonOutput) { $obj | ConvertTo-Json -Depth 10 | Write-Output }
    else { $obj | ConvertTo-Json -Depth 5 | Write-Output }
}

# ---------------------------------------------------------------------------
# INJECTION GUARD — before dispatch to child agents
# ---------------------------------------------------------------------------
$injMatch = Test-Injection -text $Query
if ($injMatch) {
    $rejectResult = [ordered]@{
        action       = 'gate:pr-check'
        ok           = $false
        verdict      = 'ESCALATE'
        status       = 'SECURITY_VIOLATION'
        reason       = "Injection pattern detected: '$injMatch'"
        action_taken = 'REJECT'
    }
    Write-GateLog @{ success = $false; security_violation = $true; pattern = $injMatch }
    Out-GateResult $rejectResult
    exit 0
}

# --- Header -----------------------------------------------------------------
Write-Host ''
Write-Host '=============================================' -ForegroundColor Cyan
Write-Host ' Agent PR Gate (The PR Guardian)           ' -ForegroundColor Cyan
Write-Host " Action   : gate:pr-check"                   -ForegroundColor Cyan
if ($PrNumber) { Write-Host " PR       : #$PrNumber"     -ForegroundColor Cyan }
Write-Host " Evaluator: $(-not $NoEvaluator) | Timeout: ${GlobalTimeout}s" -ForegroundColor Cyan
Write-Host '=============================================' -ForegroundColor Cyan
Write-Host ''

$startTime = Get-Date
$noEvalBool = [bool]$NoEvaluator

# ---------------------------------------------------------------------------
# BUILD AGENT JOB DEFINITIONS
# ---------------------------------------------------------------------------
$reviewArgs = @{
    Query  = $Query
    Action = 'review:docs-impact'
}
$secArgs = @{
    Query      = $Query
    Action     = 'security:analyze'
    JsonOutput = $true
}
$infraArgs = @{
    Query      = $Query
    Action     = 'infra:compliance-check'
    JsonOutput = $true
}
# Only pass NoEvaluator when it is actually set (avoids splatting $false for switch)
if ($noEvalBool) {
    $reviewArgs['NoEvaluator'] = $true
    $secArgs['NoEvaluator'] = $true
    $infraArgs['NoEvaluator'] = $true
}

$agentJobs = @(
    @{
        Name    = 'review'
        Script  = 'agents/agent_review/Invoke-AgentReview.ps1'
        Args    = $reviewArgs
        Timeout = 180
    },
    @{
        Name    = 'security'
        Script  = 'agents/agent_security/Invoke-AgentSecurity.ps1'
        Args    = $secArgs
        Timeout = 180
    },
    @{
        Name    = 'infra'
        Script  = 'agents/agent_infra/Invoke-AgentInfra.ps1'
        Args    = $infraArgs
        Timeout = 180
    }
)

# ---------------------------------------------------------------------------
# STEP 1 — PARALLEL EXECUTION
# ---------------------------------------------------------------------------
Write-Host '[1/3] Launching parallel agents: review + security + infra...' -ForegroundColor Yellow

$parallelResult = & $ParallelScript -AgentJobs $agentJobs -GlobalTimeout $GlobalTimeout -SecureMode

Write-Host '[2/3] Aggregating results...' -ForegroundColor Yellow

$jr = $parallelResult.JobResults

# ---------------------------------------------------------------------------
# STEP 2 — COLLECT PER-AGENT OUTCOMES
# ---------------------------------------------------------------------------
$reviewSuccess = ($jr.Contains('review') -and $jr['review'].Success)
$secSuccess = ($jr.Contains('security') -and $jr['security'].Success)
$infraSuccess = ($jr.Contains('infra') -and $jr['infra'].Success)

$failedAgents = [System.Collections.Generic.List[string]]::new()
if (-not $reviewSuccess) { $failedAgents.Add('review') }
if (-not $secSuccess) { $failedAgents.Add('security') }
if (-not $infraSuccess) { $failedAgents.Add('infra') }

# --- Parse structured output ------------------------------------------------
$secParsed = if ($secSuccess) { Get-ParsedOutput $jr['security'].Output } else { $null }
$infraParsed = if ($infraSuccess) { Get-ParsedOutput $jr['infra'].Output }    else { $null }
$reviewRaw = if ($reviewSuccess) { $jr['review'].Output }                   else { $null }

# --- Risk levels ------------------------------------------------------------
$secRisk = if ($secParsed -and $secParsed.PSObject.Properties['risk_level']) { [string]$secParsed.risk_level } else { 'MEDIUM' }
$infraRisk = if ($infraParsed -and $infraParsed.PSObject.Properties['risk_level']) { [string]$infraParsed.risk_level } else { 'MEDIUM' }

# --- Confidence values ------------------------------------------------------
$secConf = if ($secParsed -and $secParsed.PSObject.Properties['confidence']) { [double]$secParsed.confidence } else { 0.5 }
$infraConf = if ($infraParsed -and $infraParsed.PSObject.Properties['confidence']) { [double]$infraParsed.confidence } else { 0.5 }

# --- Human review flags -----------------------------------------------------
$secHuman = if ($secParsed -and $secParsed.PSObject.Properties['requires_human_review']) { [bool]$secParsed.requires_human_review } else { $false }
$infraHuman = if ($infraParsed -and $infraParsed.PSObject.Properties['requires_human_review']) { [bool]$infraParsed.requires_human_review } else { $false }

# --- Review verdict (keyword extracted from Answer text) --------------------
$reviewVerdict = Get-ReviewVerdict $reviewRaw

# --- Metadata (safe accessors) ----------------------------------------------
$secMeta = if ($secParsed -and $secParsed.PSObject.Properties['meta']) { $secParsed.meta }  else { $null }
$infraMeta = if ($infraParsed -and $infraParsed.PSObject.Properties['meta']) { $infraParsed.meta } else { $null }

# ---------------------------------------------------------------------------
# STEP 3 — VERDICT AGGREGATION
# ---------------------------------------------------------------------------
$worstRiskScore = [Math]::Max(
    (Get-RiskScore $secRisk),
    (Get-RiskScore $infraRisk)
)
# Failed agent = treat as at least HIGH risk
if ($failedAgents.Count -gt 0) {
    $worstRiskScore = [Math]::Max($worstRiskScore, 3)
}

$overallRisk = Get-RiskLabel $worstRiskScore
$overallConfidence = [Math]::Round([Math]::Min($secConf, $infraConf), 4)
$requiresHuman = $secHuman -or $infraHuman

$verdict = if ($failedAgents.Count -gt 0 -or $overallRisk -eq 'CRITICAL' -or $requiresHuman -or $overallConfidence -lt 0.70) {
    'ESCALATE'
}
elseif ($overallRisk -in @('HIGH', 'MEDIUM') -or $reviewVerdict -in @('REQUEST_CHANGES', 'NEEDS_DISCUSSION', 'UNKNOWN')) {
    'REQUEST_CHANGES'
}
else {
    'APPROVE'
}

# --- Collect blocking findings (CRITICAL or HIGH) ---------------------------
$blockingFindings = [System.Collections.Generic.List[object]]::new()
foreach ($pair in @(@('security', $secParsed), @('infra', $infraParsed))) {
    $agentName = $pair[0]
    $parsed = $pair[1]
    if ($null -eq $parsed) { continue }
    if (-not $parsed.PSObject.Properties['findings']) { continue }
    foreach ($f in $parsed.findings) {
        $sev = if ($f.PSObject.Properties['severity']) { [string]$f.severity } else { 'UNKNOWN' }
        if ((Get-RiskScore $sev) -ge (Get-RiskScore 'HIGH')) {
            $blockingFindings.Add([PSCustomObject]@{ agent = $agentName; finding = $f })
        }
    }
}

# ---------------------------------------------------------------------------
# STEP 4 — BUILD OUTPUT
# ---------------------------------------------------------------------------
$durationSec = [Math]::Round(((Get-Date) - $startTime).TotalSeconds, 2)
$verdictColor = if ($verdict -eq 'APPROVE') { 'Green' } elseif ($verdict -eq 'ESCALATE') { 'Red' } else { 'Yellow' }

$summaryParts = @()
if ($failedAgents.Count -gt 0) { $summaryParts += "FAILED: $($failedAgents -join ', ')" }
$summaryParts += "Review: $reviewVerdict"
$summaryParts += "Security: $secRisk (conf $secConf)"
$summaryParts += "Infra: $infraRisk (conf $infraConf)"
$summaryText = $summaryParts -join ' | '

# Cost computation
$reviewCost = if ($reviewRaw -and $reviewRaw.PSObject.Properties['CostUSD']) { [double]$reviewRaw.CostUSD } else { 0.0 }
$secCost = if ($secMeta -and $secMeta.PSObject.Properties['cost_usd']) { [double]$secMeta.cost_usd } else { 0.0 }
$infraCost = if ($infraMeta -and $infraMeta.PSObject.Properties['cost_usd']) { [double]$infraMeta.cost_usd } else { 0.0 }
$totalCost = [Math]::Round($reviewCost + $secCost + $infraCost, 6)

# Findings count
$secFindCount = if ($secParsed -and $secParsed.PSObject.Properties['findings']) { @($secParsed.findings).Count } else { 0 }
$infraFindCount = if ($infraParsed -and $infraParsed.PSObject.Properties['findings']) { @($infraParsed.findings).Count } else { 0 }

$gateResult = [ordered]@{
    action                = 'gate:pr-check'
    ok                    = $true
    verdict               = $verdict
    overall_risk          = $overallRisk
    overall_confidence    = $overallConfidence
    requires_human_review = ($requiresHuman -or ($verdict -eq 'ESCALATE'))
    blocking_findings     = $blockingFindings.ToArray()
    summary               = $summaryText
    agents                = [ordered]@{
        review   = [ordered]@{
            success          = $reviewSuccess
            verdict          = $reviewVerdict
            rag_chunks       = if ($reviewRaw -and $reviewRaw.PSObject.Properties['RAGChunks']) { $reviewRaw.RAGChunks }     else { 0 }
            evaluator_status = if ($reviewRaw -and $reviewRaw.PSObject.Properties['EvaluatorStatus']) { $reviewRaw.EvaluatorStatus } else { 'N/A' }
            cost_usd         = $reviewCost
            error            = if (-not $reviewSuccess -and $jr.Contains('review')) { $jr['review'].Error } else { $null }
        }
        security = [ordered]@{
            success               = $secSuccess
            risk_level            = $secRisk
            confidence            = $secConf
            requires_human_review = $secHuman
            findings_count        = $secFindCount
            rag_chunks            = if ($secMeta -and $secMeta.PSObject.Properties['rag_chunks']) { $secMeta.rag_chunks } else { 0 }
            cost_usd              = $secCost
            error                 = if (-not $secSuccess -and $jr.Contains('security')) { $jr['security'].Error } else { $null }
        }
        infra    = [ordered]@{
            success               = $infraSuccess
            risk_level            = $infraRisk
            confidence            = $infraConf
            requires_human_review = $infraHuman
            findings_count        = $infraFindCount
            rag_chunks            = if ($infraMeta -and $infraMeta.PSObject.Properties['rag_chunks']) { $infraMeta.rag_chunks } else { 0 }
            cost_usd              = $infraCost
            error                 = if (-not $infraSuccess -and $jr.Contains('infra')) { $jr['infra'].Error } else { $null }
        }
    }
    meta                  = [ordered]@{
        failed_agents     = $failedAgents.ToArray()
        duration_sec      = $durationSec
        parallel_wall_sec = $parallelResult.DurationSec
        total_cost_usd    = $totalCost
    }
    pr_number             = $PrNumber
    startedAt             = $startTime.ToUniversalTime().ToString('o')
    finishedAt            = (Get-Date).ToUniversalTime().ToString('o')
    contractId            = 'action-result'
    contractVersion       = '1.0'
}

Write-Host "[3/3] Verdict: $verdict | Risk: $overallRisk | Confidence: $overallConfidence | Cost: `$$totalCost" -ForegroundColor $verdictColor
Write-Host ''

Write-GateLog @{ success = $true; agent = 'agent_pr_gate'; verdict = $verdict; overall_risk = $overallRisk; pr_number = $PrNumber }
Out-GateResult $gateResult
