<#
.SYNOPSIS
    Manages agent task state (state.json) and renders task.md.

.DESCRIPTION
    Implements the "State-as-Code" workflow.
    - Init: Creates a new state.json.
    - Add: Adds a task or subtask.
    - Update: Updates task status.
    - Render: Generates task.md from state.json.

.EXAMPLE
    pwsh agent-task.ps1 -Init -Title "New Capability"
    pwsh agent-task.ps1 -Add -Title "Research"
    pwsh agent-task.ps1 -Update -Id 1 -Status completed
#>

[CmdletBinding()]
Param(
    [Parameter(ParameterSetName = 'Init')]
    [switch]$Init,

    [Parameter(ParameterSetName = 'Add')]
    [switch]$Add,

    [Parameter(ParameterSetName = 'Update')]
    [switch]$Update,

    [Parameter(ParameterSetName = 'Render')]
    [switch]$Render,

    [Parameter(ParameterSetName = 'Init')]
    [Parameter(ParameterSetName = 'Add')]
    [string]$Title,

    [Parameter(ParameterSetName = 'Add')]
    [int]$ParentId,

    [Parameter(ParameterSetName = 'Update')]
    [int]$Id,

    [Parameter(ParameterSetName = 'Update')]
    [ValidateSet('pending', 'in-progress', 'completed', 'skipped')]
    [string]$Status,

    [string]$StateFile = "state.json",
    [string]$TaskFile = "task.md"
)

$ErrorActionPreference = "Stop"

function Get-NextId {
    param($Tasks)
    $max = 0
    $Tasks | ForEach-Object { 
        if ($_.id -gt $max) { $max = $_.id }
        if ($_.subtasks) {
            $_.subtasks | ForEach-Object { if ($_.id -gt $max) { $max = $_.id } }
        }
    }
    return $max + 1
}

function Find-Task {
    param($Tasks, $Id)
    foreach ($t in $Tasks) {
        if ($t.id -eq $Id) { return $t }
        if ($t.subtasks) {
            $found = Find-Task -Tasks $t.subtasks -Id $Id
            if ($found) { return $found }
        }
    }
    return $null
}

function ConvertTo-Markdown {
    param($State)
    
    $sb = [System.Text.StringBuilder]::new()
    $null = $sb.AppendLine("# $($State.title)")
    $null = $sb.AppendLine("")

    foreach ($task in $State.tasks) {
        $mark = " "
        if ($task.status -eq 'completed') { $mark = "x" }
        elseif ($task.status -eq 'in-progress') { $mark = "/" }
        elseif ($task.status -eq 'skipped') { $mark = "-" }

        $null = $sb.AppendLine("- [$mark] $($task.title) <!-- id: $($task.id) -->")

        if ($task.subtasks) {
            foreach ($sub in $task.subtasks) {
                $subMark = " "
                if ($sub.status -eq 'completed') { $subMark = "x" }
                elseif ($sub.status -eq 'in-progress') { $subMark = "/" }
                elseif ($sub.status -eq 'skipped') { $subMark = "-" }
                
                $null = $sb.AppendLine("    - [$subMark] $($sub.title) <!-- id: $($sub.id) -->")
            }
        }
    }
    return $sb.ToString()
}

# --- Main Logic ---

if ($Init) {
    $state = @{
        version     = "1.0"
        title       = $Title
        status      = "in-progress"
        tasks       = @()
        lastUpdated = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ")
    }
    $state | ConvertTo-Json -Depth 10 | Set-Content -Path $StateFile
    Write-Host "Initialized $StateFile"
    # Auto-render
    $Render = $true
}

if (-not (Test-Path $StateFile)) {
    Write-Error "State file '$StateFile' not found. Run with -Init first."
}

$jsonContent = Get-Content -Path $StateFile -Raw
$state = $jsonContent | ConvertFrom-Json

if ($Add) {
    $newId = Get-NextId -Tasks $state.tasks
    $newTask = @{
        id       = $newId
        title    = $Title
        status   = "pending"
        subtasks = @()
    }

    if ($ParentId) {
        $parent = Find-Task -Tasks $state.tasks -Id $ParentId
        if (-not $parent) { Write-Error "Parent ID $ParentId not found." }
        if (-not $parent.subtasks) { 
            # If subtasks is $null or missing, initialize it
            if ($parent.PSObject.Properties['subtasks']) {
                $parent.subtasks = @()
            }
            else {
                $parent | Add-Member -MemberType NoteProperty -Name "subtasks" -Value @() 
            }
        }
        $parent.subtasks += $newTask
    }
    else {
        $state.tasks += $newTask
    }
    Write-Host "Added task '$Title' (ID: $newId)"
    $state.lastUpdated = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ")
    $state | ConvertTo-Json -Depth 10 | Set-Content -Path $StateFile
    $Render = $true
}

if ($Update) {
    if (-not $Id) { Write-Error "Id is required for update." }
    $task = Find-Task -Tasks $state.tasks -Id $Id
    if (-not $task) { Write-Error "Task ID $Id not found." }
    
    $task.status = $Status
    Write-Host "Updated Task $Id to '$Status'"
    $state.lastUpdated = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ")
    $state | ConvertTo-Json -Depth 10 | Set-Content -Path $StateFile
    $Render = $true

    # Proactive GEDI Check
    if ($Status -eq 'completed') {
        $gediScript = Join-Path $PSScriptRoot "agent-gedi.ps1"
        if (Test-Path $gediScript) {
            & $gediScript -StateFile $StateFile
        }
    }
}

if ($Render) {
    $md = ConvertTo-Markdown -State $state
    $md | Set-Content -Path $TaskFile
    Write-Host "Rendered $TaskFile"
}
