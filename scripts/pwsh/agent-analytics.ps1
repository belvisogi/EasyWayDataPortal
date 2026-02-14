#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Agent Analytics - Eye of Providence
    Genera report su produttività e qualità del codice.

.DESCRIPTION
    Analizza log git, issue log e stato del sistema per generare metriche e report.
    Supporta output in Console, Markdown e HTML.

.PARAMETER Action
    Azione da eseguire: report, metrics

.PARAMETER Range
    Periodo di analisi: today, week, month, all (default: week)

.PARAMETER OutputDir
    Directory per il salvataggio dei report (default: agents/reports)

.EXAMPLE
    ./agent-analytics.ps1 -Action report -Range week
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('report', 'metrics')]
    [string]$Action,

    [Parameter(Mandatory = $false)]
    [ValidateSet('today', 'week', 'month', 'all')]
    [string]$Range = 'week',

    [Parameter(Mandatory = $false)]
    [string]$OutputDir = "agents/reports"
)

$ErrorActionPreference = "Stop"

# ============================================================================
# Configuration
# ============================================================================

$AGENT_NAME = "agent_analytics"
$LOG_DIR = "agents/logs"
$ISSUE_LOG = "$LOG_DIR/issues.jsonl"
$KANBAN_LOG = "$LOG_DIR/kanban.json"
$GIT_LOG_PATTERN = "$LOG_DIR/agent_release_git_commit_*.log"

# Assicurati che la cartella reports esista
if (-not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
}

# ============================================================================
# Helper Functions
# ============================================================================

function Get-DateRange {
    param([string]$Range)
    
    $end = Get-Date
    $start = switch ($Range) {
        'today' { $end.Date }
        'week' { $end.AddDays(-7).Date }
        'month' { $end.AddDays(-30).Date }
        'all' { [DateTime]::MinValue }
    }
    return @{ Start = $start; End = $end }
}

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    
    $color = switch ($Level) {
        "INFO" { "White" }
        "WARN" { "Yellow" }
        "ERROR" { "Red" }
        "SUCCESS" { "Green" }
        Default { "White" }
    }
    
    Write-Host "[$timestamp] [$Level] $Message" -ForegroundColor $color
}

# ============================================================================
# Data Gathering Functions
# ============================================================================

function Get-GitMetrics {
    param($StartDate, $EndDate)
    
    Write-Log "Analyzing Git metrics from $($StartDate.ToString('yyyy-MM-dd')) to $($EndDate.ToString('yyyy-MM-dd'))..." "INFO"
    
    $since = $StartDate.ToString("yyyy-MM-dd")
    $until = $EndDate.ToString("yyyy-MM-dd")
    
    try {
        # Get raw git log: hash|author|date|subject
        $gitLog = git log --since="$since 00:00:00" --until="$until 23:59:59" --pretty=format:"%h|%an|%ad|%s" --date=iso
        
        if ([string]::IsNullOrWhiteSpace($gitLog)) {
            Write-Log "No commits found in range." "WARN"
            return @{ TotalCommits = 0; ByType = @{}; ByScope = @{}; ByAuthor = @{} }
        }
        
        $entries = $gitLog -split "`n"
        $totalCommits = $entries.Count
        
        $byType = @{}
        $byScope = @{}
        $byAuthor = @{}
        
        foreach ($line in $entries) {
            $parts = $line -split "\|"
            if ($parts.Count -lt 4) { continue }
            
            $author = $parts[1]
            $subject = $parts[3]
            
            # Count Author
            if (-not $byAuthor.ContainsKey($author)) { $byAuthor[$author] = 0 }
            $byAuthor[$author]++
            
            # Parse Conventional Commit
            if ($subject -match '^(feat|fix|chore|docs|style|refactor|test|perf|ci|build)(?:\(([^)]+)\))?: (.+)$') {
                $type = $matches[1]
                $scope = if ($matches[2]) { $matches[2] } else { "none" }
                
                # Count Type
                if (-not $byType.ContainsKey($type)) { $byType[$type] = 0 }
                $byType[$type]++
                
                # Count Scope
                if (-not $byScope.ContainsKey($scope)) { $byScope[$scope] = 0 }
                $byScope[$scope]++
            }
            else {
                if (-not $byType.ContainsKey("other")) { $byType["other"] = 0 }
                $byType["other"]++
            }
        }
        
        return @{
            TotalCommits = $totalCommits
            byType       = $byType
            byScope      = $byScope
            byAuthor     = $byAuthor
        }
    }
    catch {
        Write-Log "Error analyzing git log: $_" "ERROR"
        return @{ Error = $_.Message }
    }
}

function Get-IssueMetrics {
    param($StartDate, $EndDate)
    
    Write-Log "Analyzing Issue metrics..." "INFO"
    
    $issuesFile = "agents/logs/issues.jsonl"
    if (-not (Test-Path $issuesFile)) {
        Write-Log "Issues log file not found at $issuesFile" "WARN"
        return @{ TotalIssues = 0; OpenCount = 0; ResolvedCount = 0; MTTR_Hours = 0 }
    }
    
    $totalIssues = 0
    $openCount = 0
    $resolvedCount = 0
    $totalResolutionTimeHours = 0
    $resolvedIssuesCount = 0
    $bySeverity = @{}
    
    Get-Content $issuesFile | ForEach-Object {
        try {
            $issue = $_ | ConvertFrom-Json
            $created = [DateTime]::Parse($issue.timestamp)
            
            # Filter by date range (created within range)
            if ($created -ge $StartDate -and $created -le $EndDate) {
                $totalIssues++
                
                # Count Severity
                $sev = $issue.severity
                if (-not $bySeverity.ContainsKey($sev)) { $bySeverity[$sev] = 0 }
                $bySeverity[$sev]++
                
                if ($issue.status -eq 'resolved') {
                    $resolvedCount++
                    
                    # Calculate MTTR if resolution info exists
                    if ($issue.resolution -and $issue.resolution.resolved_at) {
                        $resolvedAt = [DateTime]::Parse($issue.resolution.resolved_at)
                        $duration = $resolvedAt - $created
                        $totalResolutionTimeHours += $duration.TotalHours
                        $resolvedIssuesCount++
                    }
                }
                elseif ($issue.status -ne 'wont_fix') {
                    $openCount++
                }
            }
        }
        catch {
            Write-Log "Skipping invalid issue line: $_" "WARN"
        }
    }
    
    $mttr = if ($resolvedIssuesCount -gt 0) {
        [Math]::Round($totalResolutionTimeHours / $resolvedIssuesCount, 2)
    }
    else { 0 }
    
    return @{
        TotalIssues   = $totalIssues
        OpenCount     = $openCount
        ResolvedCount = $resolvedCount
        MTTR_Hours    = $mttr
        BySeverity    = $bySeverity
    }
}

function Get-QualityMetrics {
    Write-Log "Analyzing Quality metrics..." "INFO"
    
    # 1. TODO Count
    $todoCount = 0
    try {
        $todoResult = git grep -c "TODO"
        if ($todoResult) {
            $todoResult -split "`n" | ForEach-Object {
                if ($_ -match ':\d+$') {
                    $todoCount += [int]($_ -split ':')[-1]
                }
            }
        }
    }
    catch {
        Write-Log "Could not count TODOs: $_" "WARN"
    }
    
    # 2. Test Count
    $testCount = (Get-ChildItem -Path . -Recurse -Include "*test.ps1", "*.spec.js", "*.test.js" -ErrorAction SilentlyContinue).Count
    
    # 3. Lint/Validation Issues (from Issue Log)
    $issuesFile = "agents/logs/issues.jsonl"
    $lintIssues = 0
    if (Test-Path $issuesFile) {
        $lintIssues = (Get-Content $issuesFile | ConvertFrom-Json | Where-Object { $_.status -ne 'resolved' -and $_.category -match 'validation|lint' }).Count
    }

    return @{
        TodoCount  = $todoCount
        TestCount  = $testCount
        LintIssues = $lintIssues
    }
}

# ============================================================================
# Reporting Functions
# ============================================================================

function Generate-MarkdownReport {
    param($Metrics, $Range, $OutFile)
    
    $md = "# 👁️ Eye of Providence - Analytics Report`n`n"
    $md += "**Range**: $($Range) ($($Metrics.Range.Start.ToString('yyyy-MM-dd')) - $($Metrics.Range.End.ToString('yyyy-MM-dd')))`n"
    $md += "**Generated**: $(Get-Date -Format 'yyyy-MM-dd HH:mm')`n`n"
    
    $md += "## 📊 Executive Summary`n`n"
    $md += "| Metric | Value |`n"
    $md += "|---|---|`n"
    $md += "| **Commits** | $($Metrics.Git.TotalCommits) |`n"
    $md += "| **Active Authors** | $($Metrics.Git.ByAuthor.Count) |`n"
    $md += "| **New Issues** | $($Metrics.Issues.TotalIssues) |`n"
    $md += "| **Open Issues** | $($Metrics.Issues.OpenCount) |`n"
    $md += "| **MTTR** | $($Metrics.Issues.MTTR_Hours)h |`n"
    $md += "| **Tests Found** | $($Metrics.Quality.TestCount) |`n"
    $md += "| **Technical Debt (TODOs)** | $($Metrics.Quality.TodoCount) |`n`n"
    
    $md += "## 📉 Productivity (Git)`n`n"
    
    $md += "### Commits by Type`n"
    $Metrics.Git.ByType.Keys | Sort-Object | ForEach-Object {
        $md += "- **$_**: $($Metrics.Git.ByType[$_])`n"
    }
    $md += "`n"
    
    $md += "### Commits by Scope`n"
    $Metrics.Git.ByScope.Keys | Sort-Object | ForEach-Object {
        $md += "- **$_**: $($Metrics.Git.ByScope[$_])`n"
    }
    $md += "`n"

    $md += "## 🐞 Quality (Issues)`n`n"
    $md += "### Issues by Severity`n"
    $Metrics.Issues.BySeverity.Keys | Sort-Object | ForEach-Object {
        $md += "- **$_**: $($Metrics.Issues.BySeverity[$_])`n"
    }
    
    $md | Set-Content $OutFile -Encoding UTF8
    Write-Log "Markdown report generated: $OutFile" "SUCCESS"
}

function Generate-HtmlReport {
    param($Metrics, $Range, $OutFile)
    
    $style = @"
<style>
    :root { --bg: #0b1020; --card: #121c3f; --text: #e7ecff; --accent: #3b82f6; --border: rgba(255,255,255,0.1); }
    body { font-family: system-ui, sans-serif; background: var(--bg); color: var(--text); padding: 20px; line-height: 1.5; }
    .container { max-width: 1000px; margin: 0 auto; }
    h1, h2, h3 { color: #fff; }
    .grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 20px; margin-bottom: 30px; }
    .card { background: var(--card); border: 1px solid var(--border); padding: 20px; border-radius: 12px; }
    .card h3 { margin-top: 0; font-size: 14px; color: #9aa7c0; text-transform: uppercase; }
    .big-num { font-size: 32px; font-weight: bold; color: var(--accent); }
    table { width: 100%; border-collapse: collapse; margin-top: 10px; }
    th, td { text-align: left; padding: 8px; border-bottom: 1px solid var(--border); }
    th { color: #9aa7c0; font-weight: normal; }
</style>
"@
    
    $html = @"
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <title>Analytics Report</title>
    $style
</head>
<body>
    <div class="container">
        <header>
            <h1>👁️ Eye of Providence</h1>
            <p>Analytics Report &bull; $Range &bull; $(Get-Date -Format 'yyyy-MM-dd HH:mm')</p>
        </header>
        
        <h2>📊 Executive Summary</h2>
        <div class="grid">
            <div class="card"><h3>Commits</h3><div class="big-num">$($Metrics.Git.TotalCommits)</div></div>
            <div class="card"><h3>Active Authors</h3><div class="big-num">$($Metrics.Git.ByAuthor.Count)</div></div>
            <div class="card"><h3>New Issues</h3><div class="big-num">$($Metrics.Issues.TotalIssues)</div></div>
            <div class="card"><h3>MTTR</h3><div class="big-num">$($Metrics.Issues.MTTR_Hours)h</div></div>
            <div class="card"><h3>Tech Debt (TODO)</h3><div class="big-num">$($Metrics.Quality.TodoCount)</div></div>
        </div>
        
        <div class="grid">
            <div class="card">
                <h3>Commits by Type</h3>
                <table>
$(
    $Metrics.Git.ByType.Keys | Sort-Object | ForEach-Object { "<tr><td>$_</td><td>$($Metrics.Git.ByType[$_])</td></tr>" } | Out-String
)
                </table>
            </div>
            
             <div class="card">
                <h3>Issues by Severity</h3>
                <table>
$(
    $Metrics.Issues.BySeverity.Keys | Sort-Object | ForEach-Object { "<tr><td>$_</td><td>$($Metrics.Issues.BySeverity[$_])</td></tr>" } | Out-String
)
                </table>
            </div>
        </div>

    </div>
</body>
</html>
"@
    
    $html | Set-Content $OutFile -Encoding UTF8
    Write-Log "HTML report generated: $OutFile" "SUCCESS"
}

# ============================================================================
# Main Logic
# ============================================================================

function Main {
    $dates = Get-DateRange -Range $Range
    
    $metrics = @{
        Range   = $dates
        Git     = Get-GitMetrics -StartDate $dates.Start -EndDate $dates.End
        Issues  = Get-IssueMetrics -StartDate $dates.Start -EndDate $dates.End
        Quality = Get-QualityMetrics
    }
    
    if ($Action -eq 'metrics') {
        $metrics | ConvertTo-Json -Depth 5
    }
    elseif ($Action -eq 'report') {
        $reportBase = Join-Path $OutputDir "analytics-$(Get-Date -Format 'yyyyMMdd')"
        Generate-MarkdownReport -Metrics $metrics -Range $Range -OutFile "${reportBase}.md"
        Generate-HtmlReport -Metrics $metrics -Range $Range -OutFile "${reportBase}.html"
    }
}

Main
