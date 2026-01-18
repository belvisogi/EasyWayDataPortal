param(
  [string]$Path = "Wiki/EasyWayData.wiki",
  [string[]]$ExcludePaths = @('logs/reports'),
  [string]$ScopesPath = "docs/agentic/templates/docs/tag-taxonomy.scopes.json",
  [string]$ScopeName = "",
  [ValidateSet('off','warn','error')]
  [string]$DraftHygiene = 'off',
  [switch]$IncludeFullPath,
  [switch]$FailOnError,
  [string]$SummaryOut = "wiki-frontmatter-lint.json"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

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

function Get-RelPath {
  param([string]$Root, [string]$FullName)
  $rootFull = (Resolve-Path -LiteralPath $Root).Path
  $full = (Resolve-Path -LiteralPath $FullName).Path
  $rel = $full.Substring($rootFull.Length).TrimStart('/',[char]92)
  return $rel.Replace([char]92,'/')
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

function Test-FrontMatter {
  param(
    [string]$File,
    [string]$RelPath,
    [string]$DraftHygiene,
    [switch]$IncludeFullPath
  )
  $text = Get-Content -LiteralPath $File -Raw -ErrorAction Stop
  if (-not $text.StartsWith("---`n") -and -not $text.StartsWith("---`r`n")) {
    $r = @{ file = $RelPath; ok = $false; error = 'missing_yaml_front_matter' }
    if ($IncludeFullPath) { $r.fullPath = $File }
    return $r
  }
  $end = ($text.IndexOf("`n---", 4))
  if ($end -lt 0) {
    $r = @{ file = $RelPath; ok = $false; error = 'unterminated_front_matter' }
    if ($IncludeFullPath) { $r.fullPath = $File }
    return $r
  }

  $fm = $text.Substring(4, $end - 4)
  $lines = $fm -split "`r?`n"
  $req = @{ id=$false; title=$false; summary=$false; status=$false; owner=$false; tags=$false; llm_include=$false; llm_chunk=$false }

  $inLlm = $false
  $inTags = $false
  foreach ($l in $lines) {
    $t = $l.TrimEnd()
    $tt = $t.Trim()

    if ($tt -match '^id\s*:\s*\S+') { $req.id = $true; $inTags = $false; continue }
    if ($tt -match '^title\s*:\s*\S+') { $req.title = $true; $inTags = $false; continue }
    # summary can be empty in legacy; treat empty as missing
    if ($tt -match '^summary\s*:\s*\S+') { $req.summary = $true; $inTags = $false; continue }
    if ($tt -match '^status\s*:\s*\S+') { $req.status = $true; $inTags = $false; continue }
    if ($tt -match '^owner\s*:\s*\S+') { $req.owner = $true; $inTags = $false; continue }

    if ($tt -match '^tags\s*:\s*\[') { $req.tags = $true; $inTags = $false; continue }
    if ($tt -match '^tags\s*:\s*$') { $inTags = $true; continue }
    if ($inTags -and $tt -match '^\-\s*\S+') { $req.tags = $true; continue }

    if ($tt -match '^llm\s*:\s*$') { $inLlm = $true; $inTags = $false; continue }
    if ($inLlm -and $tt -match '^include\s*:\s*(true|false)\s*$') { $req.llm_include = $true; continue }
    if ($inLlm -and $tt -match '^chunk_hint\s*:\s*\d+(-\d+)?\s*$') { $req.llm_chunk = $true; continue }

    # Exit llm if we see a new top-level key
    if ($inLlm -and $l -match '^[A-Za-z0-9_-]+\s*:') { $inLlm = $false }
  }

  $missing = @()
  foreach ($k in $req.Keys) { if (-not $req[$k]) { $missing += $k } }
  if ($missing.Count -gt 0) {
    $r = @{ file = $RelPath; ok = $false; missing = $missing }
    if ($IncludeFullPath) { $r.fullPath = $File }
    return $r
  }

  $r = @{ file = $RelPath; ok = $true }
  if ($IncludeFullPath) { $r.fullPath = $File }

  # Draft hygiene (phased): draft pages should not be "stale noise"
  if ($DraftHygiene -ne 'off') {
    $status = ''
    if ($fm -match '(?m)^status\s*:\s*(?<s>\S+)\s*$') { $status = $Matches['s'].Trim().ToLowerInvariant() }
    if ($status -eq 'draft') {
      $missingDraft = @()
      $hasUpdated = [regex]::IsMatch($fm, '(?m)^updated\s*:\s*\S+')
      $hasNext = [regex]::IsMatch($fm, '(?m)^next\s*:\s*\S+')
      $hasChecklist = [regex]::IsMatch($fm, '(?m)^checklist\s*:\s*(\[|$)')
      if (-not $hasUpdated) { $missingDraft += 'updated' }
      if (-not $hasNext -and -not $hasChecklist) { $missingDraft += 'next_or_checklist' }

      if ($missingDraft.Count -gt 0) {
        $r.draftMissing = $missingDraft
        if ($DraftHygiene -eq 'error') { $r.ok = $false }
      }
    }
  }

  return $r
}

$excludePrefixes = Resolve-ExcludePrefixes -Root $Path -Exclude $ExcludePaths
$scopeEntries = Load-ScopeEntries -ScopesPath $ScopesPath -ScopeName $ScopeName

$results = @()
Get-ChildItem -LiteralPath $Path -Recurse -Filter *.md |
  Where-Object { -not (Is-Excluded -FullName ($_.FullName) -Prefixes $excludePrefixes) } |
  ForEach-Object {
    $rel = Get-RelPath -Root $Path -FullName $_.FullName
    if (-not (Is-InScope -RelPath $rel -ScopeEntries $scopeEntries)) { return }
    $results += Test-FrontMatter -File $_.FullName -RelPath $rel -DraftHygiene $DraftHygiene -IncludeFullPath:$IncludeFullPath
  }

$failures = @($results | Where-Object { -not $_.ok })
$draftIssues = @(
  $results | Where-Object {
    if ($_ -is [hashtable]) {
      return $_.ContainsKey('draftMissing') -and $_.draftMissing -and $_.draftMissing.Count -gt 0
    }
    return ($_.PSObject.Properties.Name -contains 'draftMissing') -and $_.draftMissing -and $_.draftMissing.Count -gt 0
  }
)
$summary = @{
  ok = ($failures.Count -eq 0)
  excluded = $ExcludePaths
  scopesPath = $ScopesPath
  scopeName = $ScopeName
  draftHygiene = $DraftHygiene
  draftIssues = $draftIssues.Count
  includeFullPath = [bool]$IncludeFullPath
  files = $results.Count
  failures = $failures.Count
  results = $results
}
$json = $summary | ConvertTo-Json -Depth 6
Set-Content -LiteralPath $SummaryOut -Value $json -Encoding utf8
Write-Output $json
if ($FailOnError -and -not $summary.ok) { exit 1 }
