param(
  [string]$Path = "Wiki/EasyWayData.wiki",
  [string[]]$ExcludePaths = @('logs/reports', 'old', '.attachments'),
  [string]$ScopesPath = "docs/agentic/templates/docs/tag-taxonomy.scopes.json",
  [string]$ScopeName = "",
  [string[]]$PlaceholderSummaries = @(
    'Breve descrizione del documento.',
    'TODO - aggiungere un sommario breve.',
    'TODO - definire next step.'
  ),
  [string]$SummaryOut = "wiki-gap-report.json",
  [switch]$FailOnError
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

function Extract-FrontMatter([string]$Text) {
  $m = [regex]::Match($Text, '^(---\r?\n)(?<fm>.*?)(\r?\n---\r?\n)', [System.Text.RegularExpressions.RegexOptions]::Singleline)
  if (-not $m.Success) { return $null }
  return $m.Groups['fm'].Value
}

function Get-FmValue([string]$FrontMatter, [string]$Key) {
  if (-not $FrontMatter) { return '' }
  $m = [regex]::Match($FrontMatter, "(?m)^$([regex]::Escape($Key))\s*:\s*(?<v>.*)$")
  if (-not $m.Success) { return '' }
  return ($m.Groups['v'].Value).Trim()
}

function Has-LlmIncludeFalse([string]$FrontMatter) {
  if (-not $FrontMatter) { return $false }
  return [regex]::IsMatch($FrontMatter, '(?m)^\s*include\s*:\s*false\s*$')
}

function Has-Heading([string]$Text, [string]$Heading) {
  return [regex]::IsMatch($Text, "(?im)^##\s+$([regex]::Escape($Heading))\b")
}

function Parse-LayerFromFrontMatter([string]$FrontMatter) {
  if (-not $FrontMatter) { return '' }
  if ($FrontMatter -match 'layer/(?<v>[a-zA-Z0-9_-]+)') { return [string]$Matches['v'] }
  return ''
}

$excludePrefixes = Resolve-ExcludePrefixes -Root $Path -Exclude $ExcludePaths
$scopeEntries = Load-ScopeEntries -ScopesPath $ScopesPath -ScopeName $ScopeName

$results = New-Object System.Collections.Generic.List[object]
$files = @(Get-ChildItem -LiteralPath $Path -Recurse -File -Filter '*.md' |
  Where-Object { -not (Is-Excluded -FullName ($_.FullName) -Prefixes $excludePrefixes) })

$totalFiles = $files.Count
$processed = 0

foreach ($f in $files) {
  $processed++
  if ($processed % 10 -eq 0) {
    Write-Progress -Activity "Analyzing Wiki Gaps" -Status "Linting files" -PercentComplete (($processed / $totalFiles) * 100) -CurrentOperation "$($f.Name)"
  }
  $rel = Get-RelPath -Root $Path -FullName $f.FullName
  if (-not (Is-InScope -RelPath $rel -ScopeEntries $scopeEntries)) { continue }

  $text = Get-Content -LiteralPath $f.FullName -Raw -Encoding UTF8
  $fm = Extract-FrontMatter $text
  if ($null -eq $fm) {
    $results.Add([pscustomobject]@{ file = $rel; ok = $false; issues = @('missing_front_matter') })
    continue
  }

  $issues = New-Object System.Collections.Generic.List[string]

  $status = (Get-FmValue $fm 'status').ToLowerInvariant()
  $owner = Get-FmValue $fm 'owner'
  $summary = Get-FmValue $fm 'summary'
  $updated = Get-FmValue $fm 'updated'
  $next = Get-FmValue $fm 'next'
  $hasChecklist = [regex]::IsMatch($fm, '(?m)^checklist\s*:\s*(\[\s*|$)')
  $canonical = Get-FmValue $fm 'canonical'
  $layer = Parse-LayerFromFrontMatter $fm

  if ([string]::IsNullOrWhiteSpace($owner)) { $issues.Add('missing_owner') }

  if ([string]::IsNullOrWhiteSpace($summary)) { $issues.Add('missing_summary') }
  elseif ($PlaceholderSummaries -contains $summary) { $issues.Add('placeholder_summary') }

  if ($status -eq 'draft') {
    if ([string]::IsNullOrWhiteSpace($updated)) { $issues.Add('draft_missing_updated') }
    if ([string]::IsNullOrWhiteSpace($next) -and -not $hasChecklist) { $issues.Add('draft_missing_next_or_checklist') }
  }

  if ($status -eq 'deprecated') {
    if ([string]::IsNullOrWhiteSpace($canonical)) { $issues.Add('deprecated_missing_canonical') }
    if (-not (Has-LlmIncludeFalse $fm)) { $issues.Add('deprecated_llm_include_not_false') }
  }

  if ($layer -in @('runbook', 'howto')) {
    if (-not (Has-Heading $text 'Prerequisiti')) { $issues.Add('missing_section_prerequisiti') }
    if (-not (Has-Heading $text 'Passi')) { $issues.Add('missing_section_passi') }
    if (-not (Has-Heading $text 'Verify')) { $issues.Add('missing_section_verify') }
  }

  if ($layer -in @('runbook', 'howto', 'orchestration', 'intent')) {
    if (-not (Has-Heading $text 'Domande a cui risponde')) {
      $issues.Add('missing_section_domande_a_cui_risponde')
    }
  }

  $ok = ($issues.Count -eq 0)
  $results.Add([pscustomobject]@{
      file   = $rel
      ok     = $ok
      status = $status
      layer  = $layer
      issues = @($issues.ToArray())
    })
}
Write-Progress -Activity "Analyzing Wiki Gaps" -Completed

$resultsArray = @($results.ToArray())
$failures = @($resultsArray | Where-Object { -not $_.ok })
$summary = [pscustomobject]@{
  ok         = ($failures.Count -eq 0)
  path       = $Path
  excluded   = @($ExcludePaths)
  scopesPath = $ScopesPath
  scopeName  = $ScopeName
  files      = $resultsArray.Count
  failures   = $failures.Count
  counts     = [pscustomobject]@{
    missing_owner                  = (@($resultsArray | Where-Object { $_.issues -contains 'missing_owner' })).Count
    missing_or_placeholder_summary = (@($resultsArray | Where-Object { $_.issues -contains 'missing_summary' -or $_.issues -contains 'placeholder_summary' })).Count
    draft_missing_hygiene          = (@($resultsArray | Where-Object { $_.issues -contains 'draft_missing_updated' -or $_.issues -contains 'draft_missing_next_or_checklist' })).Count
    deprecated_missing_redirect    = (@($resultsArray | Where-Object { $_.issues -contains 'deprecated_missing_canonical' -or $_.issues -contains 'deprecated_llm_include_not_false' })).Count
    runbook_howto_missing_sections = (@(
        $resultsArray | Where-Object {
          $_.issues -contains 'missing_section_prerequisiti' -or
          $_.issues -contains 'missing_section_passi' -or
          $_.issues -contains 'missing_section_verify'
        }
      )).Count
    missing_questions              = (@($resultsArray | Where-Object { $_.issues -contains 'missing_section_domande_a_cui_risponde' })).Count
  }
  results    = $resultsArray
}

$json = $summary | ConvertTo-Json -Depth 8
Set-Content -LiteralPath $SummaryOut -Value $json -Encoding utf8
Write-Output $json
if ($FailOnError -and -not $summary.ok) { exit 1 }
