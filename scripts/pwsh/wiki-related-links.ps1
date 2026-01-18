param(
  [string]$WikiPath = "Wiki/EasyWayData.wiki",
  [string[]]$ExcludePaths = @('logs/reports', 'old', '.attachments', '.obsidian'),
  [int]$TopK = 7,
  [switch]$Apply,
  [switch]$WhatIf = $true,
  [switch]$NonInteractive,
  [ValidateSet('orphans-only','all')]
  [string]$ApplyScope = 'orphans-only',
  [double]$MinScore = 0.35,
  [int]$MaxLinksToAdd = 5,
  [string]$SeeAlsoHeading = '## Vedi anche',
  [int]$MaxTermsPerDoc = 500,
  [int]$MinTokenLen = 3,
  [string]$OutJson = "out/wiki-related-links.suggestions.json",
  [string]$ApplyOutDir = "out/wiki-related-links-apply",
  [string]$LinkGraphJson = "out/wiki-link-graph.EasyWayData.wiki.json",
  [switch]$IncludeDebugTerms,
  [switch]$FailOnError
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if ($ExcludePaths.Count -eq 1 -and $ExcludePaths[0] -match ',') {
  $ExcludePaths = @($ExcludePaths[0].Split(',') | ForEach-Object { $_.Trim() } | Where-Object { $_ })
}

function Ensure-ParentDir([string]$path) {
  $dir = Split-Path -Parent $path
  if ([string]::IsNullOrWhiteSpace($dir)) { return }
  New-Item -ItemType Directory -Force -Path $dir | Out-Null
}

function Escape-LinkTarget([string]$relPath) {
  if ($null -eq $relPath) { return '' }
  return ($relPath `
    -replace '\(', '%28' `
    -replace '\)', '%29' `
    -replace '\+', '%2B' `
    -replace ' ', '%20')
}

function Strip-Code([string]$text) {
  if ($null -eq $text) { return '' }
  $t = [regex]::Replace($text, '(?s)```.*?```', '')
  $t = [regex]::Replace($t, '`[^`]*`', '')
  return $t
}

function Rel([string]$root, [string]$fullName) {
  $rel = $fullName.Substring($root.Length)
  $rel = $rel.TrimStart([char]92, [char]47)
  return $rel.Replace([char]92, [char]47)
}

function Get-DirRel([string]$pathRel) {
  if ([string]::IsNullOrWhiteSpace($pathRel)) { return '' }
  $i = $pathRel.LastIndexOf('/')
  if ($i -lt 0) { return '.' }
  return $pathRel.Substring(0, $i)
}

function Get-RelLink([string]$fromRel, [string]$toRel) {
  # fromRel/toRel are repo-relative within WikiPath (e.g. 'foo/bar.md')
  $fromDir = Split-Path -Parent ($fromRel -replace '/', [IO.Path]::DirectorySeparatorChar)
  if ([string]::IsNullOrWhiteSpace($fromDir)) { $fromDir = '.' }
  $fromFull = Join-Path $root $fromDir
  $toFull = Join-Path $root ($toRel -replace '/', [IO.Path]::DirectorySeparatorChar)
  $rel = [IO.Path]::GetRelativePath($fromFull, $toFull)
  $rel = $rel.Replace([char]92, [char]47)
  if (-not ($rel.StartsWith('.') -or $rel.StartsWith('/'))) { $rel = './' + $rel }
  return (Escape-LinkTarget $rel)
}

function Parse-FrontMatter([string]$content) {
  # Returns: @{ title=?; summary=?; tags=@() }
  $res = @{ title = $null; summary = $null; tags = @() }
  if (-not $content.StartsWith("---")) { return $res }
  $end = $content.IndexOf("`n---", 3)
  if ($end -lt 0) { return $res }

  $fm = $content.Substring(3, $end - 3)
  foreach ($line in ($fm -split "`r?`n")) {
    $l = $line.Trim()
    if ($l -match '^(title)\s*:\s*(.+)$') { $res.title = $Matches[2].Trim().Trim('"') ; continue }
    if ($l -match '^(summary)\s*:\s*(.+)$') { $res.summary = $Matches[2].Trim().Trim('"') ; continue }
    if ($l -match '^tags\s*:\s*\[(.*)\]\s*$') {
      $inner = $Matches[1]
      $tags = @()
      foreach ($t in ($inner -split ',')) {
        $x = $t.Trim().Trim('"').Trim("'")
        if ($x) { $tags += $x }
      }
      $res.tags = $tags
      continue
    }
  }
  return $res
}

function Tokenize([string]$text, [int]$minLen) {
  if ([string]::IsNullOrWhiteSpace($text)) { return @() }
  $t = $text.ToLowerInvariant()
  $t = $t -replace '[^a-z0-9àèéìòù_\- ]', ' '
  $t = $t -replace '\s+', ' '
  $raw = $t.Split(' ', [System.StringSplitOptions]::RemoveEmptyEntries)

  $stop = @(
    # IT
    'il','lo','la','i','gli','le','un','uno','una','di','del','dello','della','dei','degli','delle',
    'a','ad','da','dal','dallo','dalla','dai','dagli','dalle','in','con','su','per','tra','fra',
    'e','ed','o','od','ma','che','come','se','non','si','piu','più','meno','anche','solo','tutto','tutti',
    'questa','questo','questi','quelle','quelli','quale','quali','quando','dove','perche','perché',
    # EN
    'the','a','an','and','or','but','to','of','in','on','for','with','by','is','are','be','as','at','from','it',
    'this','that','these','those','how','why','what','when','where'
  ) | ForEach-Object { $_.ToLowerInvariant() }
  $stopSet = [System.Collections.Generic.HashSet[string]]::new()
  foreach ($s in $stop) { if ($s) { $stopSet.Add($s) | Out-Null } }

  $tokensOut = New-Object System.Collections.Generic.List[string]
  foreach ($w in $raw) {
    if ($w.Length -lt $minLen) { continue }
    if ($stopSet.Contains($w)) { continue }
    $tokensOut.Add($w)
  }
  return @($tokensOut)
}

function Build-TF([string[]]$tokens, [int]$maxTerms) {
  $map = @{}
  foreach ($t in $tokens) {
    if ($map.ContainsKey($t)) { $map[$t] = $map[$t] + 1 } else { $map[$t] = 1 }
  }
  if ($map.Count -le $maxTerms) { return $map }
  # keep top maxTerms
  $top = $map.GetEnumerator() | Sort-Object Value -Descending | Select-Object -First $maxTerms
  $trim = @{}
  foreach ($kv in $top) { $trim[$kv.Key] = [int]$kv.Value }
  return $trim
}

function Cosine([hashtable]$vecA, [double]$normA, [hashtable]$vecB, [double]$normB) {
  if ($normA -le 0.0 -or $normB -le 0.0) { return 0.0 }
  # iterate over smaller map
  $dot = 0.0
  $aSmall = $vecA; $bBig = $vecB
  if ($vecB.Count -lt $vecA.Count) { $aSmall = $vecB; $bBig = $vecA }
  foreach ($kv in $aSmall.GetEnumerator()) {
    $k = $kv.Key
    if ($bBig.ContainsKey($k)) { $dot += [double]$kv.Value * [double]$bBig[$k] }
  }
  return $dot / ($normA * $normB)
}

$root = (Resolve-Path -LiteralPath $WikiPath).Path
$excludePrefixes = @()
foreach ($e in $ExcludePaths) {
  if ([string]::IsNullOrWhiteSpace($e)) { continue }
  $full = [IO.Path]::GetFullPath((Join-Path $root $e))
  if (-not $full.EndsWith([IO.Path]::DirectorySeparatorChar)) {
    $full = $full + [IO.Path]::DirectorySeparatorChar
  }
  $excludePrefixes += $full
}

function Is-Excluded([string]$fullName) {
  foreach ($p in $excludePrefixes) {
    if ($fullName.StartsWith($p, [StringComparison]::OrdinalIgnoreCase)) { return $true }
  }
  return $false
}

$files = Get-ChildItem -LiteralPath $root -Recurse -Filter *.md -File |
  Where-Object { -not (Is-Excluded -fullName $_.FullName) }

if ($files.Count -lt 2) {
  $msg = "Not enough markdown files under $WikiPath"
  if ($FailOnError) { throw $msg } else { Write-Warning $msg; exit 0 }
}

# Collect doc metadata + tokens
$docs = New-Object System.Collections.Generic.List[object]
foreach ($f in $files) {
  $rel = Rel $root $f.FullName
  $content = Get-Content -LiteralPath $f.FullName -Raw -Encoding UTF8
  $fm = Parse-FrontMatter $content

  $scan = Strip-Code $content
  # prefer title/summary + headings; limit body to keep perf stable
  $body = $scan
  if ($body.Length -gt 20000) { $body = $body.Substring(0, 20000) }
  $text = @(
    $fm.title,
    $fm.summary,
    ($fm.tags -join ' '),
    $body
  ) -join "`n"

  $tokens = Tokenize -text $text -minLen $MinTokenLen
  $tf = Build-TF -tokens $tokens -maxTerms $MaxTermsPerDoc

  $docs.Add([pscustomobject]@{
    path = $rel
    dir = (Get-DirRel $rel)
    title = ($fm.title ?? [IO.Path]::GetFileNameWithoutExtension($rel))
    summary = $fm.summary
    tags = @($fm.tags)
    tf = $tf
  }) | Out-Null
}

$N = $docs.Count

# Document frequency
$df = @{}
foreach ($d in $docs) {
  foreach ($k in $d.tf.Keys) {
    if ($df.ContainsKey($k)) { $df[$k] = $df[$k] + 1 } else { $df[$k] = 1 }
  }
}

# Build tf-idf vectors + norms
foreach ($d in $docs) {
  $vec = @{}
  $sumSq = 0.0
  foreach ($kv in $d.tf.GetEnumerator()) {
    $term = $kv.Key
    $tfv = [double]$kv.Value
    $dfv = [double]$df[$term]
    $idf = [Math]::Log(($N + 1.0) / ($dfv + 1.0)) + 1.0
    $w = $tfv * $idf
    $vec[$term] = $w
    $sumSq += ($w * $w)
  }
  $d | Add-Member -NotePropertyName vec -NotePropertyValue $vec -Force
  $d | Add-Member -NotePropertyName norm -NotePropertyValue ([Math]::Sqrt($sumSq)) -Force
  if ($IncludeDebugTerms) {
    $topTerms = $vec.GetEnumerator() | Sort-Object Value -Descending | Select-Object -First 20 | ForEach-Object { $_.Key }
    $d | Add-Member -NotePropertyName debugTopTerms -NotePropertyValue @($topTerms) -Force
  }
  $d.PSObject.Properties.Remove('tf') | Out-Null
}

function Tags-Overlap([object]$a, [object]$b) {
  if (-not $a.tags -or -not $b.tags) { return 0 }
  $set = [System.Collections.Generic.HashSet[string]]::new()
  foreach ($t in $a.tags) { if ($t) { $set.Add($t.ToLowerInvariant()) | Out-Null } }
  $n = 0
  foreach ($t in $b.tags) { if ($t -and $set.Contains($t.ToLowerInvariant())) { $n++ } }
  return $n
}

function Score([object]$a, [object]$b) {
  $cos = Cosine -vecA $a.vec -normA $a.norm -vecB $b.vec -normB $b.norm
  $tagOv = Tags-Overlap $a $b
  $sameDir = if ($a.dir -eq $b.dir) { 1 } else { 0 }
  $sameTop = if (($a.dir.Split('/')[0]) -and (($a.dir.Split('/')[0]) -eq ($b.dir.Split('/')[0]))) { 1 } else { 0 }
  # Heuristics: keep cosine as main signal; small boosts for tags and directory proximity
  return ($cos + (0.08 * $tagOv) + (0.04 * $sameDir) + (0.02 * $sameTop))
}

# --- Apply helpers (human-in-the-loop + reversible) ---
function Get-OrphansFromGraph([string]$graphJsonPath) {
  if (-not (Test-Path -LiteralPath $graphJsonPath)) { return $null }
  try {
    $obj = Get-Content -LiteralPath $graphJsonPath -Raw -Encoding UTF8 | ConvertFrom-Json
    if ($null -eq $obj.orphans) { return $null }
    return @($obj.orphans | ForEach-Object { [string]$_ })
  } catch { return $null }
}

function Find-HeadingBlock([string]$content, [string]$headingLine) {
  # Returns @{ found=$bool; start=$int; end=$int } with indexes in lines array
  $lines = $content -split "\r?\n"
  $target = $headingLine.Trim()
  $start = -1
  for ($i = 0; $i -lt $lines.Length; $i++) {
    if ($lines[$i].Trim() -ieq $target) { $start = $i; break }
  }
  if ($start -lt 0) { return @{ found = $false; lines = $lines } }
  $end = $lines.Length
  for ($j = $start + 1; $j -lt $lines.Length; $j++) {
    if ($lines[$j] -match '^\s*##\s+') { $end = $j; break }
  }
  return @{ found = $true; start = $start; end = $end; lines = $lines }
}

function Extract-ExistingLinkTargets([string]$content) {
  $targets = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
  $scan = Strip-Code $content
  $matches = [regex]::Matches($scan, "\[[^\]]*\]\(([^\)]+)\)")
  foreach ($m in $matches) {
    $raw = $m.Groups[1].Value.Trim()
    if (-not $raw) { continue }
    if ($raw -match '^(https?:|mailto:|data:)') { continue }
    $t = $raw
    if ($t.Contains('#')) { $t = $t.Substring(0, $t.IndexOf('#')) }
    $rawNoAnchor = $t.Trim()
    if ($rawNoAnchor) { $targets.Add($rawNoAnchor) | Out-Null }

    $t = [System.Uri]::UnescapeDataString($t).Trim()
    if (-not $t) { continue }
    $targets.Add($t) | Out-Null

    # also store an encoded form to de-dup vs newly generated links
    $targets.Add((Escape-LinkTarget $t)) | Out-Null
  }
  return $targets
}

function Apply-SeeAlsoLinks {
  param(
    [string]$docRelPath,
    [string]$docFullPath,
    [object[]]$candidates,
    [string]$headingLine,
    [int]$maxAdd,
    [double]$minScore
  )

  $content = Get-Content -LiteralPath $docFullPath -Raw -Encoding UTF8
  $existing = Extract-ExistingLinkTargets $content
  if ($null -eq $existing) {
    $existing = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
  }

  $toAdd = New-Object System.Collections.Generic.List[object]
  foreach ($c in $candidates) {
    if ($toAdd.Count -ge $maxAdd) { break }
    if ($null -eq $c -or $null -eq $c.path) { continue }
    if ([double]$c.score -lt $minScore) { continue }

    $relTarget = [string]$c.path
    $link = Get-RelLink -fromRel $docRelPath -toRel $relTarget
    if ($existing.Contains($link)) { continue }

    $title = if ($c.title) { [string]$c.title } else { [IO.Path]::GetFileNameWithoutExtension($relTarget) }
    $toAdd.Add([pscustomobject]@{ title = $title; path = $relTarget; link = $link; score = [double]$c.score }) | Out-Null
  }

  if ($toAdd.Count -eq 0) { return [pscustomobject]@{ changed = $false; added = @(); reason = 'no_candidates' } }

  $addedArray = $null
  try { $addedArray = [object[]]$toAdd.ToArray() } catch { $addedArray = [object[]]@($toAdd) }

  $block = Find-HeadingBlock -content $content -headingLine $headingLine
  $lines = $block.lines

  $insertLines = @()
  foreach ($a in $toAdd) {
    $insertLines += ('- [' + $a.title + '](' + $a.link + ')')
  }

  if (-not $block.found) {
    # append at end
    $newLines = @($lines + '' + $headingLine + '' + $insertLines)
    $new = ($newLines -join "`n").TrimEnd() + "`n"
    return [pscustomobject]@{ changed = $true; content = $new; added = $addedArray ; where = 'append' }
  }

  # insert inside existing block, before next H2 or EOF
  $start = [int]$block.start
  $end = [int]$block.end
  $prefix = @($lines[0..($end - 1)])
  $suffix = @()
  if ($end -lt $lines.Length) { $suffix = @($lines[$end..($lines.Length - 1)]) }

  # ensure empty line after heading
  if ($start + 1 -lt $prefix.Length -and -not [string]::IsNullOrWhiteSpace($prefix[$start + 1])) {
    $prefix = @($lines[0..$start] + '' + $lines[($start + 1)..($end - 1)])
  }

  $newLines = @($prefix + $insertLines + $suffix)
  $new = ($newLines -join "`n").TrimEnd() + "`n"
  return [pscustomobject]@{ changed = $true; content = $new; added = $addedArray; where = 'existing_block' }
}

# Suggestions
$suggestions = New-Object System.Collections.Generic.List[object]
for ($i = 0; $i -lt $docs.Count; $i++) {
  $a = $docs[$i]
  $cands = New-Object System.Collections.Generic.List[object]
  for ($j = 0; $j -lt $docs.Count; $j++) {
    if ($i -eq $j) { continue }
    $b = $docs[$j]
    $s = Score $a $b
    if ($s -le 0.0) { continue }
    $cands.Add([pscustomobject]@{
      path = $b.path
      title = $b.title
      score = [Math]::Round($s, 4)
      tagOverlap = (Tags-Overlap $a $b)
      sameDir = ($a.dir -eq $b.dir)
    }) | Out-Null
  }
  $top = $cands | Sort-Object score -Descending | Select-Object -First $TopK
  $suggestions.Add([pscustomobject]@{
    path = $a.path
    title = $a.title
    tags = @($a.tags)
    suggestions = @($top)
  }) | Out-Null
}

$report = [ordered]@{}
$report['ok'] = $true
$report['generatedAt'] = (Get-Date).ToString('o')
$report['wikiPath'] = $WikiPath.Replace([char]92, [char]47)
$report['excluded'] = @($ExcludePaths)
$report['docs'] = $docs.Count
$report['topK'] = $TopK
$report['method'] = @{
  primary = 'tf-idf cosine similarity'
  boosts = @('tag overlap', 'same directory', 'same top-level directory')
  notes = @(
    'Suggestions only; no file modifications performed.',
    'Use the report to add manual cross-links (e.g., a "Vedi anche" section) or to update section indexes.'
  )
}
$resultsArray = $null
try {
  # Ensure we store a plain array (stable for JSON conversion)
  $resultsArray = [object[]]$suggestions.ToArray()
} catch {
  $resultsArray = [object[]]@($suggestions)
}
$report['results'] = $resultsArray

Ensure-ParentDir $OutJson
$report | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $OutJson -Encoding UTF8
Write-Output ($report | ConvertTo-Json -Depth 6)

if (-not $Apply) { exit 0 }

# APPLY phase (reversible)
$orphans = $null
if ($ApplyScope -eq 'orphans-only') {
  $orphans = Get-OrphansFromGraph -graphJsonPath $LinkGraphJson
  if ($null -eq $orphans -or $orphans.Count -eq 0) {
    Write-Warning "ApplyScope=orphans-only ma non trovo orfani in $LinkGraphJson. Esegui prima: pwsh scripts/wiki-orphan-index.ps1"
    exit 2
  }
}

$targets = @()
foreach ($r in $resultsArray) {
  if ($null -eq $r -or -not $r.path) { continue }
  $p = [string]$r.path
  if ($ApplyScope -eq 'orphans-only' -and -not ($orphans -contains $p)) { continue }
  $targets += $r
}

if ($targets.Count -eq 0) {
  Write-Host "Nessun target da aggiornare (scope=$ApplyScope)." -ForegroundColor Yellow
  exit 0
}

$plan = $targets | ForEach-Object {
  [pscustomobject]@{
    path = $_.path
    suggestions = @($_.suggestions | Where-Object { $_.score -ge $MinScore } | Select-Object -First $MaxLinksToAdd)
  }
}

Write-Host "`n== Related links apply plan ==" -ForegroundColor Cyan
Write-Host ("scope={0} whatIf={1} minScore={2} maxLinks={3} targets={4}" -f $ApplyScope, [bool]$WhatIf, $MinScore, $MaxLinksToAdd, $targets.Count)
foreach ($p in ($plan | Select-Object -First 20)) {
  $n = if ($p.suggestions) { $p.suggestions.Count } else { 0 }
  Write-Host ("- {0}: +{1} links" -f $p.path, $n)
}
if ($plan.Count -gt 20) { Write-Host ("... +{0} altri" -f ($plan.Count - 20)) }

# Human-in-the-loop: chiedi conferma solo quando stai per scrivere i .md (WhatIf:$false)
if ((-not $NonInteractive) -and (-not $WhatIf)) {
  $ans = $null
  try { $ans = Read-Host "Procedo con apply (scrittura su file)? [y/N]" } catch { $ans = $null }
  if ([string]::IsNullOrWhiteSpace($ans) -or $ans.Trim().ToLowerInvariant() -ne 'y') {
    Write-Host "Apply annullato dall'utente." -ForegroundColor Yellow
    exit 0
  }
} elseif ((-not $NonInteractive) -and $WhatIf) {
  Write-Host "WhatIf attivo: eseguo preview senza richiesta conferma (nessuna scrittura dei .md)." -ForegroundColor Yellow
}

$runId = (Get-Date).ToString('yyyyMMdd-HHmmss')
$runDir = Join-Path $ApplyOutDir $runId
New-Item -ItemType Directory -Force -Path $runDir | Out-Null

$changes = New-Object System.Collections.Generic.List[object]
$hadErrors = $false

foreach ($t in $targets) {
  $docRel = [string]$t.path
  $docFull = Join-Path $root ($docRel -replace '/', [IO.Path]::DirectorySeparatorChar)
  if (-not (Test-Path -LiteralPath $docFull)) { continue }

  $applied = Apply-SeeAlsoLinks -docRelPath $docRel -docFullPath $docFull -candidates ([object[]]$t.suggestions) -headingLine $SeeAlsoHeading -maxAdd $MaxLinksToAdd -minScore $MinScore
  if (-not $applied.changed) { continue }

  $backupRel = ($docRel + '.bak')
  $backupFull = Join-Path $runDir ($backupRel -replace '/', [IO.Path]::DirectorySeparatorChar)
  Ensure-ParentDir $backupFull
  Copy-Item -LiteralPath $docFull -Destination $backupFull -Force
  $runDirFull = (Resolve-Path -LiteralPath $runDir).Path
  $backupFullResolved = (Resolve-Path -LiteralPath $backupFull).Path
  $backupRelOut = $backupFullResolved.Substring($runDirFull.Length).TrimStart([char]92, [char]47).Replace([char]92, [char]47)

  $changes.Add([pscustomobject]@{
    path = $docRel
    backup = $backupRelOut
    added = @($applied.added | ForEach-Object { @{ title=$_.title; path=$_.path; score=$_.score } })
  }) | Out-Null

  if ($WhatIf) { continue }
  try {
    Set-Content -LiteralPath $docFull -Value $applied.content -Encoding UTF8
  } catch {
    $hadErrors = $true
    Write-Warning ("Write failed for {0}: {1}" -f $docRel, $_.Exception.Message)
  }
}

$changesArray = $null
try { $changesArray = [object[]]$changes.ToArray() } catch { $changesArray = [object[]]@($changes) }

$applySummary = @{
  ok = (-not $hadErrors)
  runId = $runId
  whatIf = [bool]$WhatIf
  scope = $ApplyScope
  minScore = $MinScore
  maxLinksToAdd = $MaxLinksToAdd
  targets = $targets.Count
  changed = $changes.Count
  backupDir = $runDir.Replace([char]92,[char]47)
  changes = $changesArray
  rollback = @{
    note = 'Per rollback: copia i file .bak dal backupDir sulle rispettive destinazioni.'
  }
}
Ensure-ParentDir (Join-Path $runDir 'apply-summary.json')
$applySummary | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath (Join-Path $runDir 'apply-summary.json') -Encoding UTF8
Write-Host ("`nApply summary scritto in {0}" -f (Join-Path $runDir 'apply-summary.json')) -ForegroundColor Green
if ($hadErrors -and $FailOnError) { exit 1 }
