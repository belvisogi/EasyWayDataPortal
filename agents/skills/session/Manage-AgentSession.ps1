#!/usr/bin/env pwsh
<#
.SYNOPSIS
    CRUD operations for agent working memory sessions (Gap 2 - agent-evolution-roadmap).

.DESCRIPTION
    Working memory session files are ephemeral JSON files stored at:
      agents/<agent_id>/memory/session.json

    Each session captures intermediate state for multi-step L2/L3 agent workflows.
    Sessions expire automatically (default TTL: 30 minutes) and are deleted on Close.

    Schema: agents/core/schemas/session.schema.json

.EXAMPLE
    # Create a session
    $s = Manage-AgentSession -Operation New -AgentId agent_review -Intent "review:docs-impact"

    # Update after a step
    Manage-AgentSession -Operation Update -SessionFile $s.SessionFile `
        -CompletedStep "fetch_changed_files" `
        -StepResult @{ changed_files = @("portal-api/routes/health.js") }

    # Set current step
    Manage-AgentSession -Operation SetStep -SessionFile $s.SessionFile -StepName "generate_verdict"

    # Read current state
    $state = Manage-AgentSession -Operation Get -SessionFile $s.SessionFile

    # Close (deletes the file, returns summary)
    $summary = Manage-AgentSession -Operation Close -SessionFile $s.SessionFile
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("New", "Get", "Update", "SetStep", "Close", "Cleanup")]
    [string]$Operation,

    # --- New ---
    [string]$AgentId,
    [string]$Intent,
    [hashtable]$InitialMetadata = @{},
    [string]$CorrelationId = $null,
    [int]$TtlMinutes = 30,

    # --- Get / Update / SetStep / Close ---
    [string]$SessionFile,

    # --- Update ---
    [string]$CompletedStep,
    [hashtable]$StepResult = @{},
    [double]$Confidence = -1,   # -1 = do not update

    # --- SetStep ---
    [string]$StepName,

    # --- Cleanup: remove expired sessions for an agent ---
    [string]$CleanupAgentId,

    # --- Shared ---
    [string]$SessionsRoot = ""   # override root dir (default: agents/<agent_id>/memory)
)

$ErrorActionPreference = "Stop"

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
function _SessionDir {
    param([string]$AId)
    if ($SessionsRoot) { return $SessionsRoot }
    $agentsRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
    return Join-Path $agentsRoot "agent_$($AId -replace '^agent_', '')" "memory"
}

function _NewUUID {
    return [System.Guid]::NewGuid().ToString()
}

function _ReadSession {
    param([string]$File)
    if (-not (Test-Path $File)) {
        throw "Session file not found: $File"
    }
    $raw = Get-Content $File -Raw -Encoding UTF8
    return $raw | ConvertFrom-Json
}

function _WriteSession {
    param([string]$File, [psobject]$Data)
    $dir = Split-Path $File -Parent
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    $json = $Data | ConvertTo-Json -Depth 10
    [System.IO.File]::WriteAllText($File, $json, [System.Text.UTF8Encoding]::new($false))
}

# ---------------------------------------------------------------------------
# Operations
# ---------------------------------------------------------------------------
switch ($Operation) {

    "New" {
        if (-not $AgentId) { throw "AgentId is required for Operation=New" }
        if (-not $Intent)   { throw "Intent is required for Operation=New" }

        $sessionId  = _NewUUID
        $now        = (Get-Date).ToUniversalTime()
        $expiresAt  = $now.AddMinutes($TtlMinutes)

        $session = [ordered]@{
            session_id           = $sessionId
            agent_id             = $AgentId
            started_at           = $now.ToString("o")
            expires_at           = $expiresAt.ToString("o")
            intent               = $Intent
            status               = "active"
            current_step         = $null
            steps_completed      = @()
            steps_failed         = @()
            intermediate_results = @{}
            confidence           = $null
            metadata             = $InitialMetadata
            correlation_id       = $CorrelationId
        }

        $dir  = _SessionDir -AId $AgentId
        $file = Join-Path $dir "session.json"
        _WriteSession -File $file -Data $session

        Write-Verbose "[Manage-AgentSession] New session: $sessionId for $AgentId (expires $($expiresAt.ToString('o')))"

        return @{
            Success     = $true
            SessionId   = $sessionId
            SessionFile = $file
            ExpiresAt   = $expiresAt.ToString("o")
        }
    }

    "Get" {
        if (-not $SessionFile) { throw "SessionFile is required for Operation=Get" }
        $session = _ReadSession -File $SessionFile

        # Check expiry
        $expired = (Get-Date).ToUniversalTime() -gt [datetime]$session.expires_at
        if ($expired -and $session.status -eq "active") {
            Write-Warning "[Manage-AgentSession] Session $($session.session_id) has expired."
        }

        return @{
            Success  = $true
            Session  = $session
            Expired  = $expired
        }
    }

    "Update" {
        if (-not $SessionFile) { throw "SessionFile is required for Operation=Update" }

        $session = _ReadSession -File $SessionFile

        # Mark completed step
        if ($CompletedStep) {
            $done = @($session.steps_completed) + @($CompletedStep)
            $session | Add-Member -MemberType NoteProperty -Name "steps_completed" -Value $done -Force
            if ($session.current_step -eq $CompletedStep) {
                $session | Add-Member -MemberType NoteProperty -Name "current_step" -Value $null -Force
            }
        }

        # Merge step result into intermediate_results
        if ($StepResult.Count -gt 0) {
            $ir = $session.intermediate_results
            if ($null -eq $ir) { $ir = [pscustomobject]@{} }
            foreach ($k in $StepResult.Keys) {
                $ir | Add-Member -MemberType NoteProperty -Name $k -Value $StepResult[$k] -Force
            }
            $session | Add-Member -MemberType NoteProperty -Name "intermediate_results" -Value $ir -Force
        }

        # Update confidence if provided
        if ($Confidence -ge 0) {
            $session | Add-Member -MemberType NoteProperty -Name "confidence" -Value $Confidence -Force
        }

        _WriteSession -File $SessionFile -Data $session

        Write-Verbose "[Manage-AgentSession] Updated session $($session.session_id): step='$CompletedStep'"

        return @{ Success = $true; SessionId = $session.session_id }
    }

    "SetStep" {
        if (-not $SessionFile) { throw "SessionFile is required for Operation=SetStep" }
        if (-not $StepName)    { throw "StepName is required for Operation=SetStep" }

        $session = _ReadSession -File $SessionFile
        $session | Add-Member -MemberType NoteProperty -Name "current_step" -Value $StepName -Force
        _WriteSession -File $SessionFile -Data $session

        Write-Verbose "[Manage-AgentSession] Set current_step='$StepName' on session $($session.session_id)"

        return @{ Success = $true; SessionId = $session.session_id; CurrentStep = $StepName }
    }

    "Close" {
        if (-not $SessionFile) { throw "SessionFile is required for Operation=Close" }

        $session = _ReadSession -File $SessionFile
        $session | Add-Member -MemberType NoteProperty -Name "status" -Value "completed" -Force
        $session | Add-Member -MemberType NoteProperty -Name "current_step" -Value $null -Force

        $summary = @{
            Success         = $true
            SessionId       = $session.session_id
            AgentId         = $session.agent_id
            Intent          = $session.intent
            StepsCompleted  = @($session.steps_completed)
            StepsFailed     = @($session.steps_failed)
            FinalConfidence = $session.confidence
        }

        Remove-Item $SessionFile -Force
        Write-Verbose "[Manage-AgentSession] Closed and deleted session $($session.session_id)"

        return $summary
    }

    "Cleanup" {
        # Remove expired session files for a given agent (or all agents if CleanupAgentId is empty)
        $agentsRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
        $pattern    = if ($CleanupAgentId) {
            Join-Path $agentsRoot "agent_$($CleanupAgentId -replace '^agent_', '')" "memory" "session.json"
        } else {
            Join-Path $agentsRoot "agent_*" "memory" "session.json"
        }

        $removed = 0
        $now     = (Get-Date).ToUniversalTime()

        foreach ($f in (Get-Item $pattern -ErrorAction SilentlyContinue)) {
            try {
                $s = Get-Content $f -Raw | ConvertFrom-Json
                if ($now -gt [datetime]$s.expires_at) {
                    Remove-Item $f -Force
                    Write-Verbose "[Manage-AgentSession] Removed expired session: $($s.session_id) ($($s.agent_id))"
                    $removed++
                }
            }
            catch {
                Write-Warning "[Manage-AgentSession] Could not evaluate $f : $_"
            }
        }

        return @{ Success = $true; RemovedCount = $removed }
    }
}
