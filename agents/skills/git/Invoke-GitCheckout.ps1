<#
.SYNOPSIS
    Safely checks out a git branch.

.DESCRIPTION
    Checks out a specific branch. Can optionally create it if missing, or force checkout.
    Verifies the operation was successful.

.PARAMETER Branch
    Name of the branch to checkout (e.g., "main", "develop", "feature/new-ui").

.PARAMETER Create
    If set, creates the branch if it doesn't exist (equivalent to `git checkout -b`).

.PARAMETER Force
    Force checkout even if there are local changes (equivalent to `git checkout -f`).

.EXAMPLE
    Invoke-GitCheckout -Branch "develop"

.OUTPUTS
    PSCustomObject with status and details.
#>
function Invoke-GitCheckout {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Branch,

        [Parameter(Mandatory = $false)]
        [switch]$Create,

        [Parameter(Mandatory = $false)]
        [switch]$Force
    )

    try {
        Write-Verbose "Checking out branch: $Branch (Create: $Create, Force: $Force)"

        git rev-parse --is-inside-work-tree *> $null
        if ($LASTEXITCODE -ne 0) {
            throw "Not inside a git repository."
        }

        $currentBranch = (git rev-parse --abbrev-ref HEAD).Trim()
        if ($currentBranch -eq $Branch) {
            return [PSCustomObject]@{
                Status       = "Success"
                Operation    = "Checkout"
                Branch       = $Branch
                Previous     = $currentBranch
                Created      = $false
                RemoteTracked = $false
                Timestamp    = Get-Date -Format "o"
            }
        }

        git show-ref --verify --quiet "refs/heads/$Branch"
        $localExists = ($LASTEXITCODE -eq 0)

        # Detect remote branch existence without creating local refs.
        $remoteExists = $false
        $remoteHead = git ls-remote --heads origin $Branch 2>$null
        if ($LASTEXITCODE -eq 0 -and $remoteHead) {
            $remoteExists = $true
        }

        $cmdArgs = @("checkout")
        if ($Force) { $cmdArgs += "-f" }

        $created = $false
        $tracked = $false

        if ($localExists) {
            $cmdArgs += $Branch
        } elseif ($remoteExists) {
            $cmdArgs += @("--track", "origin/$Branch")
            $tracked = $true
        } elseif ($Create) {
            $cmdArgs += @("-b", $Branch)
            $created = $true
        } else {
            throw "Branch '$Branch' does not exist locally or on origin. Use -Create to create it."
        }

        $output = & git @cmdArgs 2>&1
        if ($LASTEXITCODE -ne 0) {
            throw "Git checkout failed: $output"
        }

        return [PSCustomObject]@{
            Status        = "Success"
            Operation     = "Checkout"
            Branch        = $Branch
            Previous      = $currentBranch
            Created       = $created
            RemoteTracked = $tracked
            Timestamp     = Get-Date -Format "o"
        }

    }
    catch {
        $errorMsg = $_.Exception.Message
        Write-Error "Invoke-GitCheckout failed: $errorMsg"
        throw
    }
}
