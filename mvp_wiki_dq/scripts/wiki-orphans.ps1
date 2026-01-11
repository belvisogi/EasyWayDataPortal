param(
  [string]$WikiPath = "wiki",
  [string[]]$ExcludePaths = @('logs', 'old', '.attachments'),
  [string]$OutMd = "wiki/orphans.md",
  [string]$OutJson = "out/graph.json",
  [string]$OutDot = "out/graph.dot",
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
  return ($relPath -replace ' ', '%20' -replace '\(', '%28' -replace '\)', '%29' -replace '\+', '%2B')
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
  if (-not $full.EndsWith([IO.Path]::DirectorySeparatorChar)) { $full = $full + [IO.Path]::DirectorySeparatorChar }
  $excludePrefixes += $full
}

function Is-Excluded([string]$fullName) {
  foreach ($p in $excludePrefixes) {
    if ($fullName.StartsWith($p, [StringComparison]::OrdinalIgnoreCase)) { return $true }
  }
  return $false
}

function Rel([string]$fullName) {
  $rel = $fullName.Substring($root.Length).TrimStart([char]92, [char]47)
  return $rel.Replace([char]92, [char]47)
}

$files = Get-ChildItem -LiteralPath $root -Recurse -Filter *.md -File | Where-Object { -not (Is-Excluded $_.FullName) }

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
  $src = Rel $f.FullName
  $srcKey = $src.ToLowerInvariant()
  if (-not $adjOut.ContainsKey($srcKey)) { $adjOut[$srcKey] = New-Object System.Collections.Generic.HashSet[string] }
  if (-not $adjIn.ContainsKey($srcKey)) { $adjIn[$srcKey] = New-Object System.Collections.Generic.HashSet[string] }

  if ($src -ieq 'orphans.md') { continue }

  $dir = Split-Path -Parent $f.FullName
  $scan = Strip-Code (Get-Content -LiteralPath $f.FullName -Raw -Encoding UTF8)

  foreach ($m in [regex]::Matches($scan, "\[[^\]]*\]\(([^\)]+)\)")) {
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

  foreach ($m in [regex]::Matches($scan, "\[\[([^\]]+)\]\]")) {
    $raw = $m.Groups[1].Value.Trim()
    if (-not $raw) { continue }
    $parts = $raw.Split('|', 2)
    $targetPart = $parts[0].Trim()
    if (-not $targetPart) { continue }
    if ($targetPart.StartsWith('#')) { continue }
    if ($targetPart.Contains('#')) { $targetPart = $targetPart.Substring(0, $targetPart.IndexOf('#')) }
    $targetPart = $targetPart.Trim()

    $dstRel = $null
    if ($targetPart -match '\.md$') {
      $cand = $targetPart.Replace('\\','/')
      if ($byRel.ContainsKey($cand.ToLowerInvariant())) { $dstRel = $byRel[$cand.ToLowerInvariant()] }
    } else {
      $key = $targetPart.ToLowerInvariant()
      if ($byName.ContainsKey($key) -and $byName[$key].Count -gt 0) { $dstRel = $byName[$key][0] }
    }
    if (-not $dstRel) { continue }
    $dstKey = $dstRel.ToLowerInvariant()
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

$visited = New-Object System.Collections.Generic.HashSet[string]
$components = New-Object System.Collections.Generic.List[object]
foreach ($n in $nodes) {
  if ($visited.Contains($n)) { continue }
  $q = New-Object System.Collections.Generic.Queue[string]
  $q.Enqueue($n); $visited.Add($n) | Out-Null
  $members = New-Object System.Collections.Generic.List[string]
  while ($q.Count -gt 0) {
    $cur = $q.Dequeue()
    $members.Add($cur)
    foreach ($nb in @(@($adjOut[$cur]) + @($adjIn[$cur]))) {
      if (-not $visited.Contains($nb)) { $visited.Add($nb) | Out-Null; $q.Enqueue($nb) }
    }
  }
  $components.Add([pscustomobject]@{ size = $members.Count; nodes = @($members) }) | Out-Null
}
$componentsSorted = $components | Sort-Object size -Descending

function ToRel([string]$key) { return $byRel[$key] }
$orphans = @($nodes | Where-Object { ($inDegree[$_] + $outDegree[$_]) -eq 0 } | ForEach-Object { ToRel $_ })

$report = [pscustomobject]@{
  ok = $true
  nodes = $nodes.Count
  edges = $edgeCount
  components = $componentsSorted.Count
  largestComponentSize = ($componentsSorted | Select-Object -First 1).size
  orphans = @($orphans)
  graph = [pscustomobject]@{
    nodes = @(
      foreach ($n in $nodes) {
        [pscustomobject]@{
          id = $n
          path = (ToRel $n)
          inDegree = [int]$inDegree[$n]
          outDegree = [int]$outDegree[$n]
          degree = [int]($inDegree[$n] + $outDegree[$n])
        }
      }
    )
    links = @(
      foreach ($src in $nodes) {
        foreach ($dst in @($adjOut[$src])) {
          [pscustomobject]@{ source = $src; target = $dst }
        }
      }
    )
  }
}

Ensure-ParentDir $OutJson
$report | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $OutJson -Encoding UTF8
Ensure-ParentDir $OutDot
("graph Wiki {`n  overlap=false; splines=true;`n}") | Set-Content -LiteralPath $OutDot -Encoding UTF8

Ensure-ParentDir $OutMd
$updated = (Get-Date).ToString('yyyy-MM-dd')
$md = New-Object System.Text.StringBuilder
[void]$md.AppendLine('---')
[void]$md.AppendLine('id: mvp-orphans')
[void]$md.AppendLine('title: Orphans')
[void]$md.AppendLine('summary: Pagine isolate (degree=0) da collegare.')
[void]$md.AppendLine('status: draft')
[void]$md.AppendLine('owner: team-platform')
[void]$md.AppendLine('tags: [domain/docs, layer/index, audience/dev, privacy/internal, language/it, dq, kanban]')
[void]$md.AppendLine("updated: '$updated'")
[void]$md.AppendLine('---')
[void]$md.AppendLine('')
[void]$md.AppendLine('# Orphans')
[void]$md.AppendLine('')
[void]$md.AppendLine("Totale: $($orphans.Count)")
[void]$md.AppendLine('')
foreach ($p in @($orphans | Sort-Object)) {
  [void]$md.AppendLine('- [' + $p + '](./' + (Escape-LinkTarget $p) + ')')
}
$md.ToString() | Set-Content -LiteralPath $OutMd -Encoding UTF8

Write-Output ($report | ConvertTo-Json -Depth 4)
if ($FailOnError -and $orphans.Count -gt 0) { exit 1 }
