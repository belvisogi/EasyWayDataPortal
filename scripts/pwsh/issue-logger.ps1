#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Agent Issue Logger - Registra problemi e difficoltà degli agenti

.DESCRIPTION
    Quando un agente incontra un problema o difficoltà, usa questo script
    per registrare l'issue in un log centralizzato JSON.

.PARAMETER Agent
    Nome dell'agente che registra l'issue

.PARAMETER Severity
    Severità: critical, high, medium, low

.PARAMETER Category
    Categoria: execution_failed, validation_error, missing_dependency, etc.

.PARAMETER Description
    Descrizione del problema

.PARAMETER Context
    Contesto aggiuntivo (JSON string o hashtable)

.PARAMETER SuggestedFix
    Suggerimento dell'agente per risolvere il problema

.EXAMPLE
    pwsh scripts/pwsh/issue-logger.ps1 `
      -Agent "agent_dba" `
      -Severity "high" `
      -Category "missing_dependency" `
      -Description "db/migrations/ directory not found" `
      -SuggestedFix "Create db/migrations/ directory"
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$Agent,
    
    [Parameter(Mandatory = $true)]
    [ValidateSet('critical', 'high', 'medium', 'low')]
    [string]$Severity,
    
    [Parameter(Mandatory = $true)]
    [ValidateSet('execution_failed', 'validation_error', 'missing_dependency', 
        'configuration_error', 'knowledge_gap', 'tool_unavailable',
        'permission_denied', 'timeout', 'other')]
    [string]$Category,
    
    [Parameter(Mandatory = $true)]
    [string]$Description,
    
    [Parameter(Mandatory = $false)]
    [object]$Context = @{},
    
    [Parameter(Mandatory = $false)]
    [string]$UserInput = "",
    
    [Parameter(Mandatory = $false)]
    [string]$Intent = "",
    
    [Parameter(Mandatory = $false)]
    [string]$ActionAttempted = "",
    
    [Parameter(Mandatory = $false)]
    [string]$ErrorMessage = "",
    
    [Parameter(Mandatory = $false)]
    [string]$Impact = "",
    
    [Parameter(Mandatory = $false)]
    [string]$SuggestedFix = "",
    
    [Parameter(Mandatory = $false)]
    [string[]]$Tags = @()
)

$ErrorActionPreference = 'Stop'

# Paths
$issueLogPath = "agents/logs/issues.jsonl"
$kanbanPath = "agents/logs/kanban.json"

# Ensure directories exist
$logDir = Split-Path $issueLogPath -Parent
if (-not (Test-Path $logDir)) {
    New-Item -ItemType Directory -Path $logDir -Force | Out-Null
}

# Generate issue ID
$date = Get-Date -Format 'yyyyMMdd'
$existingIssues = @()
if (Test-Path $issueLogPath) {
    $existingIssues = Get-Content $issueLogPath | ForEach-Object {
        $_ | ConvertFrom-Json
    } | Where-Object { $_.id -match "^ISSUE-$date-" }
}
$nextNumber = ($existingIssues.Count + 1).ToString('000')
$issueId = "ISSUE-$date-$nextNumber"

# Build context
$contextObj = @{
    user_input       = $UserInput
    intent           = $Intent
    action_attempted = $ActionAttempted
    error_message    = $ErrorMessage
}

# Merge with provided context
if ($Context -is [hashtable]) {
    foreach ($key in $Context.Keys) {
        $contextObj[$key] = $Context[$key]
    }
}
elseif ($Context -is [string]) {
    try {
        $parsedContext = $Context | ConvertFrom-Json -AsHashtable
        foreach ($key in $parsedContext.Keys) {
            $contextObj[$key] = $parsedContext[$key]
        }
    }
    catch {
        Write-Warning "Could not parse Context as JSON: $_"
    }
}

# Create issue object
$issue = @{
    id             = $issueId
    timestamp      = Get-Date -Format 'o'
    agent          = $Agent
    severity       = $Severity
    category       = $Category
    description    = $Description
    context        = $contextObj
    impact         = $Impact
    suggested_fix  = $SuggestedFix
    status         = "open"
    assigned_to    = "agent_governance"  # Default assignment
    related_issues = @()
    metadata       = @{
        created_by = $Agent
        updated_at = Get-Date -Format 'o'
        tags       = $Tags
    }
}

# Append to JSONL log
$issue | ConvertTo-Json -Depth 10 -Compress | Add-Content $issueLogPath -Encoding UTF8

Write-Host "✅ Issue logged: $issueId" -ForegroundColor Green
Write-Host "   Agent: $Agent" -ForegroundColor Cyan
Write-Host "   Severity: $Severity" -ForegroundColor $(
    switch ($Severity) {
        'critical' { 'Red' }
        'high' { 'Yellow' }
        'medium' { 'White' }
        'low' { 'Gray' }
    }
)
Write-Host "   Category: $Category"
Write-Host "   Description: $Description"

# Update Kanban board
if (Test-Path $kanbanPath) {
    $kanban = Get-Content $kanbanPath -Raw | ConvertFrom-Json
}
else {
    $kanban = @{
        columns    = @{
            backlog     = @()
            in_review   = @()
            planned     = @()
            in_progress = @()
            resolved    = @()
        }
        updated_at = Get-Date -Format 'o'
    }
}

# Add to backlog
$kanban.columns.backlog += @{
    issue_id    = $issueId
    agent       = $Agent
    severity    = $Severity
    category    = $Category
    description = $Description
    added_at    = Get-Date -Format 'o'
}

$kanban.updated_at = Get-Date -Format 'o'
$kanban | ConvertTo-Json -Depth 10 | Set-Content $kanbanPath -Encoding UTF8

Write-Host "✅ Added to Kanban backlog" -ForegroundColor Green

# Notify agent_governance if critical/high
if ($Severity -in @('critical', 'high')) {
    Write-Host "⚠️  High-priority issue - agent_governance will be notified" -ForegroundColor Yellow
    
    # Create notification for governance
    $notificationPath = "agents/agent_governance/notifications.jsonl"
    $notification = @{
        timestamp       = Get-Date -Format 'o'
        type            = "high_priority_issue"
        issue_id        = $issueId
        agent           = $Agent
        severity        = $Severity
        description     = $Description
        action_required = "Review and propose improvement"
    }
    
    $notification | ConvertTo-Json -Compress | Add-Content $notificationPath -Encoding UTF8
}

# Return issue ID for scripting
return $issueId
