param(
    [string]$Branch = "",
    [string[]]$Remotes = @("ado", "github", "forgejo", "origin"),
    [int]$IntervalSeconds = 60,
    [int]$Samples = 0,
    [switch]$RepairMissingBranch,
    [string]$LogFile = "docs/ops/branch-presence-monitor.log"
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

function Get-ExistingRemotes {
    $res = Invoke-GitCapture -Args @("remote")
    if ($res.ExitCode -ne 0) {
        throw "Unable to list remotes: $($res.Output)"
    }
    return @($res.Output.Split("`n") | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne "" })
}

function Test-Branch {
    param(
        [Parameter(Mandatory = $true)][string]$Remote,
        [Parameter(Mandatory = $true)][string]$BranchName
    )
    $res = Invoke-GitCapture -Args @("ls-remote", "--heads", $Remote, $BranchName)
    if ($res.ExitCode -ne 0) {
        return [PSCustomObject]@{
            Present = $false
            Ref     = ""
            Error   = $res.Output
        }
    }

    if ([string]::IsNullOrWhiteSpace($res.Output)) {
        return [PSCustomObject]@{
            Present = $false
            Ref     = ""
            Error   = ""
        }
    }

    $line = $res.Output.Split("`n")[0].Trim()
    return [PSCustomObject]@{
        Present = $true
        Ref     = $line
        Error   = ""
    }
}

function Write-LogLine {
    param([string]$Line)
    $dir = Split-Path -Parent $LogFile
    if (-not (Test-Path -LiteralPath $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
    Add-Content -Path $LogFile -Value $Line
}

if ([string]::IsNullOrWhiteSpace($Branch)) {
    $current = Invoke-GitCapture -Args @("branch", "--show-current")
    if ($current.ExitCode -ne 0 -or [string]::IsNullOrWhiteSpace($current.Output)) {
        throw "Cannot detect current branch."
    }
    $Branch = $current.Output.Trim()
}

$existingRemotes = Get-ExistingRemotes
$normalizedRemotes = @()
foreach ($r in $Remotes) {
    if ([string]::IsNullOrWhiteSpace($r)) {
        continue
    }
    if ($r.Contains(",")) {
        $normalizedRemotes += @($r.Split(",") | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne "" })
    }
    else {
        $normalizedRemotes += $r.Trim()
    }
}

$selectedRemotes = @($normalizedRemotes | Where-Object { $existingRemotes -contains $_ } | Select-Object -Unique)
if ($selectedRemotes.Count -eq 0) {
    throw "No selected remotes found in repository."
}

Write-Host "Branch monitor started"
Write-Host "Branch:  $Branch"
Write-Host "Remotes: $($selectedRemotes -join ', ')"
Write-Host "Log:     $LogFile"
if ($RepairMissingBranch) {
    Write-Host "Repair mode: enabled"
}

$previousPresence = @{}
$sampleCounter = 0

while ($true) {
    $sampleCounter++
    $ts = Get-Date -Format "yyyy-MM-ddTHH:mm:ssK"

    foreach ($remote in $selectedRemotes) {
        $check = Test-Branch -Remote $remote -BranchName $Branch
        $status = "ok"
        $detail = $check.Ref
        $repair = "no"

        if ($check.Error) {
            $status = "error"
            $detail = $check.Error
        }
        elseif (-not $check.Present) {
            $status = "missing"
            $detail = "branch-not-found"

            if ($RepairMissingBranch) {
                $push = Invoke-GitCapture -Args @("push", $remote, "refs/heads/$Branch:refs/heads/$Branch")
                if ($push.ExitCode -eq 0) {
                    $recheck = Test-Branch -Remote $remote -BranchName $Branch
                    if ($recheck.Present) {
                        $status = "repaired"
                        $detail = $recheck.Ref
                        $repair = "yes"
                    }
                    else {
                        $status = "repair-failed"
                        $detail = "repair-push-sent-but-branch-still-missing"
                        $repair = "failed"
                    }
                }
                else {
                    $status = "repair-error"
                    $detail = $push.Output
                    $repair = "failed"
                }
            }
        }

        if ($previousPresence.ContainsKey($remote) -and $previousPresence[$remote] -eq $true -and $check.Present -eq $false) {
            Write-Host "ALERT: branch became missing on '$remote' at $ts" -ForegroundColor Red
        }
        $previousPresence[$remote] = $check.Present

        $line = "$ts sample=$sampleCounter branch=$Branch remote=$remote status=$status repair=$repair detail=$detail"
        Write-Host $line
        Write-LogLine -Line $line
    }

    if ($Samples -gt 0 -and $sampleCounter -ge $Samples) {
        break
    }
    Start-Sleep -Seconds $IntervalSeconds
}

Write-Host "Branch monitor finished." -ForegroundColor Green
