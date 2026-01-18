param(
  [string]$Path = "Wiki/EasyWayData.wiki",
  [string]$TaxonomyPath = "docs/agentic/templates/docs/tag-taxonomy.json",
  [string[]]$ExcludePaths = @('logs/reports'),
  [switch]$Apply,
  [switch]$IncludeFullPath,
  [string]$SummaryOut = "wiki-tags-facetize.json"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Read-Json($p) {
  if (-not (Test-Path -LiteralPath $p)) { throw "Taxonomy not found: $p" }
  return (Get-Content -LiteralPath $p -Raw | ConvertFrom-Json)
}

function Resolve-ExcludePrefixes {
  param([string]$Root, [string[]]$Exclude)
  $rootFull = (Resolve-Path -LiteralPath $Root).Path
  $out = @()
  foreach ($e in $Exclude) {
    if ([string]::IsNullOrWhiteSpace($e)) { continue }
    $candidate = $e
    if (-not [System.IO.Path]::IsPathRooted($candidate)) { $candidate = Join-Path $rootFull $candidate }
    try { $full = [System.IO.Path]::GetFullPath($candidate) } catch { continue }
    if (-not $full.EndsWith([System.IO.Path]::DirectorySeparatorChar)) { $full = $full + [System.IO.Path]::DirectorySeparatorChar }
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

function Extract-FrontMatterAndRest {
  param([string]$Text)
  $m = [regex]::Match($Text, '^(---\r?\n)(?<fm>.*?)(\r?\n---\r?\n)(?<rest>.*)$', [System.Text.RegularExpressions.RegexOptions]::Singleline)
  if (-not $m.Success) { return $null }
  return @{ fm=$m.Groups['fm'].Value; rest=$m.Groups['rest'].Value }
}

function Parse-Tags {
  param([string]$FrontMatter)
  $tags = @()
  if (-not $FrontMatter) { return $tags }

  $inline = [regex]::Match($FrontMatter, '(?m)^tags\s*:\s*\[(?<v>[^\]]*)\]\s*$')
  if ($inline.Success) {
    $parts = $inline.Groups['v'].Value -split ','
    foreach ($p in $parts) {
      $x = $p.Trim().Trim('"',[char]39)
      if ($x) { $tags += $x }
    }
    return $tags
  }

  $lines = $FrontMatter -split "\r?\n"
  $inTags = $false
  foreach ($l in $lines) {
    $tt = $l.Trim()
    if ($tt -match '^tags\s*:\s*$') { $inTags = $true; continue }
    if ($inTags) {
      if ($tt -match '^\-\s*(?<x>\S.*)$') {
        $x = $Matches['x'].Trim().Trim('"',[char]39)
        if ($x) { $tags += $x }
        continue
      }
      if ($l -match '^[A-Za-z0-9_-]+\s*:') { break }
    }
  }
  return $tags
}

function Replace-TagsInline {
  param([string]$FrontMatter, [string[]]$Tags)
  $tagsYaml = '[' + ($Tags -join ', ') + ']'

  if ([regex]::IsMatch($FrontMatter, '(?m)^tags\s*:\s*\[')) {
    return [regex]::Replace($FrontMatter, '(?m)^tags\s*:\s*\[[^\]]*\]\s*$', "tags: $tagsYaml")
  }
  if ([regex]::IsMatch($FrontMatter, '(?m)^tags\s*:\s*$')) {
    $fm = [regex]::Replace($FrontMatter, '(?ms)^tags\s*:\s*$\r?\n(?:\s*\-\s*.*\r?\n)*', '')
    return ($fm.TrimEnd() + "`n" + "tags: $tagsYaml`n")
  }
  return ($FrontMatter.TrimEnd() + "`n" + "tags: $tagsYaml`n")
}

$tax = Read-Json $TaxonomyPath
$facetNames = @($tax.required_facets)
$allowed = @{}
foreach ($k in $tax.facets.PSObject.Properties.Name) { $allowed[$k] = @($tax.facets.$k) }

$excludePrefixes = Resolve-ExcludePrefixes -Root $Path -Exclude $ExcludePaths
$results = @()

Get-ChildItem -LiteralPath $Path -Recurse -Filter *.md |
  Where-Object { -not (Is-Excluded -FullName ($_.FullName) -Prefixes $excludePrefixes) } |
  ForEach-Object {
    $file = $_.FullName
    $rel = Get-RelPath -Root $Path -FullName $file
    $text = Get-Content -LiteralPath $file -Raw
    $p = Extract-FrontMatterAndRest $text
    if (-not $p) {
      $r = @{ file = $rel; rel = $rel; ok = $false; error = 'missing_front_matter' }
      if ($IncludeFullPath) { $r.fullPath = $file }
      $results += $r
      return
    }

    $fm = $p.fm
    $rest = $p.rest
    $tags = Parse-Tags $fm

    $mapped = @()
    foreach ($t in $tags) {
      $tag = $t.Trim()
      if (-not $tag) { continue }

      # Convert facet-value forms like privacy-internal, language-it, layer-reference -> facet/value
      $m = [regex]::Match($tag, '^(domain|layer|audience|privacy|language)[-_](?<val>.+)$')
      if ($m.Success) {
        $facet = $m.Groups[1].Value
        $val = $m.Groups['val'].Value -replace '_','-'
        if ($allowed.ContainsKey($facet) -and ($allowed[$facet] -contains $val)) {
          $mapped += "$facet/$val"
          continue
        }
      }

      $mapped += $tag
    }

    # De-duplicate facet tags by facet (keep first), keep all free tags
    $seenFacet = @{}
    foreach ($f in $facetNames) { $seenFacet[$f] = $false }

    $out = New-Object System.Collections.Generic.List[string]
    foreach ($t in $mapped) {
      $mm = [regex]::Match($t, '^(?<facet>domain|layer|audience|privacy|language)/(?<val>.+)$')
      if ($mm.Success) {
        $facet = $mm.Groups['facet'].Value
        if ($facet -ne 'audience' -and $seenFacet[$facet]) { continue }
        if ($facet -ne 'audience') { $seenFacet[$facet] = $true }
        $out.Add($t)
        continue
      }
      if (-not ($out -contains $t)) { $out.Add($t) }
    }

    $newFm = Replace-TagsInline -FrontMatter $fm -Tags @($out)
    if ($newFm -eq $fm) {
      $r = @{ file = $rel; rel = $rel; ok = $true; changed = $false }
      if ($IncludeFullPath) { $r.fullPath = $file }
      $results += $r
      return
    }

    $newText = "---`n" + $newFm.TrimEnd() + "`n---`n" + $rest
    if ($Apply) {
      Set-Content -LiteralPath $file -Value $newText -Encoding utf8
    }
    $r = @{ file = $rel; rel = $rel; ok = $true; changed = $true }
    if ($IncludeFullPath) { $r.fullPath = $file }
    $results += $r
  }

$changed = @($results | Where-Object { $_.changed })
$summary = @{ applied=[bool]$Apply; excluded=$ExcludePaths; includeFullPath = [bool]$IncludeFullPath; files=$results.Count; changed=$changed.Count; results=$results }
$json = $summary | ConvertTo-Json -Depth 6
Set-Content -LiteralPath $SummaryOut -Value $json -Encoding utf8
Write-Output $json
