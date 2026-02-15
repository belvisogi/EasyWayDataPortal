param(
    [string]$Branch = "develop",
    [string]$Remote = "origin",
    [ValidateSet("align", "ff-only")]
    [string]$Mode = "align",
    [switch]$SetGuardrails,
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"

function Invoke-Git {
    param([string[]]$GitArgs)
    $output = & git @GitArgs 2>&1
    [PSCustomObject]@{
        ExitCode = $LASTEXITCODE
        Output   = ($output -join "`n").Trim()
    }
}

function Assert-GitOk {
    param([string[]]$GitArgs, [string]$Context)
    $res = Invoke-Git -GitArgs $GitArgs
    if ($res.ExitCode -ne 0) {
        throw "$Context failed: $($res.Output)"
    }
    return $res.Output
}

function Test-RebaseInProgress {
    return (Test-Path ".git\rebase-merge") -or (Test-Path ".git\rebase-apply")
}

function Get-Divergence {
    param([string]$Left, [string]$Right)
    $counts = Assert-GitOk -GitArgs @("rev-list", "--left-right", "--count", "$Left...$Right") -Context "Compute divergence"
    $parts = @($counts -split "\s+")
    if ($parts.Count -lt 2) {
        throw "Unexpected divergence output: '$counts'"
    }
    [PSCustomObject]@{
        Ahead  = [int]$parts[0]
        Behind = [int]$parts[1]
    }
}

Write-Host "Git Safe Sync" -ForegroundColor Cyan
Write-Host "Branch: $Branch"
Write-Host "Remote: $Remote"
Write-Host "Mode:   $Mode"

if (Test-RebaseInProgress) {
    if ($DryRun) {
        Write-Host "[DRY-RUN] Would run: git rebase --abort" -ForegroundColor Yellow
    } else {
        Write-Host "Rebase in progress detected. Aborting..." -ForegroundColor Yellow
        Assert-GitOk -GitArgs @("rebase", "--abort") -Context "Abort rebase" | Out-Null
    }
}

$current = Assert-GitOk -GitArgs @("branch", "--show-current") -Context "Detect current branch"
if ($current -ne $Branch) {
    if ($DryRun) {
        Write-Host "[DRY-RUN] Would run: git checkout $Branch" -ForegroundColor Yellow
    } else {
            Assert-GitOk -GitArgs @("checkout", $Branch) -Context "Checkout branch" | Out-Null
    }
}

if ($SetGuardrails) {
    $guardrails = @(
        @("config", "pull.rebase", "false"),
        @("config", "branch.$Branch.rebase", "false"),
        @("config", "pull.ff", "only")
    )
    foreach ($cmd in $guardrails) {
        if ($DryRun) {
            Write-Host "[DRY-RUN] Would run: git $($cmd -join ' ')" -ForegroundColor Yellow
        } else {
            Assert-GitOk -GitArgs $cmd -Context "Set guardrail '$($cmd -join ' ')'" | Out-Null
        }
    }
}

if ($DryRun) {
    Write-Host "[DRY-RUN] Would run: git fetch $Remote" -ForegroundColor Yellow
} else {
    Assert-GitOk -GitArgs @("fetch", $Remote) -Context "Fetch remote" | Out-Null
}

$remoteRef = "$Remote/$Branch"
Assert-GitOk -GitArgs @("rev-parse", "--verify", $remoteRef) -Context "Verify remote ref" | Out-Null

$div = Get-Divergence -Left $Branch -Right $remoteRef
Write-Host "Divergence: ahead=$($div.Ahead) behind=$($div.Behind)"

if ($div.Ahead -gt 0) {
    $backup = "backup/$Branch-local-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
    if ($DryRun) {
        Write-Host "[DRY-RUN] Would create backup branch: $backup -> $Branch" -ForegroundColor Yellow
    } else {
        Assert-GitOk -GitArgs @("branch", $backup, $Branch) -Context "Create backup branch" | Out-Null
        Write-Host "Backup created: $backup" -ForegroundColor Green
    }
}

if ($div.Ahead -eq 0 -and $div.Behind -eq 0) {
    Write-Host "Already aligned." -ForegroundColor Green
    exit 0
}

if ($Mode -eq "ff-only" -and $div.Ahead -eq 0 -and $div.Behind -gt 0) {
    if ($DryRun) {
        Write-Host "[DRY-RUN] Would run: git merge --ff-only $remoteRef" -ForegroundColor Yellow
    } else {
        Assert-GitOk -GitArgs @("merge", "--ff-only", $remoteRef) -Context "Fast-forward merge" | Out-Null
    }
} elseif ($Mode -eq "ff-only" -and $div.Ahead -gt 0) {
    throw "Cannot ff-only sync because local branch is ahead by $($div.Ahead) commits."
} else {
    if ($DryRun) {
        Write-Host "[DRY-RUN] Would run: git reset --hard $remoteRef" -ForegroundColor Yellow
    } else {
        Assert-GitOk -GitArgs @("reset", "--hard", $remoteRef) -Context "Hard align to remote" | Out-Null
    }
}

$finalDiv = Get-Divergence -Left $Branch -Right $remoteRef
Write-Host "Final divergence: ahead=$($finalDiv.Ahead) behind=$($finalDiv.Behind)" -ForegroundColor Cyan
if ($finalDiv.Ahead -eq 0 -and $finalDiv.Behind -eq 0) {
    Write-Host "Safe sync completed." -ForegroundColor Green
} else {
    throw "Safe sync incomplete."
}
