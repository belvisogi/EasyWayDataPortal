#Requires -Version 5.1
<#
.SYNOPSIS
    Loads platform secrets into the process environment (idempotent, non-destructive).

.DESCRIPTION
    Reads KEY=VALUE pairs from a .env-format secrets file and sets them as process-level
    environment variables. Skips any key already present in the environment, so it is
    safe to call in every context:

      - Container (easyway-runner): env vars already injected by Docker -> no-op, zero overhead
      - SSH shell: env vars not set -> loaded from file -> all callers work transparently
      - CI/CD pipeline: individual vars can be pre-set to override file values -> respected

    This is the SINGLE ENTRY POINT for secrets in every agent runner. No agent should
    read $env:DEEPSEEK_API_KEY or similar directly without calling this first.

    Design principles (enterprise best practice):
      - Single Source of Truth: all platform secrets live in one file (.env.secrets)
      - Non-destructive: set once, never overwrite (prevents accidental secret leaking)
      - Fail-safe: if file not found, function returns silently (container scenario)
      - Audit-safe: actual secret values are never logged (only key names)
      - Portable: works on Linux (server), Windows (dev), any CI/CD runner

    See: Wiki/EasyWayData.wiki/security/secrets-management.md for full documentation.

.PARAMETER SecretsFile
    Path to the .env-format secrets file.
    Defaults to /opt/easyway/.env.secrets (Linux server) or
    $env:USERPROFILE\.easyway\secrets (Windows dev).
    Pass a custom path for testing or alternative environments.

.OUTPUTS
    [hashtable] Keys loaded during this call (values masked as '***').
    Empty hashtable if all keys were already present or file not found.

.EXAMPLE
    # Standard usage at the top of any agent runner
    $importSecrets = Join-Path $SkillsDir 'utilities' 'Import-AgentSecrets.ps1'
    . $importSecrets
    Import-AgentSecrets | Out-Null

.EXAMPLE
    # With explicit path (CI/CD or test)
    Import-AgentSecrets -SecretsFile '/run/secrets/.env.platform'

.EXAMPLE
    # Check what was loaded
    $loaded = Import-AgentSecrets
    Write-Host "Loaded secrets: $($loaded.Keys -join ', ')"

.NOTES
    Evolution: introduced in Session 14 to fix fragmented secrets loading across agents.
    Supersedes: manual 'export QDRANT_API_KEY=...' pattern from SSH shell.
    See: Wiki/EasyWayData.wiki/security/secrets-management.md
#>
function Import-AgentSecrets {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$AgentId,

        [Parameter(Mandatory = $false)]
        [string]$SecretsFile = '',  # Kept for backward compatibility but overridden by RBAC

        [Parameter(Mandatory = $false)]
        [string]$RegistryFile = ''
    )

    # ── 1. Resolve Sovereign Registry ──────────────────────────────────────────
    if (-not $RegistryFile) {
        if ($IsLinux -or $IsMacOS) {
            $RegistryFile = '/etc/easyway/rbac-master.json'
            $FallbackRegistry = '/opt/easyway/rbac-master.json'
            if (-not (Test-Path $RegistryFile) -and (Test-Path $FallbackRegistry)) { $RegistryFile = $FallbackRegistry }
        }
        else {
            $RegistryFile = 'C:\old\rbac-master.json'
        }
    }

    if (-not (Test-Path $RegistryFile)) {
        Write-Warning "[RBAC-GATEKEEPER] FATAL: Sovereign Registry not found at $RegistryFile"
        throw "UnauthorizedAccessException: Sovereign Registry Missing. Halting agent execution."
    }

    $registry = Get-Content $RegistryFile -Raw | ConvertFrom-Json
    $auditLog = if ($registry.audit_log_path) { $registry.audit_log_path } else { 'C:\old\logs\rbac-audit.log' }

    # ── 2. Enforce Agent Identity ──────────────────────────────────────────────
    $agentPolicy = $registry.agents.$AgentId
    if ($null -eq $agentPolicy) {
        $msg = "DENY: Agent '$AgentId' not registered in $RegistryFile"
        Write-Warning "[RBAC-GATEKEEPER] $msg"
        Add-Content -Path $auditLog -Value "$((Get-Date).ToString('o')) | $AgentId | DENY | Unregistered Agent" -ErrorAction SilentlyContinue
        throw "UnauthorizedAccessException: $msg"
    }

    # ── 3. Financial Gatekeeping (Stop-Loss) ───────────────────────────────────
    $budget = if ($null -ne $agentPolicy.monthly_budget_usd) { [double]$agentPolicy.monthly_budget_usd } else { 0.0 }
    
    # Try to read agent's current spend from memory
    $repoRoot = (git rev-parse --show-toplevel 2>$null)
    if (-not $repoRoot) { $repoRoot = $PWD.Path }
    $memoryPath = Join-Path $repoRoot "agents" ($AgentId -replace 'agent_', '') "memory" "context.json"
    $currentSpend = 0.0

    if (Test-Path $memoryPath) {
        try {
            $mem = Get-Content $memoryPath -Raw | ConvertFrom-Json
            if ($mem.llm_usage.total_cost_usd) {
                $currentSpend = [double]$mem.llm_usage.total_cost_usd
            }
        }
        catch {}
    }

    $llmBlocked = $false
    if ($agentPolicy.llm_access) {
        if ($budget -gt 0 -and $currentSpend -ge $budget) {
            $msg = "DENY: Agent '$AgentId' exceeded budget (`$$currentSpend / `$$budget)"
            Write-Warning "[RBAC-GATEKEEPER] $msg"
            Add-Content -Path $auditLog -Value "$((Get-Date).ToString('o')) | $AgentId | DENY_LLM | Budget Exceeded" -ErrorAction SilentlyContinue
            $llmBlocked = $true
        }
    }
    else {
        $llmBlocked = $true
    }

    # ── 4. Load Allowed Environment Profiles ───────────────────────────────────
    $loaded = @{}
    $skipped = @()

    $allowedProfiles = @($agentPolicy.allowed_profiles)
    if ($allowedProfiles.Count -eq 0 -and -not $agentPolicy.llm_access) {
        Write-Verbose "[RBAC-GATEKEEPER] Agent '$AgentId' has no valid permissions or profiles."
        return @{}
    }

    # Standard secrets location for LLM
    $llmSecretsFile = if ($IsLinux -or $IsMacOS) { '/opt/easyway/.env.secrets' } else { "$env:USERPROFILE\.easyway\secrets" }
    if ($agentPolicy.llm_access -and -not $llmBlocked) {
        $allowedProfiles += $llmSecretsFile
    }

    foreach ($profilePath in $allowedProfiles) {
        if (-not (Test-Path $profilePath)) {
            Write-Verbose "[RBAC-GATEKEEPER] Profile not found: $profilePath"
            continue
        }

        foreach ($line in (Get-Content $profilePath -Encoding UTF8)) {
            $line = $line.Trim()
            if ([string]::IsNullOrWhiteSpace($line) -or $line.StartsWith('#')) { continue }
            if ($line -notmatch '^([A-Za-z][A-Za-z0-9_]*)=(.+)$') { continue }

            $key = $Matches[1]
            $value = $Matches[2].Trim()

            # Prevent loading LLM keys if blocked
            if ($llmBlocked -and ($key -match 'API_KEY' -or $key -match 'LLM')) {
                continue
            }

            $existing = [System.Environment]::GetEnvironmentVariable($key)
            if ($null -ne $existing -and $existing -ne '') {
                $skipped += $key
                continue
            }

            [System.Environment]::SetEnvironmentVariable($key, $value, [System.EnvironmentVariableTarget]::Process)
            $loaded[$key] = '***'
        }
    }

    # ── 5. Setup Audit Trail ───────────────────────────────────────────────────
    if ($loaded.Count -gt 0) {
        $logMsg = "$((Get-Date).ToString('o')) | $AgentId | ALLOW | Loaded $($loaded.Count) keys. LLM Access: $(if($llmBlocked){'BLOCKED'}else{'YES'}). Spend: `$$currentSpend/`$$budget"
        Add-Content -Path $auditLog -Value $logMsg -ErrorAction SilentlyContinue
        Write-Verbose "[RBAC-GATEKEEPER] $logMsg"
    }

    return $loaded
}
