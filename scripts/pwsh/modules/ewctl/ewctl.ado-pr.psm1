<#
.SYNOPSIS
  [ADO-PR] Shared module for Azure DevOps Pull Request operations.
  Eliminates duplication across Create-ReleasePR, New-PbiBranch, Publish-WikiPages.

.DESCRIPTION
  Provides structural guarantees:
  - Work item linking via API (not fragile regex)
  - Pre-PR conflict detection
  - noFastForward merge strategy enforcement
  - PAT identity governance (different PATs for different scopes)
#>

# ── Private Constants ────────────────────────────────────────────────────────
$script:DefaultOrgUrl  = 'https://dev.azure.com/EasyWayData'
$script:DefaultProject = 'EasyWay-DataPortal'
$script:DefaultRepoId  = 'EasyWayDataPortal'
$script:DefaultApiVer  = '7.1'

# ── 1. Resolve-AdoPat ────────────────────────────────────────────────────────
function Resolve-AdoPat {
    <#
    .SYNOPSIS  Resolves an ADO PAT from parameter, environment variable, or .env file.
    .DESCRIPTION
        Priority: explicit $Pat > environment variable > .env.local/.env.secrets file.
        Cross-platform: checks Windows and Linux paths.
    #>
    [CmdletBinding()]
    param(
        [string]$Pat,
        [string[]]$EnvVarNames = @('ADO_PR_CREATOR_PAT', 'AZURE_DEVOPS_EXT_PAT'),
        [string[]]$EnvFiles = @('C:\old\.env.local', '/opt/easyway/.env.secrets')
    )

    # 1. Explicit parameter
    if ($Pat) { return $Pat }

    # 2. Environment variables (in priority order)
    foreach ($name in $EnvVarNames) {
        $val = [System.Environment]::GetEnvironmentVariable($name)
        if ($val) { return $val }
    }

    # 3. .env files on disk
    foreach ($file in $EnvFiles) {
        if (Test-Path $file) {
            $lines = Get-Content $file -ErrorAction SilentlyContinue
            foreach ($name in $EnvVarNames) {
                $match = $lines | Where-Object { $_ -match "^${name}=" } | Select-Object -First 1
                if ($match) {
                    return ($match -split '=', 2)[1].Trim().Trim('"')
                }
            }
        }
    }

    return $null
}

# ── 2. New-AdoAuthHeaders ───────────────────────────────────────────────────
function New-AdoAuthHeaders {
    <#
    .SYNOPSIS  Creates HTTP headers for ADO REST API calls.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Pat,
        [string]$ContentType = 'application/json'
    )
    $bytes = [System.Text.Encoding]::UTF8.GetBytes(":$Pat")
    $b64   = [System.Convert]::ToBase64String($bytes)
    return @{ Authorization = "Basic $b64"; 'Content-Type' = $ContentType }
}

# ── 3. Invoke-AdoApi ─────────────────────────────────────────────────────────
function Invoke-AdoApi {
    <#
    .SYNOPSIS  Makes an ADO REST API call with standard error handling.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Url,
        [Parameter(Mandatory)]
        [hashtable]$Headers,
        [ValidateSet('Get', 'Post', 'Patch')]
        [string]$Method = 'Get',
        [string]$Body,
        [int]$TimeoutSec = 30
    )
    try {
        $params = @{
            Uri     = $Url
            Headers = $Headers
            Method  = $Method
            TimeoutSec = $TimeoutSec
        }
        if ($Body) { $params.Body = $Body }
        return Invoke-RestMethod @params
    }
    catch {
        $code = $_.Exception.Response.StatusCode.value__
        Write-Warning "ADO API error ${code}: $Url"
        return $null
    }
}

# ── 4. Get-PrWorkItemIds ─────────────────────────────────────────────────────
function Get-PrWorkItemIds {
    <#
    .SYNOPSIS  Gets work item IDs linked to one or more ADO PRs.
    .DESCRIPTION
        Uses GET pullrequests/{id}/workitems API for structural linking.
        Optionally falls back to title regex ([PBI-N], AB#N) for legacy PRs.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$Headers,
        [Parameter(Mandatory)]
        [int[]]$PrIds,
        [object[]]$PrObjects,                     # optional: PR objects with .title/.description
        [switch]$IncludeTitleFallback,
        [string]$OrgUrl  = $script:DefaultOrgUrl,
        [string]$Project = $script:DefaultProject,
        [string]$RepoId  = $script:DefaultRepoId
    )

    $allIds = [System.Collections.Generic.HashSet[int]]::new()
    $repoBase = "$OrgUrl/$Project/_apis/git/repositories/$RepoId"

    foreach ($prId in $PrIds) {
        # Structural: query API for linked work items
        $resp = Invoke-AdoApi -Url "$repoBase/pullrequests/$prId/workitems?api-version=$($script:DefaultApiVer)" -Headers $Headers
        if ($resp -and $resp.value) {
            foreach ($wi in $resp.value) {
                [void]$allIds.Add([int]$wi.id)
            }
        }
    }

    # Fallback: regex on PR titles/descriptions for legacy PRs
    if ($IncludeTitleFallback -and $PrObjects) {
        foreach ($pr in $PrObjects) {
            $text = "$($pr.title) $($pr.description)"
            if ($text -match '\[PBI-(\d+)\]') { [void]$allIds.Add([int]$Matches[1]) }
            $abMatches = [regex]::Matches($text, 'AB#(\d+)')
            foreach ($m in $abMatches) { [void]$allIds.Add([int]$m.Groups[1].Value) }
        }
    }

    return [int[]]($allIds | Sort-Object)
}

# ── 5. Test-MergeConflicts ────────────────────────────────────────────────────
function Test-MergeConflicts {
    <#
    .SYNOPSIS  Checks if merging source into target would produce conflicts.
    .DESCRIPTION
        Performs a local dry-run merge without modifying the working tree.
        Uses git stash + detached HEAD + merge --no-commit + abort pattern.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$SourceBranch,
        [Parameter(Mandatory)]
        [string]$TargetBranch,
        [switch]$FetchFirst
    )

    $result = [PSCustomObject]@{
        HasConflicts    = $false
        ConflictedFiles = @()
        SourceSHA       = ''
        TargetSHA       = ''
    }

    $originalBranch = git rev-parse --abbrev-ref HEAD 2>$null
    $hadChanges = $false

    try {
        # Fetch if requested
        if ($FetchFirst) {
            git fetch origin $SourceBranch $TargetBranch 2>$null
        }

        # Check branches exist
        $result.SourceSHA = git rev-parse "origin/$SourceBranch" 2>$null
        $result.TargetSHA = git rev-parse "origin/$TargetBranch" 2>$null
        if (-not $result.SourceSHA -or -not $result.TargetSHA) {
            Write-Warning "Cannot check conflicts: branch not found"
            return $result
        }

        # Stash any local changes
        $stashOutput = git stash 2>&1
        $hadChanges = $stashOutput -notmatch 'No local changes'

        # Detach to target branch
        git checkout --detach "origin/$TargetBranch" 2>$null

        # Attempt merge
        $mergeOutput = git merge --no-commit --no-ff "origin/$SourceBranch" 2>&1
        if ($LASTEXITCODE -ne 0) {
            $result.HasConflicts = $true
            $result.ConflictedFiles = @(git diff --name-only --diff-filter=U 2>$null)
            git merge --abort 2>$null
        }
        else {
            # Clean merge — abort to not leave the merge commit
            git merge --abort 2>$null
            git reset --hard HEAD 2>$null
        }
    }
    finally {
        # Restore original state
        if ($originalBranch -and $originalBranch -ne 'HEAD') {
            git checkout $originalBranch 2>$null
        }
        elseif ($originalBranch -eq 'HEAD') {
            git checkout - 2>$null
        }
        if ($hadChanges) {
            git stash pop 2>$null
        }
    }

    return $result
}

# ── 6. New-AdoPullRequest ─────────────────────────────────────────────────────
function New-AdoPullRequest {
    <#
    .SYNOPSIS  Creates an ADO Pull Request with structural guarantees.
    .DESCRIPTION
        - Always uses noFastForward merge strategy
        - Links work items when provided
        - Optionally checks for merge conflicts before creation
        - Returns structured result object
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$Headers,
        [Parameter(Mandatory)]
        [string]$Title,
        [Parameter(Mandatory)]
        [string]$SourceBranch,
        [Parameter(Mandatory)]
        [string]$TargetBranch,
        [string]$Description   = '',
        [int[]]$WorkItemIds    = @(),
        [hashtable]$WorkItemHeaders,      # separate auth for WI PATCH (ADO_WORKITEMS_PAT)
        [switch]$IsDraft,
        [switch]$SkipConflictCheck,
        [string]$OrgUrl  = $script:DefaultOrgUrl,
        [string]$Project = $script:DefaultProject,
        [string]$RepoId  = $script:DefaultRepoId
    )

    $result = [PSCustomObject]@{
        Success     = $false
        PrId        = 0
        PrUrl       = ''
        WorkItemIds = $WorkItemIds
        Conflicts   = $null
        Error       = ''
    }

    # Pre-flight conflict check
    if (-not $SkipConflictCheck) {
        $conflicts = Test-MergeConflicts -SourceBranch $SourceBranch -TargetBranch $TargetBranch -FetchFirst
        $result.Conflicts = $conflicts
        if ($conflicts.HasConflicts) {
            $files = $conflicts.ConflictedFiles -join ', '
            $result.Error = "Merge conflicts detected: $files"
            return $result
        }
    }

    # Build PR body
    $bodyHash = @{
        title             = $Title
        description       = $Description
        sourceRefName     = "refs/heads/$SourceBranch"
        targetRefName     = "refs/heads/$TargetBranch"
        isDraft           = [bool]$IsDraft
        completionOptions = @{
            squashMerge   = $false
            mergeStrategy = 'noFastForward'
        }
    }
    if ($WorkItemIds.Count -gt 0) {
        $bodyHash.workItemRefs = $WorkItemIds | ForEach-Object { @{ id = "$_" } }
    }
    $body = $bodyHash | ConvertTo-Json -Depth 3

    # Create PR
    $repoBase = "$OrgUrl/$Project/_apis/git/repositories/$RepoId"
    try {
        $resp = Invoke-RestMethod -Uri "$repoBase/pullrequests?api-version=$($script:DefaultApiVer)" `
            -Headers $Headers -Method Post -Body $body
        $result.Success = $true
        $result.PrId    = $resp.pullRequestId
        $result.PrUrl   = "$OrgUrl/$Project/_git/$RepoId/pullrequest/$($resp.pullRequestId)"
    }
    catch {
        $errBody = $_.ErrorDetails.Message
        $result.Error = "$($_.Exception.Message) $errBody"
        return $result
    }

    # ── Post-creation: create ArtifactLink on each work item ──────────────
    # workItemRefs in the PR body is NOT sufficient for ADO branch policy
    # "Work Items must be linked". The policy checks for ArtifactLink relations
    # on the work item side pointing back to the PR. We must PATCH each WI.
    # NOTE: WI PATCH often requires a different PAT (ADO_WORKITEMS_PAT / scrum-master)
    # than the PR creator PAT. Use -WorkItemHeaders or auto-resolve from env.
    if ($result.Success -and $WorkItemIds.Count -gt 0) {
        # Resolve WI auth headers (separate identity governance)
        $wiAuth = $WorkItemHeaders
        if (-not $wiAuth) {
            $wiPat = Resolve-AdoPat -EnvVarNames @('ADO_WORKITEMS_PAT', 'ADO_PR_CREATOR_PAT', 'AZURE_DEVOPS_EXT_PAT')
            if ($wiPat) {
                $wiAuth = New-AdoAuthHeaders -Pat $wiPat
            } else {
                Write-Warning "No PAT available for work item linking. PR created but WI ArtifactLink skipped."
            }
        }

        if ($wiAuth) {
            $projectId = $null
            # Resolve project ID and repo GUID using $Headers (PR creator PAT
            # has Code Read scope). $wiAuth (scrum-master) may lack Code Read.
            try {
                $projResp = Invoke-RestMethod -Uri "$OrgUrl/_apis/projects/$Project`?api-version=$($script:DefaultApiVer)" `
                    -Headers $Headers -Method Get
                $projectId = $projResp.id
            } catch {
                Write-Warning "Could not resolve project ID for ArtifactLink: $($_.Exception.Message)"
            }

            # Resolve repository GUID (RepoId param may be name, not GUID)
            $repoGuid = $null
            if ($projectId) {
                try {
                    $repoResp = Invoke-RestMethod -Uri "$repoBase`?api-version=$($script:DefaultApiVer)" `
                        -Headers $Headers -Method Get
                    $repoGuid = $repoResp.id
                } catch {
                    Write-Warning "Could not resolve repo GUID for ArtifactLink: $($_.Exception.Message)"
                }
            }

            if ($projectId -and $repoGuid) {
                $artifactUri = "vstfs:///Git/PullRequestId/${projectId}%2f${repoGuid}%2f$($result.PrId)"
                $wiBaseUrl = "$OrgUrl/$Project/_apis/wit/workitems"

                foreach ($wiId in $WorkItemIds) {
                    $patchBody = @(
                        @{
                            op    = 'add'
                            path  = '/relations/-'
                            value = @{
                                rel        = 'ArtifactLink'
                                url        = $artifactUri
                                attributes = @{ name = 'Pull Request' }
                            }
                        }
                    ) | ConvertTo-Json -Depth 4

                    # Work item PATCH requires application/json-patch+json
                    $wiPatchHeaders = @{
                        Authorization  = $wiAuth.Authorization
                        'Content-Type' = 'application/json-patch+json'
                    }
                    try {
                        Invoke-RestMethod -Uri "$wiBaseUrl/${wiId}?api-version=$($script:DefaultApiVer)" `
                            -Headers $wiPatchHeaders -Method Patch -Body $patchBody | Out-Null
                        Write-Verbose "Linked work item #$wiId to PR #$($result.PrId) via ArtifactLink"
                    } catch {
                        $errMsg = $_.Exception.Message
                        if ($errMsg -match 'already exists') {
                            Write-Verbose "Work item #$wiId already linked to PR #$($result.PrId)"
                        } else {
                            Write-Warning "Failed to link work item #$wiId to PR #$($result.PrId): $errMsg"
                        }
                    }
                }
            }
        }
    }

    return $result
}

# ── Export ────────────────────────────────────────────────────────────────────
Export-ModuleMember -Function @(
    'Resolve-AdoPat',
    'New-AdoAuthHeaders',
    'Invoke-AdoApi',
    'Get-PrWorkItemIds',
    'Test-MergeConflicts',
    'New-AdoPullRequest'
)
