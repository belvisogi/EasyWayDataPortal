#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Agent Release - Smart Release Manager (Level 2)

.DESCRIPTION
    Orchestrates a safe release flow with optional LLM context analysis:
    - preflight checks
    - release notes draft generation
    - checkout/pull/merge/push
    - return to original branch
#>

[CmdletBinding()]
param(
    [string]$TargetBranch,
    [string]$SourceBranch,
    [ValidateSet("merge", "squash")]
    [string]$Strategy = "merge",
    [switch]$SkipLLM,
    [switch]$AllowDirty,
    [switch]$Yes
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

    # Workflow guards from standards/gitlab-workflow.md
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
    } else {
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
        } catch {
            Write-Warn "Skill load failed for '$skillId'. Falling back to native git calls when possible."
        }
    }
}

Write-Info "Release plan: $SourceBranch -> $TargetBranch (strategy: $Strategy)"

git fetch origin --prune | Out-Null

# Warn on local behind remote for source and target.
foreach ($branch in @($SourceBranch, $TargetBranch)) {
    git rev-parse --verify --quiet "refs/remotes/origin/$branch" *> $null
    if ($LASTEXITCODE -eq 0) {
        $ab = Get-AheadBehind -LocalBranch $branch -RemoteBranch "origin/$branch"
        if ($ab.Behind -gt 0) {
            Write-Warn "Local '$branch' is behind origin/$branch by $($ab.Behind) commit(s)."
        }
    }
}

# Safety advisory for direct develop -> main promotions.
if ($SourceBranch -eq "develop" -and $TargetBranch -eq "main") {
    Write-Warn "Direct develop -> main merge detected. Consider release/* as intermediate branch."
}

$commitLines = @(git log "$TargetBranch..$SourceBranch" --pretty=format:'%h %ad %an %s' --date=short)
$commitSubjects = @(git log "$TargetBranch..$SourceBranch" --pretty=format:'%s')

if (-not $commitLines -or $commitLines.Count -eq 0) {
    Write-Warn "No new commits to merge from '$SourceBranch' into '$TargetBranch'."
    if (-not $Yes) {
        $emptyProceed = Read-Host "Proceed anyway? (y/N)"
        if ($emptyProceed -ne 'y') { exit 0 }
    }
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
    } catch {
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
    $confirm = Read-Host "Execute merge + push now? (y/N)"
    if ($confirm -ne 'y') {
        Write-Warn "Operation cancelled by user."
        exit 0
    }
}

$releaseSucceeded = $false
try {
    # Checkout target
    if (Get-Command Invoke-GitCheckout -ErrorAction SilentlyContinue) {
        Invoke-GitCheckout -Branch $TargetBranch | Out-Null
    } else {
        git checkout $TargetBranch | Out-Null
    }

    # Update target from remote using ff-only to avoid accidental merge commits.
    git pull --ff-only origin $TargetBranch
    if ($LASTEXITCODE -ne 0) {
        throw "Unable to fast-forward '$TargetBranch' from origin/$TargetBranch."
    }

    # Merge
    if (Get-Command Invoke-GitMerge -ErrorAction SilentlyContinue) {
        if ($Strategy -eq "squash") {
            Invoke-GitMerge -SourceBranch $SourceBranch -Squash | Out-Null
        } else {
            Invoke-GitMerge -SourceBranch $SourceBranch -NoFastForward | Out-Null
        }
    } else {
        if ($Strategy -eq "squash") {
            git merge --squash $SourceBranch
        } else {
            git merge --no-ff $SourceBranch
        }
        if ($LASTEXITCODE -ne 0) {
            throw "Merge failed."
        }
    }

    # Push
    if (Get-Command Invoke-GitPush -ErrorAction SilentlyContinue) {
        Invoke-GitPush -Branch $TargetBranch | Out-Null
    } else {
        git push origin $TargetBranch
        if ($LASTEXITCODE -ne 0) {
            throw "Push failed."
        }
    }

    $releaseSucceeded = $true
    Write-Info "Release completed successfully: $SourceBranch -> $TargetBranch"
}
finally {
    $currentBranch = (git rev-parse --abbrev-ref HEAD).Trim()
    if ($currentBranch -ne $originalBranch) {
        try {
            git checkout $originalBranch | Out-Null
            Write-Info "Returned to original branch '$originalBranch'."
        } catch {
            Write-Warn "Could not return to original branch '$originalBranch': $($_.Exception.Message)"
        }
    }
}

if (-not $releaseSucceeded) {
    exit 1
}
