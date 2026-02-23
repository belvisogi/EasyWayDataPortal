#Requires -Version 5.1
<#
.SYNOPSIS
    State Machine module for the EasyWay Agentic SDLC pipeline.
.DESCRIPTION
    Loads, validates, and manages state transitions for SDLC pipelines.
    Each pipeline run has a context (JSON file) tracking current state,
    history, and artifacts produced at each stage.

    See: EASYWAY_AGENTIC_SDLC_MASTER.md section 4 (Flusso end-to-end)
    See: config/state-machine.schema.json
.NOTES
    Part of Phase 9 Feature 16 - Runtime State Machine Orchestrator (PBI #20).
#>

# ── Load State Machine Definition ─────────────────────────────────────────────

function Read-StateMachine {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)] [string]$Path
    )

    if (-not (Test-Path $Path)) {
        throw "State machine file not found: $Path"
    }
    $sm = Get-Content $Path -Raw -Encoding UTF8 | ConvertFrom-Json

    # Validate required fields
    if (-not $sm.id) { throw "State machine missing 'id'" }
    if (-not $sm.initialState) { throw "State machine missing 'initialState'" }
    if (-not $sm.states) { throw "State machine missing 'states'" }
    if (-not $sm.transitions) { throw "State machine missing 'transitions'" }

    # Validate initialState exists
    if (-not $sm.states.PSObject.Properties[$sm.initialState]) {
        throw "Initial state '$($sm.initialState)' not found in states"
    }

    # Validate all transitions reference valid states
    foreach ($t in $sm.transitions) {
        if (-not $sm.states.PSObject.Properties[$t.from]) {
            throw "Transition references unknown state '$($t.from)'"
        }
        if (-not $sm.states.PSObject.Properties[$t.to]) {
            throw "Transition references unknown state '$($t.to)'"
        }
    }

    return $sm
}

# ── Pipeline Context (run state) ──────────────────────────────────────────────

function New-PipelineContext {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)] [string]$PrdId,
        [Parameter(Mandatory = $true)] [PSCustomObject]$StateMachine,
        [Parameter(Mandatory = $false)] [string]$OutputPath
    )

    $context = [ordered]@{
        pipelineId   = [guid]::NewGuid().ToString()
        prdId        = $PrdId
        stateMachine = $StateMachine.id
        currentState = $StateMachine.initialState
        status       = 'running'
        createdAt    = (Get-Date).ToString('o')
        updatedAt    = (Get-Date).ToString('o')
        history      = @(
            [ordered]@{
                state     = $StateMachine.initialState
                enteredAt = (Get-Date).ToString('o')
                trigger   = 'init'
            }
        )
        artifacts    = @{}
    }

    if ($OutputPath) {
        $dir = [IO.Path]::GetDirectoryName($OutputPath)
        if ($dir -and -not (Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
        $context | ConvertTo-Json -Depth 20 | Out-File -FilePath $OutputPath -Encoding utf8
    }

    return $context
}

# ── Get Available Transitions ─────────────────────────────────────────────────

function Get-AvailableTransitions {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)] [PSCustomObject]$StateMachine,
        [Parameter(Mandatory = $true)] [string]$CurrentState
    )

    $available = @()
    foreach ($t in $StateMachine.transitions) {
        if ($t.from -eq $CurrentState) {
            $available += [ordered]@{
                to      = $t.to
                trigger = $t.trigger
                guard   = $t.guard
            }
        }
    }
    return $available
}

# ── Invoke Transition ─────────────────────────────────────────────────────────

function Invoke-StateTransition {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)] [PSCustomObject]$StateMachine,
        [Parameter(Mandatory = $true)] [hashtable]$Context,
        [Parameter(Mandatory = $true)] [string]$Trigger,
        [Parameter(Mandatory = $false)] [string]$ContextPath
    )

    $current = $Context.currentState
    $stateObj = $StateMachine.states.PSObject.Properties[$current].Value

    # Check human gate
    if ($stateObj.requiresHumanGate -and $Trigger -notin @('human_approve', 'human_reject', 'timeout')) {
        throw "State '$current' requires human gate. Valid triggers: human_approve, human_reject, timeout. Got: $Trigger"
    }

    # Find matching transition
    $match = $null
    foreach ($t in $StateMachine.transitions) {
        if ($t.from -eq $current -and $t.trigger -eq $Trigger) {
            $match = $t
            break
        }
    }

    if (-not $match) {
        $valid = ($StateMachine.transitions | Where-Object { $_.from -eq $current } | ForEach-Object { $_.trigger }) -join ', '
        throw "No transition from '$current' with trigger '$Trigger'. Valid triggers: $valid"
    }

    # Apply transition
    $Context.currentState = $match.to
    $Context.updatedAt = (Get-Date).ToString('o')
    $Context.history += [ordered]@{
        state     = $match.to
        enteredAt = (Get-Date).ToString('o')
        trigger   = $Trigger
        from      = $current
    }

    # Check if final state
    $newStateObj = $StateMachine.states.PSObject.Properties[$match.to].Value
    if ($newStateObj.isFinal) {
        $Context.status = 'completed'
    }

    # Persist if path given
    if ($ContextPath) {
        $Context | ConvertTo-Json -Depth 20 | Out-File -FilePath $ContextPath -Encoding utf8
    }

    return $Context
}

# ── Get State Info ────────────────────────────────────────────────────────────

function Get-StateInfo {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)] [PSCustomObject]$StateMachine,
        [Parameter(Mandatory = $true)] [string]$StateName
    )

    $prop = $StateMachine.states.PSObject.Properties[$StateName]
    if (-not $prop) { throw "State '$StateName' not found" }

    $state = $prop.Value
    return [ordered]@{
        name              = $StateName
        displayName       = $state.displayName
        phase             = $state.phase
        agent             = $state.agent
        requiresHumanGate = [bool]$state.requiresHumanGate
        isFinal           = [bool]$state.isFinal
        timeout           = $state.timeout
    }
}

Export-ModuleMember -Function 'Read-StateMachine', 'New-PipelineContext', 'Get-AvailableTransitions', 'Invoke-StateTransition', 'Get-StateInfo'
