#Requires -Version 5.1
<#
.SYNOPSIS
    Structured JSON telemetry logger for the EasyWay Agentic SDLC.
.DESCRIPTION
    Emits structured JSON events conforming to config/telemetry-event.schema.json.
    Events are appended to a JSONL (JSON Lines) file for downstream processing
    (Datadog, Splunk, Application Insights, or plain file analysis).

    See: config/telemetry-event.schema.json
    See: EASYWAY_AGENTIC_SDLC_MASTER.md section 5 (Telemetry)
.NOTES
    Part of Phase 9 Feature 18 - Structured Event Logging (PBI #21).
#>

# ── Module State ──────────────────────────────────────────────────────────────
$script:LogPath = $null
$script:TraceId = $null

# ── Initialize Logger ─────────────────────────────────────────────────────────

function Initialize-TelemetryLogger {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)] [string]$LogPath,
        [Parameter(Mandatory = $false)] [string]$TraceId
    )

    if ($LogPath) {
        $dir = [IO.Path]::GetDirectoryName($LogPath)
        if ($dir -and -not (Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
        $script:LogPath = $LogPath
    }
    else {
        $script:LogPath = Join-Path $PWD.Path 'out' 'telemetry.jsonl'
        $dir = [IO.Path]::GetDirectoryName($script:LogPath)
        if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
    }

    $script:TraceId = if ($TraceId) { $TraceId } else { [guid]::NewGuid().ToString().Substring(0, 8) }

    Write-Host "[Telemetry] Initialized: $($script:LogPath) (trace: $($script:TraceId))"
}

# ── Write Event ───────────────────────────────────────────────────────────────

function Write-TelemetryEvent {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]  [string]$AgentId,
        [Parameter(Mandatory = $true)]  [ValidateSet('L1', 'L2', 'L3', 'human', 'system')] [string]$AgentLevel,
        [Parameter(Mandatory = $true)]  [string]$Action,
        [Parameter(Mandatory = $true)]  [ValidateSet('success', 'failure', 'skipped', 'blocked', 'timeout')] [string]$Outcome,
        [Parameter(Mandatory = $false)] [ValidateSet('action', 'transition', 'gate', 'error', 'metric')] [string]$EventType = 'action',
        [Parameter(Mandatory = $false)] [string]$PrdId,
        [Parameter(Mandatory = $false)] [int]$WorkItemId,
        [Parameter(Mandatory = $false)] [string]$WorkItemType,
        [Parameter(Mandatory = $false)] [string]$PipelineState,
        [Parameter(Mandatory = $false)] [int]$DurationMs,
        [Parameter(Mandatory = $false)] [ValidateSet('High', 'Medium', 'Low')] [string]$Confidence,
        [Parameter(Mandatory = $false)] [hashtable]$Details,
        [Parameter(Mandatory = $false)] [hashtable]$Error
    )

    $telEvent = [ordered]@{
        timestamp  = (Get-Date).ToString('o')
        eventType  = $EventType
        traceId    = $script:TraceId
        spanId     = [guid]::NewGuid().ToString().Substring(0, 8)
        agentId    = $AgentId
        agentLevel = $AgentLevel
        action     = $Action
        outcome    = $Outcome
    }

    if ($PrdId) { $telEvent.prdId = $PrdId }
    if ($WorkItemId) { $telEvent.workItemId = $WorkItemId }
    if ($WorkItemType) { $telEvent.workItemType = $WorkItemType }
    if ($PipelineState) { $telEvent.pipelineState = $PipelineState }
    if ($DurationMs) { $telEvent.durationMs = $DurationMs }
    if ($Confidence) { $telEvent.confidence = $Confidence }
    if ($Details) { $telEvent.details = $Details }
    if ($Error) { $telEvent.error = $Error }

    $json = $telEvent | ConvertTo-Json -Depth 10 -Compress

    # Write to JSONL file
    if ($script:LogPath) {
        $json | Out-File -FilePath $script:LogPath -Append -Encoding utf8
    }

    # Also write to console for visibility
    $color = switch ($Outcome) {
        'success' { 'Green' }
        'failure' { 'Red' }
        'skipped' { 'Yellow' }
        'blocked' { 'DarkYellow' }
        'timeout' { 'Magenta' }
        default { 'Gray' }
    }
    Write-Host "[TEL] $AgentId/$Action -> $Outcome" -ForegroundColor $color

    return $telEvent
}

# ── Convenience: Measure Action Duration ──────────────────────────────────────

function Measure-AgentAction {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]  [string]$AgentId,
        [Parameter(Mandatory = $true)]  [ValidateSet('L1', 'L2', 'L3', 'human', 'system')] [string]$AgentLevel,
        [Parameter(Mandatory = $true)]  [string]$Action,
        [Parameter(Mandatory = $true)]  [scriptblock]$ScriptBlock,
        [Parameter(Mandatory = $false)] [string]$PrdId,
        [Parameter(Mandatory = $false)] [string]$PipelineState
    )

    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $outcome = 'success'
    $errorInfo = $null
    $result = $null

    try {
        $result = & $ScriptBlock
    }
    catch {
        $outcome = 'failure'
        $errorInfo = @{
            message    = $_.Exception.Message
            type       = $_.Exception.GetType().Name
            stackTrace = $_.ScriptStackTrace
        }
    }
    finally {
        $sw.Stop()
        $null = Write-TelemetryEvent `
            -AgentId $AgentId `
            -AgentLevel $AgentLevel `
            -Action $Action `
            -Outcome $outcome `
            -EventType 'action' `
            -PrdId $PrdId `
            -PipelineState $PipelineState `
            -DurationMs $sw.ElapsedMilliseconds `
            -Error $errorInfo
    }

    if ($errorInfo) { throw $errorInfo.message }
    return $result
}

# ── Read Telemetry Log ────────────────────────────────────────────────────────

function Read-TelemetryLog {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)] [string]$Path
    )

    $logFile = if ($Path) { $Path } else { $script:LogPath }
    if (-not $logFile -or -not (Test-Path $logFile)) {
        Write-Warning "No telemetry log found at: $logFile"
        return @()
    }

    $events = @()
    Get-Content $logFile -Encoding UTF8 | ForEach-Object {
        if ($_.Trim()) {
            $events += ($_ | ConvertFrom-Json)
        }
    }
    return $events
}

Export-ModuleMember -Function 'Initialize-TelemetryLogger', 'Write-TelemetryEvent', 'Measure-AgentAction', 'Read-TelemetryLog'
