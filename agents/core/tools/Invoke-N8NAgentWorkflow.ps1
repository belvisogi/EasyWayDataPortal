<#
.SYNOPSIS
    Bridge script: n8n → EasyWay Agent Router.

.DESCRIPTION
    Receives JSON input from n8n (via stdin or -InputJson parameter),
    validates against n8n-agent-node.schema.json, loads the decision profile,
    routes to agent-llm-router, and returns structured JSON output.

    Designed to be called from n8n's "Execute Command" node:
        echo '{"agentId":"agent_dba","action":"invoke","prompt":"Check DB health"}' | pwsh -File Invoke-N8NAgentWorkflow.ps1

.PARAMETER InputJson
    JSON string conforming to n8n-agent-node.schema.json. If omitted, reads from stdin.

.EXAMPLE
    # From n8n Execute Command node:
    echo '{"agentId":"agent_dba","action":"invoke","prompt":"Check DB health"}' | pwsh -File Invoke-N8NAgentWorkflow.ps1

.OUTPUTS
    JSON: { status, result, usage, agentId, timestamp }
#>
param(
    [string]$InputJson
)

$ErrorActionPreference = "Stop"

# ── Read input ──
if ([string]::IsNullOrWhiteSpace($InputJson)) {
    # Read from stdin (piped from n8n)
    $InputJson = [Console]::In.ReadToEnd()
}

if ([string]::IsNullOrWhiteSpace($InputJson)) {
    $errorOutput = @{
        status    = "error"
        result    = @{ message = "No input provided. Pass JSON via stdin or -InputJson parameter." }
        usage     = @{}
        timestamp = (Get-Date -Format "o")
    }
    $errorOutput | ConvertTo-Json -Depth 5
    exit 1
}

# ── Parse input ──
try {
    $request = $InputJson | ConvertFrom-Json
}
catch {
    $errorOutput = @{
        status    = "error"
        result    = @{ message = "Invalid JSON input: $_" }
        usage     = @{}
        timestamp = (Get-Date -Format "o")
    }
    $errorOutput | ConvertTo-Json -Depth 5
    exit 1
}

# ── Validate required fields ──
$requiredFields = @("agentId", "action", "prompt")
foreach ($field in $requiredFields) {
    if (-not $request.PSObject.Properties[$field] -or [string]::IsNullOrWhiteSpace($request.$field)) {
        $errorOutput = @{
            status    = "error"
            result    = @{ message = "Missing required field: $field" }
            usage     = @{}
            timestamp = (Get-Date -Format "o")
        }
        $errorOutput | ConvertTo-Json -Depth 5
        exit 1
    }
}

# ── Validate action verb ──
$validActions = @("invoke", "plan", "feedback")
if ($request.action -notin $validActions) {
    $errorOutput = @{
        status    = "error"
        result    = @{ message = "Invalid action: '$($request.action)'. Must be one of: $($validActions -join ', ')" }
        usage     = @{}
        timestamp = (Get-Date -Format "o")
    }
    $errorOutput | ConvertTo-Json -Depth 5
    exit 1
}

# ── Load Decision Profile (if specified) ──
$decisionProfileData = $null
if ($request.decisionProfile -and $request.decisionProfile -ne "") {
    $profilePath = Join-Path $PSScriptRoot "..\..\agents\config\decision-profiles\$($request.decisionProfile).json"
    if (Test-Path $profilePath) {
        $decisionProfileData = Get-Content $profilePath -Raw | ConvertFrom-Json
        Write-Verbose "Loaded decision profile: $($request.decisionProfile)"
    }
    else {
        Write-Warning "Decision profile not found: $($request.decisionProfile)"
    }
}

# ── Build router arguments ──
$routerScript = Join-Path $PSScriptRoot "..\..\scripts\pwsh\agent-llm-router.ps1"
if (-not (Test-Path $routerScript)) {
    # Try alternate location
    $routerScript = Join-Path $PSScriptRoot "..\..\agents\core\tools\agent-llm-router.ps1"
}

$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

$routerArgs = @(
    "-Agent", $request.agentId,
    "-Action", $request.action,
    "-Prompt", "`"$($request.prompt)`""
)

if ($request.preference -and $request.preference -ne "") {
    $routerArgs += @("-Preference", $request.preference)
}

if ($request.decisionProfile -and $request.decisionProfile -ne "") {
    $routerArgs += @("-DecisionProfile", $request.decisionProfile)
}

if ($request.action -eq "plan") {
    $routerArgs += "-PlanOnly"
}

# ── Execute with timeout ──
$timeoutSec = if ($request.timeout_seconds) { $request.timeout_seconds } else { 120 }

try {
    # Use a job for timeout support
    $job = Start-Job -ScriptBlock {
        param($script, $args)
        & pwsh -NoProfile -File $script @args 2>&1
    } -ArgumentList $routerScript, $routerArgs

    $completed = Wait-Job -Job $job -Timeout $timeoutSec
    $output = Receive-Job -Job $job

    if (-not $completed -or $job.State -eq "Running") {
        Stop-Job -Job $job -ErrorAction SilentlyContinue
        Remove-Job -Job $job -Force -ErrorAction SilentlyContinue

        $stopwatch.Stop()
        $result = @{
            status    = "timeout"
            result    = @{ message = "Agent execution timed out after $timeoutSec seconds." }
            agentId   = $request.agentId
            usage     = @{ duration_ms = $stopwatch.ElapsedMilliseconds }
            timestamp = (Get-Date -Format "o")
        }
        $result | ConvertTo-Json -Depth 5
        exit 1
    }

    Remove-Job -Job $job -Force -ErrorAction SilentlyContinue
    $stopwatch.Stop()

    # ── Build success output ──
    $resultObj = @{
        status    = "success"
        result    = @{
            output = ($output | Out-String).Trim()
        }
        agentId   = $request.agentId
        action    = $request.action
        usage     = @{
            duration_ms = $stopwatch.ElapsedMilliseconds
        }
        timestamp = (Get-Date -Format "o")
    }

    if ($decisionProfileData) {
        $resultObj.decisionProfile = @{
            name       = $decisionProfileData.name
            risk_level = $decisionProfileData.risk_level
            threshold  = $decisionProfileData.auto_approve_threshold_usd
        }
    }

    $resultObj | ConvertTo-Json -Depth 5

}
catch {
    $stopwatch.Stop()
    $errorOutput = @{
        status    = "error"
        result    = @{ message = "Agent execution failed: $_" }
        agentId   = $request.agentId
        usage     = @{ duration_ms = $stopwatch.ElapsedMilliseconds }
        timestamp = (Get-Date -Format "o")
    }
    $errorOutput | ConvertTo-Json -Depth 5
    exit 1
}
