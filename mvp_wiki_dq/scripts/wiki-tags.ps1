param(
  [string]$Path = "wiki",
  [string]$TaxonomyPath = "config/tag-taxonomy.json",
  [string[]]$ExcludePaths = @('logs', 'old', '.attachments'),
  [switch]$RequireFacets,
  [switch]$FailOnError,
  [string]$SummaryOut = "out/tags.json"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if ($ExcludePaths.Count -eq 1 -and $ExcludePaths[0] -match ',') {
  $ExcludePaths = @($ExcludePaths[0].Split(',') | ForEach-Object { $_.Trim() } | Where-Object { $_ })
}

function Read-Json([string]$p) {
  if (-not (Test-Path -LiteralPath $p)) { throw "JSON not found: $p" }
  return (Get-Content -LiteralPath $p -Raw | ConvertFrom-Json)
}

function Resolve-ExcludePrefixes([string]$Root, [string[]]$Exclude) {
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

function Is-Excluded([string]$FullName, [string[]]$Prefixes) {
  foreach ($p in $Prefixes) { if ($FullName.StartsWith($p, [System.StringComparison]::OrdinalIgnoreCase)) { return $true } }
  return $false
}

function Get-RelPath([string]$Root, [string]$FullName) {
  $rootFull = (Resolve-Path -LiteralPath $Root).Path
  $full = (Resolve-Path -LiteralPath $FullName).Path
  return $full.Substring($rootFull.Length).TrimStart('/',[char]92).Replace([char]92,'/')
}

function Extract-FrontMatter([string]$Text) {
  $m = [regex]::Match($Text, '^(---\r?\n)(?<fm>.*?)(\r?\n---\r?\n)', 'Singleline')
  if (-not $m.Success) { return $null }
  return $m.Groups['fm'].Value
}

function Parse-Tags([string]$FrontMatter) {
  $tags = New-Object System.Collections.Generic.List[string]
  if (-not $FrontMatter) { return ,$tags.ToArray() }

  $inline = [regex]::Match($FrontMatter, '(?m)^tags\s*:\s*\[(?<v>[^\]]*)\]\s*$')
  if ($inline.Success) {
    foreach ($p in ($inline.Groups['v'].Value -split ',')) {
      $t = $p.Trim()
      if ($t) { $tags.Add($t.Trim('"',[char]39)) }
    }
    return ,$tags.ToArray()
  }

  $lines = $FrontMatter -split "\r?\n"
  $inTags = $false
  foreach ($l in $lines) {
    $tt = $l.Trim()
    if ($tt -match '^tags\s*:\s*$') { $inTags = $true; continue }
    if ($inTags) {
      if ($tt -match '^\-\s*(?<x>\S.*)$') {
        $t = $Matches['x'].Trim().Trim('"',[char]39)
        if ($t) { $tags.Add($t) }
        continue
      }
      if ($l -match '^[A-Za-z0-9_-]+\s*:') { break }
    }
  }
  return ,$tags.ToArray()
}

function Suggest-Facets([string]$RelPath) {
  $p = '/' + $RelPath.Replace('\\','/').TrimStart('/')
  $s = @{}
  if ($p -match '/wiki/orch/') { $s.domain='docs'; $s.layer='orchestration' }
  elseif ($p -match '/wiki/index\.md$') { $s.domain='docs'; $s.layer='index' }
  else { $s.domain='docs'; $s.layer='reference' }
  $s.privacy='internal'
  $s.language='it'
  $s.audience=@('dev')
  return $s
}

function Ensure-ParentDir([string]$path) {
  $dir = Split-Path -Parent $path
  if ([string]::IsNullOrWhiteSpace($dir)) { return }
  New-Item -ItemType Directory -Force -Path $dir | Out-Null
}

$tax = Read-Json $TaxonomyPath
$facets = @{}
foreach ($k in $tax.facets.PSObject.Properties.Name) { $facets[$k] = @($tax.facets.$k) }
$required = @($tax.required_facets)
$card = @{}
foreach ($k in $tax.facet_cardinality.PSObject.Properties.Name) { $card[$k] = [string]$tax.facet_cardinality.$k }
$freeRe = [regex]::new([string]$tax.free_tag_regex)

$excludePrefixes = Resolve-ExcludePrefixes -Root $Path -Exclude $ExcludePaths

$results = New-Object System.Collections.Generic.List[object]
Get-ChildItem -LiteralPath $Path -Recurse -Filter *.md -File |
  Where-Object { -not (Is-Excluded -FullName $_.FullName -Prefixes $excludePrefixes) } |
  ForEach-Object {
    $rel = Get-RelPath -Root $Path -FullName $_.FullName
    $text = Get-Content -LiteralPath $_.FullName -Raw -Encoding UTF8
    $fm = Extract-FrontMatter $text
    $tags = Parse-Tags $fm

    $errors = New-Object System.Collections.Generic.List[string]
    $warnings = New-Object System.Collections.Generic.List[string]

    if ($null -eq $fm) { $errors.Add('missing_front_matter') }
    elseif ($tags.Count -eq 0) { $errors.Add('missing_tags') }

    $facetValues = @{}
    foreach ($f in $required) { $facetValues[$f] = @() }

    foreach ($t in $tags) {
      $tag = $t.Trim()
      if (-not $tag) { continue }

      $m = [regex]::Match($tag, '^(?<facet>[a-zA-Z0-9_-]+)/(?<val>.+)$')
      if ($m.Success) {
        $facet = $m.Groups['facet'].Value
        $val = $m.Groups['val'].Value
        if (-not $facets.ContainsKey($facet)) { $errors.Add("unknown_facet:$facet"); continue }
        if ($facets[$facet] -notcontains $val) { $errors.Add("invalid_value:$facet/$val"); continue }
        $facetValues[$facet] += $val
        continue
      }

      if (-not $freeRe.IsMatch($tag)) { $errors.Add("invalid_free_tag:$tag") }
    }

    foreach ($f in $required) {
      $vals = @($facetValues[$f])
      $unique = @($vals | Select-Object -Unique)
      if ($unique.Count -ne $vals.Count) { $errors.Add("duplicate_facet_value:$f") }
      $c = $card[$f]
      if ($c -eq 'one') {
        if ($unique.Count -gt 1) { $errors.Add("multiple_values_not_allowed:$f") }
        if ($unique.Count -eq 0) {
          if ($RequireFacets) { $errors.Add("missing_facet:$f") } else { $warnings.Add("missing_facet:$f") }
        }
      } elseif ($c -eq 'oneOrMore') {
        if ($unique.Count -eq 0) {
          if ($RequireFacets) { $errors.Add("missing_facet:$f") } else { $warnings.Add("missing_facet:$f") }
        }
      }
    }

    $ok = ($errors.Count -eq 0)
    $results.Add([pscustomobject]@{
      file = $rel
      ok = $ok
      tags = @($tags)
      errors = @($errors.ToArray())
      warnings = @($warnings.ToArray())
      suggested = (Suggest-Facets $rel)
    }) | Out-Null
  }

$failures = @($results | Where-Object { -not $_.ok })
$summary = [pscustomobject]@{
  ok = ($failures.Count -eq 0)
  requireFacets = [bool]$RequireFacets
  taxonomy = $TaxonomyPath
  excluded = @($ExcludePaths)
  files = $results.Count
  failures = $failures.Count
  results = @($results.ToArray())
}

Ensure-ParentDir $SummaryOut
$json = $summary | ConvertTo-Json -Depth 8
Set-Content -LiteralPath $SummaryOut -Value $json -Encoding utf8
Write-Output $json
if ($FailOnError -and -not $summary.ok) { exit 1 }
