param(
  [string]$Path = "Wiki/EasyWayData.wiki",
  [string]$TaxonomyPath = "docs/agentic/templates/docs/tag-taxonomy.json",
  [string[]]$ExcludePaths = @('logs/reports'),
  [switch]$RequireFacets,
  [ValidateSet('all','core')]
  [string]$RequireFacetsScope = 'all',
  [string]$ScopesPath = "docs/agentic/templates/docs/tag-taxonomy.scopes.json",
  [string]$ScopeName = 'core',
  [switch]$IncludeFullPath,
  [switch]$FailOnError,
  [string]$SummaryOut = "wiki-tags-lint.json"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

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

function Extract-FrontMatter {
  param([string]$Text)
  $m = [regex]::Match($Text, '^(---\r?\n)(?<fm>.*?)(\r?\n---\r?\n)', [System.Text.RegularExpressions.RegexOptions]::Singleline)
  if (-not $m.Success) { return $null }
  return $m.Groups['fm'].Value
}

function Parse-Tags {
  param([string]$FrontMatter)
  $tags = New-Object System.Collections.Generic.List[string]
  # Ensure callers always receive a stable array type (even for a single tag),
  # otherwise `$tags.Count` can fail when PowerShell unwraps a single string.
  if (-not $FrontMatter) { return ,@() }

  $inline = [regex]::Match($FrontMatter, '(?m)^tags\s*:\s*\[(?<v>[^\]]*)\]\s*$')
  if ($inline.Success) {
    $parts = $inline.Groups['v'].Value -split ','
    foreach ($p in $parts) {
      $t = $p.Trim()
      if ($t) { $tags.Add($t.Trim('"',[char]39)) }
    }
    return ,($tags.ToArray())
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
  return ,($tags.ToArray())
}

function Suggest-Facets {
  param([string]$WikiPath)
  $rel = '/' + $WikiPath.Replace('\\','/').TrimStart('/')
  $s = @{}

  if ($rel -match '/orchestrations/') { $s.domain = 'control-plane'; $s.layer = 'orchestration' }
  elseif ($rel -match '/control-plane/') { $s.domain = 'control-plane'; $s.layer = 'reference' }
  elseif ($rel -match '/domains/') {
    $s.layer = 'reference'
    if ($rel -match '/domains/db\.md$') { $s.domain = 'db' }
    elseif ($rel -match '/domains/datalake\.md$') { $s.domain = 'datalake' }
    elseif ($rel -match '/domains/frontend\.md$') { $s.domain = 'frontend' }
    elseif ($rel -match '/domains/docs-governance\.md$') { $s.domain = 'docs' }
    else { $s.domain = 'docs' }
  }
  elseif ($rel -match '/UX/') { $s.domain = 'ux'; $s.layer = 'spec' }
  elseif ($rel -match '/blueprints/') { $s.domain = 'docs'; $s.layer = 'blueprint' }
  elseif ($rel -match '/start-here\.md$') { $s.domain = 'docs'; $s.layer = 'index' }
  else { $s.domain = 'docs'; $s.layer = 'reference' }

  $s.privacy = 'internal'
  $s.language = 'it'
  $s.audience = @('dev')
  return $s
}

function Get-RelPath {
  param([string]$Root, [string]$FullName)
  $rootFull = (Resolve-Path -LiteralPath $Root).Path
  $full = (Resolve-Path -LiteralPath $FullName).Path
  $rel = $full.Substring($rootFull.Length).TrimStart('/',[char]92)
  return $rel.Replace([char]92,'/')
}

function Load-CoreScope {
  param([string]$ScopesPath, [string]$ScopeName)
  if (-not (Test-Path -LiteralPath $ScopesPath)) { return @() }
  $obj = Read-Json $ScopesPath
  $scope = $obj.scopes.$ScopeName
  if ($null -eq $scope) { return @() }
  return @($scope)
}

function Is-InScope {
  param([string]$RelPath, [string[]]$ScopeEntries)
  if ($null -eq $ScopeEntries -or $ScopeEntries.Count -eq 0) { return $true }
  foreach ($e in $ScopeEntries) {
    $p = [string]$e
    if (-not $p) { continue }
    $p = $p.Replace('\\','/')
    if ($p.EndsWith('/')) {
      if ($RelPath.StartsWith($p, [System.StringComparison]::OrdinalIgnoreCase)) { return $true }
    } else {
      if ($RelPath.Equals($p, [System.StringComparison]::OrdinalIgnoreCase)) { return $true }
    }
  }
  return $false
}

$tax = Read-Json $TaxonomyPath
$facets = @{}
foreach ($k in $tax.facets.PSObject.Properties.Name) { $facets[$k] = @($tax.facets.$k) }
$required = @($tax.required_facets)
$card = @{}
foreach ($k in $tax.facet_cardinality.PSObject.Properties.Name) { $card[$k] = [string]$tax.facet_cardinality.$k }
$freeRe = [regex]::new([string]$tax.free_tag_regex)

$scopeEntries = @()
if ($RequireFacets -and $RequireFacetsScope -eq 'core') {
  $scopeEntries = Load-CoreScope -ScopesPath $ScopesPath -ScopeName $ScopeName
}

$excludePrefixes = Resolve-ExcludePrefixes -Root $Path -Exclude $ExcludePaths

$results = @()
Get-ChildItem -LiteralPath $Path -Recurse -Filter *.md |
  Where-Object { -not (Is-Excluded -FullName ($_.FullName) -Prefixes $excludePrefixes) } |
  ForEach-Object {
    $file = $_.FullName
    $text = Get-Content -LiteralPath $file -Raw
    $fm = Extract-FrontMatter $text
    $tags = Parse-Tags $fm

    $errors = New-Object System.Collections.Generic.List[string]
    $warnings = New-Object System.Collections.Generic.List[string]

    $rel = Get-RelPath -Root $Path -FullName $file
    $inScope = if ($RequireFacets -and $RequireFacetsScope -eq 'core') { Is-InScope -RelPath $rel -ScopeEntries $scopeEntries } else { $true }
    if ($RequireFacets -and $RequireFacetsScope -eq 'core' -and -not $inScope) { return }

    if ($null -eq $fm) {
      $errors.Add('missing_front_matter')
      $r = @{ file = $rel; rel = $rel; ok = $false; inScope = $inScope; tags = @(); errors = @($errors); warnings = @($warnings) }
      if ($IncludeFullPath) { $r.fullPath = $file }
      $results += $r
      return
    }

    if ($tags.Count -eq 0) {
      $errors.Add('missing_tags')
      $r = @{ file = $rel; rel = $rel; ok = $false; inScope = $inScope; tags = @(); errors = @($errors); warnings = @($warnings) }
      if ($IncludeFullPath) { $r.fullPath = $file }
      $results += $r
      return
    }

    $facetValues = @{}
    foreach ($f in $required) { $facetValues[$f] = @() }

    foreach ($t in $tags) {
      $tag = $t.Trim()
      if (-not $tag) { continue }

      $m = [regex]::Match($tag, '^(?<facet>[a-zA-Z0-9_-]+)/(?<val>.+)$')
      if ($m.Success) {
        $facet = $m.Groups['facet'].Value
        $val = $m.Groups['val'].Value

        if (-not $facets.ContainsKey($facet)) {
          $errors.Add("unknown_facet:$facet")
          continue
        }

        if ($facets[$facet] -notcontains $val) {
          $errors.Add("invalid_value:$facet/$val")
          continue
        }

        $facetValues[$facet] += $val
        continue
      }

      if (-not $freeRe.IsMatch($tag)) {
        $errors.Add("invalid_free_tag:$tag")
      }
    }

    foreach ($f in $required) {
      $vals = @($facetValues[$f])
      $unique = @($vals | Select-Object -Unique)

      if ($unique.Count -ne $vals.Count) {
        $errors.Add("duplicate_facet_value:$f")
      }

      $c = $card[$f]
      if ($c -eq 'one') {
        if ($unique.Count -gt 1) { $errors.Add("multiple_values_not_allowed:$f") }
        if ($unique.Count -eq 0) {
          if ($RequireFacets -and $inScope -and $RequireFacetsScope -ne 'all') {
            $errors.Add("missing_facet:$f")
          } elseif ($RequireFacets -and $RequireFacetsScope -eq 'all') {
            $errors.Add("missing_facet:$f")
          } else {
            $warnings.Add("missing_facet:$f")
          }
        }
      } elseif ($c -eq 'oneOrMore') {
        if ($unique.Count -eq 0) {
          if ($RequireFacets -and $inScope -and $RequireFacetsScope -ne 'all') {
            $errors.Add("missing_facet:$f")
          } elseif ($RequireFacets -and $RequireFacetsScope -eq 'all') {
            $errors.Add("missing_facet:$f")
          } else {
            $warnings.Add("missing_facet:$f")
          }
        }
      }
    }

    $suggest = Suggest-Facets $rel
    $ok = ($errors.Count -eq 0)
    $r = @{ file = $rel; rel = $rel; ok = $ok; inScope = $inScope; tags = @($tags); errors = @($errors); warnings = @($warnings); suggested = $suggest }
    if ($IncludeFullPath) { $r.fullPath = $file }
    $results += $r
  }

$failures = @($results | Where-Object { -not $_.ok })
$summary = @{ ok = ($failures.Count -eq 0); requireFacets = [bool]$RequireFacets; requireFacetsScope = $RequireFacetsScope; scopeName = $ScopeName; scopesPath = $ScopesPath; taxonomy = $TaxonomyPath; excluded = $ExcludePaths; includeFullPath = [bool]$IncludeFullPath; files = $results.Count; failures = $failures.Count; results = $results }
$json = $summary | ConvertTo-Json -Depth 8
Set-Content -LiteralPath $SummaryOut -Value $json -Encoding utf8
Write-Output $json
if ($FailOnError -and -not $summary.ok) { exit 1 }
