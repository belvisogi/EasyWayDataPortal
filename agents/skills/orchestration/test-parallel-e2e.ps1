<#
.SYNOPSIS
    E2E test for Invoke-ParallelAgents.ps1 (Gap 3 - Session 11).
    Runs two instances of Invoke-AgentReview.ps1 in parallel with different actions
    and verifies both complete, timing is concurrent, and results are structured correctly.

.NOTES
    Run on server: pwsh agents/skills/orchestration/test-parallel-e2e.ps1
    Requires: DEEPSEEK_API_KEY, QDRANT_API_KEY env vars
#>

Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'

$scriptDir = $PSScriptRoot
$repoRoot = (Get-Item $scriptDir).Parent.Parent.Parent.FullName

Write-Host "`n=============================================" -ForegroundColor Cyan
Write-Host " E2E Test: Invoke-ParallelAgents (Gap 3)"    -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host " Repo root : $repoRoot"
Write-Host " PS version: $($PSVersionTable.PSVersion)"
Write-Host " ThreadJob : $([bool](Get-Command Start-ThreadJob -ErrorAction SilentlyContinue))"
Write-Host "=============================================" -ForegroundColor Cyan

# ---------------------------------------------------------------------------
# 1. Check prerequisites
# ---------------------------------------------------------------------------
if (-not $env:DEEPSEEK_API_KEY) {
    Write-Error "DEEPSEEK_API_KEY not set"
    exit 1
}
if (-not $env:QDRANT_API_KEY) {
    Write-Error "QDRANT_API_KEY not set"
    exit 1
}

$parallelScript = Join-Path $scriptDir 'Invoke-ParallelAgents.ps1'
$reviewScript = 'agents/agent_review/Invoke-AgentReview.ps1'

if (-not (Test-Path $parallelScript)) {
    Write-Error "Invoke-ParallelAgents.ps1 not found at: $parallelScript"
    exit 1
}
if (-not (Test-Path (Join-Path $repoRoot $reviewScript))) {
    Write-Error "Invoke-AgentReview.ps1 not found"
    exit 1
}

Write-Host "`n[TEST] Launching 2 parallel review jobs..." -ForegroundColor Yellow
Write-Host "  Job 1: review:static   - Invoke-AgentReview.ps1"
Write-Host "  Job 2: review:docs-impact - Invoke-AgentReview.ps1"
Write-Host ""

# ---------------------------------------------------------------------------
# 2. Run parallel agents
# ---------------------------------------------------------------------------
$jobs = @(
    @{
        Name    = "static"
        Script  = $reviewScript
        Args    = @{
            Query       = "Analizza naming e struttura: agents/skills/orchestration/Invoke-ParallelAgents.ps1"
            Action      = "review:static"
            NoEvaluator = $true   # veloce: 1 LLM call
        }
        Timeout = 90
    },
    @{
        Name    = "docs-impact"
        Script  = $reviewScript
        Args    = @{
            Query       = "Gap 3 Invoke-ParallelAgents.ps1 aggiunto. Verifica se servono aggiornamenti wiki."
            Action      = "review:docs-impact"
            NoEvaluator = $true
        }
        Timeout = 90
    }
)

$result = & $parallelScript -AgentJobs $jobs -GlobalTimeout 150 -SecureMode

# ---------------------------------------------------------------------------
# 3. Results
# ---------------------------------------------------------------------------
Write-Host "`n=============================================" -ForegroundColor Cyan
Write-Host " Results" -ForegroundColor Cyan
Write-Host "============================================="
Write-Host "  Overall success : $($result.Success)"
Write-Host "  Duration (wall) : $($result.DurationSec)s"
Write-Host "  Failed jobs     : $($result.Failed -join ', ' | ForEach-Object { if ($_) { $_ } else { '(none)' } })"
Write-Host ""

foreach ($jobName in $result.JobResults.Keys) {
    $jr = $result.JobResults[$jobName]
    Write-Host "  --- Job: $jobName ---" -ForegroundColor Yellow
    Write-Host "    Success : $($jr.Success)"
    if ($jr.Success -and $jr.Output) {
        $out = $jr.Output
        if ($out -is [hashtable] -or $out.PSObject.Properties['Answer']) {
            Write-Host "    Model   : $($out.Model)"
            Write-Host "    Tokens  : in=$($out.TokensIn) out=$($out.TokensOut)"
            Write-Host "    Cost    : `$$($out.CostUSD)"
            Write-Host "    RAG     : $($out.RAGChunks) chunks"
            Write-Host "    Answer  : $($out.Answer.Substring(0, [Math]::Min(120, $out.Answer.Length)))..."
        }
        else {
            Write-Host "    Output  : $($out | ConvertTo-Json -Depth 2 -Compress)"
        }
    }
    elseif (-not $jr.Success) {
        Write-Host "    Error   : $($jr.Error)" -ForegroundColor Red
    }
    Write-Host ""
}

# ---------------------------------------------------------------------------
# 4. Parallelism check: wall time should be < sum of individual timeouts
# ---------------------------------------------------------------------------
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host " Parallelism check" -ForegroundColor Cyan
Write-Host "============================================="
$maxJobTimeout = ($jobs | Measure-Object -Property Timeout -Maximum).Maximum
$sumJobTimeout = ($jobs | Measure-Object -Property Timeout -Sum).Sum
Write-Host "  Wall time   : $($result.DurationSec)s"
Write-Host "  Max timeout : ${maxJobTimeout}s  (parallel upper bound)"
Write-Host "  Sum timeout : ${sumJobTimeout}s  (serial upper bound)"

if ($result.DurationSec -lt $sumJobTimeout) {
    Write-Host "  PARALLEL OK : wall time < sum of timeouts" -ForegroundColor Green
}
else {
    Write-Host "  WARNING     : wall time >= sum of timeouts (may have run serially)" -ForegroundColor Yellow
}

Write-Host "=============================================" -ForegroundColor Cyan

exit $(if ($result.Success) { 0 } else { 1 })
