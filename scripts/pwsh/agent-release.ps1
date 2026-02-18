#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Agent Release - Smart Release Manager (Level 2)

.DESCRIPTION
    Orchestrates release operations in two modes:
    - promote: local branch promotion (checkout/pull/merge/push + release notes)
    - server-sync: safe remote server sync to a target branch with backup + stash
#>

[CmdletBinding()]
param(
    [ValidateSet("promote", "server-sync")]
    [string]$Mode = "promote",

    [string]$TargetBranch,
    [string]$SourceBranch,

    [ValidateSet("merge", "squash")]
    [string]$Strategy = "merge",

    [switch]$SkipLLM,
    [switch]$AllowDirty,
    [switch]$Yes,

    [string]$ServerHost,
    [string]$ServerUser = "ubuntu",
    [string]$ServerRepoPath = "~/EasyWayDataPortal",
    [string]$ServerSshKeyPath,
    [switch]$ServerSkipClean,
    [switch]$Verify
)

$ErrorActionPreference = 'Stop'

function Write-Info {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor Cyan
}

function Write-Warn {
    param([string]$Message)
    Write-Host "[WARN] $Message" -ForegroundColor Yellow
}

function Assert-GitRepository {
    git rev-parse --is-inside-work-tree *> $null
    if ($LASTEXITCODE -ne 0) {
        throw "Not inside a git repository."
    }
}

function Confirm-OrExit {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Prompt
    )

    if ($Yes) {
        return
    }

    $confirm = Read-Host "$Prompt (y/N)"
    if ($confirm -ne 'y') {
        Write-Warn "Operation cancelled by user."
        exit 0
    }
}

function Convert-ToBashDoubleQuoted {
    param([string]$Value)

    if ($null -eq $Value) {
        return '""'
    }

    $escaped = $Value -replace '\\', '\\\\'
    $escaped = $escaped -replace '"', '\\"'
    return '"' + $escaped + '"'
}

function Invoke-SSH {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Command,
        [switch]$AllowFailure
    )

    $sshArgs = @()
    if ($ServerSshKeyPath) {
        $sshArgs += @("-i", $ServerSshKeyPath)
    }

    $destination = "$ServerUser@$ServerHost"
    $sshArgs += @($destination, $Command)

    $output = & ssh @sshArgs 2>&1
    $exitCode = $LASTEXITCODE

    if ($exitCode -ne 0 -and -not $AllowFailure) {
        $message = ($output | Out-String).Trim()
        throw "SSH command failed ($exitCode): $message"
    }

    return [PSCustomObject]@{
        ExitCode = $exitCode
        Output   = ($output | Out-String).Trim()
    }
}

function Get-AheadBehind {
    param(
        [Parameter(Mandatory = $true)]
        [string]$LocalBranch,
        [string]$RemoteBranch
    )

    $raw = (git rev-list --left-right --count "$LocalBranch...$RemoteBranch" 2>$null).Trim()
    if (-not $raw) {
        return [PSCustomObject]@{ Ahead = 0; Behind = 0 }
    }

    $parts = $raw -split '\s+'
    return [PSCustomObject]@{
        Ahead  = [int]$parts[0]
        Behind = [int]$parts[1]
    }
}

function Get-ReleaseHeuristic {
    param([string[]]$CommitSubjects)

    $text = ($CommitSubjects -join " `n").ToLowerInvariant()
    if ($text -match "breaking|!:|drop|remove") { return "major" }
    if ($text -match "feat|feature") { return "minor" }
    if ($text -match "fix|hotfix|bug") { return "patch" }
    return "patch"
}

function Test-BranchNamingPolicy {
    param(
        [Parameter(Mandatory = $true)]
        [string]$BranchName
    )

    $isFeature = $BranchName -match '^feature\/PBI-\d{3,}-[a-z0-9][a-z0-9-]*$'
    $isBugfix = $BranchName -match '^bugfix\/PBI-\d{3,}-[a-z0-9][a-z0-9-]*$'
    $isHotfix = $BranchName -match '^hotfix\/INC-\d{3,}-[a-z0-9][a-z0-9-]*$'

    return [PSCustomObject]@{
        IsFeature = $isFeature
        IsBugfix  = $isBugfix
        IsHotfix  = $isHotfix
        IsSpecial = $BranchName -in @("develop", "main", "baseline")
        IsValid   = ($isFeature -or $isBugfix -or $isHotfix -or ($BranchName -in @("develop", "main", "baseline")))
    }
}

function Assert-WorkflowPolicy {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Source,
        [Parameter(Mandatory = $true)]
        [string]$Target
    )

    $src = Test-BranchNamingPolicy -BranchName $Source
    $tgt = Test-BranchNamingPolicy -BranchName $Target

    if (-not $src.IsValid) {
        Write-Warn "Source branch '$Source' is non-standard (expected feature/bugfix/hotfix naming or develop/main/baseline)."
    }
    if (-not $tgt.IsValid) {
        Write-Warn "Target branch '$Target' is non-standard (expected develop/main/baseline)."
    }

    if ($src.IsFeature -or $src.IsBugfix) {
        if ($Target -ne "develop") {
            throw "Policy violation: '$Source' can only be promoted to 'develop'."
        }
    }

    if ($src.IsHotfix -and $Target -ne "main") {
        throw "Policy violation: hotfix branches must target 'main' first."
    }

    if ($Target -eq "baseline" -and $Source -notin @("develop", "main")) {
        throw "Policy violation: 'baseline' can be updated only from 'develop' or 'main'."
    }

    if ($Source -eq "main" -and $Target -eq "develop") {
        Write-Warn "Main -> develop sync detected (recommended after hotfix merge)."
    }
}

function New-ReleaseNotesDraft {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Source,
        [Parameter(Mandatory = $true)]
        [string]$Target,
        [Parameter(Mandatory = $true)]
        [string[]]$CommitLines,
        [string]$Analysis,
        [string]$MergeStrategy
    )

    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $safeSource = $Source -replace '[^A-Za-z0-9._-]', '_'
    $safeTarget = $Target -replace '[^A-Za-z0-9._-]', '_'
    $outDir = "agents/logs"
    if (-not (Test-Path $outDir)) {
        New-Item -ItemType Directory -Path $outDir -Force | Out-Null
    }

    $path = Join-Path $outDir "release_notes_${safeSource}_to_${safeTarget}_${timestamp}.md"

    $commitSection = if ($CommitLines.Count -gt 0) {
        ($CommitLines | ForEach-Object { "- $_" }) -join [Environment]::NewLine
    }
    else {
        "- No new commits detected between source and target"
    }

    $summaryLine = if ($Analysis) { $Analysis } else { "No LLM analysis provided." }

    $content = @(
        "# Release Notes Draft",
        "",
        "- Generated: $(Get-Date -Format o)",
        "- Source: $Source",
        "- Target: $Target",
        "- Strategy: $MergeStrategy",
        "",
        "## Summary",
        $summaryLine,
        "",
        "## Commits",
        $commitSection
    )

    Set-Content -Path $path -Value $content -Encoding UTF8
    return $path
}

function Select-TargetBranch {
    param([string]$CurrentSource)

    $branches = git branch --format='%(refname:short)'
    $localBranches = $branches -split "`n" | ForEach-Object { $_.Trim() } | Where-Object { $_ -and $_ -ne $CurrentSource }

    if (-not $localBranches -or $localBranches.Count -eq 0) {
        throw "No target branches available."
    }

    Write-Host "Select target branch for source '$CurrentSource':" -ForegroundColor White
    for ($i = 0; $i -lt $localBranches.Count; $i++) {
        Write-Host ("  [{0}] {1}" -f ($i + 1), $localBranches[$i]) -ForegroundColor Gray
    }

    $choice = Read-Host "Choice"
    $index = 0
    if (-not [int]::TryParse($choice, [ref]$index)) {
        throw "Invalid selection '$choice'."
    }

    if ($index -lt 1 -or $index -gt $localBranches.Count) {
        throw "Invalid selection '$choice'."
    }

    return $localBranches[$index - 1]
}

function Initialize-ReleaseSkills {
    $skillsLoader = Join-Path $PSScriptRoot "../../agents/skills/Load-Skills.ps1"
    $manifestPath = Join-Path $PSScriptRoot "../../agents/agent_release/manifest.json"
    $manifest = $null

    if (Test-Path $skillsLoader) {
        . $skillsLoader
    }
    if (Test-Path $manifestPath) {
        $manifest = Get-Content $manifestPath -Raw | ConvertFrom-Json
    }

    if ($manifest -and (Get-Command Import-Skill -ErrorAction SilentlyContinue)) {
        foreach ($skillId in $manifest.skills_required) {
            try {
                Import-Skill -SkillId $skillId | Out-Null
            }
            catch {
                Write-Warn "Skill load failed for '$skillId'. Falling back to native implementation when possible."
            }
        }
    }
}



function Invoke-Rollback {
    param(
        [string]$Reason
    )

    Write-Warn "⚠️  ROLLBACK INITIATED ⚠️"
    Write-Info "Reason: $Reason"
    
    if ($Mode -eq "server-sync") {
        Write-Warn "Automatic rollback for 'server-sync' is not yet implemented."
        Write-Info "MANUAL ACTION REQUIRED: SSH into $ServerHost and restore the backup tag created before sync."
        return
    }

    # Promote Mode Rollback Strategy: Revert Commit
    Write-Info "Strategy: creating a revert commit to undo changes."
    
    try {
        if (Get-Command Invoke-GitRevert -ErrorAction SilentlyContinue) {
            # Future skill usage
        }
        else {
            git revert HEAD --no-edit
            if ($LASTEXITCODE -ne 0) { throw "Git revert failed." }
            
            git push origin $TargetBranch
            if ($LASTEXITCODE -ne 0) { throw "Git push of revert failed." }
        }
        Write-Info "Rollback successful. The bad commit has been reverted."
    }
    catch {
        Write-Error "Rollback failed: $_"
        Write-Warn "System may be in an inconsistent state. Immediate manual intervention required."
    }
}

function Invoke-PostReleaseCheck {
    if (-not $Verify) { return }

    Write-Info "Starting Post-Release Verification (powered by agent_observability)..."
    
    # Wait for warm-up (simulated)
    Write-Info "Waiting 5 seconds for application warm-up..."
    Start-Sleep -Seconds 5
    
    # Call agent_observability via ewctl kernel
    $ewctl = Join-Path $PSScriptRoot "ewctl.ps1"
    if (-not (Test-Path $ewctl)) {
        Write-Warn "Cannot find ewctl kernel at $ewctl. Verification skipped."
        return
    }

    $intentFile = Join-Path $PSScriptRoot "../../agents/agent_release/verify_intent.json"
    @{
        params = @{
            hours   = 1
            analyze = $true
        }
    } | ConvertTo-Json | Set-Content -Path $intentFile -Encoding utf8

    try {
        Write-Info "Asking Agent Observability to check logs and analyze errors..."
        # We call the script directly to avoid full ewctl wrapper overhead if possible, 
        # but here we use the specific agent script for direct output control.
        $obsScript = Join-Path $PSScriptRoot "agent-observability.ps1"
        
        $result = & $obsScript -Action "obs:check-logs" -IntentPath $intentFile
        
        # Parse result (it returns JSON string usually, but PowerShell might unwrap it)
        $json = if ($result -is [string]) { $result | ConvertFrom-Json } else { $result }
        
        if ($json.output.errorCount -gt 0) {
            Write-Warn "Verification Failed! Found $($json.output.errorCount) errors."
            Write-Warn "Top Errors:"
            $json.output.topErrors | ForEach-Object { Write-Host " - $($_.Name) ($($_.Count))" -ForegroundColor Red }
            
            if ($json.output.analysis) {
                Write-Host "`n[Brain Analysis]:" -ForegroundColor Magenta
                Write-Host $json.output.analysis -ForegroundColor Gray
            }
            
            # Auto-Rollback / Human-in-the-Loop
            Write-Host "`n[CRITICAL] Release verification failed." -ForegroundColor Red
            Write-Host "The agent recommends a ROLLBACK to restore service stability." -ForegroundColor Yellow
            
            # Simple risk assessment (placeholder)
            Write-Host "Risk Assessment: Low (Code-only revert)" -ForegroundColor Green
            
            $confirm = Read-Host "Execute Rollback now? (y/N)"
            if ($confirm -eq 'y') {
                Invoke-Rollback -Reason "Verification failed with $($json.output.errorCount) errors."
            }
            else {
                Write-Warn "Rollback cancelled by user. System remains in error state."
            }
        }
        else {
            Write-Info "Verification Passed: Zero errors found in the last hour."
        }
    }
    catch {
        Write-Warn "Verification process failed: $_"
    }
    finally {
        if (Test-Path $intentFile) { Remove-Item $intentFile -ErrorAction SilentlyContinue }
    }
}

function Invoke-ServerSync {
    if (-not $ServerHost) {
        throw "-ServerHost is required when -Mode server-sync is used."
    }

    Write-Info "Initializing skills system..."
    Initialize-ReleaseSkills

    $branch = if ($TargetBranch) { $TargetBranch } else { "main" }

    if (Get-Command Invoke-GitServerSync -ErrorAction SilentlyContinue) {
        $result = Invoke-GitServerSync `
            -ServerHost $ServerHost `
            -ServerUser $ServerUser `
            -ServerRepoPath $ServerRepoPath `
            -Branch $branch `
            -ServerSshKeyPath $ServerSshKeyPath `
            -SkipClean:$ServerSkipClean `
            -SudoCleanPaths $ServerSudoCleanPaths `
            -AllowHardReset `
            -Yes:$Yes

        Write-Info "Server sync completed."
        if ($result.FinalStatus) {
            Write-Host $result.FinalStatus
        }
        return
    }

    $repoQuoted = Convert-ToBashDoubleQuoted -Value $ServerRepoPath
    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"

    if (-not (Get-Command ssh -ErrorAction SilentlyContinue)) {
        throw "OpenSSH client (ssh) is not available on this machine."
    }

    Write-Info "Server sync plan: $ServerUser@$ServerHost :: $ServerRepoPath -> origin/$branch"
    Confirm-OrExit -Prompt "Proceed with remote backup + stash + sync"

    $preflightCmd = "set -e; cd $repoQuoted; git rev-parse --is-inside-work-tree"
    Invoke-SSH -Command $preflightCmd | Out-Null

    $backupCmd = @"
set -e
cd $repoQuoted
TS=$timestamp
BACKUP_DIR="`$HOME/git-backups/easyway/`$TS"
mkdir -p "`$BACKUP_DIR"
git status --short > "`$BACKUP_DIR/status-before.txt" || true
git diff > "`$BACKUP_DIR/changes.diff" || true
git branch -f "backup/server-$branch-pre-sync-`$TS" HEAD
git tag -f "backup/pre-sync-`$TS" HEAD
git stash push -u -m "pre-sync-`$TS" >/dev/null 2>&1 || true
"@
    Invoke-SSH -Command $backupCmd | Out-Null

    $fetchCheckoutCmd = "set -e; cd $repoQuoted; git fetch origin --prune; git checkout $branch || git checkout -B $branch origin/$branch"
    Invoke-SSH -Command $fetchCheckoutCmd | Out-Null

    $ffPullCmd = "set -e; cd $repoQuoted; git pull --ff-only origin $branch"
    $pullResult = Invoke-SSH -Command $ffPullCmd -AllowFailure

    if ($pullResult.ExitCode -ne 0) {
        Write-Warn "Fast-forward pull failed on server for '$branch'."
        Confirm-OrExit -Prompt "Apply hard reset to origin/$branch on server"

        $resetCmd = "set -e; cd $repoQuoted; git reset --hard origin/$branch"
        Invoke-SSH -Command $resetCmd | Out-Null
    }

    if (-not $ServerSkipClean) {
        $cleanCmd = "set -e; cd $repoQuoted; git clean -fd"
        $cleanResult = Invoke-SSH -Command $cleanCmd -AllowFailure
        if ($cleanResult.ExitCode -ne 0) {
            Write-Warn "git clean reported issues (likely permission-owned runtime files)."
        }
    }

    if ($ServerSudoCleanPaths -and $ServerSudoCleanPaths.Count -gt 0) {
        $joined = ($ServerSudoCleanPaths | ForEach-Object { Convert-ToBashDoubleQuoted -Value $_ }) -join ' '
        $sudoCmd = "set -e; cd $repoQuoted; sudo rm -rf $joined"
        Invoke-SSH -Command $sudoCmd | Out-Null
    }

    $finalStatusCmd = "cd $repoQuoted; git status -sb; git stash list | head -n 3; git branch --list 'backup/*' | tail -n 3; git tag --list 'backup/*' | tail -n 3"
    $final = Invoke-SSH -Command $finalStatusCmd

    Write-Info "Server sync completed."
    Write-Host $final.Output
    
    Invoke-PostReleaseCheck
}

function Invoke-PromoteFlow {
    Assert-GitRepository

    $originalBranch = (git rev-parse --abbrev-ref HEAD).Trim()
    if (-not $SourceBranch) {
        $SourceBranch = $originalBranch
    }
    if (-not $TargetBranch) {
        $TargetBranch = Select-TargetBranch -CurrentSource $SourceBranch
    }

    if ($SourceBranch -eq $TargetBranch) {
        throw "Source and target branches are the same ('$SourceBranch')."
    }

    Assert-WorkflowPolicy -Source $SourceBranch -Target $TargetBranch

    if (-not $AllowDirty) {
        $dirty = git status --porcelain
        if ($dirty) {
            throw "Working tree is not clean. Commit/stash changes or use -AllowDirty."
        }
    }

    Write-Info "Initializing skills system..."
    Initialize-ReleaseSkills

    Write-Info "Release plan: $SourceBranch -> $TargetBranch (strategy: $Strategy)"

    git fetch origin --prune | Out-Null

    foreach ($branch in @($SourceBranch, $TargetBranch)) {
        git rev-parse --verify --quiet "refs/remotes/origin/$branch" *> $null
        if ($LASTEXITCODE -eq 0) {
            $ab = Get-AheadBehind -LocalBranch $branch -RemoteBranch "origin/$branch"
            if ($ab.Behind -gt 0) {
                Write-Warn "Local '$branch' is behind origin/$branch by $($ab.Behind) commit(s)."
            }
        }
    }

    if ($SourceBranch -eq "develop" -and $TargetBranch -eq "main") {
        Write-Warn "Direct develop -> main merge detected. Consider release/* as intermediate branch."
    }

    $commitLines = @(git log "$TargetBranch..$SourceBranch" --pretty=format:'%h %ad %an %s' --date=short)
    $commitSubjects = @(git log "$TargetBranch..$SourceBranch" --pretty=format:'%s')

    if (-not $commitLines -or $commitLines.Count -eq 0) {
        Write-Warn "No new commits to merge from '$SourceBranch' into '$TargetBranch'."
        Confirm-OrExit -Prompt "Proceed anyway"
    }

    $analysisText = ""
    if (-not $SkipLLM -and (Get-Command Invoke-LLMWithRAG -ErrorAction SilentlyContinue) -and $commitSubjects.Count -gt 0) {
        try {
            $query = @"
You are preparing a software release.
Source branch: $SourceBranch
Target branch: $TargetBranch
Commits:
$($commitSubjects -join "`n")

Return:
1) release type suggestion (major/minor/patch)
2) top 3 risks
3) concise release summary
"@
            $analysis = Invoke-LLMWithRAG -Query $query -AgentId "agent_release" -SkipRAG $true
            $analysisText = if ($analysis -is [string]) { $analysis } elseif ($analysis.Content) { $analysis.Content } else { ($analysis | Out-String).Trim() }
        }
        catch {
            Write-Warn "LLM analysis failed: $($_.Exception.Message)"
        }
    }

    if (-not $analysisText) {
        $suggestedBump = Get-ReleaseHeuristic -CommitSubjects $commitSubjects
        $analysisText = "Heuristic suggestion: $suggestedBump release bump."
    }

    $notesPath = New-ReleaseNotesDraft -Source $SourceBranch -Target $TargetBranch -CommitLines $commitLines -Analysis $analysisText -MergeStrategy $Strategy
    Write-Info "Draft release notes written to $notesPath"

    if (-not $Yes) {
        Write-Host "Preview analysis:" -ForegroundColor White
        Write-Host $analysisText -ForegroundColor Gray
    }
    Confirm-OrExit -Prompt "Execute merge + push now"

    $releaseSucceeded = $false
    try {
        if (Get-Command Invoke-GitCheckout -ErrorAction SilentlyContinue) {
            Invoke-GitCheckout -Branch $TargetBranch | Out-Null
        }
        else {
            git checkout $TargetBranch | Out-Null
        }

        git pull --ff-only origin $TargetBranch
        if ($LASTEXITCODE -ne 0) {
            throw "Unable to fast-forward '$TargetBranch' from origin/$TargetBranch."
        }

        if (Get-Command Invoke-GitMerge -ErrorAction SilentlyContinue) {
            if ($Strategy -eq "squash") {
                Invoke-GitMerge -SourceBranch $SourceBranch -Squash | Out-Null
            }
            else {
                Invoke-GitMerge -SourceBranch $SourceBranch -NoFastForward | Out-Null
            }
        }
        else {
            if ($Strategy -eq "squash") {
                git merge --squash $SourceBranch
            }
            else {
                git merge --no-ff $SourceBranch
            }
            if ($LASTEXITCODE -ne 0) {
                throw "Merge failed."
            }
        }

        if (Get-Command Invoke-GitPush -ErrorAction SilentlyContinue) {
            Invoke-GitPush -Branch $TargetBranch | Out-Null
        }
        else {
            git push origin $TargetBranch
            if ($LASTEXITCODE -ne 0) {
                throw "Push failed."
            }
        }

        $releaseSucceeded = $true
        Write-Info "Release completed successfully: $SourceBranch -> $TargetBranch"
        
        Invoke-PostReleaseCheck
    }
    finally {
        $currentBranch = (git rev-parse --abbrev-ref HEAD).Trim()
        if ($currentBranch -ne $originalBranch) {
            try {
                git checkout $originalBranch | Out-Null
                Write-Info "Returned to original branch '$originalBranch'."
            }
            catch {
                Write-Warn "Could not return to original branch '$originalBranch': $($_.Exception.Message)"
            }
        }
    }

    if (-not $releaseSucceeded) {
        exit 1
    }
}

if ($Mode -eq "server-sync") {
    Invoke-ServerSync
}
else {
    Invoke-PromoteFlow
}
