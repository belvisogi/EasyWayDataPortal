param(
  [string]$Path = "Wiki/EasyWayData.wiki",
  [string[]]$ExcludePaths = @('logs/reports'),
  [string]$ScopesPath = "docs/agentic/templates/docs/tag-taxonomy.scopes.json",
  [string]$ScopeName = "",
  [string]$Owner = "team-platform",
  [string]$Status = "draft",
  [string[]]$DefaultTags = @('docs', 'privacy/internal', 'language/it'),
  [string]$ChunkHint = "250-400",
  [switch]$EnsureDraftHygiene,
  [string]$DefaultNext = "TODO - definire next step.",
  [switch]$FixPlaceholderSummary,
  [string[]]$PlaceholderSummaries = @(
    'Breve descrizione del documento.',
    'TODO - aggiungere un sommario breve.',
    'TODO - definire next step.'
  ),
  [switch]$Apply,
  [switch]$ForceReplaceUnterminated,
  [switch]$IncludeFullPath,
  [string]$SummaryOut = "wiki-frontmatter-patch.json"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if ($ExcludePaths.Count -eq 1 -and $ExcludePaths[0] -match ',') {
  $ExcludePaths = @($ExcludePaths[0].Split(',') | ForEach-Object { $_.Trim() } | Where-Object { $_ })
}

function New-KebabId {
  param([string]$Root, [string]$File)
  $abs = (Resolve-Path -LiteralPath $File).Path
  $rootPath = (Resolve-Path -LiteralPath $Root).Path
  $rel = $abs.Substring($rootPath.Length).TrimStart('/', [char]92)
  $rel = $rel.Replace([char]92, '/').ToLowerInvariant()
  $name = [System.IO.Path]::GetFileNameWithoutExtension($rel)
  $dir = [System.IO.Path]::GetDirectoryName($rel)
  if ($dir) {
    $dir = $dir.Replace('\\', '/').Replace('/', '-')
  }
  else {
    $dir = ""
  }
  $raw = if ([string]::IsNullOrWhiteSpace($dir)) { $name } else { "$dir-$name" }
  $raw = ($raw -replace "[^a-z0-9]+", "-").Trim('-')
  return "ew-$raw"
}

function Get-FirstHeadingOrName {
  param([string]$File)
  $lines = Get-Content -LiteralPath $File -TotalCount 50
  foreach ($l in $lines) {
    if ($l.Trim().StartsWith('#')) {
      return ($l -replace '^#+\s*', '').Trim()
    }
  }
  return ([System.IO.Path]::GetFileNameWithoutExtension($File) -replace '[_\-]+', ' ')
}

function Normalize-YamlScalar {
  param([string]$Value)
  if ($null -eq $Value) { return '' }
  $t = $Value.Trim()
  if ($t.Length -ge 2 -and $t.StartsWith("'") -and $t.EndsWith("'")) {
    $t = $t.Substring(1, $t.Length - 2)
    $t = $t.Replace("''", "'")
    return $t.Trim()
  }
  if ($t.Length -ge 2 -and $t.StartsWith('"') -and $t.EndsWith('"')) {
    $t = $t.Substring(1, $t.Length - 2)
    $t = $t.Replace('\"', '"')
    return $t.Trim()
  }
  return $t.Trim()
}

function Quote-YamlSingle {
  param([string]$Value)
  $t = [string]$Value
  $t = $t.Replace("'", "''")
  return "'" + $t + "'"
}

function Build-SummaryFromTitle {
  param([string]$Title)
  $t = ([string]$Title).Trim()
  if ([string]::IsNullOrWhiteSpace($t)) { return 'Documento' }
  if ($t.Length -gt 140) { $t = $t.Substring(0, 137) + '...' }
  return "Documento su $t."
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
  Write-Host "TRACE: Get-RelPath Root='$Root' FullName='$FullName'"
  $r = Resolve-Path -LiteralPath $Root
  if (-not $r) { throw "Root not found: $Root" }
  $rootFull = $r.Path
  
  $f = Resolve-Path -LiteralPath $FullName
  if (-not $f) { throw "File not found: $FullName" }
  $full = $f.Path
  
  if ($null -eq $rootFull) { throw "Start is null" }
  if ($null -eq $full) { throw "Full is null" }
  
  $rel = $full.Substring($rootFull.Length).TrimStart('/', [char]92)
  return $rel.Replace([char]92, '/')
}

function Suggest-Facets {
  param([string]$WikiPath)
  Write-Host "TRACE: Suggest-Facets input='$WikiPath'"
  if ($null -eq $WikiPath) { return New-Object System.Collections.Generic.List[string] }
  $rel = '/' + $WikiPath.Replace('\', '/').TrimStart('/')
  $s = New-Object System.Collections.Generic.List[string]

  if ($rel -match '/orchestrations/') { $s.Add('domain/control-plane'); $s.Add('layer/orchestration') }
  elseif ($rel -match '/control-plane/') { $s.Add('domain/control-plane'); $s.Add('layer/reference') }
  elseif ($rel -match '/domains/') {
    $s.Add('layer/reference')
    if ($rel -match '/domains/db\.md$') { $s.Add('domain/db') }
    elseif ($rel -match '/domains/datalake\.md$') { $s.Add('domain/datalake') }
    elseif ($rel -match '/domains/frontend\.md$') { $s.Add('domain/frontend') }
    elseif ($rel -match '/domains/docs-governance\.md$') { $s.Add('domain/docs') }
    else { $s.Add('domain/docs') }
  }
  elseif ($rel -match '/UX/') { $s.Add('domain/ux'); $s.Add('layer/spec') }
  elseif ($rel -match '/blueprints/') { $s.Add('domain/docs'); $s.Add('layer/blueprint') }
  elseif ($rel -match '/start-here\.md$') { $s.Add('domain/docs'); $s.Add('layer/index') }
  elseif ($rel -match '/security/') { $s.Add('domain/security'); $s.Add('layer/spec') }
  elseif ($rel -match '/standards/') { $s.Add('domain/docs'); $s.Add('layer/spec') }
  elseif ($rel -match '/use-cases/') { $s.Add('domain/docs'); $s.Add('layer/intent') }
  else { $s.Add('domain/docs'); $s.Add('layer/reference') }

  $s.Add('privacy/internal')
  $s.Add('language/it')
  $s.Add('audience/dev')
  return $s
}

function Read-Json {
  param([string]$p)
  if (-not (Test-Path -LiteralPath $p)) { throw "JSON not found: $p" }
  return (Get-Content -LiteralPath $p -Raw | ConvertFrom-Json)
}

function Load-ScopeEntries {
  param([string]$ScopesPath, [string]$ScopeName)
  if ([string]::IsNullOrWhiteSpace($ScopeName)) { return @() }
  if (-not (Test-Path -LiteralPath $ScopesPath)) { throw "Scopes JSON not found: $ScopesPath" }
  $obj = Read-Json $ScopesPath
  $scope = $obj.scopes.$ScopeName
  if ($null -eq $scope) { throw "Scope not found in ${ScopesPath}: $ScopeName" }
  return @($scope)
}

function Is-InScope {
  param([string]$RelPath, [string[]]$ScopeEntries)
  if ($null -eq $ScopeEntries -or $ScopeEntries.Count -eq 0) { return $true }
  foreach ($e in $ScopeEntries) {
    $p = [string]$e
    if (-not $p) { continue }
    $p = $p.Replace('\\', '/')
    if ($p.EndsWith('/')) {
      if ($RelPath.StartsWith($p, [System.StringComparison]::OrdinalIgnoreCase)) { return $true }
    }
    else {
      if ($RelPath.Equals($p, [System.StringComparison]::OrdinalIgnoreCase)) { return $true }
    }
  }
  return $false
}

function Ensure-FrontMatter {
  param([string]$File)

  $text = Get-Content -LiteralPath $File -Raw
  if ($null -eq $text) { $text = "" }

  $id = New-KebabId -Root $Path -File $File
  $title = Get-FirstHeadingOrName -File $File
  $defaultSummary = 'TODO - aggiungere un sommario breve.'
  
  Write-Host "DEBUG: Processing $File"
  $relPath = Get-RelPath -Root $Path -FullName $File
  if (-not $relPath) { Write-Host "ERROR: RelPath is null for $File"; return @{ action = 'error'; changed = $false } }
  
  $suggested = Suggest-Facets -WikiPath $relPath
  $tagsYaml = "[" + ($suggested -join ', ') + "]"

  if ($FixPlaceholderSummary) {
    $defaultSummary = Quote-YamlSingle (Build-SummaryFromTitle -Title $title)
  }

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
    return @{ action = 'inserted'; changed = $true; content = ($fm + $text) }
  }

  $m = [regex]::Match($text, '^(---\r?\n)(?<fm>.*?)(\r?\n---\r?\n)(?<rest>.*)$', [System.Text.RegularExpressions.RegexOptions]::Singleline)
  if (-not $m.Success) {
    if (-not $ForceReplaceUnterminated) {
      return @{ action = 'skip_unterminated'; changed = $false }
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
    return @{ action = 'replaced_unterminated'; changed = $true; content = ($fm + $text) }
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
  $statusVal = ''
  $mStatus = ($lines | Where-Object { $_ -match '^status\s*:\s*\S+' } | Select-Object -First 1)
  if ($mStatus -match '^status\s*:\s*(?<s>\S+)\s*$') { $statusVal = $Matches['s'].Trim() }

  $titleVal = ''
  $mTitle = ($lines | Where-Object { $_ -match '^title\s*:\s*\S+' } | Select-Object -First 1)
  if ($mTitle -match '^title\s*:\s*(?<t>.+?)\s*$') { $titleVal = Normalize-YamlScalar $Matches['t'] }
  if ([string]::IsNullOrWhiteSpace($titleVal)) { $titleVal = $title }

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

  $hasUpdated = [bool]($lines | Where-Object { $_ -match '^updated\s*:\s*\S+' } | Select-Object -First 1)
  $hasNext = [bool]($lines | Where-Object { $_ -match '^next\s*:\s*\S+' } | Select-Object -First 1)
  $hasChecklist = [bool]($lines | Where-Object { $_ -match '^checklist\s*:\s*(\[|$)' } | Select-Object -First 1)

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

    if ($FixPlaceholderSummary -and $tt -match '^summary\s*:\s*(?<v>.+?)\s*$') {
      $current = Normalize-YamlScalar $Matches['v']
      if ($PlaceholderSummaries | Where-Object { $_.Equals($current, [System.StringComparison]::OrdinalIgnoreCase) } | Select-Object -First 1) {
        $replacement = Quote-YamlSingle (Build-SummaryFromTitle -Title $titleVal)
        $outLines.Add("summary: $replacement")
        $hasNonEmptySummary = $true
        $hasAnySummary = $true
        continue
      }
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

  if ($EnsureDraftHygiene) {
    $finalStatus = $statusVal
    if ([string]::IsNullOrWhiteSpace($finalStatus)) { $finalStatus = $Status }
    if ($finalStatus -eq 'draft') {
      if (-not $hasUpdated) {
        $today = (Get-Date).ToString('yyyy-MM-dd')
        $outLines.Add("updated: '$today'")
      }
      if (-not $hasNext -and -not $hasChecklist) {
        $outLines.Add("next: $DefaultNext")
      }
    }
  }

  $newFm = ($outLines -join "`n").TrimEnd() + "`n"
  $newText = "---`n" + $newFm + "---`n" + $rest

  if ($newText -eq $text) { return @{ action = 'present'; changed = $false } }
  return @{ action = 'patched'; changed = $true; content = $newText }
}

$excludePrefixes = @(Resolve-ExcludePrefixes -Root $Path -Exclude $ExcludePaths)
$scopeEntries = Load-ScopeEntries -ScopesPath $ScopesPath -ScopeName $ScopeName
$results = @()

Write-Host "DEBUG: ExcludePrefixes count=$($excludePrefixes.Count)"

$files = Get-ChildItem -LiteralPath $Path -Recurse -Filter *.md 
foreach ($fItem in $files) {
  if (-not $fItem) { continue }
  if (-not $fItem.FullName) { continue }
  
  if (Is-Excluded -FullName $fItem.FullName -Prefixes $excludePrefixes) { continue }
  
  $res = Ensure-FrontMatter -File $fItem.FullName
  $rel = Get-RelPath -Root $Path -FullName $fItem.FullName
  if (-not (Is-InScope -RelPath $rel -ScopeEntries $scopeEntries)) { continue }
  
  $entry = @{ file = $rel; rel = $rel; action = $res.action; changed = [bool]$res.changed }
  if ($IncludeFullPath) { $entry.fullPath = $fItem.FullName }
  
  if ($Apply -and $res.changed -and $res.content) {
    Set-Content -LiteralPath $fItem.FullName -Value $res.content -Encoding utf8
    $entry.applied = $true
  }
  else {
    $entry.applied = $false
  }
  $results += $entry
}

$summary = @{
  applied               = [bool]$Apply
  excluded              = $ExcludePaths
  scopesPath            = $ScopesPath
  scopeName             = $ScopeName
  ensureDraftHygiene    = [bool]$EnsureDraftHygiene
  fixPlaceholderSummary = [bool]$FixPlaceholderSummary
  includeFullPath       = [bool]$IncludeFullPath
  results               = $results
}
$json = $summary | ConvertTo-Json -Depth 6
Set-Content -LiteralPath $SummaryOut -Value $json -Encoding utf8
Write-Output $json
