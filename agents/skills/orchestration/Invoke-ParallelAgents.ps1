<#
.SYNOPSIS
    Skill: orchestration.parallel-agents v1.0.0
    Run multiple agent scripts concurrently and return merged results.

.DESCRIPTION
    Executes an array of agent jobs in parallel using Start-ThreadJob (PS7+)
    or Start-Job (PS5.1 fallback). Waits for all jobs up to GlobalTimeout,
    then collects and merges results.

    Part of the EasyWay Agent Skills registry v2.8.0 (Gap 3 - Session 10).

.PARAMETER AgentJobs
    Array of hashtables. Each entry must have:
      Name    - logical label used as key in JobResults
      Script  - path to the agent script (.ps1)
      Args    - hashtable of named parameters for the script
      Timeout - per-job timeout in seconds (default: 120)

.PARAMETER GlobalTimeout
    Maximum seconds to wait for ALL jobs to complete. Default: 180.
    After timeout, running jobs are stopped and marked as Failed.

.PARAMETER FailFast
    If set: the first job failure aborts all remaining jobs immediately.

.PARAMETER SecureMode
    If set: suppresses logging of sensitive fields (ApiKey, credentials).

.OUTPUTS
    Hashtable with keys:
      Success     [bool]      - True if at least one job succeeded
      JobResults  [hashtable] - keyed by Name; each value is the job output or error
      Failed      [string[]]  - names of jobs that failed or timed out
      DurationSec [double]    - total wall-clock time

.EXAMPLE
    # Run agent_review + agent_security in parallel for the same PR
    $results = Invoke-ParallelAgents -AgentJobs @(
        @{
            Name    = "review"
            Script  = "agents/agent_review/Invoke-AgentReview.ps1"
            Args    = @{ Query = "PR #42 docs check"; Action = "review:static" }
            Timeout = 120
        },
        @{
            Name    = "security"
            Script  = "agents/agent_security/run-with-rag.ps1"
            Args    = @{ Query = "PR #42 security scan"; Action = "security:analyze" }
            Timeout = 90
        }
    ) -GlobalTimeout 150 -SecureMode

    $results.JobResults["review"].Answer
    $results.Failed   # @() if all succeeded

.NOTES
    - Start-ThreadJob shares the calling process memory space (PS7+, faster).
    - Start-Job spawns a new PowerShell process (PS5.1+, subprocess isolation).
    - Script paths are resolved relative to the repository root (parent of agents/).
    - Each job runs in its own PowerShell scope; imported env vars are inherited.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [array]$AgentJobs,

    [int]$GlobalTimeout = 180,

    [switch]$FailFast,

    [switch]$SecureMode
)

Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'

# ---------------------------------------------------------------------------
# Resolve repo root (three levels up: orchestration/ -> skills/ -> agents/ -> repo)
# ---------------------------------------------------------------------------
$repoRoot = (Get-Item $PSScriptRoot).Parent.Parent.Parent.FullName

# ---------------------------------------------------------------------------
# Detect Start-ThreadJob availability (PS7+)
# ---------------------------------------------------------------------------
$useThreadJob = [bool](Get-Command Start-ThreadJob -ErrorAction SilentlyContinue)
$jobEngine = if ($useThreadJob) { 'Start-ThreadJob (PS7)' } else { 'Start-Job (PS5.1)' }

if (-not $SecureMode) {
    Write-Host "[Invoke-ParallelAgents] Starting $($AgentJobs.Count) jobs using $jobEngine" -ForegroundColor Cyan
    Write-Host "[Invoke-ParallelAgents] GlobalTimeout: ${GlobalTimeout}s | FailFast: $($FailFast.IsPresent)" -ForegroundColor Cyan
}

$startTime = [datetime]::UtcNow
$jobs      = @{}   # Name -> Job object
$results   = @{}   # Name -> output hashtable
$failed    = [System.Collections.Generic.List[string]]::new()

# ---------------------------------------------------------------------------
# Launch all jobs
# ---------------------------------------------------------------------------
foreach ($jobDef in $AgentJobs) {
    $name    = $jobDef.Name
    $script  = Join-Path $repoRoot $jobDef.Script
    $args_   = if ($jobDef.ContainsKey('Args')) { $jobDef.Args } else { @{} }
    $timeout = if ($jobDef.ContainsKey('Timeout')) { $jobDef.Timeout } else { 120 }

    if (-not (Test-Path $script)) {
        Write-Warning "[Invoke-ParallelAgents] Script not found for '$name': $script — skipping"
        $failed.Add($name)
        $results[$name] = @{ Success = $false; Error = "Script not found: $script" }
        continue
    }

    if (-not $SecureMode) {
        Write-Host "[Invoke-ParallelAgents] Launching '$name' -> $($jobDef.Script)" -ForegroundColor Gray
    }

    # Capture $script, $args_, $timeout for closure
    $capturedScript  = $script
    $capturedArgs    = $args_
    $capturedTimeout = $timeout

    $scriptBlock = {
        param($ScriptPath, $ScriptArgs, $JobTimeout)
        # 'Continue' prevents Python/native stderr warnings from becoming terminating errors
        # while still allowing the agent script's own error handling to work correctly.
        $ErrorActionPreference = 'Continue'
        try {
            $result = & $ScriptPath @ScriptArgs
            if ($LASTEXITCODE -and $LASTEXITCODE -ne 0) {
                return @{ Success = $false; Error = "Script exited with code $LASTEXITCODE"; Output = $result }
            }
            return @{ Success = $true; Output = $result }
        } catch {
            return @{ Success = $false; Error = $_.Exception.Message; Output = $null }
        }
    }

    try {
        if ($useThreadJob) {
            $job = Start-ThreadJob -ScriptBlock $scriptBlock `
                -ArgumentList $capturedScript, $capturedArgs, $capturedTimeout `
                -Name $name
        } else {
            $job = Start-Job -ScriptBlock $scriptBlock `
                -ArgumentList $capturedScript, $capturedArgs, $capturedTimeout `
                -Name $name
        }
        $jobs[$name] = @{ Job = $job; Timeout = $capturedTimeout; LaunchedAt = [datetime]::UtcNow }
    } catch {
        Write-Warning "[Invoke-ParallelAgents] Failed to launch '$name': $_"
        $failed.Add($name)
        $results[$name] = @{ Success = $false; Error = "Launch failed: $_" }
    }
}

# ---------------------------------------------------------------------------
# Wait and collect results
# ---------------------------------------------------------------------------
$deadline = $startTime.AddSeconds($GlobalTimeout)

while ($jobs.Count -gt 0 -and [datetime]::UtcNow -lt $deadline) {
    $toRemove = @()

    foreach ($name in $jobs.Keys) {
        $entry = $jobs[$name]
        $job   = $entry.Job

        # Check per-job timeout
        $elapsed = ([datetime]::UtcNow - $entry.LaunchedAt).TotalSeconds
        if ($elapsed -gt $entry.Timeout) {
            Write-Warning "[Invoke-ParallelAgents] Job '$name' timed out after $($entry.Timeout)s"
            Stop-Job -Job $job -ErrorAction SilentlyContinue
            Remove-Job -Job $job -Force -ErrorAction SilentlyContinue
            $failed.Add($name)
            $results[$name] = @{ Success = $false; Error = "Timed out after $($entry.Timeout)s" }
            $toRemove += $name

            if ($FailFast) {
                Write-Warning "[Invoke-ParallelAgents] FailFast: aborting remaining jobs"
                break
            }
            continue
        }

        # Check if completed
        if ($job.State -in 'Completed', 'Failed', 'Stopped') {
            try {
                $output = Receive-Job -Job $job -ErrorAction SilentlyContinue
                if ($job.State -eq 'Completed' -and $output -and $output.PSObject.Properties['Success']) {
                    $results[$name] = $output
                    if (-not $output.Success) { $failed.Add($name) }
                } elseif ($job.State -eq 'Failed') {
                    $results[$name] = @{ Success = $false; Error = "Job state: Failed" }
                    $failed.Add($name)
                } else {
                    $results[$name] = @{ Success = $true; Output = $output }
                }
            } catch {
                $results[$name] = @{ Success = $false; Error = $_.Exception.Message }
                $failed.Add($name)
            }
            Remove-Job -Job $job -Force -ErrorAction SilentlyContinue
            $toRemove += $name

            if ($FailFast -and $failed.Contains($name)) {
                Write-Warning "[Invoke-ParallelAgents] FailFast: aborting remaining jobs"
                break
            }
        }
    }

    foreach ($n in $toRemove) { $jobs.Remove($n) }

    if ($jobs.Count -gt 0) {
        Start-Sleep -Milliseconds 500
    }
}

# ---------------------------------------------------------------------------
# Handle global timeout: stop remaining jobs
# ---------------------------------------------------------------------------
foreach ($name in $jobs.Keys) {
    Write-Warning "[Invoke-ParallelAgents] Global timeout: stopping '$name'"
    Stop-Job  -Job $jobs[$name].Job -ErrorAction SilentlyContinue
    Remove-Job -Job $jobs[$name].Job -Force -ErrorAction SilentlyContinue
    $failed.Add($name)
    $results[$name] = @{ Success = $false; Error = "Aborted by GlobalTimeout (${GlobalTimeout}s)" }
}

# ---------------------------------------------------------------------------
# Build return value
# ---------------------------------------------------------------------------
$durationSec = ([datetime]::UtcNow - $startTime).TotalSeconds
$overallSuccess = ($failed.Count -eq 0) -or ($results.Values | Where-Object { $_.Success } | Select-Object -First 1)

$summary = @{
    Success     = [bool]$overallSuccess
    JobResults  = $results
    Failed      = $failed.ToArray()
    DurationSec = [math]::Round($durationSec, 2)
}

if (-not $SecureMode) {
    $successCount = ($results.Values | Where-Object { $_.Success }).Count
    Write-Host "[Invoke-ParallelAgents] Done: $successCount/$($results.Count) succeeded in $($summary.DurationSec)s" `
        -ForegroundColor ($failed.Count -eq 0 ? 'Green' : 'Yellow')
    if ($failed.Count -gt 0) {
        Write-Warning "[Invoke-ParallelAgents] Failed jobs: $($failed -join ', ')"
    }
}

return $summary
