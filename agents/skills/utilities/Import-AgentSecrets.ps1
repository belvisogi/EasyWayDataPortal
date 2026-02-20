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
        [Parameter(Mandatory = $false)]
        [string]$SecretsFile = ''
    )

    # ── Resolve secrets file path ──────────────────────────────────────────────
    if (-not $SecretsFile) {
        if ($IsLinux -or $IsMacOS) {
            $SecretsFile = '/opt/easyway/.env.secrets'
        } else {
            # Windows: dev workstation path
            $SecretsFile = Join-Path $env:USERPROFILE '.easyway' 'secrets'
        }
    }

    # ── File not found: silent return (container scenario, env vars already set) ─
    if (-not (Test-Path $SecretsFile)) {
        Write-Verbose "[Import-AgentSecrets] Secrets file not found: $SecretsFile (assuming env vars already set)"
        return @{}
    }

    # ── Parse and load KEY=VALUE pairs ─────────────────────────────────────────
    $loaded  = @{}
    $skipped = @()

    foreach ($line in (Get-Content $SecretsFile -Encoding UTF8)) {
        $line = $line.Trim()

        # Skip blank lines and comments
        if ([string]::IsNullOrWhiteSpace($line) -or $line.StartsWith('#')) { continue }

        # Match KEY=VALUE (KEY must start with letter, contain only A-Z 0-9 _)
        if ($line -notmatch '^([A-Za-z][A-Za-z0-9_]*)=(.+)$') { continue }

        $key   = $Matches[1]
        $value = $Matches[2].Trim()

        # Non-destructive: skip if already present (Docker/CI already set it)
        $existing = [System.Environment]::GetEnvironmentVariable($key)
        if ($null -ne $existing -and $existing -ne '') {
            $skipped += $key
            Write-Verbose "[Import-AgentSecrets] Skipped (already set): $key"
            continue
        }

        # Set at process level so child processes (e.g. python3 rag_search.py) inherit it
        [System.Environment]::SetEnvironmentVariable($key, $value, [System.EnvironmentVariableTarget]::Process)
        $loaded[$key] = '***'   # Never log actual values
        Write-Verbose "[Import-AgentSecrets] Loaded: $key"
    }

    # ── Summary ────────────────────────────────────────────────────────────────
    if ($loaded.Count -gt 0) {
        Write-Verbose "[Import-AgentSecrets] Loaded $($loaded.Count) secret(s) from: $SecretsFile"
    }
    if ($skipped.Count -gt 0) {
        Write-Verbose "[Import-AgentSecrets] Skipped $($skipped.Count) already-set key(s): $($skipped -join ', ')"
    }

    return $loaded
}
