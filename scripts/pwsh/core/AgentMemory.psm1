
<#
.SYNOPSIS
    Core module for managing Agent Memory (Factory Pattern).
    Dispatches calls to AzureMemoryProvider or LocalMemoryProvider.
#>

$mode = $env:EASYWAY_MODE
if ([string]::IsNullOrWhiteSpace($mode)) { $mode = "Framework" } # Default to Local

$providerModule = if ($mode -eq "Enterprise") {
    Join-Path $PSScriptRoot "providers/AzureMemoryProvider.psm1"
} else {
    Join-Path $PSScriptRoot "providers/LocalMemoryProvider.psm1"
}

if (Test-Path $providerModule) {
    Import-Module $providerModule -Force -DisableNameChecking
} else {
    Write-Error "Memory Provider not found: $providerModule"
}

function Initialize-AgentMemory {
    param([string]$AgentName, [string]$AgentsDir="agents")
    if ($mode -eq "Enterprise") { Initialize-AzureMemory @PSBoundParameters }
    else { Initialize-LocalMemory @PSBoundParameters }
}

function Get-AgentContext {
    param([string]$AgentName, [string]$AgentsDir="agents")
    if ($mode -eq "Enterprise") { Get-AzureContext @PSBoundParameters }
    else { Get-LocalContext @PSBoundParameters }
}

function Set-AgentContext {
    param([string]$AgentName, [PSCustomObject]$Context, [string]$AgentsDir="agents")
    if ($mode -eq "Enterprise") { Set-AzureContext @PSBoundParameters }
    else { Set-LocalContext @PSBoundParameters }
}

# Session Management (Usually Local/Ephemeral even in Cloud, but can be abstracted)
function Start-AgentSession {
    param([string]$AgentName, [string]$Intent, [string]$AgentsDir="agents")
    
    Initialize-AgentMemory -AgentName $AgentName -AgentsDir $AgentsDir

    $sessionFile = Join-Path $AgentsDir "$AgentName/memory/session_active.json"
    $session = @{
        id = [guid]::NewGuid().ToString()
        start_time = (Get-Date).ToString("o")
        intent = $Intent
        status = "running"
        mode = $env:EASYWAY_MODE
        steps = @()
    }
    $session | ConvertTo-Json -Depth 5 | Set-Content -Path $sessionFile
    return $session
}

function Update-AgentSession {
    param([string]$AgentName, [string]$StepDescription, [string]$Status="inprogress", [string]$AgentsDir="agents")
    $path = Join-Path $AgentsDir "$AgentName/memory/session_active.json"
    if (-not (Test-Path $path)) { return }

    $session = Get-Content -Raw $path | ConvertFrom-Json
    $step = @{ time=(Get-Date).ToString("o"); description=$StepDescription; status=$Status }
    
    if (-not $session.steps) { $session | Add-Member -MemberType NoteProperty -Name "steps" -Value @() }
    $steps = [System.Collections.ArrayList]@($session.steps)
    $null = $steps.Add($step)
    $session.steps = $steps
    
    $session | ConvertTo-Json -Depth 5 | Set-Content -Path $path
}

function Stop-AgentSession {
    param([string]$AgentName, [string]$Result="success", [string]$AgentsDir="agents")
    $path = Join-Path $AgentsDir "$AgentName/memory/session_active.json"
    if (-not (Test-Path $path)) { return }
    Remove-Item $path -Force
    
    $ctx = Get-AgentContext -AgentName $AgentName -AgentsDir $AgentsDir
    if ($ctx) {
        $ctx.stats.runs++
        if ($Result -eq "error") { $ctx.stats.errors++ }
        if (-not $ctx.stats.modes) { $ctx.stats | Add-Member NoteProperty "modes" @{} }
        # $ctx.stats.modes.$mode++ # Pseudo-code tracking
        
        Set-AgentContext -AgentName $AgentName -Context $ctx -AgentsDir $AgentsDir
    }
}

Export-ModuleMember -Function Initialize-AgentMemory, Get-AgentContext, Set-AgentContext, Start-AgentSession, Update-AgentSession, Stop-AgentSession
