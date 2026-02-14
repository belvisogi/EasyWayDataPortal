param(
    [ValidateSet("validate-auth", "sync", "monitor", "create-pr")]
    [string]$Action = "sync",
    [string]$Branch = "",
    [string]$Title = "",
    [string]$Description = "",
    [string]$ConfigPath = ".\scripts\pwsh\multi-vcs.config.ps1",
    [int]$PostPushChecks = 5,
    [int]$PostPushCheckIntervalSeconds = 10,
    [int]$MonitorSamples = 12,
    [int]$MonitorIntervalSeconds = 30,
    [switch]$UseLlmRouter,
    [string]$LlmRouterConfigPath = ".\scripts\pwsh\llm-router.config.ps1",
    [string]$RagEvidenceId = "",
    [string]$LlmAgentId = "agent-multi-vcs",
    [switch]$RepairMissingBranch,
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"

function Invoke-GitCapture {
    param([Parameter(Mandatory = $true)][string[]]$Args)
    $output = & git @Args 2>&1
    return [PSCustomObject]@{
        ExitCode = $LASTEXITCODE
        Output   = ($output -join "`n").Trim()
    }
}

function Resolve-Branch {
    param([string]$InputBranch)
    if (-not [string]::IsNullOrWhiteSpace($InputBranch)) {
        return $InputBranch.Trim()
    }
    $res = Invoke-GitCapture -Args @("branch", "--show-current")
    if ($res.ExitCode -ne 0 -or [string]::IsNullOrWhiteSpace($res.Output)) {
        throw "Cannot detect current branch."
    }
    return $res.Output.Trim()
}

function Get-Config {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) {
        throw "Config not found: $Path (copy multi-vcs.config.example.ps1)"
    }
    $cfg = & $Path
    if ($null -eq $cfg) {
        throw "Invalid config file: $Path"
    }
    return $cfg
}

function Get-ExistingRemotes {
    $res = Invoke-GitCapture -Args @("remote")
    if ($res.ExitCode -ne 0) {
        throw "Unable to list remotes: $($res.Output)"
    }
    return @($res.Output.Split("`n") | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne "" })
}

function Test-RemoteAuth {
    param(
        [Parameter(Mandatory = $true)][string]$Remote,
        [Parameter(Mandatory = $true)][string]$BranchName
    )
    $res = Invoke-GitCapture -Args @("ls-remote", "--heads", $Remote, $BranchName)
    if ($res.ExitCode -ne 0) {
        return [PSCustomObject]@{ Remote = $Remote; Status = "error"; Detail = $res.Output }
    }
    if ([string]::IsNullOrWhiteSpace($res.Output)) {
        return [PSCustomObject]@{ Remote = $Remote; Status = "ok"; Detail = "auth-ok branch-not-found" }
    }
    return [PSCustomObject]@{ Remote = $Remote; Status = "ok"; Detail = "auth-ok branch-visible" }
}

function Invoke-CreatePrAdo {
    param(
        [hashtable]$Provider,
        [string]$SourceBranch,
        [string]$PrTitle,
        [string]$PrDescription,
        [bool]$PlanOnly
    )
    $cmd = @(
        "repos", "pr", "create",
        "--organization", $Provider.Organization,
        "--project", $Provider.Project,
        "--repository", $Provider.Repository,
        "--source-branch", $SourceBranch,
        "--target-branch", $Provider.TargetBranch,
        "--title", $PrTitle
    )
    if (-not [string]::IsNullOrWhiteSpace($PrDescription)) {
        $cmd += @("--description", $PrDescription)
    }

    if ($PlanOnly) {
        Write-Host "[PLAN][ado] az $($cmd -join ' ')" -ForegroundColor Yellow
        return
    }
    & az @cmd
    if ($LASTEXITCODE -ne 0) {
        throw "ADO PR creation failed."
    }
}

function Invoke-CreatePrGithub {
    param(
        [hashtable]$Provider,
        [string]$SourceBranch,
        [string]$PrTitle,
        [string]$PrDescription,
        [bool]$PlanOnly
    )
    $cmd = @(
        "pr", "create",
        "--repo", $Provider.Repo,
        "--base", $Provider.TargetBranch,
        "--head", $SourceBranch,
        "--title", $PrTitle
    )
    if (-not [string]::IsNullOrWhiteSpace($PrDescription)) {
        $cmd += @("--body", $PrDescription)
    }

    if ($PlanOnly) {
        Write-Host "[PLAN][github] gh $($cmd -join ' ')" -ForegroundColor Yellow
        return
    }
    & gh @cmd
    if ($LASTEXITCODE -ne 0) {
        throw "GitHub PR creation failed."
    }
}

function Invoke-CreatePrForgejo {
    param(
        [hashtable]$Provider,
        [string]$SourceBranch,
        [string]$PrTitle,
        [string]$PrDescription,
        [bool]$PlanOnly
    )
    $cmd = @(
        "pr", "create",
        "--repo", $Provider.Repo,
        "--base", $Provider.TargetBranch,
        "--head", $SourceBranch,
        "--title", $PrTitle
    )
    if (-not [string]::IsNullOrWhiteSpace($PrDescription)) {
        $cmd += @("--description", $PrDescription)
    }
    if (-not [string]::IsNullOrWhiteSpace($Provider.Url)) {
        $cmd += @("--login", $Provider.Url)
    }

    if ($PlanOnly) {
        Write-Host "[PLAN][forgejo] tea $($cmd -join ' ')" -ForegroundColor Yellow
        return
    }
    & tea @cmd
    if ($LASTEXITCODE -ne 0) {
        throw "Forgejo PR creation failed."
    }
}

function Try-GeneratePrDraftWithLlm {
    param(
        [string]$CurrentTitle,
        [string]$CurrentDescription,
        [string]$BranchName,
        [string[]]$Remotes
    )

    if (-not $UseLlmRouter) {
        return @{
            Title = $CurrentTitle
            Description = $CurrentDescription
            Used = $false
            Error = ""
        }
    }

    if ([string]::IsNullOrWhiteSpace($RagEvidenceId)) {
        Write-Warning "LLM router enabled but RagEvidenceId missing. Skipping LLM drafting."
        return @{
            Title = $CurrentTitle
            Description = $CurrentDescription
            Used = $false
            Error = "missing_rag_evidence"
        }
    }

    $prompt = @"
Generate a concise PR draft for multi-vcs sync.
Return strict JSON with keys: title, description.
Context:
- branch: $BranchName
- remotes: $($Remotes -join ", ")
- current_title: $CurrentTitle
- current_description: $CurrentDescription
- rules: conventional-commit style title; description max 8 lines; include verification intent.
"@

    try {
        $routerArgs = @(
            "-NoProfile", "-File", ".\scripts\pwsh\agent-llm-router.ps1",
            "-Action", "invoke",
            "-ConfigPath", $LlmRouterConfigPath,
            "-Prompt", $prompt,
            "-TaskType", "multi-vcs-pr-draft",
            "-AgentId", $LlmAgentId,
            "-RagEvidenceId", $RagEvidenceId,
            "-JsonOutput"
        )
        if ($DryRun) { $routerArgs += "-DryRun" }
        $raw = & pwsh @routerArgs
        if ($LASTEXITCODE -ne 0) {
            throw "LLM router invoke failed."
        }
        $routerObj = $raw | ConvertFrom-Json
        $llmText = [string]$routerObj.output
        if ([string]::IsNullOrWhiteSpace($llmText)) {
            throw "LLM router returned empty output."
        }

        $parsed = $llmText | ConvertFrom-Json
        $newTitle = if ([string]::IsNullOrWhiteSpace($parsed.title)) { $CurrentTitle } else { [string]$parsed.title }
        $newDescription = if ([string]::IsNullOrWhiteSpace($parsed.description)) { $CurrentDescription } else { [string]$parsed.description }
        return @{
            Title = $newTitle
            Description = $newDescription
            Used = $true
            Error = ""
        }
    }
    catch {
        Write-Warning "LLM PR drafting skipped: $($_.Exception.Message)"
        return @{
            Title = $CurrentTitle
            Description = $CurrentDescription
            Used = $false
            Error = $_.Exception.Message
        }
    }
}

$cfg = Get-Config -Path $ConfigPath
$branchName = Resolve-Branch -InputBranch $Branch
$existingRemotes = Get-ExistingRemotes
$targetRemotes = @($cfg.Remotes | Where-Object { $existingRemotes -contains $_ } | Select-Object -Unique)

if ($targetRemotes.Count -eq 0) {
    throw "No configured remotes found in repository."
}

Write-Host "Agent Multi-VCS" -ForegroundColor Cyan
Write-Host "Action:  $Action"
Write-Host "Branch:  $branchName"
Write-Host "Remotes: $($targetRemotes -join ', ')"

switch ($Action) {
    "validate-auth" {
        $results = @()
        foreach ($r in $targetRemotes) {
            $results += Test-RemoteAuth -Remote $r -BranchName $branchName
        }
        $results | Format-Table -AutoSize
    }
    "sync" {
        $args = @(
            "-NoProfile", "-File", ".\scripts\pwsh\push-all-remotes.ps1",
            "-Branch", $branchName,
            "-Remotes", ($targetRemotes -join ","),
            "-PostPushChecks", $PostPushChecks,
            "-PostPushCheckIntervalSeconds", $PostPushCheckIntervalSeconds,
            "-SkipCommit"
        )
        if ($RepairMissingBranch) { $args += "-RepairMissingBranch" }
        if ($DryRun) { $args += "-DryRun" }

        & pwsh @args
        if ($LASTEXITCODE -ne 0) {
            throw "Multi-remote sync failed."
        }
    }
    "monitor" {
        $args = @(
            "-NoProfile", "-File", ".\scripts\pwsh\watch-branch-presence.ps1",
            "-Branch", $branchName,
            "-Remotes", ($targetRemotes -join ","),
            "-IntervalSeconds", $MonitorIntervalSeconds,
            "-Samples", $MonitorSamples,
            "-LogFile", "docs/ops/branch-presence-monitor.log"
        )
        if ($RepairMissingBranch) { $args += "-RepairMissingBranch" }
        & pwsh @args
        if ($LASTEXITCODE -ne 0) {
            throw "Branch monitor failed."
        }
    }
    "create-pr" {
        if ([string]::IsNullOrWhiteSpace($Title)) {
            $Title = "chore(multi-vcs): sync $branchName"
        }
        if ([string]::IsNullOrWhiteSpace($Description)) {
            $Description = "PR generated by agent-multi-vcs."
        }

        $draft = Try-GeneratePrDraftWithLlm -CurrentTitle $Title -CurrentDescription $Description -BranchName $branchName -Remotes $targetRemotes
        $Title = $draft.Title
        $Description = $draft.Description
        if ($draft.Used) {
            Write-Host "LLM router drafting applied for PR title/description." -ForegroundColor Cyan
        }

        foreach ($providerName in @("ado", "github", "forgejo")) {
            if (-not $cfg.Providers.ContainsKey($providerName)) {
                continue
            }
            $p = $cfg.Providers[$providerName]
            if (-not $p.Enabled) {
                continue
            }
            switch ($providerName) {
                "ado"     { Invoke-CreatePrAdo -Provider $p -SourceBranch $branchName -PrTitle $Title -PrDescription $Description -PlanOnly $DryRun.IsPresent }
                "github"  { Invoke-CreatePrGithub -Provider $p -SourceBranch $branchName -PrTitle $Title -PrDescription $Description -PlanOnly $DryRun.IsPresent }
                "forgejo" { Invoke-CreatePrForgejo -Provider $p -SourceBranch $branchName -PrTitle $Title -PrDescription $Description -PlanOnly $DryRun.IsPresent }
            }
        }
    }
}

Write-Host "Done." -ForegroundColor Green
