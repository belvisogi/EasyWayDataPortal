param(
  [string]$Path = "Wiki/EasyWayData.wiki",
  [string[]]$ExcludePaths = @('logs/reports'),
  [string]$Owner = "team-platform",
  [string]$Status = "draft",
  [string[]]$DefaultTags = @('docs','privacy/internal','language/it'),
  [string]$ChunkHint = "250-400",
  [switch]$Apply,
  [switch]$ForceReplaceUnterminated,
  [switch]$IncludeFullPath,
  [string]$SummaryOut = "wiki-frontmatter-patch.json"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function New-KebabId {
  param([string]$Root,[string]$File)
  $abs = (Resolve-Path -LiteralPath $File).Path
  $rootPath = (Resolve-Path -LiteralPath $Root).Path
  $rel = $abs.Substring($rootPath.Length).TrimStart('/',[char]92)
  $rel = $rel.Replace([char]92,'/').ToLowerInvariant()
  $name = [System.IO.Path]::GetFileNameWithoutExtension($rel)
  $dir = [System.IO.Path]::GetDirectoryName($rel).Replace('\\','/').Replace('/','-')
  $raw = if ([string]::IsNullOrWhiteSpace($dir)) { $name } else { "$dir-$name" }
  $raw = ($raw -replace "[^a-z0-9]+","-").Trim('-')
  return "ew-$raw"
}

function Get-FirstHeadingOrName {
  param([string]$File)
  $lines = Get-Content -LiteralPath $File -TotalCount 50
  foreach ($l in $lines) {
    if ($l.Trim().StartsWith('#')) {
      return ($l -replace '^#+\s*','').Trim()
    }
  }
  return ([System.IO.Path]::GetFileNameWithoutExtension($File) -replace '[_\-]+',' ')
}

function Resolve-ExcludePrefixes {
  param([string]$Root, [string[]]$Exclude)
  $rootFull = (Resolve-Path -LiteralPath $Root).Path
  $out = @()
  foreach ($e in $Exclude) {
    if ([string]::IsNullOrWhiteSpace($e)) { continue }
    $candidate = $e
    if (-not [System.IO.Path]::IsPathRooted($candidate)) {
      $candidate = Join-Path $rootFull $candidate
    }
    try { $full = [System.IO.Path]::GetFullPath($candidate) } catch { continue }
    if (-not $full.EndsWith([System.IO.Path]::DirectorySeparatorChar)) {
      $full = $full + [System.IO.Path]::DirectorySeparatorChar
    }
    $out += $full
  }
  return $out
}

function Is-Excluded {
  param([string]$FullName, [string[]]$Prefixes)
  foreach ($p in $Prefixes) {
    if ($FullName.StartsWith($p, [System.StringComparison]::OrdinalIgnoreCase)) { return $true }
  }
  return $false
}

function Get-RelPath {
  param([string]$Root, [string]$FullName)
  $rootFull = (Resolve-Path -LiteralPath $Root).Path
  $full = (Resolve-Path -LiteralPath $FullName).Path
  $rel = $full.Substring($rootFull.Length).TrimStart('/',[char]92)
  return $rel.Replace([char]92,'/')
}

function Ensure-FrontMatter {
  param([string]$File)

  $text = Get-Content -LiteralPath $File -Raw

  $id = New-KebabId -Root $Path -File $File
  $title = Get-FirstHeadingOrName -File $File
  $defaultSummary = 'TODO - aggiungere un sommario breve.'
  $tagsYaml = "[" + ($DefaultTags -join ', ') + "]"

  if (-not ($text.StartsWith("---`n") -or $text.StartsWith("---`r`n"))) {
    $fm = @"
---
id: $id
title: $title
summary: $defaultSummary
status: $Status
owner: $Owner
tags: $tagsYaml
llm:
  include: true
  pii: none
  chunk_hint: $ChunkHint
  redaction: [email, phone]
entities: []
---

"@
    return @{ action='inserted'; changed=$true; content=($fm + $text) }
  }

  $m = [regex]::Match($text, '^(---\r?\n)(?<fm>.*?)(\r?\n---\r?\n)(?<rest>.*)$', [System.Text.RegularExpressions.RegexOptions]::Singleline)
  if (-not $m.Success) {
    if (-not $ForceReplaceUnterminated) {
      return @{ action='skip_unterminated'; changed=$false }
    }
    $fm = @"
---
id: $id
title: $title
summary: $defaultSummary
status: $Status
owner: $Owner
tags: $tagsYaml
llm:
  include: true
  pii: none
  chunk_hint: $ChunkHint
  redaction: [email, phone]
entities: []
---

"@
    return @{ action='replaced_unterminated'; changed=$true; content=($fm + $text) }
  }

  $fmBlock = $m.Groups['fm'].Value
  $rest = $m.Groups['rest'].Value
  $lines = $fmBlock -split "\r?\n"

  $hasId = [bool]($lines | Where-Object { $_ -match '^id\s*:\s*\S+' } | Select-Object -First 1)
  $hasTitle = [bool]($lines | Where-Object { $_ -match '^title\s*:\s*\S+' } | Select-Object -First 1)

  $hasNonEmptySummary = [bool]($lines | Where-Object { $_ -match '^summary\s*:\s*\S+' } | Select-Object -First 1)
  $hasAnySummary = [bool]($lines | Where-Object { $_ -match '^summary\s*:' } | Select-Object -First 1)

  $hasNonEmptyStatus = [bool]($lines | Where-Object { $_ -match '^status\s*:\s*\S+' } | Select-Object -First 1)
  $hasAnyStatus = [bool]($lines | Where-Object { $_ -match '^status\s*:' } | Select-Object -First 1)

  $hasNonEmptyOwner = [bool]($lines | Where-Object { $_ -match '^owner\s*:\s*\S+' } | Select-Object -First 1)
  $hasAnyOwner = [bool]($lines | Where-Object { $_ -match '^owner\s*:' } | Select-Object -First 1)

  $hasEntities = [bool]($lines | Where-Object { $_ -match '^entities\s*:\s*' } | Select-Object -First 1)

  $hasTagsInline = [bool]($lines | Where-Object { $_ -match '^tags\s*:\s*\[' } | Select-Object -First 1)
  $hasTagsList = [bool]([regex]::IsMatch($fmBlock, '(?m)^tags\s*:\s*\r?\n\s*-\s*\S+'))
  $hasTags = ($hasTagsInline -or $hasTagsList)

  $hasLlm = [bool]($lines | Where-Object { $_ -match '^llm\s*:\s*$' } | Select-Object -First 1)
  $hasLlmInclude = [bool]([regex]::IsMatch($fmBlock, '(?m)^\s+include\s*:\s*(true|false)\s*$'))
  $hasLlmChunk = [bool]([regex]::IsMatch($fmBlock, '(?m)^\s+chunk_hint\s*:\s*\d+(-\d+)?\s*$'))
  $hasNonEmptyPii = [bool]([regex]::IsMatch($fmBlock, '(?m)^\s+pii\s*:\s*\S+'))
  $hasAnyPii = [bool]([regex]::IsMatch($fmBlock, '(?m)^\s+pii\s*:'))

  $outLines = New-Object System.Collections.Generic.List[string]

  $inTags = $false
  $inLlm = $false

  foreach ($l in $lines) {
    $tt = $l.Trim()

    # Drop empty duplicates if a non-empty value exists elsewhere
    if ($tt -match '^summary\s*:\s*$') {
      if ($hasNonEmptySummary) { continue }
      $outLines.Add("summary: $defaultSummary")
      $hasNonEmptySummary = $true
      $hasAnySummary = $true
      continue
    }
    if ($tt -match '^owner\s*:\s*$') {
      if ($hasNonEmptyOwner) { continue }
      $outLines.Add("owner: $Owner")
      $hasNonEmptyOwner = $true
      $hasAnyOwner = $true
      continue
    }
    if ($tt -match '^status\s*:\s*$') {
      if ($hasNonEmptyStatus) { continue }
      $outLines.Add("status: $Status")
      $hasNonEmptyStatus = $true
      $hasAnyStatus = $true
      continue
    }

    if ($tt -match '^tags\s*:\s*$') { $inTags = $true; $inLlm = $false; $outLines.Add($l); continue }
    if ($inTags) {
      if ($tt -match '^\-\s*$') { continue }
      if ($tt -match '^\-\s*\S+') { $outLines.Add($l); continue }
      if ($l -match '^[A-Za-z0-9_-]+\s*:') { $inTags = $false }
    }

    if ($tt -eq 'llm:') {
      $inLlm = $true
      $inTags = $false
      $outLines.Add($l)
      if (-not $hasLlmInclude) { $outLines.Add('  include: true'); $hasLlmInclude = $true }
      if (-not $hasAnyPii -or (-not $hasNonEmptyPii)) { $outLines.Add('  pii: none'); $hasAnyPii = $true; $hasNonEmptyPii = $true }
      if (-not $hasLlmChunk) { $outLines.Add("  chunk_hint: $ChunkHint"); $hasLlmChunk = $true }
      if (-not ([regex]::IsMatch($fmBlock, '(?m)^\s+redaction\s*:'))) { $outLines.Add('  redaction: [email, phone]') }
      continue
    }

    if ($inLlm -and $tt -match '^pii\s*:\s*$') {
      if ($hasNonEmptyPii) { continue }
      $outLines.Add('  pii: none')
      $hasAnyPii = $true
      $hasNonEmptyPii = $true
      continue
    }

    if ($inLlm -and $l -match '^[A-Za-z0-9_-]+\s*:') { $inLlm = $false }

    $outLines.Add($l)
  }

  if (-not $hasId) { $outLines.Add("id: $id") }
  if (-not $hasTitle) { $outLines.Add("title: $title") }
  if (-not $hasAnySummary -or -not $hasNonEmptySummary) { $outLines.Add("summary: $defaultSummary") }
  if (-not $hasAnyStatus -or -not $hasNonEmptyStatus) { $outLines.Add("status: $Status") }
  if (-not $hasAnyOwner -or -not $hasNonEmptyOwner) { $outLines.Add("owner: $Owner") }
  if (-not $hasTags) { $outLines.Add("tags: $tagsYaml") }
  if (-not $hasLlm) {
    $outLines.Add('llm:')
    $outLines.Add('  include: true')
    $outLines.Add('  pii: none')
    $outLines.Add("  chunk_hint: $ChunkHint")
    $outLines.Add('  redaction: [email, phone]')
  }
  if (-not $hasEntities) { $outLines.Add('entities: []') }

  $newFm = ($outLines -join "`n").TrimEnd() + "`n"
  $newText = "---`n" + $newFm + "---`n" + $rest

  if ($newText -eq $text) { return @{ action='present'; changed=$false } }
  return @{ action='patched'; changed=$true; content=$newText }
}

$excludePrefixes = Resolve-ExcludePrefixes -Root $Path -Exclude $ExcludePaths
$results = @()

Get-ChildItem -LiteralPath $Path -Recurse -Filter *.md | Where-Object { -not (Is-Excluded -FullName ($_.FullName) -Prefixes $excludePrefixes) } | ForEach-Object {
  $res = Ensure-FrontMatter -File $_.FullName
  $rel = Get-RelPath -Root $Path -FullName $_.FullName
  $entry = @{ file = $rel; rel = $rel; action = $res.action; changed = [bool]$res.changed }
  if ($IncludeFullPath) { $entry.fullPath = $_.FullName }
  if ($Apply -and $res.changed -and $res.content) {
    Set-Content -LiteralPath $_.FullName -Value $res.content -Encoding utf8
    $entry.applied = $true
  } else {
    $entry.applied = $false
  }
  $results += $entry
}

$summary = @{ applied = [bool]$Apply; excluded = $ExcludePaths; includeFullPath = [bool]$IncludeFullPath; results = $results }
$json = $summary | ConvertTo-Json -Depth 6
Set-Content -LiteralPath $SummaryOut -Value $json -Encoding utf8
Write-Output $json
