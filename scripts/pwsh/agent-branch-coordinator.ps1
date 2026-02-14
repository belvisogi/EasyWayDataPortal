param(
    [ValidateSet("recommend", "claim", "release", "heartbeat", "status")]
    [string]$Action = "recommend",
    [string]$Branch = "",
    [Alias("AgentId")]
    [string]$WorkerId = "",
    [string]$TaskId = "",
    [string]$Tool = "",
    [string]$LeaseFile = "docs/ops/branch-leases.json",
    [switch]$UseLlmRouter,
    [string]$LlmRouterConfigPath = ".\scripts\pwsh\llm-router.config.ps1",
    [string]$RagEvidenceId = "",
    [string]$LlmAgentId = "agent-branch-coordinator",
    [int]$LeaseTtlMinutes = 180,
    [switch]$Force,
    [switch]$AllowProtected,
    [switch]$JsonOutput
)

$ErrorActionPreference = "Stop"

function Invoke-GitCapture {
    param([string[]]$GitArgs)
    $output = & git @GitArgs 2>&1
    [PSCustomObject]@{
        ExitCode = $LASTEXITCODE
        Output   = ($output -join "`n").Trim()
    }
}

function Resolve-CurrentBranch {
    $res = Invoke-GitCapture -GitArgs @("branch", "--show-current")
    if ($res.ExitCode -eq 0 -and -not [string]::IsNullOrWhiteSpace($res.Output)) {
        return $res.Output.Trim()
    }

    $fallback = Invoke-GitCapture -GitArgs @("rev-parse", "--abbrev-ref", "HEAD")
    if ($fallback.ExitCode -eq 0 -and -not [string]::IsNullOrWhiteSpace($fallback.Output)) {
        return $fallback.Output.Trim()
    }

    throw "Cannot detect current branch. branchOut='$($res.Output)' fallbackOut='$($fallback.Output)'"
}

function Resolve-WorkerId {
    param([string]$PreferredWorkerId)
    if (-not [string]::IsNullOrWhiteSpace($PreferredWorkerId)) { return $PreferredWorkerId.Trim() }
    return "$env:COMPUTERNAME-$env:USERNAME".ToLower()
}

function Get-NowIso {
    return (Get-Date).ToString("o")
}

function Get-LeaseData {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) {
        $dir = Split-Path -Parent $Path
        if (-not [string]::IsNullOrWhiteSpace($dir) -and -not (Test-Path -LiteralPath $dir)) {
            New-Item -ItemType Directory -Path $dir -Force | Out-Null
        }
        $empty = @{ leases = @() }
        $empty | ConvertTo-Json -Depth 10 | Set-Content -Path $Path -Encoding utf8
    }
    $raw = Get-Content -Path $Path -Raw
    if ([string]::IsNullOrWhiteSpace($raw)) {
        return @{ leases = @() }
    }
    $data = $raw | ConvertFrom-Json
    if ($null -eq $data.leases) {
        $data = @{ leases = @() }
    }
    return $data
}

function Save-LeaseData {
    param([string]$Path, $Data)
    $Data | ConvertTo-Json -Depth 10 | Set-Content -Path $Path -Encoding utf8
}

function Get-ActiveLeases {
    param($Data, [int]$TtlMinutes)
    $now = Get-Date
    @($Data.leases | Where-Object {
            if (-not $_.updatedAt) { return $false }
            $updated = [datetime]$_.updatedAt
            ($now - $updated).TotalMinutes -lt $TtlMinutes
        })
}

function New-BranchNameSuggestion {
    param([string]$Worker, [string]$Task)
    $stamp = Get-Date -Format "yyyyMMdd-HHmm"
    $slug = if ([string]::IsNullOrWhiteSpace($Task)) {
        "work"
    } else {
        ($Task.ToLower() -replace "[^a-z0-9\-]", "-" -replace "-+", "-").Trim("-")
    }
    $workerSlug = ($Worker.ToLower() -replace "[^a-z0-9\-]", "-" -replace "-+", "-").Trim("-")
    return "feature/$workerSlug-$slug-$stamp"
}

function Is-ProtectedBranch {
    param([string]$Name)
    return $Name -in @("main", "develop", "baseline")
}

function Out-Advice {
    param($Obj)
    if ($JsonOutput) {
        $Obj | ConvertTo-Json -Depth 10
    } else {
        Write-Host "Decision: $($Obj.decision)"
        Write-Host "Reason:   $($Obj.reason)"
        if ($Obj.currentBranch) { Write-Host "Current:  $($Obj.currentBranch)" }
        if ($Obj.targetBranch)  { Write-Host "Target:   $($Obj.targetBranch)" }
        if ($Obj.llmAdvice)      { Write-Host "LLM:      $($Obj.llmAdvice)" }
    }
}

function Try-GetLlmAdvice {
    param(
        [string]$Decision,
        [string]$Reason,
        [string]$Current,
        [string]$Target,
        [int]$ActiveLeasesCount
    )

    if (-not $UseLlmRouter) { return "" }
    if ([string]::IsNullOrWhiteSpace($RagEvidenceId)) {
        Write-Warning "LLM router enabled but RagEvidenceId missing. Skipping LLM advice."
        return ""
    }

    $prompt = @"
You are a branch scheduling advisor.
Provide one concise sentence (max 25 words) reinforcing or correcting this recommendation.
Context:
- decision: $Decision
- reason: $Reason
- current_branch: $Current
- target_branch: $Target
- active_leases_count: $ActiveLeasesCount
"@

    try {
        $routerArgs = @(
            "-NoProfile", "-File", ".\scripts\pwsh\agent-llm-router.ps1",
            "-Action", "invoke",
            "-ConfigPath", $LlmRouterConfigPath,
            "-Prompt", $prompt,
            "-TaskType", "branch-coordination-advice",
            "-AgentId", $LlmAgentId,
            "-RagEvidenceId", $RagEvidenceId,
            "-JsonOutput"
        )
        $raw = & pwsh @routerArgs
        if ($LASTEXITCODE -ne 0) { throw "LLM router invoke failed." }
        $obj = $raw | ConvertFrom-Json
        return ([string]$obj.output).Trim()
    }
    catch {
        Write-Warning "LLM advice skipped: $($_.Exception.Message)"
        return ""
    }
}

$worker = Resolve-WorkerId -PreferredWorkerId $WorkerId
$currentBranch = Resolve-CurrentBranch
$targetBranch = if ([string]::IsNullOrWhiteSpace($Branch)) { $currentBranch } else { $Branch.Trim() }
$toolLabel = if ([string]::IsNullOrWhiteSpace($Tool)) { "unknown" } else { $Tool.Trim() }

$data = Get-LeaseData -Path $LeaseFile
$activeLeases = Get-ActiveLeases -Data $data -TtlMinutes $LeaseTtlMinutes

switch ($Action) {
    "status" {
        $status = @($activeLeases | Sort-Object branch, workerId)
        if ($JsonOutput) {
            if ($status.Count -eq 0) {
                "[]"
            } else {
                $status | ConvertTo-Json -Depth 10
            }
        } else {
            $status | Format-Table workerId, branch, taskId, tool, host, updatedAt -AutoSize
        }
        break
    }

    "recommend" {
        $myLease = $activeLeases | Where-Object { $_.workerId -eq $worker } | Select-Object -First 1
        $branchLease = $activeLeases | Where-Object { $_.branch -eq $currentBranch -and $_.workerId -ne $worker } | Select-Object -First 1

        if ($myLease -and $currentBranch -ne $myLease.branch) {
            $advice = @{
                decision      = "switch-branch"
                reason        = "Worker has active lease on another branch."
                currentBranch = $currentBranch
                targetBranch  = $myLease.branch
            }
            $llmAdvice = Try-GetLlmAdvice -Decision $advice.decision -Reason $advice.reason -Current $advice.currentBranch -Target $advice.targetBranch -ActiveLeasesCount @($activeLeases).Count
            if (-not [string]::IsNullOrWhiteSpace($llmAdvice)) { $advice.llmAdvice = $llmAdvice }
            Out-Advice $advice
            break
        }

        if (Is-ProtectedBranch -Name $currentBranch) {
            $suggested = New-BranchNameSuggestion -Worker $worker -Task $TaskId
            $advice = @{
                decision      = "create-and-switch"
                reason        = "Current branch is protected; work must happen on feature/hotfix branch."
                currentBranch = $currentBranch
                targetBranch  = $suggested
            }
            $llmAdvice = Try-GetLlmAdvice -Decision $advice.decision -Reason $advice.reason -Current $advice.currentBranch -Target $advice.targetBranch -ActiveLeasesCount @($activeLeases).Count
            if (-not [string]::IsNullOrWhiteSpace($llmAdvice)) { $advice.llmAdvice = $llmAdvice }
            Out-Advice $advice
            break
        }

        if ($branchLease) {
            $suggested = New-BranchNameSuggestion -Worker $worker -Task $TaskId
            $advice = @{
                decision      = "switch-branch"
                reason        = "Current branch is leased by another worker ($($branchLease.workerId))."
                currentBranch = $currentBranch
                targetBranch  = $suggested
            }
            $llmAdvice = Try-GetLlmAdvice -Decision $advice.decision -Reason $advice.reason -Current $advice.currentBranch -Target $advice.targetBranch -ActiveLeasesCount @($activeLeases).Count
            if (-not [string]::IsNullOrWhiteSpace($llmAdvice)) { $advice.llmAdvice = $llmAdvice }
            Out-Advice $advice
            break
        }

        $advice = @{
            decision      = "stay"
            reason        = "Branch is safe for current worker."
            currentBranch = $currentBranch
            targetBranch  = $currentBranch
        }
        $llmAdvice = Try-GetLlmAdvice -Decision $advice.decision -Reason $advice.reason -Current $advice.currentBranch -Target $advice.targetBranch -ActiveLeasesCount @($activeLeases).Count
        if (-not [string]::IsNullOrWhiteSpace($llmAdvice)) { $advice.llmAdvice = $llmAdvice }
        Out-Advice $advice
        break
    }

    "claim" {
        if ((Is-ProtectedBranch -Name $targetBranch) -and -not $AllowProtected) {
            throw "Refusing claim on protected branch '$targetBranch'. Use -AllowProtected only for exceptional operations."
        }

        $conflict = $activeLeases | Where-Object { $_.branch -eq $targetBranch -and $_.workerId -ne $worker } | Select-Object -First 1
        if ($conflict -and -not $Force) {
            throw "Branch '$targetBranch' already leased by '$($conflict.workerId)'. Use -Force to override."
        }

        $data.leases = @($data.leases | Where-Object { -not (($_.workerId -eq $worker) -or ($_.branch -eq $targetBranch)) })
        $data.leases += [PSCustomObject]@{
            workerId  = $worker
            branch    = $targetBranch
            taskId    = $TaskId
            tool      = $toolLabel
            host      = $env:COMPUTERNAME
            updatedAt = Get-NowIso
        }
        Save-LeaseData -Path $LeaseFile -Data $data
        Write-Host "Lease claimed: $worker -> $targetBranch"
        break
    }

    "heartbeat" {
        $updated = $false
        foreach ($l in $data.leases) {
            if ($l.workerId -eq $worker -and $l.branch -eq $targetBranch) {
                $l.updatedAt = Get-NowIso
                if (-not [string]::IsNullOrWhiteSpace($TaskId)) { $l.taskId = $TaskId }
                if (-not [string]::IsNullOrWhiteSpace($Tool))   { $l.tool = $toolLabel }
                $updated = $true
            }
        }
        if (-not $updated) {
            throw "No lease found for worker '$worker' on branch '$targetBranch'."
        }
        Save-LeaseData -Path $LeaseFile -Data $data
        Write-Host "Lease heartbeat updated: $worker -> $targetBranch"
        break
    }

    "release" {
        $before = @($data.leases).Count
        $data.leases = @($data.leases | Where-Object { -not ($_.workerId -eq $worker -and $_.branch -eq $targetBranch) })
        $after = @($data.leases).Count
        Save-LeaseData -Path $LeaseFile -Data $data
        if ($before -eq $after) {
            Write-Host "No lease to release for $worker on $targetBranch"
        } else {
            Write-Host "Lease released: $worker -> $targetBranch"
        }
        break
    }
}
