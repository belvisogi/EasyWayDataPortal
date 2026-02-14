<#
.SYNOPSIS
    Merges a branch into the current branch.

.DESCRIPTION
    Merges the specified source branch into the currently checked out branch.
    Aborts immediately if conflicts occur to prevent leaving the repo in a broken state.

.PARAMETER SourceBranch
    Name of the branch to merge FROM (e.g., "develop").

.PARAMETER Squash
    Perform a squash merge.

.PARAMETER NoFastForward
    Create a merge commit even if fast-forward is possible (--no-ff).

.EXAMPLE
    Invoke-GitMerge -SourceBranch "feature/login" -NoFastForward

.OUTPUTS
    PSCustomObject with merge result.
#>
function Invoke-GitMerge {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$SourceBranch,

        [Parameter(Mandatory = $false)]
        [switch]$Squash,

        [Parameter(Mandatory = $false)]
        [switch]$NoFastForward
    )

    try {
        git rev-parse --is-inside-work-tree *> $null
        if ($LASTEXITCODE -ne 0) {
            throw "Not inside a git repository."
        }

        git show-ref --verify --quiet "refs/heads/$SourceBranch"
        $sourceExistsLocal = ($LASTEXITCODE -eq 0)
        if (-not $sourceExistsLocal) {
            throw "Source branch '$SourceBranch' does not exist locally."
        }

        $currentBranch = (git rev-parse --abbrev-ref HEAD).Trim()
        Write-Verbose "Merging '$SourceBranch' into '$currentBranch'..."

        $cmdArgs = @("merge")
        if ($Squash) { $cmdArgs += "--squash" }
        if ($NoFastForward) { $cmdArgs += "--no-ff" }
        $cmdArgs += $SourceBranch

        # Capture output and error
        $output = & git @cmdArgs 2>&1
        $exitCode = $LASTEXITCODE

        if ($exitCode -ne 0) {
            # If merge is in progress, abort it to restore clean state.
            git rev-parse -q --verify MERGE_HEAD *> $null
            $mergeInProgress = ($LASTEXITCODE -eq 0)
            if ($mergeInProgress) {
                Write-Warning "Merge conflict detected. Aborting merge to restore state."
                git merge --abort 2>$null
                throw "Merge conflict detected between '$SourceBranch' and '$currentBranch'. Merge aborted."
            }

            throw "Git merge failed: $output"
        }

        return [PSCustomObject]@{
            Status         = "Success"
            Operation      = "Merge"
            Source         = $SourceBranch
            Target         = $currentBranch
            Squash         = $Squash.IsPresent
            NoFastForward  = $NoFastForward.IsPresent
            Timestamp      = Get-Date -Format "o"
        }

    }
    catch {
        Write-Error "Invoke-GitMerge failed: $_"
        throw
    }
}
