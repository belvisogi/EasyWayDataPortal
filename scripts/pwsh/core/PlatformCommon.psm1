#Requires -Version 5.1
<#
.SYNOPSIS
    Shared utilities for the EasyWay Platform Abstraction Layer.
.DESCRIPTION
    Provides cross-platform helper functions consumed by the generic platform
    scripts (platform-plan.ps1, platform-apply.ps1) and all adapter modules.
    Eliminates code duplication previously present in ado-plan-apply.ps1 and
    ado-apply.ps1.

    See: EASYWAY_AGENTIC_SDLC_MASTER.md §11 (Platform Adapter Pattern)
    See: docs/AGENTIC_ARCHITECTURE_ENTERPRISE_PRD.md §19 (Nomenclatura)
.NOTES
    Part of Phase 9 Feature 17 — Platform Adapter SDK (IPlatformAdapter).
#>

# ── 1. Configuration Loading ─────────────────────────────────────────────────

function Read-PlatformConfig {
    <#
    .SYNOPSIS  Loads and validates platform-config.json.
    .PARAMETER ConfigPath  Path to the JSON config file.
    .OUTPUTS   PSCustomObject — the parsed configuration.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ConfigPath
    )

    if (-not (Test-Path $ConfigPath)) {
        throw "Platform config not found: $ConfigPath"
    }

    $config = Get-Content -Raw -Path $ConfigPath | ConvertFrom-Json

    # ── Mandatory field validation ──
    $requiredRoot = @('platform', 'connection', 'auth', 'workItemHierarchy')
    foreach ($field in $requiredRoot) {
        if (-not $config.$field) {
            throw "Platform config missing required field: '$field'"
        }
    }

    $validPlatforms = @('ado', 'github', 'jira', 'forgejo', 'businessmap', 'witboost')
    if ($config.platform -notin $validPlatforms) {
        throw "Unknown platform '$($config.platform)'. Valid: $($validPlatforms -join ', ')"
    }

    if (-not $config.connection.baseUrl) {
        throw "Platform config missing 'connection.baseUrl'"
    }
    if (-not $config.connection.project) {
        throw "Platform config missing 'connection.project'"
    }
    if (-not $config.auth.envVariable) {
        throw "Platform config missing 'auth.envVariable'"
    }
    if (-not $config.workItemHierarchy.chain -or $config.workItemHierarchy.chain.Count -eq 0) {
        throw "Platform config 'workItemHierarchy.chain' must have at least one entry"
    }

    Write-Verbose "[PlatformCommon] Loaded config for platform '$($config.platform)' — $($config.displayName)"
    return $config
}

# ── 2. Authentication ─────────────────────────────────────────────────────────

function Get-AuthHeader {
    <#
    .SYNOPSIS  Builds the HTTP Authorization header from config.
    .PARAMETER Config  The platform config object.
    .PARAMETER Token   The raw auth token (PAT, API key, etc.).
    .OUTPUTS   Hashtable — ready-to-use HTTP headers.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Config,

        [Parameter(Mandatory = $true)]
        [string]$Token
    )

    $scheme = if ($Config.auth.headerScheme) { $Config.auth.headerScheme } else { 'Bearer' }

    switch ($scheme) {
        'Basic' {
            $encoded = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":" + $Token))
            return @{ Authorization = "Basic $encoded" }
        }
        'Bearer' {
            return @{ Authorization = "Bearer $Token" }
        }
        'token' {
            return @{ Authorization = "token $Token" }
        }
        default {
            throw "Unsupported auth header scheme: $scheme"
        }
    }
}

# ── 3. URL Building ───────────────────────────────────────────────────────────

function Join-PlatformUrl {
    <#
    .SYNOPSIS  Builds a full API URL from config base + project + path.
    .PARAMETER Config        The platform config object.
    .PARAMETER PathAndQuery  URL path + query string to append.
    .OUTPUTS   String — complete URL.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Config,

        [Parameter(Mandatory = $true)]
        [string]$PathAndQuery
    )

    $base    = $Config.connection.baseUrl.TrimEnd('/')
    $projEnc = [uri]::EscapeDataString($Config.connection.project)
    return "{0}/{1}{2}" -f $base, $projEnc, $PathAndQuery
}

# ── 4. Work Item Hierarchy Helpers ────────────────────────────────────────────

function Format-WorkItemTitle {
    <#
    .SYNOPSIS  Ensures a work item title has the correct prefix per PRD §19.1.
    .DESCRIPTION
        Idempotent: if the title already starts with the prefix, returns it unchanged.
    .PARAMETER Title   The raw title.
    .PARAMETER Prefix  The prefix to apply (e.g. "[Epic]").
    .OUTPUTS   String — the prefixed title.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Title,

        [Parameter(Mandatory = $true)]
        [string]$Prefix
    )

    $trimmed = $Title.Trim()
    if (-not $trimmed.StartsWith($Prefix, [System.StringComparison]::InvariantCultureIgnoreCase)) {
        return "$Prefix $trimmed"
    }
    return $trimmed
}

function Get-HierarchyLevel {
    <#
    .SYNOPSIS  Resolves a backlog nesting depth (1=epic, 2=feature, 3=pbi) to
               the platform-specific work item type and prefix from config.
    .PARAMETER Config  The platform config object.
    .PARAMETER Level   Nesting depth (1-based).
    .OUTPUTS   PSCustomObject with .type and .prefix properties.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Config,

        [Parameter(Mandatory = $true)]
        [int]$Level
    )

    $entry = $Config.workItemHierarchy.chain | Where-Object { $_.level -eq $Level }
    if (-not $entry) {
        throw "No hierarchy entry for level $Level in platform config"
    }
    return $entry
}

function Get-HierarchyLevelByType {
    <#
    .SYNOPSIS  Resolves a work item type name to its hierarchy config entry.
    .PARAMETER Config  The platform config object.
    .PARAMETER Type    The work item type name (e.g. "Epic").
    .OUTPUTS   PSCustomObject with .level, .type, .prefix properties.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Config,

        [Parameter(Mandatory = $true)]
        [string]$Type
    )

    $entry = $Config.workItemHierarchy.chain | Where-Object { $_.type -eq $Type }
    if (-not $entry) {
        throw "Unknown work item type '$Type' — not defined in platform config hierarchy chain"
    }
    return $entry
}

# ── 5. Backlog File Loading ───────────────────────────────────────────────────

function Read-BacklogFile {
    <#
    .SYNOPSIS  Loads a backlog JSON file (e.g. phase9_backlog.json).
    .PARAMETER Path  Path to the backlog JSON file.
    .OUTPUTS   PSCustomObject — the parsed backlog.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    if (-not (Test-Path $Path)) {
        throw "Backlog file not found: $Path"
    }
    return (Get-Content -Raw -Path $Path | ConvertFrom-Json)
}

# ── 6. Token Resolution ──────────────────────────────────────────────────────

function Resolve-PlatformToken {
    <#
    .SYNOPSIS  Resolves the auth token using Import-AgentSecrets + fallback.
    .DESCRIPTION
        1. Tries Import-AgentSecrets (Sovereign Gatekeeper) for the given agent role.
        2. Falls back to .env files if token not in environment (terminal caching issue).
    .PARAMETER Config   The platform config object.
    .PARAMETER AgentId  Agent identity for RBAC lookup.
    .PARAMETER RepoRoot Repository root path.
    .OUTPUTS   String — the resolved token, or $null.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Config,

        [Parameter(Mandatory = $true)]
        [string]$AgentId,

        [Parameter(Mandatory = $true)]
        [string]$RepoRoot
    )

    $envVar = $Config.auth.envVariable
    $importSecretsScript = Join-Path $RepoRoot "agents" "skills" "utilities" "Import-AgentSecrets.ps1"

    if (Test-Path $importSecretsScript) {
        . $importSecretsScript
        $secrets = Import-AgentSecrets -AgentId $AgentId
        $token = [System.Environment]::GetEnvironmentVariable($envVar)
        if ($token) { return $token }
    }
    else {
        Write-Warning "[PlatformCommon] Sovereign Gatekeeper not found: $importSecretsScript"
    }

    # ── Fallback: role-specific .env file ──
    $roleSuffix = switch -Wildcard ($AgentId) {
        '*planner*'  { 'planner' }
        '*executor*' { 'executor' }
        default      { 'developer' }
    }
    $envFilePath = "C:\old\.env.$roleSuffix"
    if (Test-Path $envFilePath) {
        $match = Get-Content $envFilePath | Where-Object { $_ -match "^$envVar=" } | ForEach-Object { ($_.Split("=", 2))[1] }
        if ($match) {
            Write-Verbose "[PlatformCommon] Token loaded from fallback file: $envFilePath"
            return $match
        }
    }

    return $null
}

# ── Export ─────────────────────────────────────────────────────────────────────

Export-ModuleMember -Function @(
    'Read-PlatformConfig',
    'Get-AuthHeader',
    'Join-PlatformUrl',
    'Format-WorkItemTitle',
    'Get-HierarchyLevel',
    'Get-HierarchyLevelByType',
    'Read-BacklogFile',
    'Resolve-PlatformToken'
)
