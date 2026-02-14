<#
.SYNOPSIS
    Pushes changes to the remote repository.

.DESCRIPTION
    Pushes the current branch to origin.
    Includes safety checks (though simple for now).

.PARAMETER SetUpstream
    If set, sets the upstream branch (-u).

.PARAMETER Force
    Force push (Use with EXTREME CAUTION).

.EXAMPLE
    Invoke-GitPush -SetUpstream

.OUTPUTS
    PSCustomObject with push status.
#>
function Invoke-GitPush {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$Branch,

        [Parameter(Mandatory = $false)]
        [string]$Remote = "origin",

        [Parameter(Mandatory = $false)]
        [switch]$SetUpstream,

        [Parameter(Mandatory = $false)]
        [switch]$Force,

        [Parameter(Mandatory = $false)]
        [string[]]$ProtectedBranches = @("main", "master")
    )

    try {
        git rev-parse --is-inside-work-tree *> $null
        if ($LASTEXITCODE -ne 0) {
            throw "Not inside a git repository."
        }

        if (-not $Branch) {
            $Branch = (git rev-parse --abbrev-ref HEAD).Trim()
        }

        Write-Verbose "Pushing branch '$Branch' to '$Remote'..."

        if ($ProtectedBranches -contains $Branch -and $Force) {
            throw "Force push is blocked for protected branch '$Branch'."
        }

        git fetch $Remote $Branch --quiet 2>$null
        git rev-parse --verify --quiet "refs/remotes/$Remote/$Branch"
        $remoteBranchExists = ($LASTEXITCODE -eq 0)
        if ($remoteBranchExists) {
            $aheadBehind = (git rev-list --left-right --count "$Branch...$Remote/$Branch").Trim()
            if ($aheadBehind) {
                $parts = $aheadBehind -split '\s+'
                $behind = [int]$parts[1]
                if ($behind -gt 0 -and -not $Force) {
                    throw "Local branch '$Branch' is behind '$Remote/$Branch' by $behind commit(s). Pull/rebase before push."
                }
            }
        }

        $cmdArgs = @("push")
        if ($Force) { $cmdArgs += "--force-with-lease" } # Safer than --force
        if ($SetUpstream) { $cmdArgs += "-u" }
        $cmdArgs += @($Remote, $Branch)

        $output = & git @cmdArgs 2>&1
        if ($LASTEXITCODE -ne 0) {
            throw "Git push failed: $output"
        }

        return [PSCustomObject]@{
            Status        = "Success"
            Operation     = "Push"
            Branch        = $Branch
            Remote        = $Remote
            SetUpstream   = $SetUpstream.IsPresent
            ForceWithLease = $Force.IsPresent
            Timestamp     = Get-Date -Format "o"
        }

    }
    catch {
        Write-Error "Invoke-GitPush failed: $_"
        throw
    }
}
