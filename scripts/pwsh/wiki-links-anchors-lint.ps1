param(
  [string]$Path = "Wiki/EasyWayData.wiki",
  [string[]]$ExcludePaths = @('logs/reports', 'old', '.attachments'),
  [string]$ScopesPath = "docs/agentic/templates/docs/tag-taxonomy.scopes.json",
  [string]$ScopeName = "",
  [switch]$FailOnError,
  [string]$SummaryOut = "wiki-links-anchors-lint.json"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if ($ExcludePaths.Count -eq 1 -and $ExcludePaths[0] -match ',') {
  $ExcludePaths = @($ExcludePaths[0].Split(',') | ForEach-Object { $_.Trim() } | Where-Object { $_ })
}

function Read-Json($p) {
  if (-not (Test-Path -LiteralPath $p)) { throw "JSON not found: $p" }
  return (Get-Content -LiteralPath $p -Raw | ConvertFrom-Json)
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
  $rel = $full.Substring($rootFull.Length).TrimStart('/', [char]92)
  return $rel.Replace([char]92, '/')
}

function Load-ScopeEntries {
  param([string]$ScopesPath, [string]$ScopeName)
  if ([string]::IsNullOrWhiteSpace($ScopeName)) { return @() }
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

function Slug([string]$t) {
  if ($null -eq $t) { return '' }
  $s = $t.ToLowerInvariant()
  $s = $s -replace "[`*_~]", ''
  $s = $s -replace "\s+", '-'
  $s = $s -replace "[^a-z0-9\-]", ''
  $s = $s -replace "-+", '-'
  $s = $s -replace "^-|-$", ''
  return $s
}

function Get-HeadingsCache {
  param([string]$File)
  $heads = @{}
  Get-Content -LiteralPath $File -Encoding UTF8 | ForEach-Object {
    if ($_ -match '^(#+)\s+(.+)$') {
      $slug = Slug $Matches[2]
      if ($slug) { $heads[$slug] = $true }
    }
  }
  return $heads
}

$excludePrefixes = Resolve-ExcludePrefixes -Root $Path -Exclude $ExcludePaths
$scopeEntries = Load-ScopeEntries -ScopesPath $ScopesPath -ScopeName $ScopeName

$issues = New-Object System.Collections.Generic.List[object]
$filesScanned = 0

$allFiles = Get-ChildItem -LiteralPath $Path -Recurse -Filter *.md |
Where-Object { -not (Is-Excluded -FullName ($_.FullName) -Prefixes $excludePrefixes) }

foreach ($f in $allFiles) {
  $rel = Get-RelPath -Root $Path -FullName $f.FullName
  if (-not (Is-InScope -RelPath $rel -ScopeEntries $scopeEntries)) { continue }

  $filesScanned++
  $dir = Split-Path -Parent $f.FullName
  $content = Get-Content -LiteralPath $f.FullName -Raw -Encoding UTF8
  if ([string]::IsNullOrWhiteSpace($content)) { continue }

  $matches = [regex]::Matches($content, "\[[^\]]*\]\(([^\)]+)\)")
  if ($matches.Count -eq 0) { continue }

  $fileHeadings = $null

  foreach ($m in $matches) {
    $raw = $m.Groups[1].Value.Trim()
    if (-not $raw) { continue }

    if ($raw -match '^(https?:|mailto:|data:)') { continue }

    if ($raw.StartsWith('#')) {
      if ($null -eq $fileHeadings) { $fileHeadings = Get-HeadingsCache -File $f.FullName }
      $anc = $raw.Substring(1)
      $slug = Slug $anc
      if (-not $fileHeadings.ContainsKey($slug)) {
        $issues.Add([pscustomobject]@{ file = $rel; link = $raw; issue = 'missing-local-anchor' })
      }
      continue
    }

    $target = $raw
    $anchor = $null
    if ($target.Contains('#')) {
      $anchor = $target.Substring($target.IndexOf('#') + 1)
      $target = $target.Substring(0, $target.IndexOf('#'))
    }

    $targetUnescaped = [System.Uri]::UnescapeDataString($target)
    $tpath = if ([IO.Path]::IsPathRooted($targetUnescaped)) { $targetUnescaped } else { Join-Path $dir $targetUnescaped }
    try { $tfull = [System.IO.Path]::GetFullPath($tpath) } catch { $tfull = $tpath }

    if (-not (Test-Path -LiteralPath $tfull)) {
      # Fallback: Try RAW path (case where file has %20 or %2D in name literally)
      $tpathRaw = if ([IO.Path]::IsPathRooted($target)) { $target } else { Join-Path $dir $target }
      try { $tfullRaw = [System.IO.Path]::GetFullPath($tpathRaw) } catch { $tfullRaw = $tpathRaw }
       
      if (-not (Test-Path -LiteralPath $tfullRaw)) {
        $issues.Add([pscustomobject]@{ file = $rel; link = $raw; issue = 'missing-file' })
        continue
      }
      else {
        $tfull = $tfullRaw # Use the found raw path for anchor checking
      }
    }

    if ($anchor) {
      $slug = Slug $anchor
      $heads = Get-HeadingsCache -File $tfull
      if (-not $heads.ContainsKey($slug)) {
        $issues.Add([pscustomobject]@{ file = $rel; link = $raw; issue = 'missing-anchor' })
      }
    }
  }

  # --- CHECK OBSIDIAN LINKS [[Page]] or [[Page|Label]] ---
  $obsMatches = [regex]::Matches($content, "\[\[([^\]]+)\]\]")
  foreach ($m in $obsMatches) {
    if (!$m.Success) { continue }
    $raw = $m.Groups[1].Value
    if (-not $raw) { continue }
    
    # Handle [[Link|Label]]
    $target = $raw
    if ($target.Contains('|')) {
      $target = $target.Split('|')[0]
    }
    
    # Handle Anchor [[Link#Anchor]]
    $anchor = $null
    if ($target.Contains('#')) {
      $parts = $target.Split('#')
      $target = $parts[0]
      $anchor = $parts[1]
    }

    $target = $target.Trim()
    
    # Resolve path
    # Obsidian links are usually relative to root or current file, but usually loosely matched by filename in Vault.
    # For strict Wiki validation, we assume relative path or same-directory if not rooted.
    
    # Try relative to current dir first
    $tpath = Join-Path $dir $target
    
    # If target has no extension, assume .md
    if (-not [System.IO.Path]::HasExtension($target)) {
      $tpath += ".md"
    }

    try { $tfull = [System.IO.Path]::GetFullPath($tpath) } catch { $tfull = $tpath }

    if (-not (Test-Path -LiteralPath $tfull)) {
      # Try absolute from Wiki Root if user meant root-relative (e.g. they confirm standard)
      # But usually Obsidian links are filename based. 
      # For now implementing simple relative check + check if file exists at that path
      $issues.Add([pscustomobject]@{ file = $rel; link = "[[$raw]]"; issue = 'missing-file' })
      continue
    }

    if ($anchor) {
      $slug = Slug $anchor
      $heads = Get-HeadingsCache -File $tfull
      if (-not $heads.ContainsKey($slug)) {
        $issues.Add([pscustomobject]@{ file = $rel; link = "[[$raw]]"; issue = 'missing-anchor' })
      }
    }
  }
}

$summary = @{
  ok         = ($issues.Count -eq 0)
  path       = $Path
  excluded   = @($ExcludePaths)
  scopesPath = $ScopesPath
  scopeName  = $ScopeName
  files      = $filesScanned
  issues     = $issues.Count
  results    = @($issues.ToArray())
}

$json = $summary | ConvertTo-Json -Depth 6
Set-Content -LiteralPath $SummaryOut -Value $json -Encoding utf8
Write-Output $json
if ($FailOnError -and -not $summary.ok) { exit 1 }

