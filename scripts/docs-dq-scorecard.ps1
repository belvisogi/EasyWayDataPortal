param(
  [string]$WikiPath = "Wiki/EasyWayData.wiki",
  [string]$OutScorecard = "out/docs-dq-scorecard.json",
  [string]$OutBacklog = "out/docs-dq-backlog.json",
  [string]$OutQuestBoardPreview = "out/docs-dq-quest-board.preview.md",
  [string]$QuestBoardPath = "Wiki/EasyWayData.wiki/quest-board-docs-dq.md",
  [int]$MaxCards = 60,
  [switch]$UpdateQuestBoard,
  [switch]$NonInteractive,
  [switch]$WhatIf,
  [switch]$FailOnError
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Ensure-ParentDir([string]$path) {
  $dir = Split-Path -Parent $path
  if ([string]::IsNullOrWhiteSpace($dir)) { return }
  New-Item -ItemType Directory -Force -Path $dir | Out-Null
}

function New-TempFile([string]$prefix, [string]$ext) {
  $base = $env:RUNNER_TEMP
  if ([string]::IsNullOrWhiteSpace($base)) { $base = $env:TEMP }
  if ([string]::IsNullOrWhiteSpace($base)) { $base = (Get-Location).Path }
  $name = "$prefix-$([Guid]::NewGuid().ToString('N'))$ext"
  return (Join-Path $base $name)
}

function Read-Json([string]$p) {
  Write-Host "Reading JSON: $p"
  if (-not (Test-Path -LiteralPath $p)) { throw "JSON not found: $p" }
  return (Get-Content -LiteralPath $p -Raw | ConvertFrom-Json)
}

function Write-Utf8([string]$path, [string]$text) {
  Ensure-ParentDir $path
  Set-Content -LiteralPath $path -Value $text -Encoding utf8
}

function Get-RunId { return (Get-Date).ToString('yyyyMMdd-HHmmss') }

function Update-AutoSection {
  param(
    [string]$Text,
    [string]$AutoContent,
    [string]$StartMarker = '<!-- AUTO:START -->',
    [string]$EndMarker = '<!-- AUTO:END -->'
  )
  if ($null -eq $Text) { $Text = '' }
  $start = $Text.IndexOf($StartMarker, [System.StringComparison]::Ordinal)
  $end = $Text.IndexOf($EndMarker, [System.StringComparison]::Ordinal)
  if ($start -lt 0 -or $end -lt 0 -or $end -lt $start) {
    return ($Text.TrimEnd() + "`n`n$StartMarker`n$AutoContent`n$EndMarker`n")
  }
  $before = $Text.Substring(0, $start + $StartMarker.Length)
  $after = $Text.Substring($end)
  return ($before + "`n" + $AutoContent + "`n" + $after)
}

function New-Card {
  param(
    [string]$Type,
    [string]$Severity,
    [string]$Title,
    [string]$Description,
    [string[]]$Files,
    [string[]]$References
  )
  return [pscustomobject]@{
    id          = "{0}:{1}" -f $Type, ([Guid]::NewGuid().ToString('N').Substring(0, 8))
    type        = $Type
    severity    = $Severity
    title       = $Title
    description = $Description
    files       = @($Files | Where-Object { $_ } | Select-Object -Unique)
    references  = @($References | Where-Object { $_ } | Select-Object -Unique)
  }
}

if ($MaxCards -lt 1) { throw "MaxCards must be >= 1" }

$runId = Get-RunId
$tmpAgentReady = New-TempFile -prefix 'docs-dq-agent-ready' -ext '.json'
$tmpOrphansJson = New-TempFile -prefix 'docs-dq-orphans' -ext '.json'
$tmpOrphansDot = New-TempFile -prefix 'docs-dq-orphans' -ext '.dot'
$tmpOrphansMd = New-TempFile -prefix 'docs-dq-orphans' -ext '.md'
$tmpGap = New-TempFile -prefix 'docs-dq-gap' -ext '.json'

try {
  pwsh -NoProfile -File scripts/agent-ready-audit.ps1 -Mode all -SummaryOut $tmpAgentReady | Out-Null
  $agentReady = Read-Json $tmpAgentReady

  pwsh -NoProfile -File scripts/wiki-orphan-index.ps1 -WikiPath $WikiPath -OutJson $tmpOrphansJson -OutDot $tmpOrphansDot -OutMarkdown $tmpOrphansMd | Out-Null
  $orphans = Read-Json $tmpOrphansJson

  pwsh -NoProfile -File scripts/wiki-gap-report.ps1 -Path $WikiPath -SummaryOut $tmpGap | Out-Null
  $gap = Read-Json $tmpGap

  $agentErrors = @($agentReady.results | Where-Object { -not $_.ok -and $_.severity -eq 'error' })
  $agentWarnings = @($agentReady.results | Where-Object { -not $_.ok -and $_.severity -eq 'warning' })

  $gapFailures = @($gap.results | Where-Object { -not $_.ok })
  $orphansCount = @($orphans.orphans).Count

  $ok = ($agentErrors.Count -eq 0 -and $orphansCount -eq 0 -and $gapFailures.Count -eq 0)

  $score = 100
  $score -= [Math]::Min(40, $agentErrors.Count * 10)
  $score -= [Math]::Min(20, $orphansCount)
  $score -= [Math]::Min(20, [Math]::Ceiling($gapFailures.Count / 10.0))
  $score -= [Math]::Min(20, $agentWarnings.Count * 2)
  if ($score -lt 0) { $score = 0 }

  $scorecard = [pscustomobject]@{
    ok        = $ok
    score     = [int]$score
    runId     = $runId
    timestamp = (Get-Date).ToString('o')
    wikiPath  = $WikiPath.Replace([char]92, '/')
    metrics   = [pscustomobject]@{
      agentReady   = [pscustomobject]@{
        ok       = [bool]$agentReady.ok
        errors   = $agentErrors.Count
        warnings = $agentWarnings.Count
        checks   = [int]$agentReady.counts.checks
      }
      connectivity = [pscustomobject]@{
        nodes                = [int]$orphans.nodes
        edges                = [int]$orphans.edges
        components           = [int]$orphans.components
        largestComponentSize = [int]$orphans.largestComponentSize
        orphans              = $orphansCount
        noInbound            = @($orphans.noInbound).Count
        noOutbound           = @($orphans.noOutbound).Count
      }
      gapReport    = [pscustomobject]@{
        files    = [int]$gap.files
        failures = [int]$gap.failures
        counts   = $gap.counts
      }
    }
    notes     = @("Doc-as-Data Quality: regole + misure + remediation + kanban backlog.")
  }

  Ensure-ParentDir $OutScorecard
  $scorecard | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $OutScorecard -Encoding utf8

  $cards = New-Object System.Collections.Generic.List[object]

  foreach ($r in @($agentErrors | Select-Object -First 10)) {
    $cards.Add((New-Card `
          -Type 'gate' `
          -Severity 'error' `
          -Title ("Ripristinare check agent-ready: " + [string]$r.id) `
          -Description "Eseguire il gate indicato e correggere le violazioni (frontmatter/tags/link/WHAT-first/KB)." `
          -Files @() `
          -References @('Wiki/EasyWayData.wiki/docs-agentic-audit.md', 'scripts/agent-ready-audit.ps1'))) | Out-Null
  }

  if ($orphansCount -gt 0) {
    $sample = @($orphans.orphans | Select-Object -First 12)
    $cards.Add((New-Card `
          -Type 'connectivity' `
          -Severity 'warning' `
          -Title ("Collegare pagine isolate (orphans): {0}" -f $orphansCount) `
          -Description ("Ridurre degree=0 aggiungendo link in/out. Esempi: {0}" -f ($sample -join ', ')) `
          -Files @($sample) `
          -References @('Wiki/EasyWayData.wiki/orphans-index.md', 'Wiki/EasyWayData.wiki/docs-related-links.md', 'scripts/wiki-related-links.ps1'))) | Out-Null
  }

  $issueGroups = @()
  foreach ($f in $gapFailures) {
    foreach ($iss in @($f.issues)) {
      $issueGroups += [pscustomobject]@{ issue = [string]$iss; file = [string]$f.file }
    }
  }
  $grouped = @($issueGroups | Group-Object issue | Sort-Object Count -Descending)
  foreach ($g in $grouped) {
    if ($cards.Count -ge $MaxCards) { break }
    $files = @($g.Group | Select-Object -ExpandProperty file | Sort-Object -Unique | Select-Object -First 15)
    $sev = if ($g.Name -match '^missing_front_matter$') { 'error' } else { 'warning' }
    $cards.Add((New-Card `
          -Type 'gap' `
          -Severity $sev `
          -Title ("Fix gap: {0} ({1} file)" -f $g.Name, $g.Count) `
          -Description "Correggere il gap indicato secondo docs-agentic-audit (es. owner/summary/sezioni minime/draft hygiene)." `
          -Files $files `
          -References @('Wiki/EasyWayData.wiki/docs-agentic-audit.md', 'scripts/wiki-gap-report.ps1'))) | Out-Null
  }

  $backlog = [pscustomobject]@{
    ok        = $ok
    runId     = $runId
    timestamp = (Get-Date).ToString('o')
    maxCards  = $MaxCards
    cards     = @($cards.ToArray() | Select-Object -First $MaxCards)
  }
  Ensure-ParentDir $OutBacklog
  $backlog | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $OutBacklog -Encoding utf8

  $updated = (Get-Date).ToString('yyyy-MM-dd')
  $md = New-Object System.Text.StringBuilder
  [void]$md.AppendLine("## Snapshot DQ (auto) - $updated")
  [void]$md.AppendLine("")
  [void]$md.AppendLine("- Score: **$score** / 100")
  [void]$md.AppendLine("- Agent-ready errors: **$($agentErrors.Count)** | warnings: **$($agentWarnings.Count)**")
  [void]$md.AppendLine("- Connectivity: orphans **$orphansCount**, components **$($orphans.components)**, nodes **$($orphans.nodes)**, edges **$($orphans.edges)**")
  [void]$md.AppendLine("- Gap failures: **$($gap.failures)** su **$($gap.files)** file")
  [void]$md.AppendLine("")
  [void]$md.AppendLine("### Kanban (Backlog proposto)")
  [void]$md.AppendLine("")
  foreach ($c in @($backlog.cards)) {
    $refs = ''
    if ($c.references.Count -gt 0) { $refs = " (refs: " + ($c.references -join ', ') + ")" }
    [void]$md.AppendLine("- [ ] [$($c.severity)] $($c.title)$refs")
    if ($c.files.Count -gt 0) { [void]$md.AppendLine("  - files: " + ($c.files -join ', ')) }
  }
  [void]$md.AppendLine("")
  [void]$md.AppendLine("Artifacts:")
  [void]$md.AppendLine(('- `{0}`' -f $OutScorecard.Replace([char]92, '/')))
  [void]$md.AppendLine(('- `{0}`' -f $OutBacklog.Replace([char]92, '/')))

  $preview = $md.ToString()
  Write-Utf8 -path $OutQuestBoardPreview -text $preview

  if ($UpdateQuestBoard) {
    if ($WhatIf) {
      Write-Host "WhatIf: aggiornamento quest board saltato: $QuestBoardPath"
    }
    else {
      if (-not (Test-Path -LiteralPath $QuestBoardPath)) { throw "QuestBoardPath not found: $QuestBoardPath" }
      $existing = Get-Content -LiteralPath $QuestBoardPath -Raw -Encoding UTF8
      $newText = Update-AutoSection -Text $existing -AutoContent $preview

      $applyDir = Join-Path 'out' ("docs-dq-scorecard-apply/{0}" -f $runId)
      Ensure-ParentDir $applyDir
      $backup = Join-Path $applyDir 'quest-board-docs-dq.md.bak'
      Write-Utf8 -path $backup -text $existing
      Write-Utf8 -path $QuestBoardPath -text $newText

      $applySummary = [pscustomobject]@{
        ok             = $true
        runId          = $runId
        questBoardPath = $QuestBoardPath.Replace([char]92, '/')
        backup         = $backup.Replace([char]92, '/')
        preview        = $OutQuestBoardPreview.Replace([char]92, '/')
      }
      $applySummary | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $applyDir 'apply-summary.json') -Encoding utf8
    }
  }

  $out = [pscustomobject]@{
    ok                   = $ok
    score                = [int]$score
    scorecardOut         = $OutScorecard.Replace([char]92, '/')
    backlogOut           = $OutBacklog.Replace([char]92, '/')
    questBoardPreviewOut = $OutQuestBoardPreview.Replace([char]92, '/')
    runId                = $runId
  }
  $json = $out | ConvertTo-Json -Depth 6
  Write-Output $json
  if ($FailOnError -and -not $ok) { exit 1 }
}
finally {
  foreach ($p in @($tmpAgentReady, $tmpOrphansJson, $tmpOrphansDot, $tmpOrphansMd, $tmpGap)) {
    if ($p -and (Test-Path -LiteralPath $p)) { Remove-Item -Force -LiteralPath $p -ErrorAction SilentlyContinue }
  }
}

