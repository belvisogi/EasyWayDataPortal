Param(
  [string]$Intent = "pipeline-run",
  [string]$Actor = "agent_governance",
  [string]$Env = "dev",
  [string]$Outcome = "OK",
  [string[]]$Refs,
  [string[]]$Artifacts,
  [string]$Notes
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $MyInvocation.MyCommand.Path | Split-Path -Parent
$eventsPath = Join-Path $root 'agents/logs/events.jsonl'
$wikiLogPath = Join-Path $root 'Wiki/EasyWayData.wiki/ACTIVITY_LOG.md'

if (-not (Test-Path $eventsPath)) { New-Item -ItemType Directory -Force -Path (Split-Path $eventsPath -Parent) | Out-Null; New-Item -ItemType File -Force -Path $eventsPath | Out-Null }

$obj = [ordered]@{
  ts = (Get-Date).ToUniversalTime().ToString('o');
  actor = $Actor;
  intent = $Intent;
  env = $Env;
  outcome = $Outcome;
  refs = $Refs;
  artifacts = $Artifacts;
  notes = $Notes;
  build = [ordered]@{
    branch = $env:BUILD_SOURCEBRANCH;
    commit = $env:BUILD_SOURCEVERSION;
    buildNumber = $env:BUILD_BUILDNUMBER;
    repo = $env:BUILD_REPOSITORY_NAME;
  }
}

$line = ($obj | ConvertTo-Json -Depth 6 -Compress)
Add-Content -Path $eventsPath -Value $line
Write-Host "Appended activity event to $eventsPath" -ForegroundColor Cyan

# Generate human-friendly markdown log
$lines = Get-Content $eventsPath | Where-Object { $_ -and $_.Trim().Length -gt 0 }
$events = @()
foreach ($l in $lines) { try { $events += ($l | ConvertFrom-Json) } catch {} }

$md = @()
$md += "---"
$md += "id: ew-activity-log"
$md += "title: Activity Log"
$md += "summary: Diario di bordo automatico (pipeline/agents)"
$md += "status: draft"
$md += "owner: team-platform"
$md += "tags: [activity, audit, privacy/internal, language/it]"
$md += "---"
$md += ""
$md += "| Timestamp (UTC) | Actor | Intent | Env | Outcome | Refs | Artifacts | Notes |"
$md += "| --- | --- | --- | --- | --- | --- | --- | --- |"
foreach ($e in ($events | Sort-Object { $_.ts } -Descending)) {
  $refsStr = ($e.refs -join '<br>')
  $artStr = ($e.artifacts -join '<br>')
  $notesStr = ($e.notes)
  $md += "| $($e.ts) | $($e.actor) | $($e.intent) | $($e.env) | $($e.outcome) | $refsStr | $artStr | $notesStr |"
}

$md | Set-Content -Encoding UTF8 $wikiLogPath
Write-Host "Updated $wikiLogPath" -ForegroundColor Green

