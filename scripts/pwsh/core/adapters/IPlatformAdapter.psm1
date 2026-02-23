#Requires -Version 5.1
<#
.SYNOPSIS
    Platform Adapter SDK — All adapter classes in a single module.
.DESCRIPTION
    PowerShell v5 classes cannot be resolved across module boundaries.
    This file consolidates the IPlatformAdapter base class, AdoAdapter,
    GitHubAdapter and BusinessMapAdapter, along with the factory function.

    Individual adapter stub files (GitHubAdapter.psm1, BusinessMapAdapter.psm1)
    are preserved for documentation but this is the operational module.

    See: EASYWAY_AGENTIC_SDLC_MASTER.md §11 (Platform Adapter Pattern)
.NOTES
    Part of Phase 9 Feature 17 — Platform Adapter SDK.
#>

# ─── Base Class ───────────────────────────────────────────────────────────────

class IPlatformAdapter {
    [PSCustomObject]$Config
    [hashtable]$Headers

    IPlatformAdapter([PSCustomObject]$config, [hashtable]$headers) {
        $this.Config = $config
        $this.Headers = $headers
    }

    [object] QueryWorkItemByTitle([string]$workItemType, [string]$title, [string]$prdId) {
        throw "QueryWorkItemByTitle must be implemented by adapter '$($this.Config.platform)'"
    }

    [object] CreateWorkItem([string]$workItemType, [array]$patchOperations) {
        throw "CreateWorkItem must be implemented by adapter '$($this.Config.platform)'"
    }

    [void] LinkParentChild([int]$childId, [int]$parentId) {
        throw "LinkParentChild must be implemented by adapter '$($this.Config.platform)'"
    }

    [string] GetApiUrl([string]$pathAndQuery) {
        throw "GetApiUrl must be implemented by adapter '$($this.Config.platform)'"
    }
}

# ─── ADO Adapter ──────────────────────────────────────────────────────────────

class AdoAdapter : IPlatformAdapter {

    AdoAdapter([PSCustomObject]$config, [hashtable]$headers) : base($config, $headers) {}

    [string] GetApiUrl([string]$pathAndQuery) {
        $base = $this.Config.connection.baseUrl.TrimEnd('/')
        $projEnc = [uri]::EscapeDataString($this.Config.connection.project)
        return "{0}/{1}{2}" -f $base, $projEnc, $pathAndQuery
    }

    [object] QueryWorkItemByTitle([string]$workItemType, [string]$title, [string]$prdId) {
        $apiVer = $this.Config.connection.apiVersion
        $safeTitle = $title.Replace("'", "''")
        $wiql = "SELECT [System.Id] FROM WorkItems WHERE [System.TeamProject] = @project AND [System.WorkItemType] = '$workItemType' AND [System.Title] = '$safeTitle'"
        if ($prdId) { $wiql += " AND [System.Tags] CONTAINS 'PRD:$prdId'" }

        $postUrl = $this.GetApiUrl("/_apis/wit/wiql?api-version=$apiVer")
        try {
            $body = @{ query = $wiql } | ConvertTo-Json
            $resp = Invoke-RestMethod -Method Post -Uri $postUrl -Headers $this.Headers -ContentType 'application/json' -Body $body
            if ($resp.workItems -and $resp.workItems.Count -gt 0) { return [int]$resp.workItems[0].id }
            return $null
        }
        catch {
            Write-Warning "[AdoAdapter] WIQL query failed. Error: $_"
            return $null
        }
    }

    [object] CreateWorkItem([string]$workItemType, [array]$patchOperations) {
        $apiVer = $this.Config.connection.apiVersion
        $typeSeg = '$' + [uri]::EscapeDataString($workItemType)
        $url = $this.GetApiUrl("/_apis/wit/workitems/${typeSeg}?api-version=$apiVer")
        $body = $patchOperations | ConvertTo-Json -Depth 20
        return Invoke-RestMethod -Method Post -Uri $url -Headers $this.Headers `
            -ContentType 'application/json-patch+json' -Body $body
    }

    [void] LinkParentChild([int]$childId, [int]$parentId) {
        $apiVer = $this.Config.connection.apiVersion
        $linkType = if ($this.Config.workItemHierarchy.parentChildLinkType) {
            $this.Config.workItemHierarchy.parentChildLinkType
        }
        else { 'System.LinkTypes.Hierarchy-Reverse' }

        $url = $this.GetApiUrl("/_apis/wit/workitems/${childId}?api-version=$apiVer")
        $parentUrl = "$($this.Config.connection.baseUrl.TrimEnd('/'))/_apis/wit/workItems/$parentId"
        $patch = @(@{
                op = 'add'; path = '/relations/-'
                value = @{ rel = $linkType; url = $parentUrl }
            })
        $body = $patch | ConvertTo-Json -Depth 20 -AsArray
        $null = Invoke-RestMethod -Method Patch -Uri $url -Headers $this.Headers `
            -ContentType 'application/json-patch+json' -Body $body
    }
}

# ─── GitHub Adapter (Stub) ────────────────────────────────────────────────────

class GitHubAdapter : IPlatformAdapter {
    GitHubAdapter([PSCustomObject]$config, [hashtable]$headers) : base($config, $headers) {}
    [string] GetApiUrl([string]$p) { throw "[GitHubAdapter] Not yet implemented." }
    [object] QueryWorkItemByTitle([string]$t, [string]$s, [string]$p) { throw "[GitHubAdapter] Not yet implemented." }
    [object] CreateWorkItem([string]$t, [array]$ops) { throw "[GitHubAdapter] Not yet implemented." }
    [void]   LinkParentChild([int]$c, [int]$p) { throw "[GitHubAdapter] Not yet implemented." }
}

# ─── BusinessMap Adapter (Stub) ───────────────────────────────────────────────

class BusinessMapAdapter : IPlatformAdapter {
    BusinessMapAdapter([PSCustomObject]$config, [hashtable]$headers) : base($config, $headers) {}
    [string] GetApiUrl([string]$p) { throw "[BusinessMapAdapter] Not yet implemented." }
    [object] QueryWorkItemByTitle([string]$t, [string]$s, [string]$p) { throw "[BusinessMapAdapter] Not yet implemented." }
    [object] CreateWorkItem([string]$t, [array]$ops) { throw "[BusinessMapAdapter] Not yet implemented." }
    [void]   LinkParentChild([int]$c, [int]$p) { throw "[BusinessMapAdapter] Not yet implemented." }
}

# ─── ADO JSON-Patch Builder ──────────────────────────────────────────────────

function Build-AdoJsonPatch {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]  [string]$Title,
        [Parameter(Mandatory = $false)] [string]$Description,
        [Parameter(Mandatory = $false)] [string]$AcceptanceCriteria,
        [Parameter(Mandatory = $false)] [string]$AreaPath,
        [Parameter(Mandatory = $false)] [string]$IterationPath,
        [Parameter(Mandatory = $false)] [string[]]$Tags
    )

    $patch = @( @{ op = 'add'; path = '/fields/System.Title'; value = $Title } )
    if ($Description) { $patch += @{ op = 'add'; path = '/fields/System.Description'; value = $Description } }
    if ($AcceptanceCriteria) { $patch += @{ op = 'add'; path = '/fields/Microsoft.VSTS.Common.AcceptanceCriteria'; value = $AcceptanceCriteria } }
    if ($AreaPath) { $patch += @{ op = 'add'; path = '/fields/System.AreaPath'; value = $AreaPath } }
    if ($IterationPath) { $patch += @{ op = 'add'; path = '/fields/System.IterationPath'; value = $IterationPath } }
    if ($Tags -and $Tags.Count -gt 0) {
        $patch += @{ op = 'add'; path = '/fields/System.Tags'; value = ($Tags -join '; ') }
    }
    return $patch
}

# ─── Factory ──────────────────────────────────────────────────────────────────

function New-PlatformAdapter {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)] [PSCustomObject]$Config,
        [Parameter(Mandatory = $true)] [hashtable]$Headers
    )

    switch ($Config.platform) {
        'ado' { return [AdoAdapter]::new($Config, $Headers) }
        'github' { return [GitHubAdapter]::new($Config, $Headers) }
        'businessmap' { return [BusinessMapAdapter]::new($Config, $Headers) }
        default { throw "No adapter for platform '$($Config.platform)'. Available: ado, github, businessmap" }
    }
}

Export-ModuleMember -Function 'New-PlatformAdapter', 'Build-AdoJsonPatch'
