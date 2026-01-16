param(
  [string]$WikiPath = "Wiki/EasyWayData.wiki",
  [string[]]$ExcludePaths = @('logs/reports', 'old', '.attachments'),
  [string]$OutMarkdown = "Wiki/EasyWayData.wiki/orphans-index.md",
  [string]$OutJson = "out/wiki-link-graph.EasyWayData.wiki.json",
  [string]$OutDot = "out/wiki-link-graph.EasyWayData.wiki.dot",
  [switch]$FailOnError
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if ($ExcludePaths.Count -eq 1 -and $ExcludePaths[0] -match ',') {
  $ExcludePaths = @($ExcludePaths[0].Split(',') | ForEach-Object { $_.Trim() } | Where-Object { $_ })
}

function Strip-Code([string]$text) {
  if ($null -eq $text) { return '' }
  $t = [regex]::Replace($text, '(?s)```.*?```', '')
  $t = [regex]::Replace($t, '`[^`]*`', '')
  return $t
}

function Escape-LinkTarget([string]$relPath) {
  if ($null -eq $relPath) { return '' }
  return ($relPath `
      -replace '\(', '%28' `
      -replace '\)', '%29' `
      -replace '\+', '%2B' `
      -replace ' ', '%20')
}

function Ensure-ParentDir([string]$path) {
  $dir = Split-Path -Parent $path
  if ([string]::IsNullOrWhiteSpace($dir)) { return }
  New-Item -ItemType Directory -Force -Path $dir | Out-Null
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

function Rel([string]$fullName) {
  $rel = $fullName.Substring($root.Length)
  $rel = $rel.TrimStart([char]92, [char]47)
  return $rel.Replace([char]92, [char]47)
}

$files = @(Get-ChildItem -LiteralPath $root -Recurse -Filter *.md -File |
  Where-Object { -not (Is-Excluded -fullName $_.FullName) })

$totalFiles = $files.Count
$processed = 0

# Index for wikilinks resolution (by path and by basename)
$byRel = @{}
$byName = @{}
foreach ($f in $files) {
  $r = Rel $f.FullName
  $byRel[$r.ToLowerInvariant()] = $r
  $name = [IO.Path]::GetFileNameWithoutExtension($r).ToLowerInvariant()
  if (-not $byName.ContainsKey($name)) { $byName[$name] = New-Object System.Collections.Generic.List[string] }
  $byName[$name].Add($r)
}

$adjOut = @{}
$adjIn = @{}
foreach ($f in $files) {
  $processed++
  if ($processed % 10 -eq 0) {
    Write-Progress -Activity "Building Wiki Graph" -Status "Processing files" -PercentComplete (($processed / $totalFiles) * 100) -CurrentOperation "$($f.Name)"
  }
  $src = Rel $f.FullName
  $srcKey = $src.ToLowerInvariant()
  if (-not $adjOut.ContainsKey($srcKey)) { $adjOut[$srcKey] = New-Object System.Collections.Generic.HashSet[string] }
  if (-not $adjIn.ContainsKey($srcKey)) { $adjIn[$srcKey] = New-Object System.Collections.Generic.HashSet[string] }

  # IMPORTANT: do not count links originating from orphans-index.md when computing orphans,
  # otherwise regenerating this page would remove the only inbound link for previously isolated pages.
  if ($src -ieq 'orphans-index.md') { continue }

  $dir = Split-Path -Parent $f.FullName
  $content = Get-Content -LiteralPath $f.FullName -Raw -Encoding UTF8
  $scan = Strip-Code $content

  # Markdown links: [text](target)
  $mdMatches = [regex]::Matches($scan, "\[[^\]]*\]\(([^\)]+)\)")
  foreach ($m in $mdMatches) {
    $raw = $m.Groups[1].Value.Trim()
    if (-not $raw) { continue }
    if ($raw -match '^(https?:|mailto:|data:)') { continue }
    if ($raw.StartsWith('#')) { continue }

    $target = $raw
    if ($target.Contains('#')) { $target = $target.Substring(0, $target.IndexOf('#')) }
    $target = [System.Uri]::UnescapeDataString($target).Trim()
    if (-not $target) { continue }

    $tpath = if ([IO.Path]::IsPathRooted($target)) { $target } else { Join-Path $dir $target }
    try { $tfull = [IO.Path]::GetFullPath($tpath) } catch { continue }
    if (-not $tfull.StartsWith($root, [StringComparison]::OrdinalIgnoreCase)) { continue }
    if (-not (Test-Path -LiteralPath $tfull)) { continue }
    if ([IO.Path]::GetExtension($tfull).ToLowerInvariant() -ne '.md') { continue }
    if (Is-Excluded $tfull) { continue }

    $dst = Rel $tfull
    $dstKey = $dst.ToLowerInvariant()
    if (-not $adjOut.ContainsKey($dstKey)) { $adjOut[$dstKey] = New-Object System.Collections.Generic.HashSet[string] }
    if (-not $adjIn.ContainsKey($dstKey)) { $adjIn[$dstKey] = New-Object System.Collections.Generic.HashSet[string] }

    $adjOut[$srcKey].Add($dstKey) | Out-Null
    $adjIn[$dstKey].Add($srcKey) | Out-Null
  }

  # Wikilinks: [[target]] or [[target|label]] (best-effort)
  $wlMatches = [regex]::Matches($scan, "\[\[([^\]]+)\]\]")
  foreach ($m in $wlMatches) {
    $raw = $m.Groups[1].Value.Trim()
    if (-not $raw) { continue }

    $parts = $raw.Split('|', 2)
    $targetPart = $parts[0].Trim()
    if (-not $targetPart) { continue }
    if ($targetPart.StartsWith('#')) { continue }
    if ($targetPart.Contains('#')) { $targetPart = $targetPart.Substring(0, $targetPart.IndexOf('#')) }
    $targetPart = $targetPart.Trim()
    if (-not $targetPart) { continue }

    $candidate = $targetPart
    if (-not [IO.Path]::GetExtension($candidate)) { $candidate = $candidate + '.md' }

    $dst = $null
    if ($candidate.Contains('/') -or $candidate.Contains([char]92)) {
      $candRel = $candidate.Replace([char]92, [char]47).TrimStart([char]47)
      $key = $candRel.ToLowerInvariant()
      if ($byRel.ContainsKey($key)) { $dst = $byRel[$key] }
    }
    else {
      $nameKey = [IO.Path]::GetFileNameWithoutExtension($candidate).ToLowerInvariant()
      if ($byName.ContainsKey($nameKey) -and $byName[$nameKey].Count -eq 1) { $dst = $byName[$nameKey][0] }
    }
    if (-not $dst) { continue }

    $dstKey = $dst.ToLowerInvariant()
    if ($dstKey -eq $srcKey) { continue }
    if (-not $adjOut.ContainsKey($dstKey)) { $adjOut[$dstKey] = New-Object System.Collections.Generic.HashSet[string] }
    if (-not $adjIn.ContainsKey($dstKey)) { $adjIn[$dstKey] = New-Object System.Collections.Generic.HashSet[string] }

    $adjOut[$srcKey].Add($dstKey) | Out-Null
    $adjIn[$dstKey].Add($srcKey) | Out-Null
  }
}

$nodes = @($adjOut.Keys | Sort-Object -Unique)
$edgeCount = 0
$inDegree = @{}
$outDegree = @{}
foreach ($n in $nodes) {
  $inDegree[$n] = $adjIn[$n].Count
  $outDegree[$n] = $adjOut[$n].Count
  $edgeCount += $adjOut[$n].Count
}
Write-Progress -Activity "Building Wiki Graph" -Completed

# Connected components (undirected)
$visited = New-Object System.Collections.Generic.HashSet[string]
$components = New-Object System.Collections.Generic.List[object]
foreach ($n in $nodes) {
  if ($visited.Contains($n)) { continue }
  $q = New-Object System.Collections.Generic.Queue[string]
  $q.Enqueue($n)
  $visited.Add($n) | Out-Null
  $members = New-Object System.Collections.Generic.List[string]
  while ($q.Count -gt 0) {
    $cur = $q.Dequeue()
    $members.Add($cur)
    foreach ($nb in @(@($adjOut[$cur]) + @($adjIn[$cur]))) {
      if (-not $visited.Contains($nb)) {
        $visited.Add($nb) | Out-Null
        $q.Enqueue($nb)
      }
    }
  }
  $components.Add([pscustomobject]@{ size = $members.Count; nodes = @($members) }) | Out-Null
}
$componentsSorted = $components | Sort-Object size -Descending

function ToRelDisplay([string]$key) { return $byRel[$key] }

$orphans = @($nodes | Where-Object { ($inDegree[$_] + $outDegree[$_]) -eq 0 } | ForEach-Object { ToRelDisplay $_ })
$noInbound = @($nodes | Where-Object { $inDegree[$_] -eq 0 } | ForEach-Object { ToRelDisplay $_ })
$noOutbound = @($nodes | Where-Object { $outDegree[$_] -eq 0 } | ForEach-Object { ToRelDisplay $_ })

$top = $nodes | ForEach-Object {
  [pscustomobject]@{
    path   = (ToRelDisplay $_)
    in     = $inDegree[$_]
    out    = $outDegree[$_]
    degree = ($inDegree[$_] + $outDegree[$_])
  }
} | Sort-Object degree -Descending | Select-Object -First 25

$report = [pscustomobject]@{
  ok                   = $true
  root                 = $WikiPath.Replace([char]92, [char]47)
  excluded             = @($ExcludePaths)
  nodes                = $nodes.Count
  edges                = $edgeCount
  components           = $componentsSorted.Count
  largestComponentSize = ($componentsSorted | Select-Object -First 1).size
  orphans              = @($orphans)
  noInbound            = @($noInbound)
  noOutbound           = @($noOutbound)
  topByDegree          = @($top)
}

Ensure-ParentDir $OutJson
$report | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $OutJson -Encoding UTF8

Ensure-ParentDir $OutDot
$sb = New-Object System.Text.StringBuilder
[void]$sb.AppendLine('graph Wiki {')
[void]$sb.AppendLine('  overlap=false; splines=true;')
foreach ($k in $nodes) {
  $label = (ToRelDisplay $k).Replace('"', '\"')
  [void]$sb.AppendLine('  "' + $label + '";')
}
$seen = New-Object System.Collections.Generic.HashSet[string]
foreach ($srcKey in $nodes) {
  $src = ToRelDisplay $srcKey
  foreach ($dstKey in $adjOut[$srcKey]) {
    $dst = ToRelDisplay $dstKey
    $a = "$src -- $dst"
    $b = "$dst -- $src"
    if ($seen.Contains($a) -or $seen.Contains($b)) { continue }
    $seen.Add($a) | Out-Null
    $s = $src.Replace('"', '\"')
    $d = $dst.Replace('"', '\"')
    [void]$sb.AppendLine('  "' + $s + '" -- "' + $d + '";')
  }
}
[void]$sb.AppendLine('}')
$sb.ToString() | Set-Content -LiteralPath $OutDot -Encoding UTF8

# Markdown index (grouped by directory)
Ensure-ParentDir $OutMarkdown
$updated = (Get-Date).ToString('yyyy-MM-dd')
$groups = @($orphans | Group-Object { if ($_ -match '/') { $_.Substring(0, $_.LastIndexOf('/')) } else { '.' } } | Sort-Object Name)

$md = New-Object System.Text.StringBuilder
[void]$md.AppendLine('---')
[void]$md.AppendLine('title: Orphans Index')
[void]$md.AppendLine('summary: Pagine della Wiki senza link in ingresso/uscita (degree=0), per collegarle al grafo.')
[void]$md.AppendLine('id: ew-orphans-index')
[void]$md.AppendLine('status: draft')
[void]$md.AppendLine('owner: team-platform')
[void]$md.AppendLine('tags: [domain/docs, layer/index, audience/dev, privacy/internal, language/it, docs]')
[void]$md.AppendLine('llm:')
[void]$md.AppendLine('  include: true')
[void]$md.AppendLine('  pii: none')
[void]$md.AppendLine('entities: []')
[void]$md.AppendLine("updated: '$updated'")
[void]$md.AppendLine('---')
[void]$md.AppendLine('')
[void]$md.AppendLine('# Orphans Index')
[void]$md.AppendLine('')
[void]$md.AppendLine('Questa pagina collega le pagine attualmente isolate (degree=0) per ridurre i nodi scollegati nel grafo Obsidian.')
[void]$md.AppendLine('')
[void]$md.AppendLine('Rigenerazione: `pwsh scripts/wiki-orphan-index.ps1` (idempotente).')
[void]$md.AppendLine('')
[void]$md.AppendLine("Totale orfani: $($orphans.Count)")
[void]$md.AppendLine('')

foreach ($g in $groups) {
  [void]$md.AppendLine('## ' + $g.Name)
  foreach ($p in @($g.Group | Sort-Object)) {
    $t = Escape-LinkTarget $p
    [void]$md.AppendLine('- [' + $p + '](./' + $t + ')')
  }
  [void]$md.AppendLine('')
}

$md.ToString() | Set-Content -LiteralPath $OutMarkdown -Encoding UTF8

Write-Output ($report | ConvertTo-Json -Depth 4)
if ($FailOnError -and $orphans.Count -gt 0) { exit 1 }
