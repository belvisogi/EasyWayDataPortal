#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Kanban Manager - Gestisce la board Kanban degli issue

.DESCRIPTION
    Visualizza e gestisce la board Kanban con gli issue degli agenti.
    agent_governance usa questo per proporre miglioramenti.

.PARAMETER Action
    Azione: view, move, assign, propose-fix, resolve

.PARAMETER IssueId
    ID dell'issue da gestire

.PARAMETER Column
    Colonna target per move: backlog, in_review, planned, in_progress, resolved

.PARAMETER AssignTo
    Agente a cui assegnare l'issue

.PARAMETER ProposedFix
    Proposta di fix da agent_governance

.EXAMPLE
    # View kanban
    pwsh scripts/pwsh/kanban-manager.ps1 -Action view

.EXAMPLE
    # Move issue to in_review
    pwsh scripts/pwsh/kanban-manager.ps1 -Action move -IssueId ISSUE-20260118-001 -Column in_review

.EXAMPLE
    # Propose fix (agent_governance)
    pwsh scripts/pwsh/kanban-manager.ps1 -Action propose-fix `
      -IssueId ISSUE-20260118-001 `
      -ProposedFix "Add pre-check for db/migrations/ directory"
#>

param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('view', 'move', 'assign', 'propose-fix', 'resolve', 'export')]
    [string]$Action,
    
    [Parameter(Mandatory = $false)]
    [string]$IssueId,
    
    [Parameter(Mandatory = $false)]
    [ValidateSet('backlog', 'in_review', 'planned', 'in_progress', 'resolved')]
    [string]$Column,
    
    [Parameter(Mandatory = $false)]
    [string]$AssignTo,
    
    [Parameter(Mandatory = $false)]
    [string]$ProposedFix,
    
    [Parameter(Mandatory = $false)]
    [ValidateSet('console', 'markdown', 'json', 'html')]
    [string]$Format = 'console'
)

$ErrorActionPreference = 'Stop'

$kanbanPath = "agents/logs/kanban.json"
$issueLogPath = "agents/logs/issues.jsonl"

# Load kanban
if (-not (Test-Path $kanbanPath)) {
    Write-Error "Kanban board not found at $kanbanPath"
    exit 1
}

$kanban = Get-Content $kanbanPath -Raw | ConvertFrom-Json

# Load issues
$issues = @{}
if (Test-Path $issueLogPath) {
    Get-Content $issueLogPath | ForEach-Object {
        $issue = $_ | ConvertFrom-Json
        $issues[$issue.id] = $issue
    }
}

# Actions
switch ($Action) {
    'view' {
        if ($Format -eq 'console') {
            Write-Host "`n=== AGENT ISSUE KANBAN ===" -ForegroundColor Cyan
            Write-Host "Updated: $($kanban.updated_at)`n"
            
            foreach ($columnName in @('backlog', 'in_review', 'planned', 'in_progress', 'resolved')) {
                $columnItems = $kanban.columns.$columnName
                $count = $columnItems.Count
                
                $color = switch ($columnName) {
                    'backlog' { 'Yellow' }
                    'in_review' { 'Cyan' }
                    'planned' { 'Blue' }
                    'in_progress' { 'Magenta' }
                    'resolved' { 'Green' }
                }
                
                Write-Host "[$columnName] ($count)" -ForegroundColor $color
                
                foreach ($item in $columnItems) {
                    $issue = $issues[$item.issue_id]
                    if ($issue) {
                        $severityIcon = switch ($issue.severity) {
                            'critical' { '🔴' }
                            'high' { '🟠' }
                            'medium' { '🟡' }
                            'low' { '🟢' }
                        }
                        Write-Host "  $severityIcon $($item.issue_id) - $($issue.agent) - $($issue.description.Substring(0, [Math]::Min(60, $issue.description.Length)))..."
                    }
                }
                Write-Host ""
            }
        }
        elseif ($Format -eq 'markdown') {
            $md = "# Agent Issue Kanban`n`n"
            $md += "**Updated**: $($kanban.updated_at)`n`n"
            
            foreach ($columnName in @('backlog', 'in_review', 'planned', 'in_progress', 'resolved')) {
                $columnItems = $kanban.columns.$columnName
                $md += "## $columnName ($($columnItems.Count))`n`n"
                
                foreach ($item in $columnItems) {
                    $issue = $issues[$item.issue_id]
                    if ($issue) {
                        $md += "- **$($item.issue_id)** [$($issue.severity)] - $($issue.agent) - $($issue.description)`n"
                    }
                }
                $md += "`n"
            }
            
            $md | Out-File "out/kanban.md" -Encoding UTF8
            Write-Host "✅ Kanban exported to out/kanban.md"
        }
    }
    
    'move' {
        if (-not $IssueId -or -not $Column) {
            Write-Error "IssueId and Column required for move action"
            exit 1
        }
        
        # Find and remove from current column
        $found = $false
        foreach ($columnName in $kanban.columns.PSObject.Properties.Name) {
            $columnItems = $kanban.columns.$columnName
            $index = 0
            foreach ($item in $columnItems) {
                if ($item.issue_id -eq $IssueId) {
                    $kanban.columns.$columnName = @($columnItems | Where-Object { $_.issue_id -ne $IssueId })
                    $found = $true
                    break
                }
                $index++
            }
            if ($found) { break }
        }
        
        if (-not $found) {
            Write-Error "Issue $IssueId not found in kanban"
            exit 1
        }
        
        # Add to new column
        $issue = $issues[$IssueId]
        $kanban.columns.$Column += @{
            issue_id    = $IssueId
            agent       = $issue.agent
            severity    = $issue.severity
            category    = $issue.category
            description = $issue.description
            moved_at    = Get-Date -Format 'o'
        }
        
        # Update issue status
        $issue.status = $Column
        $issue.metadata.updated_at = Get-Date -Format 'o'
        
        # Save
        $kanban.updated_at = Get-Date -Format 'o'
        $kanban | ConvertTo-Json -Depth 10 | Set-Content $kanbanPath -Encoding UTF8
        
        # Update issue log
        $allIssues = Get-Content $issueLogPath | ForEach-Object { $_ | ConvertFrom-Json }
        $allIssues | ForEach-Object {
            if ($_.id -eq $IssueId) {
                $_.status = $Column
                $_.metadata.updated_at = Get-Date -Format 'o'
            }
            $_ | ConvertTo-Json -Compress
        } | Set-Content $issueLogPath -Encoding UTF8
        
        Write-Host "✅ Moved $IssueId to $Column" -ForegroundColor Green
    }
    
    'propose-fix' {
        if (-not $IssueId -or -not $ProposedFix) {
            Write-Error "IssueId and ProposedFix required"
            exit 1
        }
        
        $issue = $issues[$IssueId]
        if (-not $issue) {
            Write-Error "Issue $IssueId not found"
            exit 1
        }
        
        # Add proposed fix
        if (-not $issue.proposed_fixes) {
            $issue | Add-Member -NotePropertyName "proposed_fixes" -NotePropertyValue @()
        }
        
        $issue.proposed_fixes += @{
            proposed_by = "agent_governance"
            proposed_at = Get-Date -Format 'o'
            fix         = $ProposedFix
            status      = "pending_review"
        }
        
        $issue.metadata.updated_at = Get-Date -Format 'o'
        
        # Update issue log
        $allIssues = Get-Content $issueLogPath | ForEach-Object { $_ | ConvertFrom-Json }
        $allIssues | ForEach-Object {
            if ($_.id -eq $IssueId) {
                $_ = $issue
            }
            $_ | ConvertTo-Json -Compress
        } | Set-Content $issueLogPath -Encoding UTF8
        
        Write-Host "✅ Proposed fix added to $IssueId" -ForegroundColor Green
        Write-Host "   Fix: $ProposedFix" -ForegroundColor Cyan
    }
    
    'export' {
        # Export to markdown report
        $report = "# Agent Issues Report`n`n"
        $report += "**Generated**: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')`n`n"
        
        # Summary
        $totalIssues = $issues.Count
        $openIssues = ($issues.Values | Where-Object { $_.status -ne 'resolved' }).Count
        $criticalIssues = ($issues.Values | Where-Object { $_.severity -eq 'critical' }).Count
        
        $report += "## Summary`n`n"
        $report += "- **Total Issues**: $totalIssues`n"
        $report += "- **Open Issues**: $openIssues`n"
        $report += "- **Critical Issues**: $criticalIssues`n`n"
        
        # By severity
        $report += "## Issues by Severity`n`n"
        foreach ($sev in @('critical', 'high', 'medium', 'low')) {
            $count = ($issues.Values | Where-Object { $_.severity -eq $sev }).Count
            $report += "- **$sev**: $count`n"
        }
        $report += "`n"
        
        # By agent
        $report += "## Issues by Agent`n`n"
        $byAgent = $issues.Values | Group-Object -Property agent
        foreach ($group in $byAgent | Sort-Object Count -Descending) {
            $report += "- **$($group.Name)**: $($group.Count)`n"
        }
        $report += "`n"
        
        # Recent issues
        $report += "## Recent Issues (Last 10)`n`n"
        $recent = $issues.Values | Sort-Object { $_.timestamp } -Descending | Select-Object -First 10
        foreach ($issue in $recent) {
            $report += "### $($issue.id) - $($issue.agent)`n`n"
            $report += "- **Severity**: $($issue.severity)`n"
            $report += "- **Category**: $($issue.category)`n"
            $report += "- **Description**: $($issue.description)`n"
            $report += "- **Status**: $($issue.status)`n"
            if ($issue.suggested_fix) {
                $report += "- **Suggested Fix**: $($issue.suggested_fix)`n"
            }
            $report += "`n"
        }
        
        $report | Out-File "out/issues-report.md" -Encoding UTF8
        Write-Host "✅ Report exported to out/issues-report.md" -ForegroundColor Green
    }
}
