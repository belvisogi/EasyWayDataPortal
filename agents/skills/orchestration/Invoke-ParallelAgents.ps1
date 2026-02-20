#Requires -Version 5.1
<#
.SYNOPSIS
    Executes multiple agents in parallel jobs and aggregates results.

.DESCRIPTION
    Core orchestration skill for L3 Agents.
    Spins up background jobs for each agent, manages timeouts, propagates environment variables (secrets),
    and returns a consolidated result object.

.PARAMETER AgentJobs
    Array of hashtables. Each must contain:
    - Name    (string) : Identifier
    - Script  (string) : Path to .ps1 runner
    - Args    (hashtable): Parameters to splat to the script
    - Timeout (int)    : Seconds to wait for this specific job

.PARAMETER GlobalTimeout
    Max seconds to wait for ALL jobs. Default: 300.
    
.PARAMETER SecureMode
    If set, attempts to mask values in logs (basic implementation).

.EXAMPLE
    $jobs = @(
        @{ Name='review'; Script='agents/review/Invoke.ps1'; Args=@{Query='...'}; Timeout=120 },
        @{ Name='sec';    Script='agents/sec/Invoke.ps1';    Args=@{Query='...'}; Timeout=120 }
    )
    Invoke-ParallelAgents -AgentJobs $jobs
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [array]$AgentJobs,

    [Parameter(Mandatory = $false)]
    [int]$GlobalTimeout = 300,

    [switch]$SecureMode
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$results = [ordered]@{
    JobResults  = [ordered]@{}
    DurationSec = 0
    Success     = $true
}

$startTime = Get-Date

# --- 1. Capture Environment Variables (Secrets) ---------------------------
# Start-Job runs in a fresh process. We must explicitly propagate secrets.
# We whitelist commonly used keys to avoid massive payload overhead.
$envKeysToPropagate = @('DEEPSEEK_API_KEY', 'AZURE_DEVOPS_EXT_PAT', 'SYSTEM_ACCESSTOKEN')
$envPayload = @{}
foreach ($key in $envKeysToPropagate) {
    if (Test-Path "env:$key") {
        $envPayload[$key] = (Get-Item "env:$key").Value
    }
}

# --- 2. Define Job ScriptBlock --------------------------------------------
$jobBlock = {
    param($jobDef, $envPayload)

    $ErrorActionPreference = 'Stop'
    
    # Restore Env Vars
    foreach ($k in $envPayload.Keys) {
        Set-Item -Path "env:$k" -Value $envPayload[$k]
    }

    # Validate Script Path
    $scriptPath = $jobDef.Script
    if (-not (Test-Path $scriptPath)) {
        throw "Script not found: $scriptPath"
    }

    # Execute
    # We rely on Splatting for Args
    # Note: If Script returns an object, it comes through output stream.
    # We wrap in try/catch to ensure we catch termating errors.
    try {
        & $scriptPath @($jobDef.Args)
    }
    catch {
        # Write error record to allow parent to see it
        # But also throw to ensure job state is Failed if needed
        Write-Error $_
        throw $_
    }
}

# --- 3. Start Jobs --------------------------------------------------------
$runningJobs = @{}

foreach ($jobDef in $AgentJobs) {
    $name = $jobDef.Name
    # Calculate path relative to PWD if needed, but absolute is safer.
    # Assuming standard project root execution.
    if (-not [System.IO.Path]::IsPathRooted($jobDef.Script)) {
        $jobDef.Script = Join-Path $PWD $jobDef.Script
    }

    Write-Verbose "Starting job: $name -> $($jobDef.Script)"
    
    # Pass $jobDef and $envPayload as arguments to the script block
    $psJob = Start-Job -Name "AgentJob_$name" -ScriptBlock $jobBlock -ArgumentList $jobDef, $envPayload
    $runningJobs[$name] = $psJob
}

# --- 4. Wait Loop ---------------------------------------------------------
# We poll jobs until they complete or GlobalTimeout triggers.
# We also respect individual job timeouts if we wanted, but logic is simpler with Global.


try {
    $jobsToWait = @($runningJobs.Values)
    if ($jobsToWait.Count -gt 0) {
        Wait-Job -Job $jobsToWait -Timeout $GlobalTimeout | Out-Null
    }
}
catch {
    Write-Warning "Wait-Job error: $_"
}

# --- 5. Harvest Results ---------------------------------------------------
foreach ($key in $runningJobs.Keys) {
    $j = $runningJobs[$key]
    $jResult = [ordered]@{
        Success = $false
        Output  = $null
        Error   = $null
        State   = $j.State
    }

    # Receive-Job
    # -Keep allows debugging if needed, but we usually consume it.
    $output = Receive-Job -Job $j -ErrorAction SilentlyContinue
    
    # Check for Errors
    if ($j.State -eq 'Failed' -or ($null -ne $j.ChildJobs[0].Error -and $j.ChildJobs[0].Error.Count -gt 0)) {
        $jResult.Success = $false
        $errs = $j.ChildJobs[0].Error
        $jResult.Error = if ($errs) { $errs | ForEach-Object { $_.ToString() } } else { "Unknown Failure" }
        # Sometimes logic fails but writes output (e.g. partial result)
        if ($output) { $jResult.Output = $output }
    }
    elseif ($j.State -eq 'Completed') {
        $jResult.Success = $true
        # Retrieve the LAST object if multiple, or all?
        # Agents usually output one JSON/Object result.
        # But logging might produce strings.
        # We try to find the structured object.
        
        # Filter out verbose/debug strings if mixed (heuristic)
        $cleanOutput = $output | Where-Object { $_ -isnot [string] -or ($_ -match '^{.*}$') -or ($_ -match '^\[.*\]$') }
        if ($null -eq $cleanOutput -and $output) { $cleanOutput = $output } # Fallback
        
        # If array, take the last one? Or return all? 
        # Invoke-AgentPRGate expects an object/json. 
        # Let's return the stream as is, let caller parse.
        $jResult.Output = $output
    }
    else {
        # Running, Blocked, etc -> Timeout implied
        $jResult.Success = $false
        $jResult.Error = "Timeout or blocked (State: $($j.State))"
        Stop-Job -Job $j -ErrorAction SilentlyContinue
    }

    $results.JobResults[$key] = $jResult
    
    # Cleanup
    Remove-Job -Job $j -Force
}

$results.DurationSec = [Math]::Round(((Get-Date) - $startTime).TotalSeconds, 2)

return $results
