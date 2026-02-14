param(
    [string]$Branch = "",
    [string]$CommitMessage = "",
    [switch]$SkipCommit,
    [switch]$DryRun,
    [switch]$VerifyOnly,
    [string[]]$Remotes = @("ado", "github", "forgejo"),
    [switch]$NoFetch,
    [switch]$StrictRemotes
)

$ErrorActionPreference = "Stop"

function Invoke-Git {
    param(
        [Parameter(Mandatory = $true)][string[]]$Args,
        [switch]$Capture
    )

    if ($Capture) {
        $output = & git @Args 2>&1
        $exitCode = $LASTEXITCODE
        return [PSCustomObject]@{
            ExitCode = $exitCode
            Output   = ($output -join "`n")
        }
    }

    & git @Args
    if ($LASTEXITCODE -ne 0) {
        throw "git $($Args -join ' ') failed with exit code $LASTEXITCODE"
    }
}

function Ensure-RemoteExists {
    param([string]$Remote)
    $res = Invoke-Git -Args @("remote", "get-url", $Remote) -Capture
    if ($res.ExitCode -ne 0) {
        throw "Remote '$Remote' not found."
    }
}

function Get-ExistingRemotes {
    $res = Invoke-Git -Args @("remote") -Capture
    if ($res.ExitCode -ne 0) {
        throw "Unable to list git remotes."
    }
    return @($res.Output.Split("`n") | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne "" })
}

function Write-Step {
    param([string]$Text)
    Write-Host "==> $Text" -ForegroundColor Cyan
}

if ([string]::IsNullOrWhiteSpace($Branch)) {
    $current = Invoke-Git -Args @("branch", "--show-current") -Capture
    if ($current.ExitCode -ne 0 -or [string]::IsNullOrWhiteSpace($current.Output)) {
        throw "Unable to detect current branch. Pass -Branch explicitly."
    }
    $Branch = $current.Output.Trim()
}

Write-Host "Branch:  $Branch"
Write-Host "Mode:    $([string]::Join(', ', @(
    $(if ($DryRun) { 'dry-run' } else { 'execute' }),
    $(if ($VerifyOnly) { 'verify-only' } else { 'push' }),
    $(if ($SkipCommit) { 'skip-commit' } else { 'with-commit' })
)))"

$existingRemotes = Get-ExistingRemotes
$selectedRemotes = @()

foreach ($r in $Remotes) {
    if ($existingRemotes -contains $r) {
        $selectedRemotes += $r
    } elseif ($StrictRemotes) {
        throw "Remote '$r' not found."
    }
}

if ($selectedRemotes.Count -eq 0) {
    if ($existingRemotes -contains "origin") {
        Write-Host "Requested remotes not found. Falling back to 'origin'." -ForegroundColor Yellow
        $selectedRemotes = @("origin")
    } else {
        throw "No usable remotes found. Configure remotes (ado/github/forgejo) or origin."
    }
}

# de-duplicate while preserving order
$seen = @{}
$selectedRemotes = @($selectedRemotes | Where-Object { if ($seen.ContainsKey($_)) { $false } else { $seen[$_] = $true; $true } })
Write-Host "Remotes: $($selectedRemotes -join ', ')"

if (-not $VerifyOnly) {
    if (-not $SkipCommit) {
        $st = Invoke-Git -Args @("status", "--porcelain") -Capture
        if ($st.ExitCode -ne 0) {
            throw "Unable to read git status."
        }

        if (-not [string]::IsNullOrWhiteSpace($st.Output)) {
            Write-Step "Staging changes"
            if (-not $DryRun) {
                Invoke-Git -Args @("add", "-A")
            }

            if ([string]::IsNullOrWhiteSpace($CommitMessage)) {
                $CommitMessage = "chore(sync): update before multi-remote push"
            }

            Write-Step "Creating commit"
            if (-not $DryRun) {
                $commit = Invoke-Git -Args @("commit", "-m", $CommitMessage) -Capture
                if ($commit.ExitCode -ne 0) {
                    if ($commit.Output -match "nothing to commit") {
                        Write-Host "No commit created (nothing to commit)." -ForegroundColor Yellow
                    } else {
                        throw "Commit failed: $($commit.Output)"
                    }
                } else {
                    Write-Host $commit.Output
                }
            }
        } else {
            Write-Host "Working tree clean. Skipping commit."
        }
    }

    foreach ($r in $selectedRemotes) {
        Write-Step "Pushing '$Branch' to '$r'"
        if ($DryRun) {
            Write-Host "DRY-RUN: git push -u $r $Branch"
            continue
        }
        Invoke-Git -Args @("push", "-u", $r, $Branch)
    }
}

if (-not $NoFetch -and -not $DryRun) {
    foreach ($r in $selectedRemotes) {
        Write-Step "Fetching '$r' for verification"
        Invoke-Git -Args @("fetch", $r, "--prune")
    }
}

$report = @()
foreach ($r in $selectedRemotes) {
    Write-Step "Verifying '$Branch' on '$r'"
    if ($DryRun) {
        $report += [PSCustomObject]@{ Remote = $r; Branch = $Branch; Status = "dry-run"; Ref = "" }
        continue
    }

    $ls = Invoke-Git -Args @("ls-remote", "--heads", $r, $Branch) -Capture
    if ($ls.ExitCode -ne 0) {
        throw "Verification failed on '$r': $($ls.Output)"
    }

    if ([string]::IsNullOrWhiteSpace($ls.Output)) {
        throw "Branch '$Branch' not found on remote '$r' after push."
    }

    $report += [PSCustomObject]@{
        Remote = $r
        Branch = $Branch
        Status = "ok"
        Ref    = ($ls.Output.Split("`n")[0].Trim())
    }
}

Write-Host ""
Write-Host "Verification Report" -ForegroundColor Green
$report | Format-Table -AutoSize

Write-Host ""
Write-Host "Done." -ForegroundColor Green
