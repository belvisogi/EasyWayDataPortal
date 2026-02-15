param(
    [string]$Branch = "",
    [string]$CommitMessage = "",
    [switch]$SkipCommit,
    [switch]$DryRun,
    [switch]$VerifyOnly,
    [string[]]$Remotes = @("ado", "github", "forgejo"),
    [switch]$NoFetch,
    [switch]$StrictRemotes,
    [int]$PostPushChecks = 3,
    [int]$PostPushCheckIntervalSeconds = 5,
    [switch]$RepairMissingBranch
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

function Test-BranchOnRemote {
    param(
        [Parameter(Mandatory = $true)][string]$Remote,
        [Parameter(Mandatory = $true)][string]$BranchName
    )

    $ls = Invoke-Git -Args @("ls-remote", "--heads", $Remote, $BranchName) -Capture
    if ($ls.ExitCode -ne 0) {
        return [PSCustomObject]@{
            Remote  = $Remote
            Branch  = $BranchName
            Present = $false
            Error   = $ls.Output
            Ref     = ""
        }
    }

    $line = ""
    if (-not [string]::IsNullOrWhiteSpace($ls.Output)) {
        $line = $ls.Output.Split("`n")[0].Trim()
    }

    return [PSCustomObject]@{
        Remote  = $Remote
        Branch  = $BranchName
        Present = (-not [string]::IsNullOrWhiteSpace($line))
        Error   = ""
        Ref     = $line
    }
}

function Repair-BranchOnRemote {
    param(
        [Parameter(Mandatory = $true)][string]$Remote,
        [Parameter(Mandatory = $true)][string]$BranchName
    )
    Invoke-Git -Args @("push", $Remote, "refs/heads/$BranchName:refs/heads/$BranchName")
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
    }
    elseif ($StrictRemotes) {
        throw "Remote '$r' not found."
    }
}

if ($selectedRemotes.Count -eq 0) {
    if ($existingRemotes -contains "origin") {
        Write-Host "Requested remotes not found. Falling back to 'origin'." -ForegroundColor Yellow
        $selectedRemotes = @("origin")
    }
    else {
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
                    }
                    else {
                        throw "Commit failed: $($commit.Output)"
                    }
                }
                else {
                    Write-Host $commit.Output
                }
            }
        }
        else {
            Write-Host "Working tree clean. Skipping commit."
        }
    }

    foreach ($r in $selectedRemotes) {
        Ensure-RemoteExists -Remote $r
    }

    foreach ($r in $selectedRemotes) {
        Write-Step "Pushing '$Branch' to '$r'"
        if ($DryRun) {
            Write-Host "DRY-RUN: git push -u $r $Branch"
            continue
        }
        try {
            Invoke-Git -Args @("push", "-u", $r, $Branch)
        }
        catch {
            Write-Error "Failed to push to $r. Stopping sync to prevent further drift. Manual intervention required."
            throw $_
        }
    }
}

if (-not $NoFetch -and -not $DryRun) {
    foreach ($r in $selectedRemotes) {
        Write-Step "Fetching '$r' for verification"
        Invoke-Git -Args @("fetch", $r, "--prune")
    }
}

$report = @()
$verificationFailures = @()
foreach ($r in $selectedRemotes) {
    Write-Step "Verifying '$Branch' on '$r'"
    if ($DryRun) {
        $report += [PSCustomObject]@{
            Remote   = $r
            Branch   = $Branch
            Status   = "dry-run"
            Check    = 0
            Ref      = ""
            Repaired = "-"
            Detail   = ""
        }
        continue
    }

    $firstCheck = Test-BranchOnRemote -Remote $r -BranchName $Branch
    if (-not $firstCheck.Present) {
        if (-not [string]::IsNullOrWhiteSpace($firstCheck.Error)) {
            throw "Verification failed on '$r': $($firstCheck.Error)"
        }
        throw "Branch '$Branch' not found on remote '$r' after push."
    }

    $report += [PSCustomObject]@{
        Remote   = $r
        Branch   = $Branch
        Status   = "ok"
        Check    = 1
        Ref      = $firstCheck.Ref
        Repaired = "no"
        Detail   = "initial-presence"
    }
}

if (-not $DryRun -and $PostPushChecks -gt 1) {
    for ($checkIndex = 2; $checkIndex -le $PostPushChecks; $checkIndex++) {
        Write-Step "Post-push verification pass $checkIndex/$PostPushChecks"
        Start-Sleep -Seconds $PostPushCheckIntervalSeconds

        foreach ($r in $selectedRemotes) {
            $check = Test-BranchOnRemote -Remote $r -BranchName $Branch
            if ($check.Present) {
                $report += [PSCustomObject]@{
                    Remote   = $r
                    Branch   = $Branch
                    Status   = "ok"
                    Check    = $checkIndex
                    Ref      = $check.Ref
                    Repaired = "no"
                    Detail   = "present"
                }
                continue
            }

            $repairState = "n/a"
            $detail = "missing"
            if (-not [string]::IsNullOrWhiteSpace($check.Error)) {
                $detail = "verification-error: $($check.Error)"
            }

            if ($RepairMissingBranch -and [string]::IsNullOrWhiteSpace($check.Error)) {
                try {
                    Write-Host "Branch missing on '$r', attempting repair push..." -ForegroundColor Yellow
                    Repair-BranchOnRemote -Remote $r -BranchName $Branch
                    $postRepair = Test-BranchOnRemote -Remote $r -BranchName $Branch
                    if ($postRepair.Present) {
                        $repairState = "yes"
                        $detail = "repaired"
                        $report += [PSCustomObject]@{
                            Remote   = $r
                            Branch   = $Branch
                            Status   = "ok"
                            Check    = $checkIndex
                            Ref      = $postRepair.Ref
                            Repaired = $repairState
                            Detail   = $detail
                        }
                        continue
                    }
                    $repairState = "failed"
                    $detail = "repair-failed"
                }
                catch {
                    $repairState = "failed"
                    $detail = "repair-error: $($_.Exception.Message)"
                }
            }

            $report += [PSCustomObject]@{
                Remote   = $r
                Branch   = $Branch
                Status   = "failed"
                Check    = $checkIndex
                Ref      = ""
                Repaired = $repairState
                Detail   = $detail
            }
            $verificationFailures += "$r (check $checkIndex): $detail"
        }
    }
}

Write-Host ""
Write-Host "Verification Report" -ForegroundColor Green
$report | Format-Table -AutoSize

Write-Host ""
if ($verificationFailures.Count -gt 0) {
    throw "Post-push verification detected branch instability: $($verificationFailures -join '; ')"
}

Write-Host "Done." -ForegroundColor Green
