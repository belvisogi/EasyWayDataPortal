# Agent Quality Metrics Report Generator
# Reads: llm-router-events.jsonl, llm-router-feedback.jsonl
# Writes: docs/ops/reports/quality-report-YYYYMMDD.md

param(
    [string]$EventsPath = "docs/ops/logs/llm-router-events.jsonl",
    [string]$FeedbackPath = "docs/ops/logs/llm-router-feedback.jsonl",
    [string]$ReportDir = "docs/ops/reports"
)

$ErrorActionPreference = "Stop"

function Ensure-Dir { param($Path) if (-not (Test-Path $Path)) { New-Item -ItemType Directory -Path $Path -Force | Out-Null } }

Ensure-Dir $ReportDir

# 1. Load Data
$events = @()
if (Test-Path $EventsPath) {
    $events = Get-Content $EventsPath | ConvertFrom-Json
}

$feedback = @()
if (Test-Path $FeedbackPath) {
    $feedback = Get-Content $FeedbackPath | ConvertFrom-Json
}

# 2. Calculate Metrics

# 2.1 Cost Analysis
$totalCost = 0
$costByProvider = @{}
$runs = 0
$errors = 0

foreach ($e in $events) {
    if ($e.usage -and $e.usage.costUSD) {
        $cost = [double]$e.usage.costUSD
        $totalCost += $cost
        
        $p = $e.provider
        if (-not $costByProvider.ContainsKey($p)) { $costByProvider[$p] = 0.0 }
        $costByProvider[$p] += $cost
    }
    
    if ($e.type -eq "invoke_success") { $runs++ }
    if ($e.type -eq "invoke_failed") { $errors++ }
}

# 2.2 Feedback Analysis
$avgRating = 0
if ($feedback.Count -gt 0) {
    $sum = ($feedback | Measure-Object -Property rating -Sum).Sum
    $avgRating = $sum / $feedback.Count
}

# 3. Generate Markdown
$date = (Get-Date).ToString("yyyy-MM-dd")
$reportFile = Join-Path $ReportDir "quality-report-$date.md"

$md = @"
# Agent Quality Report ($date)

## Executive Summary
- **Total Runs**: $runs
- **Total Errors**: $errors
- **Error Rate**: $(if($runs){"{0:P2}" -f ($errors/$runs)}else{"0%"})
- **Total Cost**: $("`$"+"{0:N4}" -f $totalCost)
- **Avg User Rating**: $(" {0:N1} / 5.0" -f $avgRating) ($($feedback.Count) votes)

## Cost by Provider
| Provider | Cost (USD) |
|----------|------------|
"@

foreach ($k in $costByProvider.Keys) {
    $md += "| $k | $("`$"+"{0:N4}" -f $costByProvider[$k]) |`n"
}

$md += @"

## Recent Feedback
| RunID | Rating | Comment |
|-------|--------|---------|
"@

$recentFeedback = $feedback | Sort-Object timestamp -Descending | Select-Object -First 10
foreach ($f in $recentFeedback) {
    $comment = if ($f.comment) { $f.comment.Replace("|", "-") } else { "" }
    $md += "| $($f.runId) | $($f.rating) | $comment |`n"
}

$md | Set-Content -Path $reportFile -Encoding utf8

Write-Host "Report generated: $reportFile" -ForegroundColor Green
$md
