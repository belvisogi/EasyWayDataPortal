#Requires -Version 5.1
<#
.SYNOPSIS
    Sync platform-rules.snippet.md into all 9 L2 agent PROMPTS.md files.

.DESCRIPTION
    Option B (Session 8): propagates the canonical platform rules snippet
    (agents/core/prompts/platform-rules.snippet.md) into each L2 agent PROMPTS.md,
    replacing content between PLATFORM_RULES_START and PLATFORM_RULES_END markers.

    Usage:
        pwsh scripts/pwsh/Sync-AgentPlatformRules.ps1
        pwsh scripts/pwsh/Sync-AgentPlatformRules.ps1 -DryRun
        pwsh scripts/pwsh/Sync-AgentPlatformRules.ps1 -AgentFilter agent_dba

.PARAMETER SnippetFile
    Path to the canonical snippet file. Defaults to agents/core/prompts/platform-rules.snippet.md.

.PARAMETER AgentFilter
    Optional: restrict sync to a specific agent folder name (e.g. "agent_dba").

.PARAMETER DryRun
    Preview changes without writing files.

.OUTPUTS
    Console summary of updated files.

.NOTES
    Part of: Option B - platform rules distribution to L2 agents
    See: Wiki/EasyWayData.wiki/agents/platform-operational-memory.md section 12
    Related: scripts/pwsh/Sync-PlatformMemory.ps1 (syncs wiki to .cursorrules)
#>
[CmdletBinding()]
param(
    [string]$SnippetFile  = "agents/core/prompts/platform-rules.snippet.md",
    [string]$AgentFilter  = "",
    [switch]$DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$RepoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$SnippetPath = Join-Path $RepoRoot $SnippetFile

# Markers
$StartMarker = "<!-- PLATFORM_RULES_START"
$EndMarker   = "<!-- PLATFORM_RULES_END -->"

# L2 agents with Security Guardrails (detected via "Security Guardrails" in PROMPTS.md)
$L2Agents = @(
    "agent_backend",
    "agent_dba",
    "agent_docs_sync",
    "agent_governance",
    "agent_infra",
    "agent_pr_manager",
    "agent_review",
    "agent_security",
    "agent_vulnerability_scanner"
)

# ─── Load snippet ────────────────────────────────────────────────────────────
if (-not (Test-Path $SnippetPath)) {
    Write-Error "Snippet file not found: $SnippetPath"
    exit 1
}

$snippetRaw = Get-Content $SnippetPath -Raw -Encoding UTF8

# Extract only the content between PLATFORM_RULES_START and PLATFORM_RULES_END
$startIdx = $snippetRaw.IndexOf($StartMarker)
$endIdx   = $snippetRaw.LastIndexOf($EndMarker)

if ($startIdx -lt 0 -or $endIdx -lt 0 -or $endIdx -le $startIdx) {
    Write-Error "Snippet file is missing PLATFORM_RULES_START/END markers."
    exit 1
}

# Include the markers in the extracted block
$snippetBlock = $snippetRaw.Substring($startIdx, ($endIdx - $startIdx) + $EndMarker.Length)

Write-Host "Sync-AgentPlatformRules.ps1" -ForegroundColor Cyan
Write-Host "Snippet: $SnippetPath"
Write-Host "Dry-run: $DryRun"
Write-Host "Agents : $($L2Agents -join ', ')"
Write-Host ""

$updated  = 0
$skipped  = 0
$inserted = 0

foreach ($agentName in $L2Agents) {
    if ($AgentFilter -and $agentName -ne $AgentFilter) { continue }

    $promptPath = Join-Path $RepoRoot "agents" $agentName "PROMPTS.md"

    if (-not (Test-Path $promptPath)) {
        Write-Warning "[$agentName] PROMPTS.md not found, skipping."
        $skipped++
        continue
    }

    $content = Get-Content $promptPath -Raw -Encoding UTF8

    $hasPlatformSection = $content.Contains($StartMarker)

    if ($hasPlatformSection) {
        # Replace existing block
        $pStart = $content.IndexOf($StartMarker)
        $pEnd   = $content.LastIndexOf($EndMarker)

        if ($pStart -lt 0 -or $pEnd -lt 0) {
            Write-Warning "[$agentName] Malformed markers, skipping."
            $skipped++
            continue
        }

        $existing = $content.Substring($pStart, ($pEnd - $pStart) + $EndMarker.Length)

        if ($existing -eq $snippetBlock) {
            Write-Host "[$agentName] Already up to date." -ForegroundColor DarkGray
            $skipped++
            continue
        }

        $newContent = $content.Replace($existing, $snippetBlock)
        $action = "Updated"
        $updated++
    }
    else {
        # Insert after "## Security Guardrails" block — find the next top-level ## section
        # Strategy: find "## Security Guardrails (IMMUTABLE)" line end, then find the next "^## " heading
        $guardrailsHeader = "## Security Guardrails (IMMUTABLE)"
        $guardIdx = $content.IndexOf($guardrailsHeader)

        if ($guardIdx -lt 0) {
            Write-Warning "[$agentName] Security Guardrails section not found, skipping."
            $skipped++
            continue
        }

        # Find the next ## heading after Security Guardrails
        $afterGuard = $content.IndexOf("`n## ", $guardIdx + $guardrailsHeader.Length)

        if ($afterGuard -lt 0) {
            Write-Warning "[$agentName] No section after Security Guardrails found, skipping."
            $skipped++
            continue
        }

        $insertAt = $afterGuard + 1  # position after the newline

        $newContent = $content.Substring(0, $insertAt) +
                      $snippetBlock + "`n`n" +
                      $content.Substring($insertAt)
        $action = "Inserted"
        $inserted++
    }

    if ($DryRun) {
        Write-Host "[$agentName] DRY-RUN: $action (no file written)" -ForegroundColor Yellow
    }
    else {
        [System.IO.File]::WriteAllText($promptPath, $newContent, [System.Text.Encoding]::UTF8)
        Write-Host "[$agentName] $action successfully." -ForegroundColor Green
    }
}

Write-Host ""
Write-Host "Summary: $inserted inserted, $updated updated, $skipped skipped" -ForegroundColor Cyan
if ($DryRun) { Write-Host "(DRY-RUN - no files were written)" -ForegroundColor Yellow }
