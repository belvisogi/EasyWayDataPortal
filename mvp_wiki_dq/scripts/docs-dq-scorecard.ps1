param(
  [string]$WikiPath = "wiki",
  [string]$OutScorecard = "out/scorecard.wiki.json",
  [string]$OutBacklog = "out/backlog.wiki.json",
  [string]$OutPreview = "out/board.preview.md",
  [string]$BoardPath = "wiki/board.wiki.md",
  [int]$MaxCards = 60,
  [switch]$RequireTagFacets,
  [switch]$UpdateBoard,
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

function Write-Utf8([string]$path, [string]$text) {
  Ensure-ParentDir $path
  Set-Content -LiteralPath $path -Value $text -Encoding utf8
}

function Get-RunId { return (Get-Date).ToString('yyyyMMdd-HHmmss') }

function Update-AutoSection([string]$Text, [string]$AutoContent) {
  $StartMarker = '<!-- AUTO:START -->'
  $EndMarker = '<!-- AUTO:END -->'
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

function New-Card([string]$Type,[string]$Severity,[string]$Title,[string]$Description,[string[]]$Files) {
  return [pscustomobject]@{
    id = "${Type}:$([Guid]::NewGuid().ToString('N').Substring(0,8))"
    type = $Type
    severity = $Severity
    title = $Title
    description = $Description
    files = @($Files | Where-Object { $_ } | Select-Object -Unique)
  }
}

$runId = Get-RunId
Ensure-ParentDir $OutScorecard
Ensure-ParentDir $OutBacklog
Ensure-ParentDir $OutPreview

$g = (pwsh -NoProfile -File scripts/wiki-orphans.ps1 -WikiPath $WikiPath -OutJson "out/graph.$runId.json" -OutMd "wiki/orphans.md" -OutDot "out/graph.$runId.dot") | ConvertFrom-Json
$gap = (pwsh -NoProfile -File scripts/wiki-gap.ps1 -Path $WikiPath -SummaryOut "out/gap.$runId.json") | ConvertFrom-Json
$links = (pwsh -NoProfile -File scripts/wiki-links.ps1 -Path $WikiPath -SummaryOut "out/links.$runId.json") | ConvertFrom-Json
$tags = (pwsh -NoProfile -File scripts/wiki-tags.ps1 -Path $WikiPath -TaxonomyPath "config/tag-taxonomy.json" -RequireFacets:([bool]$RequireTagFacets) -SummaryOut "out/tags.$runId.json") | ConvertFrom-Json

$orphans = @($g.orphans).Count
$gapFailures = [int]$gap.failures
$linkIssues = [int]$links.issues
$tagFailures = [int]$tags.failures
$ok = ($orphans -eq 0 -and $gapFailures -eq 0 -and $linkIssues -eq 0 -and $tagFailures -eq 0)

$score = 100
$score -= [Math]::Min(30, $orphans)
$score -= [Math]::Min(40, [Math]::Ceiling($gapFailures / 10.0) * 10)
$score -= [Math]::Min(30, [Math]::Ceiling($linkIssues / 5.0) * 5)
$score -= [Math]::Min(20, [Math]::Ceiling($tagFailures / 5.0) * 5)
if ($score -lt 0) { $score = 0 }

$scorecard = [pscustomobject]@{
  ok = $ok
  score = [int]$score
  runId = $runId
  timestamp = (Get-Date).ToString('o')
  metrics = [pscustomobject]@{
    orphans = $orphans
    gapFailures = $gapFailures
    linkIssues = $linkIssues
    tagFailures = $tagFailures
  }
  artifacts = [pscustomobject]@{
    graph = ("out/graph.$runId.json")
    gap = ("out/gap.$runId.json")
    links = ("out/links.$runId.json")
    tags = ("out/tags.$runId.json")
  }
}
($scorecard | ConvertTo-Json -Depth 6) | Set-Content -LiteralPath $OutScorecard -Encoding utf8

$cards = New-Object System.Collections.Generic.List[object]
if ($orphans -gt 0) { $cards.Add((New-Card 'connectivity' 'warning' "Collegare orfani: $orphans" 'Aggiungere link in/out e rigenerare.' (@($g.orphans | Select-Object -First 12)))) | Out-Null }
if ($gapFailures -gt 0) { $cards.Add((New-Card 'metadata' 'warning' "Fix gap metadata: $gapFailures file" 'Aggiungere owner/summary (frontmatter).' (@($gap.results | Where-Object { -not $_.ok } | Select-Object -First 12 | ForEach-Object { $_.file })))) | Out-Null }
if ($linkIssues -gt 0) { $cards.Add((New-Card 'links' 'error' "Fix link/anchor: $linkIssues issue" 'Correggere link rotti/anchor.' (@($links.results | Select-Object -First 12 | ForEach-Object { $_.file })))) | Out-Null }
if ($tagFailures -gt 0) { $cards.Add((New-Card 'tags' 'warning' "Fix tags/taxonomy: $tagFailures file" 'Aggiungere tags e facets (domain/layer/audience/privacy/language).' (@($tags.results | Where-Object { -not $_.ok } | Select-Object -First 12 | ForEach-Object { $_.file })))) | Out-Null }

$backlog = [pscustomobject]@{ ok=$ok; runId=$runId; timestamp=(Get-Date).ToString('o'); cards=@($cards.ToArray() | Select-Object -First $MaxCards) }
($backlog | ConvertTo-Json -Depth 6) | Set-Content -LiteralPath $OutBacklog -Encoding utf8

$today = (Get-Date).ToString('yyyy-MM-dd')
$sb = New-Object System.Text.StringBuilder
[void]$sb.AppendLine("## Snapshot DQ (auto) - $today")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("- Score: **$score** / 100")
[void]$sb.AppendLine("- Orphans: **$orphans** | Link issues: **$linkIssues** | Gap failures: **$gapFailures** | Tag failures: **$tagFailures**")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("### Backlog")
foreach ($c in @($backlog.cards)) {
  [void]$sb.AppendLine("- [ ] [$($c.severity)] $($c.title)")
  if ($c.files.Count -gt 0) { [void]$sb.AppendLine("  - files: " + ($c.files -join ', ')) }
}
$preview = $sb.ToString()
Write-Utf8 -path $OutPreview -text $preview

if ($UpdateBoard) {
  if ($WhatIf) {
    Write-Host "WhatIf: update skipped: $BoardPath"
  } else {
    if (-not (Test-Path -LiteralPath $BoardPath)) { throw "BoardPath not found: $BoardPath" }
    $existing = Get-Content -LiteralPath $BoardPath -Raw -Encoding UTF8
    $newText = Update-AutoSection -Text $existing -AutoContent $preview
    $applyDir = Join-Path 'out' ("apply/$runId")
    Ensure-ParentDir $applyDir
    Write-Utf8 -path (Join-Path $applyDir 'board.bak.md') -text $existing
    Write-Utf8 -path $BoardPath -text $newText
  }
}

$out = [pscustomobject]@{ ok=$ok; score=[int]$score; scorecardOut=$OutScorecard; backlogOut=$OutBacklog; previewOut=$OutPreview; runId=$runId }
Write-Output ($out | ConvertTo-Json -Depth 5)
if ($FailOnError -and -not $ok) { exit 1 }
