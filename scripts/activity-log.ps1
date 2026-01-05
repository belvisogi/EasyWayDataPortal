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
$logsDir = Join-Path $root 'agents/logs'
$monthTag = (Get-Date).ToUniversalTime().ToString('yyyyMM')
$eventsPath = Join-Path $logsDir ("events-" + $monthTag + ".jsonl")
$wikiLogPath = Join-Path $root 'Wiki/EasyWayData.wiki/activity-log.md'

if (-not (Test-Path $eventsPath)) { New-Item -ItemType Directory -Force -Path $logsDir | Out-Null; New-Item -ItemType File -Force -Path $eventsPath | Out-Null }

$notesPlus = $Notes
$verReport = Join-Path $root 'versions-report.txt'
if (Test-Path $verReport) {
  try {
    $verText = Get-Content $verReport -Raw
    # Evita note troppo lunghe: tronca a 2000 caratteri
    if ($verText.Length -gt 2000) { $verText = $verText.Substring(0,2000) + "\n...[truncated]" }
    if ([string]::IsNullOrWhiteSpace($notesPlus)) { $notesPlus = "" }
    $notesPlus = ($notesPlus + "`nVersions Report:`n" + $verText).Trim()
  } catch {}
}

$obj = [ordered]@{
  ts = (Get-Date).ToUniversalTime().ToString('o');
  actor = $Actor;
  intent = $Intent;
  env = if ($Env) { $Env } else { $env:ENVIRONMENT };
  outcome = $Outcome;
  refs = $Refs;
  artifacts = $Artifacts;
  notes = $notesPlus;
  govApproved = ($env:GOV_APPROVED);
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

# Generate human-friendly markdown log (aggregate all monthly files)
$events = @()
Get-ChildItem $logsDir -Filter 'events-*.jsonl' | ForEach-Object {
  $lines = Get-Content $_.FullName | Where-Object { $_ -and $_.Trim().Length -gt 0 }
  foreach ($l in $lines) { try { $events += ($l | ConvertFrom-Json) } catch {} }
}

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
$md += "| Timestamp (UTC) | Actor | Intent | Env | Outcome | Gov | Refs | Artifacts | Notes |"
$md += "| --- | --- | --- | --- | --- | --- | --- | --- | --- |"
foreach ($e in ($events | Sort-Object { $_.ts } -Descending)) {
  $refsStr = ($e.refs -join '<br>')
  $artStr = ($e.artifacts -join '<br>')
  $notesStr = ($e.notes)
  $gov = ("" + $e.govApproved)
  $govBadge = if ($gov -and $gov.ToLower() -eq 'true') { '✅' } else { '' }
  $md += "| $($e.ts) | $($e.actor) | $($e.intent) | $($e.env) | $($e.outcome) | $govBadge | $refsStr | $artStr | $notesStr |"
}

$md | Set-Content -Encoding UTF8 $wikiLogPath
Write-Host "Updated $wikiLogPath" -ForegroundColor Green
