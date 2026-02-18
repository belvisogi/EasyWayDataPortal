#Requires -Version 5.1
<#
.SYNOPSIS
    Level 3 RAG-enhanced runner for agent_review (The Critic).

.DESCRIPTION
    Implements the L3 pattern: RAG + LLM (DeepSeek) + Evaluator-Optimizer + Working Memory.

    Gap 1 - Evaluator-Optimizer: activated via -EnableEvaluator with action-specific AC predicates.
    Gap 2 - Working Memory: optional session file via -SessionFile for multi-step review tasks.

    Actions supported:
      review:docs-impact  - verify documentation alignment with code changes
      review:static       - lightweight static analysis (naming, structure)

.PARAMETER Query
    The review request. Include MR title, changed files, and context.

.PARAMETER Action
    Which review action to perform. Default: review:docs-impact.

.PARAMETER TopK
    Number of RAG chunks to retrieve from Qdrant. Default: 5.

.PARAMETER SessionFile
    Optional path to a session JSON file created by Manage-AgentSession.
    When provided, injects session context into the system prompt (Gap 2).

.PARAMETER NoEvaluator
    Disable the Evaluator-Optimizer loop (fallback to single-shot generation).

.PARAMETER MaxIterations
    Max Evaluator-Optimizer iterations. Default: 2.

.PARAMETER ApiKey
    DeepSeek API key. Defaults to $env:DEEPSEEK_API_KEY.

.EXAMPLE
    # Simple review
    pwsh run-with-rag.ps1 -Query "Rivedi MR: feat(api): add /api/v1/health. Modificati: api/routes/health.ts, Wiki/api/endpoints.md"

.EXAMPLE
    # With session (multi-step)
    $session = & ../../skills/session/Manage-AgentSession.ps1 -Operation New -AgentId agent_review -Intent "review:docs-impact"
    pwsh run-with-rag.ps1 -Query "..." -SessionFile $session.SessionFile

.EXAMPLE
    # Static analysis action
    pwsh run-with-rag.ps1 -Action review:static -Query "Analizza naming e struttura: agents/agent_review/PROMPTS.md"

.NOTES
    Evolution Level: 3 (LLM + RAG + Evaluator-Optimizer + Working Memory)
    Part of: Session 8 - agent_review L3 upgrade
    See: agents/AGENT_EVOLUTION_GUIDE.md, agents/QUICK_START.md
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, HelpMessage = "Review request with MR context and changed files")]
    [string]$Query,

    [Parameter(Mandatory = $false)]
    [ValidateSet("review:docs-impact", "review:static")]
    [string]$Action = "review:docs-impact",

    [Parameter(Mandatory = $false, HelpMessage = "Number of RAG chunks to retrieve")]
    [int]$TopK = 5,

    [Parameter(Mandatory = $false, HelpMessage = "Path to session JSON file for working memory (Gap 2)")]
    [string]$SessionFile = "",

    [Parameter(Mandatory = $false, HelpMessage = "Disable the Evaluator-Optimizer loop")]
    [switch]$NoEvaluator,

    [Parameter(Mandatory = $false, HelpMessage = "Max Evaluator-Optimizer iterations (default: 2)")]
    [int]$MaxIterations = 2,

    [Parameter(Mandatory = $false, HelpMessage = "DeepSeek API key (defaults to env var)")]
    [string]$ApiKey = $env:DEEPSEEK_API_KEY
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# ─── Resolve paths ────────────────────────────────────────────────────────────
$AgentDir    = $PSScriptRoot
$SkillsDir   = Join-Path $AgentDir ".." "skills"
$LLMWithRAG  = Join-Path $SkillsDir "retrieval" "Invoke-LLMWithRAG.ps1"
$SessionSkill = Join-Path $SkillsDir "session" "Manage-AgentSession.ps1"
$PromptsFile = Join-Path $AgentDir "PROMPTS.md"

foreach ($p in @($LLMWithRAG, $PromptsFile)) {
    if (-not (Test-Path $p)) {
        Write-Error "Required file not found: $p"
        exit 1
    }
}

# ─── API key validation ────────────────────────────────────────────────────────
if (-not $ApiKey) {
    Write-Error "DEEPSEEK_API_KEY is not set. Provide via -ApiKey or environment variable."
    exit 1
}

# ─── Load system prompt ───────────────────────────────────────────────────────
$systemPrompt = Get-Content $PromptsFile -Raw -Encoding UTF8

# ─── Acceptance Criteria per action ───────────────────────────────────────────
$acceptanceCriteria = switch ($Action) {
    "review:docs-impact" {
        @(
            "AC-01: Output contains one of the verdicts: APPROVE, REQUEST_CHANGES, or NEEDS_DISCUSSION",
            "AC-02: Output explicitly analyzes documentation impact (lists Wiki pages to update or confirms docs are complete)",
            "AC-03: Output references the code changes (mentions changed files, endpoints, or functional areas reviewed)",
            "AC-04: Output provides constructive recommendations or confirms all checks passed"
        )
    }
    "review:static" {
        @(
            "AC-01: Output assesses naming convention compliance (OK or VIOLATION with specific examples)",
            "AC-02: Output assesses structural compliance (correct file locations, import hygiene)",
            "AC-03: Output provides specific actionable recommendations, not just generic feedback",
            "AC-04: Output references the relevant platform standard for each finding"
        )
    }
}

# ─── Header ───────────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host " Agent Review (The Critic) - Level 3" -ForegroundColor Cyan
Write-Host " Action  : $Action" -ForegroundColor Cyan
Write-Host " Evaluator: $(-not $NoEvaluator) | MaxIter: $MaxIterations" -ForegroundColor Cyan
if ($SessionFile) {
    Write-Host " Session : $SessionFile" -ForegroundColor Cyan
}
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host ""

# ─── Session: update step if provided ─────────────────────────────────────────
if ($SessionFile -and (Test-Path $SessionFile) -and (Test-Path $SessionSkill)) {
    & $SessionSkill -Operation SetStep -SessionFile $SessionFile -StepName $Action | Out-Null
    Write-Host "[Session] Step set to: $Action" -ForegroundColor DarkGray
}

# ─── Dot-source and call Invoke-LLMWithRAG ───────────────────────────────────
Write-Host "[1/2] Calling Invoke-LLMWithRAG (Action: $Action)..." -ForegroundColor Yellow
. $LLMWithRAG

$invokeParams = @{
    Query          = $Query
    AgentId        = "agent_review"
    SystemPrompt   = $systemPrompt
    TopK           = $TopK
    ApiKey         = $ApiKey
    SecureMode     = $true
}

if (-not $NoEvaluator) {
    $invokeParams["EnableEvaluator"]      = $true
    $invokeParams["AcceptanceCriteria"]   = $acceptanceCriteria
    $invokeParams["MaxIterations"]        = $MaxIterations
}

if ($SessionFile -and (Test-Path $SessionFile)) {
    $invokeParams["SessionFile"] = $SessionFile
}

$result = Invoke-LLMWithRAG @invokeParams

# ─── Output ───────────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "[2/2] Review complete." -ForegroundColor Green
Write-Host ""
Write-Host "=============================================" -ForegroundColor Green
Write-Host " The Critic's Review" -ForegroundColor Green
Write-Host "=============================================" -ForegroundColor Green
Write-Host ""
Write-Host $result.Answer
Write-Host ""

if ($result.EvaluatorRuns -gt 0) {
    Write-Host "---------------------------------------------" -ForegroundColor DarkGray
    Write-Host " Evaluator: $($result.EvaluatorRuns) iteration(s), final: $($result.EvaluatorStatus)" -ForegroundColor DarkGray
}

if ($result.RAGChunks -gt 0) {
    Write-Host "---------------------------------------------" -ForegroundColor DarkGray
    Write-Host " RAG sources: $($result.RAGChunks) chunks retrieved" -ForegroundColor DarkGray
}

# ─── Session: update with result ──────────────────────────────────────────────
if ($SessionFile -and (Test-Path $SessionFile) -and (Test-Path $SessionSkill)) {
    $confidence = if ($result.EvaluatorStatus -eq "PASS") { 0.9 } `
                  elseif ($result.EvaluatorStatus -eq "DEGRADED") { 0.65 } `
                  else { 0.75 }

    & $SessionSkill -Operation Update `
        -SessionFile $SessionFile `
        -CompletedStep $Action `
        -StepResult @{
            verdict         = "see_output"
            evaluator_status = $result.EvaluatorStatus
            rag_chunks      = $result.RAGChunks
        } `
        -Confidence $confidence | Out-Null

    Write-Host " Session updated (confidence: $confidence)" -ForegroundColor DarkGray
}

Write-Host "=============================================" -ForegroundColor Green
Write-Host ""

return $result
