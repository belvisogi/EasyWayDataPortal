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
    [ValidateSet('backlog', 'in_review', 'planned', 'in_progress', 'resolved', 'wont_fix')]
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
$outDir = "out"
$columnOrder = @('backlog', 'in_review', 'planned', 'in_progress', 'resolved', 'wont_fix')

function Ensure-OutDir {
    if (-not (Test-Path $outDir)) {
        New-Item -ItemType Directory -Path $outDir -Force | Out-Null
    }
}

function Escape-Html([string]$s) {
    if ($null -eq $s) { return "" }
    return ($s -replace '&', '&amp;' -replace '<', '&lt;' -replace '>', '&gt;' -replace '"', '&quot;' -replace "'", '&#39;')
}

function Normalize-Kanban($kb) {
    if (-not $kb.columns) {
        $kb | Add-Member -MemberType NoteProperty -Name 'columns' -Value ([pscustomobject]@{}) -Force
    }
    foreach ($col in $columnOrder) {
        if (-not ($kb.columns.PSObject.Properties.Name -contains $col)) {
            $kb.columns | Add-Member -MemberType NoteProperty -Name $col -Value @() -Force
        }
        if ($null -eq $kb.columns.$col) { $kb.columns.$col = @() }
        $kb.columns.$col = @($kb.columns.$col)
    }
    if (-not $kb.updated_at) { $kb.updated_at = Get-Date -Format 'o' }
    return $kb
}

function Save-Kanban($kb) {
    $kb.updated_at = Get-Date -Format 'o'
    $kb | ConvertTo-Json -Depth 12 | Set-Content $kanbanPath -Encoding UTF8
}

function Write-IssueLog($issueTable) {
    if (-not (Test-Path $issueLogPath)) { return }
    $all = Get-Content $issueLogPath | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | ForEach-Object { $_ | ConvertFrom-Json }
    $all | ForEach-Object {
        if ($issueTable.ContainsKey($_.id)) { $_ = $issueTable[$_.id] }
        $_ | ConvertTo-Json -Compress
    } | Set-Content $issueLogPath -Encoding UTF8
}

function Get-StatusFromColumn([string]$col) {
    if ($col -eq 'backlog') { return 'open' }
    return $col
}

function New-KanbanHtml($kb, $issueTable) {
    $updated = Escape-Html ($kb.updated_at ?? '')
    $html = New-Object System.Collections.Generic.List[string]
    $html.Add('<!doctype html>')
    $html.Add('<html lang="it"><head><meta charset="utf-8"/><meta name="viewport" content="width=device-width,initial-scale=1"/>')
    $html.Add('<title>Agent Issue Kanban</title>')
    $html.Add('<style>:root{color-scheme:dark;--bg:#0b1020;--panel:#0f1733;--card:#121c3f;--muted:#9aa7c0;--text:#e7ecff;--border:rgba(255,255,255,.08)}*{box-sizing:border-box}body{margin:0;background:linear-gradient(180deg,#070a14,var(--bg));color:var(--text);font:14px/1.45 ui-sans-serif,system-ui,-apple-system,Segoe UI,Roboto,Arial}header{position:sticky;top:0;z-index:4;backdrop-filter:blur(8px);background:rgba(7,10,20,.85);border-bottom:1px solid var(--border);padding:14px 16px;display:flex;gap:12px;align-items:baseline;flex-wrap:wrap}h1{margin:0;font-size:16px}.meta{color:var(--muted);font-size:12px}main{padding:16px}.board{display:grid;grid-template-columns:repeat(6,minmax(240px,1fr));gap:12px;align-items:start}.col{border:1px solid var(--border);border-radius:14px;overflow:hidden;background:rgba(255,255,255,.02)}.col h2{margin:0;padding:10px 12px;border-bottom:1px solid var(--border);font-size:12px;letter-spacing:.6px;text-transform:uppercase;display:flex;justify-content:space-between;align-items:center}.cards{padding:10px;display:flex;flex-direction:column;gap:10px}.card{background:var(--card);border:1px solid var(--border);border-radius:12px;padding:10px}.row{display:flex;justify-content:space-between;gap:8px;align-items:center}.id{font-weight:700}.pill{font-size:11px;padding:3px 8px;border-radius:999px;border:1px solid var(--border);color:var(--muted)}.sev-critical{color:#ff6b6b;border-color:rgba(255,107,107,.35)}.sev-high{color:#ffb86b;border-color:rgba(255,184,107,.35)}.sev-medium{color:#ffd86b;border-color:rgba(255,216,107,.35)}.sev-low{color:#8bffb0;border-color:rgba(139,255,176,.35)}.desc{margin-top:8px;color:rgba(231,236,255,.92)}.sub{margin-top:6px;color:var(--muted);font-size:12px;display:flex;gap:8px;flex-wrap:wrap}@media (max-width:1100px){.board{grid-template-columns:repeat(2,minmax(240px,1fr))}}</style>')
    $html.Add('</head><body>')
    $html.Add("<header><div><h1>Agent Issue Kanban</h1><div class='meta'>Updated: $updated</div></div></header>")
    $html.Add("<main><div class='board'>")

    foreach ($col in $columnOrder) {
        $items = @($kb.columns.$col)
        $html.Add("<section class='col'><h2><span>$col</span><span class='meta'>$($items.Count)</span></h2><div class='cards'>")
        foreach ($item in $items) {
            $issue = $issueTable[$item.issue_id]
            if (-not $issue) { continue }
            $sev = Escape-Html ($issue.severity ?? '')
            $sevClass = if ($sev) { "sev-$sev" } else { "" }
            $id = Escape-Html ($issue.id ?? $item.issue_id)
            $agent = Escape-Html ($issue.agent ?? '')
            $ass = Escape-Html ($issue.assigned_to ?? '')
            $desc = Escape-Html ($issue.description ?? '')
            $sub = if ($ass) { "$agent · $ass" } else { $agent }
            $html.Add("<div class='card'><div class='row'><div class='id'>$id</div><div class='pill $sevClass'>$sev</div></div><div class='sub'>$sub</div><div class='desc'>$desc</div></div>")
        }
        $html.Add("</div></section>")
    }

    $html.Add("</div></main></body></html>")
    return ($html -join "`n")
}

# Load kanban
if (-not (Test-Path $kanbanPath)) {
    Write-Error "Kanban board not found at $kanbanPath"
    exit 1
}

$kanban = Normalize-Kanban (Get-Content $kanbanPath -Raw | ConvertFrom-Json)

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
        if ($Format -eq 'json') {
            $payload = [pscustomobject]@{
                updated_at = $kanban.updated_at
                columns    = $columnOrder | ForEach-Object {
                    [pscustomobject]@{
                        name  = $_
                        items = @($kanban.columns.$_)
                    }
                }
                issues     = @($issues.Values)
            }
            $payload | ConvertTo-Json -Depth 30
            exit 0
        }
        elseif ($Format -eq 'html') {
            Ensure-OutDir
            $outPath = Join-Path $outDir 'kanban.html'
            (New-KanbanHtml -kb $kanban -issueTable $issues) | Out-File $outPath -Encoding UTF8
            Write-Host "✅ Kanban exported to $outPath" -ForegroundColor Green
        }
        elseif ($Format -eq 'console') {
            Write-Host "`n=== AGENT ISSUE KANBAN ===" -ForegroundColor Cyan
            Write-Host "Updated: $($kanban.updated_at)`n"
            
            foreach ($columnName in $columnOrder) {
                $columnItems = @($kanban.columns.$columnName)
                $count = $columnItems.Count
                
                $color = switch ($columnName) {
                    'backlog' { 'Yellow' }
                    'in_review' { 'Cyan' }
                    'planned' { 'Blue' }
                    'in_progress' { 'Magenta' }
                    'resolved' { 'Green' }
                    'wont_fix' { 'DarkGray' }
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
                        $desc = $issue.description
                        if ($null -eq $desc) { $desc = "" }
                        $short = $desc.Substring(0, [Math]::Min(60, $desc.Length))
                        $ass = if ($issue.assigned_to) { " -> $($issue.assigned_to)" } else { "" }
                        Write-Host "  $severityIcon $($item.issue_id) - $($issue.agent)$ass - $short..."
                    }
                }
                Write-Host ""
            }
        }
        elseif ($Format -eq 'markdown') {
            $md = "# Agent Issue Kanban`n`n"
            $md += "**Updated**: $($kanban.updated_at)`n`n"
            
            foreach ($columnName in $columnOrder) {
                $columnItems = @($kanban.columns.$columnName)
                $md += "## $columnName ($($columnItems.Count))`n`n"
                
                foreach ($item in $columnItems) {
                    $issue = $issues[$item.issue_id]
                    if ($issue) {
                        $ass = if ($issue.assigned_to) { " → $($issue.assigned_to)" } else { "" }
                        $md += "- **$($item.issue_id)** [$($issue.severity)] - $($issue.agent)$ass - $($issue.description)`n"
                    }
                }
                $md += "`n"
            }
            
            Ensure-OutDir
            $outPath = Join-Path $outDir 'kanban.md'
            $md | Out-File $outPath -Encoding UTF8
            Write-Host "✅ Kanban exported to $outPath"
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
        if (-not $issue) {
            Write-Error "Issue $IssueId not found in issue log ($issueLogPath)"
            exit 1
        }
        $kanban.columns.$Column += @{
            issue_id    = $IssueId
            agent       = $issue.agent
            severity    = $issue.severity
            category    = $issue.category
            description = $issue.description
            assigned_to = $issue.assigned_to
            moved_at    = Get-Date -Format 'o'
        }
        
        # Update issue status
        $issue.status = Get-StatusFromColumn $Column
        if (-not $issue.metadata) {
            $issue | Add-Member -NotePropertyName "metadata" -NotePropertyValue @{} -Force
        }
        $issue.metadata.updated_at = Get-Date -Format 'o'
        
        Save-Kanban $kanban
        Write-IssueLog $issues
        
        Write-Host "✅ Moved $IssueId to $Column (status=$($issue.status))" -ForegroundColor Green
    }

    'assign' {
        if (-not $IssueId -or -not $AssignTo) {
            Write-Error "IssueId and AssignTo required for assign action"
            exit 1
        }

        $issue = $issues[$IssueId]
        if (-not $issue) {
            Write-Error "Issue $IssueId not found"
            exit 1
        }

        $issue.assigned_to = $AssignTo
        if (-not $issue.metadata) {
            $issue | Add-Member -NotePropertyName "metadata" -NotePropertyValue @{} -Force
        }
        $issue.metadata.updated_at = Get-Date -Format 'o'

        foreach ($col in $columnOrder) {
            $items = @($kanban.columns.$col)
            $kanban.columns.$col = @(
                $items | ForEach-Object {
                    if ($_.issue_id -eq $IssueId) { $_.assigned_to = $AssignTo }
                    $_
                }
            )
        }

        Save-Kanban $kanban
        Write-IssueLog $issues

        Write-Host "✅ Assigned $IssueId to $AssignTo" -ForegroundColor Green
    }

    'resolve' {
        if (-not $IssueId) {
            Write-Error "IssueId required for resolve action"
            exit 1
        }

        $issue = $issues[$IssueId]
        if (-not $issue) {
            Write-Error "Issue $IssueId not found"
            exit 1
        }

        # Remove from any current column
        foreach ($col in $columnOrder) {
            $kanban.columns.$col = @($kanban.columns.$col | Where-Object { $_.issue_id -ne $IssueId })
        }

        $issue.status = 'resolved'
        if (-not $issue.metadata) { $issue | Add-Member -NotePropertyName "metadata" -NotePropertyValue @{} -Force }
        $issue.metadata.updated_at = Get-Date -Format 'o'
        if (-not $issue.resolution) { $issue | Add-Member -NotePropertyName "resolution" -NotePropertyValue @{} -Force }
        $issue.resolution.resolved_at = Get-Date -Format 'o'
        $issue.resolution.resolved_by = ($env:USERNAME ?? 'human')

        $kanban.columns.resolved += @{
            issue_id    = $IssueId
            agent       = $issue.agent
            severity    = $issue.severity
            category    = $issue.category
            description = $issue.description
            assigned_to = $issue.assigned_to
            moved_at    = Get-Date -Format 'o'
        }

        Save-Kanban $kanban
        Write-IssueLog $issues

        Write-Host "✅ Resolved $IssueId" -ForegroundColor Green
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
        
        if (-not $issue.metadata) {
            $issue | Add-Member -NotePropertyName "metadata" -NotePropertyValue @{} -Force
        }
        $issue.metadata.updated_at = Get-Date -Format 'o'

        Write-IssueLog $issues
        
        Write-Host "✅ Proposed fix added to $IssueId" -ForegroundColor Green
        Write-Host "   Fix: $ProposedFix" -ForegroundColor Cyan
    }
    
    'export' {
        if ($Format -eq 'json') {
            $summary = [pscustomobject]@{
                generated_at    = (Get-Date -Format 'o')
                total_issues    = $issues.Count
                open_issues     = ($issues.Values | Where-Object { $_.status -notin @('resolved', 'wont_fix') }).Count
                critical_open   = ($issues.Values | Where-Object { $_.severity -eq 'critical' -and $_.status -notin @('resolved', 'wont_fix') }).Count
                by_severity     = @(
                    'critical', 'high', 'medium', 'low' | ForEach-Object {
                        $sev = $_
                        [pscustomobject]@{ severity = $sev; count = ($issues.Values | Where-Object { $_.severity -eq $sev }).Count }
                    }
                )
                by_agent        = ($issues.Values | Group-Object -Property agent | Sort-Object Count -Descending | ForEach-Object { [pscustomobject]@{ agent = $_.Name; count = $_.Count } })
            }
            $summary | ConvertTo-Json -Depth 20
            exit 0
        }

        # Export to markdown report
        $report = "# Agent Issues Report`n`n"
        $report += "**Generated**: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')`n`n"
        
        # Summary
        $totalIssues = $issues.Count
        $openIssues = ($issues.Values | Where-Object { $_.status -notin @('resolved', 'wont_fix') }).Count
        $criticalIssues = ($issues.Values | Where-Object { $_.severity -eq 'critical' -and $_.status -notin @('resolved', 'wont_fix') }).Count
        
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
        
        Ensure-OutDir
        $mdOut = Join-Path $outDir 'issues-report.md'
        $report | Out-File $mdOut -Encoding UTF8

        if ($Format -eq 'html') {
            $html = New-Object System.Collections.Generic.List[string]
            $html.Add('<!doctype html>')
            $html.Add('<html lang="it"><head><meta charset="utf-8"/><meta name="viewport" content="width=device-width,initial-scale=1"/>')
            $html.Add('<title>Agent Issues Report</title>')
            $html.Add('<style>:root{color-scheme:dark}body{margin:0;padding:16px;background:#0b1020;color:#e7ecff;font:14px/1.45 ui-sans-serif,system-ui,Segoe UI,Roboto,Arial}h1,h2{margin:0 0 10px}.muted{color:#9aa7c0}code{background:rgba(255,255,255,.06);padding:2px 6px;border-radius:8px}table{width:100%;border-collapse:collapse;margin-top:10px}th,td{border:1px solid rgba(255,255,255,.08);padding:8px;vertical-align:top}th{background:rgba(255,255,255,.04);text-align:left}</style>')
            $html.Add('</head><body>')
            $html.Add("<h1>Agent Issues Report</h1><div class='muted'>Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')</div>")
            $html.Add("<h2>Summary</h2><ul><li><b>Total Issues</b>: $totalIssues</li><li><b>Open Issues</b>: $openIssues</li><li><b>Critical (open)</b>: $criticalIssues</li></ul>")
            $html.Add("<h2>Recent Issues (Last 10)</h2>")
            $html.Add("<table><thead><tr><th>ID</th><th>Agent</th><th>Severity</th><th>Status</th><th>Description</th><th>Suggested Fix</th></tr></thead><tbody>")
            foreach ($issue in $recent) {
                $id = Escape-Html $issue.id
                $agent = Escape-Html $issue.agent
                $sev = Escape-Html $issue.severity
                $st = Escape-Html $issue.status
                $desc = Escape-Html $issue.description
                $fix = Escape-Html $issue.suggested_fix
                $html.Add("<tr><td><code>$id</code></td><td>$agent</td><td>$sev</td><td>$st</td><td>$desc</td><td>$fix</td></tr>")
            }
            $html.Add('</tbody></table></body></html>')

            $htmlOut = Join-Path $outDir 'issues-report.html'
            ($html -join "`n") | Out-File $htmlOut -Encoding UTF8
            Write-Host "✅ Report exported to $htmlOut" -ForegroundColor Green
        }
        else {
            Write-Host "✅ Report exported to $mdOut" -ForegroundColor Green
        }
    }
}
