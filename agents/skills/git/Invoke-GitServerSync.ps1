<#
.SYNOPSIS
    Safely syncs a remote server repository to a target branch.

.DESCRIPTION
    Executes server-side safe sync flow through SSH:
    - backup branch/tag + status/diff snapshot
    - stash local/untracked changes
    - fetch + checkout target branch
    - pull --ff-only (optional hard reset fallback)
    - optional clean and optional sudo cleanup paths
#>
function Invoke-GitServerSync {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ServerHost,

        [Parameter(Mandatory = $false)]
        [string]$ServerUser = "ubuntu",

        [Parameter(Mandatory = $false)]
        [string]$ServerRepoPath = "~/EasyWayDataPortal",

        [Parameter(Mandatory = $false)]
        [string]$Branch = "main",

        [Parameter(Mandatory = $false)]
        [string]$ServerSshKeyPath,

        [Parameter(Mandatory = $false)]
        [switch]$SkipClean,

        [Parameter(Mandatory = $false)]
        [string[]]$SudoCleanPaths = @(),

        [Parameter(Mandatory = $false)]
        [switch]$AllowHardReset,

        [Parameter(Mandatory = $false)]
        [switch]$Yes
    )

    function Convert-ToBashDoubleQuoted {
        param([string]$Value)

        if ($null -eq $Value) {
            return '""'
        }

        $escaped = $Value -replace '\\', '\\\\'
        $escaped = $escaped -replace '"', '\\"'
        return '"' + $escaped + '"'
    }

    function Invoke-RemoteSsh {
        param(
            [Parameter(Mandatory = $true)]
            [string]$Command,
            [switch]$AllowFailure
        )

        $sshArgs = @()
        if ($ServerSshKeyPath) {
            $sshArgs += @("-i", $ServerSshKeyPath)
        }

        $sshArgs += @("$ServerUser@$ServerHost", $Command)
        $output = & ssh @sshArgs 2>&1
        $exitCode = $LASTEXITCODE

        if ($exitCode -ne 0 -and -not $AllowFailure) {
            throw "SSH command failed ($exitCode): $($output -join [Environment]::NewLine)"
        }

        return [PSCustomObject]@{
            ExitCode = $exitCode
            Output   = ($output | Out-String).Trim()
        }
    }

    function Confirm-OrThrow {
        param([string]$Prompt)
        if ($Yes) {
            return
        }

        $choice = Read-Host "$Prompt (y/N)"
        if ($choice -ne "y") {
            throw "Operation cancelled by user."
        }
    }

    if (-not (Get-Command ssh -ErrorAction SilentlyContinue)) {
        throw "OpenSSH client (ssh) is not available on this machine."
    }

    $repoQuoted = Convert-ToBashDoubleQuoted -Value $ServerRepoPath
    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"

    Confirm-OrThrow -Prompt "Proceed with remote backup + stash + sync on $ServerUser@$ServerHost"

    $preflightCmd = "set -e; cd $repoQuoted; git rev-parse --is-inside-work-tree"
    Invoke-RemoteSsh -Command $preflightCmd | Out-Null

    $backupCmd = @"
set -e
cd $repoQuoted
TS=$timestamp
BACKUP_DIR="`$HOME/git-backups/easyway/`$TS"
mkdir -p "`$BACKUP_DIR"
git status --short > "`$BACKUP_DIR/status-before.txt" || true
git diff > "`$BACKUP_DIR/changes.diff" || true
git branch -f "backup/server-$Branch-pre-sync-`$TS" HEAD
git tag -f "backup/pre-sync-`$TS" HEAD
git stash push -u -m "pre-sync-`$TS" >/dev/null 2>&1 || true
"@
    Invoke-RemoteSsh -Command $backupCmd | Out-Null

    $fetchCheckoutCmd = "set -e; cd $repoQuoted; git fetch origin --prune; git checkout $Branch || git checkout -B $Branch origin/$Branch"
    Invoke-RemoteSsh -Command $fetchCheckoutCmd | Out-Null

    $pullCmd = "set -e; cd $repoQuoted; git pull --ff-only origin $Branch"
    $pullResult = Invoke-RemoteSsh -Command $pullCmd -AllowFailure
    if ($pullResult.ExitCode -ne 0) {
        if (-not $AllowHardReset) {
            throw "Fast-forward pull failed for '$Branch'. Re-run with -AllowHardReset to realign by reset."
        }

        Confirm-OrThrow -Prompt "Fast-forward failed. Apply hard reset to origin/$Branch"
        $resetCmd = "set -e; cd $repoQuoted; git reset --hard origin/$Branch"
        Invoke-RemoteSsh -Command $resetCmd | Out-Null
    }

    if (-not $SkipClean) {
        $cleanCmd = "set -e; cd $repoQuoted; git clean -fd"
        Invoke-RemoteSsh -Command $cleanCmd -AllowFailure | Out-Null
    }

    if ($SudoCleanPaths -and $SudoCleanPaths.Count -gt 0) {
        $joined = ($SudoCleanPaths | ForEach-Object { Convert-ToBashDoubleQuoted -Value $_ }) -join ' '
        $sudoCmd = "set -e; cd $repoQuoted; sudo rm -rf $joined"
        Invoke-RemoteSsh -Command $sudoCmd | Out-Null
    }

    $finalCmd = "cd $repoQuoted; git status -sb; git stash list | head -n 3; git branch --list 'backup/*' | tail -n 3; git tag --list 'backup/*' | tail -n 3"
    $final = Invoke-RemoteSsh -Command $finalCmd

    return [PSCustomObject]@{
        Status      = "Success"
        Operation   = "ServerSync"
        ServerHost  = $ServerHost
        ServerUser  = $ServerUser
        RepoPath    = $ServerRepoPath
        Branch      = $Branch
        Timestamp   = Get-Date -Format "o"
        FinalStatus = $final.Output
    }
}
