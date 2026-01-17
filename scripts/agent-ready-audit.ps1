param(
  [ValidateSet('core', 'all')]
  [string]$Mode = 'all',
  [string]$RubricPath = "docs/agentic/templates/docs/agent-ready-rubric.json",
  [string]$SummaryOut = "agent-ready-audit.json",
  [string]$WikiPath,
  [switch]$FailOnError
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Read-Json([string]$p) {
  if (-not (Test-Path -LiteralPath $p)) { throw "JSON not found: $p" }
  return (Get-Content -LiteralPath $p -Raw | ConvertFrom-Json)
}

function New-TempFile([string]$prefix, [string]$ext) {
  $base = $env:RUNNER_TEMP
  if ([string]::IsNullOrWhiteSpace($base)) { $base = $env:TEMP }
  if ([string]::IsNullOrWhiteSpace($base)) { $base = (Get-Location).Path }
  $name = "$prefix-$([Guid]::NewGuid().ToString('N'))$ext"
  return (Join-Path $base $name)
}

function Test-JsonLineFile([string]$p) {
  if (-not (Test-Path -LiteralPath $p)) { return @{ ok = $false; error = 'missing' } }
  $lines = Get-Content -LiteralPath $p
  $i = 0
  foreach ($l in $lines) {
    $i++
    $t = $l.Trim()
    if (-not $t) { continue }
    try { $t | ConvertFrom-Json | Out-Null } catch { return @{ ok = $false; error = 'invalid_jsonl'; line = $i } }
  }
  return @{ ok = $true }
}

function Load-IntentNames([string]$dir) {
  if (-not (Test-Path -LiteralPath $dir)) { return @() }
  return @(Get-ChildItem -LiteralPath $dir -Filter '*.intent.json' -File | ForEach-Object { $_.Name -replace '\.intent\.json$', '' })
}

function Find-WikiDuplicateIds {
  param([string]$WikiPath)

  $excludeRe = [regex]::new("[/\\\\](old|logs|\\.attachments)[/\\\\]", [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
  $wikiFull = (Resolve-Path -LiteralPath $WikiPath).Path

  $pairs = New-Object System.Collections.Generic.List[object]
  Get-ChildItem -LiteralPath $WikiPath -Recurse -File -Filter '*.md' |
  Where-Object { -not $excludeRe.IsMatch($_.FullName) } |
  ForEach-Object {
    $lines = Get-Content -LiteralPath $_.FullName -TotalCount 80
    $head = ($lines -join "`n")
    if ($head -notmatch "(?ms)^---\\s*\\r?\\n(?<fm>.*?)(\\r?\\n---\\s*\\r?\\n)") { return }
    $fm = $Matches.fm
    if ($fm -notmatch "(?m)^id:\\s*(?<id>.+)$") { return }
    $id = $Matches.id.Trim()
    if ([string]::IsNullOrWhiteSpace($id)) { return }
    $rel = $_.FullName.Substring($wikiFull.Length).TrimStart([char]92).Replace([char]92, '/')
    $pairs.Add([pscustomobject]@{ id = $id; file = $rel })
  }

  $dups = @($pairs | Group-Object id | Where-Object Count -gt 1 | Sort-Object Name)
  $out = New-Object System.Collections.Generic.List[object]
  foreach ($g in $dups) {
    $files = @($g.Group | ForEach-Object { $_.file } | Sort-Object)
    $out.Add([pscustomobject]@{ id = $g.Name; files = $files })
  }
  return @($out.ToArray())
}

function Validate-BundlesScopes {
  param(
    [object]$Bundles,
    [object]$Scopes
  )
  $missing = New-Object System.Collections.Generic.List[string]
  if ($Bundles.bundles -and $Bundles.bundles.PSObject.Properties) {
    foreach ($prop in $Bundles.bundles.PSObject.Properties) {
      $bundle = $prop.Value
      foreach ($name in @($bundle.scopes)) {
        if ($Scopes.scopes.PSObject.Properties.Name -notcontains $name) { $missing.Add([string]$name) }
      }
    }
  }
  return @($missing | Sort-Object -Unique)
}

function Validate-BundlesIntentCoverage {
  param(
    [object]$Bundles,
    [string[]]$IntentNames
  )
  $covered = @()
  if ($Bundles.bundles -and $Bundles.bundles.PSObject.Properties) {
    $covered = @($Bundles.bundles.PSObject.Properties | ForEach-Object { [string]$_.Value.intent })
  }
  $missing = New-Object System.Collections.Generic.List[string]
  foreach ($i in $IntentNames) {
    if ($covered -notcontains $i) { $missing.Add([string]$i) }
  }
  return @($missing | Sort-Object -Unique)
}

$rubric = Read-Json $RubricPath
$defaults = $rubric.defaults

# Auto-detect WikiPath from manifest if not provided
if ([string]::IsNullOrWhiteSpace($WikiPath)) {
  $manifestPath = Join-Path $PSScriptRoot "../../../Rules/manifest.json"
  if (Test-Path $manifestPath) {
    try {
      $m = Get-Content $manifestPath -Raw | ConvertFrom-Json
      if ($m.wikiRoot) { 
        $WikiPath = $m.wikiRoot
        Write-Host " [Audit] Uncovered WikiRoot from manifest: $WikiPath" -ForegroundColor Cyan
      }
    }
    catch { 
      Write-Warning " [Audit] Failed to read manifest for wikiRoot" 
    }
  }
}

$wikiPath = if ([string]::IsNullOrWhiteSpace($WikiPath)) { [string]$defaults.wikiPath } else { $WikiPath }
$scopesPath = [string]$defaults.scopesPath
$taxonomyPath = [string]$defaults.taxonomyPath
$bundlesPath = [string]$defaults.bundlesPath
$intentsDir = [string]$defaults.intentsDir
$orchestrationsDir = [string]$defaults.orchestrationsDir
$kbRecipesPath = [string]$defaults.kbRecipesPath

$scopes = Read-Json $scopesPath
$bundles = Read-Json $bundlesPath
$intentNames = Load-IntentNames $intentsDir

$scopeSet = @($rubric.recommended_scope_sets.$Mode)
if ($null -eq $scopeSet -or $scopeSet.Count -eq 0) { throw "No scope set found in rubric for mode: $Mode" }

$results = New-Object System.Collections.Generic.List[object]

# 1) WHAT-first
$tmpWhat = New-TempFile -prefix 'whatfirst' -ext '.json'
try {
  $out = pwsh -File "$PSScriptRoot/whatfirst-lint.ps1" -OrchDir "$orchestrationsDir" -IntentsDir "$intentsDir" -SummaryOut "$tmpWhat" | Out-String
  $json = Get-Content -LiteralPath $tmpWhat -Raw | ConvertFrom-Json
  $results.Add([ordered]@{ id = 'whatfirst.json-valid'; ok = [bool]$json.ok; severity = 'error'; summaryOut = $tmpWhat })
}
catch {
  $results.Add([ordered]@{ id = 'whatfirst.json-valid'; ok = $false; severity = 'error'; error = $_.Exception.Message })
}
finally {
  if (Test-Path -LiteralPath $tmpWhat) { Remove-Item -Force -LiteralPath $tmpWhat -ErrorAction SilentlyContinue }
}

# 2) Per-scope Wiki checks
foreach ($scopeName in $scopeSet) {
  $tmpFm = New-TempFile -prefix "frontmatter-$scopeName" -ext '.json'
  $tmpTags = New-TempFile -prefix "tags-$scopeName" -ext '.json'
  $tmpLinks = New-TempFile -prefix "links-$scopeName" -ext '.json'
  $tmpSummary = New-TempFile -prefix "summary-$scopeName" -ext '.json'
  try {
    $fm = pwsh -File "$PSScriptRoot/wiki-frontmatter-lint.ps1" -Path "$wikiPath" -ExcludePaths logs/reports -ScopesPath "$scopesPath" -ScopeName "$scopeName" -DraftHygiene warn -SummaryOut "$tmpFm" | Out-String
    $fmj = Get-Content -LiteralPath $tmpFm -Raw | ConvertFrom-Json
    $results.Add([ordered]@{ id = 'docs.frontmatter'; scope = $scopeName; ok = [bool]$fmj.ok; severity = 'error'; files = [int]$fmj.files; failures = [int]$fmj.failures })
    $draftIssues = 0
    if ($fmj.PSObject.Properties.Name -contains 'draftIssues') { $draftIssues = [int]$fmj.draftIssues }
    $results.Add([ordered]@{ id = 'docs.draft.hygiene'; scope = $scopeName; ok = ($draftIssues -eq 0); severity = 'warning'; issues = $draftIssues })

    $tags = pwsh -File "$PSScriptRoot/wiki-tags-lint.ps1" -Path "$wikiPath" -TaxonomyPath "$taxonomyPath" -ExcludePaths "logs/reports" -RequireFacets -RequireFacetsScope core -ScopeName "$scopeName" -SummaryOut "$tmpTags" | Out-String
    $tj = Get-Content -LiteralPath $tmpTags -Raw | ConvertFrom-Json
    $results.Add([ordered]@{ id = 'docs.tags.taxonomy'; scope = $scopeName; ok = [bool]$tj.ok; severity = 'error'; files = [int]$tj.files; failures = [int]$tj.failures })

    $links = pwsh -File "$PSScriptRoot/wiki-links-anchors-lint.ps1" -Path "$wikiPath" -ExcludePaths "logs/reports,old,.attachments" -ScopesPath "$scopesPath" -ScopeName "$scopeName" -SummaryOut "$tmpLinks" | Out-String
    $lj = Get-Content -LiteralPath $tmpLinks -Raw | ConvertFrom-Json
    $results.Add([ordered]@{ id = 'docs.links.anchors'; scope = $scopeName; ok = [bool]$lj.ok; severity = 'error'; files = [int]$lj.files; issues = [int]$lj.issues })

    $sum = pwsh -File "$PSScriptRoot/wiki-summary-lint.ps1" -Path "$wikiPath" -ExcludePaths "logs/reports,old,.attachments" -ScopesPath "$scopesPath" -ScopeName "$scopeName" -SummaryOut "$tmpSummary" | Out-String
    $sj = Get-Content -LiteralPath $tmpSummary -Raw | ConvertFrom-Json
    $results.Add([ordered]@{ id = 'docs.summary.no-placeholder'; scope = $scopeName; ok = [bool]$sj.ok; severity = 'warning'; files = [int]$sj.files; failures = [int]$sj.failures })
  }
  catch {
    $results.Add([ordered]@{ id = 'docs.lint.error'; scope = $scopeName; ok = $false; severity = 'error'; error = $_.Exception.Message })
  }
  finally {
    foreach ($p in @($tmpFm, $tmpTags, $tmpLinks, $tmpSummary)) {
      if ($p -and (Test-Path -LiteralPath $p)) { Remove-Item -Force -LiteralPath $p -ErrorAction SilentlyContinue }
    }
  }
}

# 2b) Global wiki id uniqueness (indipendente dagli scope)
$dupIds = @(Find-WikiDuplicateIds -WikiPath $wikiPath)
$results.Add([ordered]@{
    id         = 'docs.ids.unique'
    ok         = ($dupIds.Count -eq 0)
    severity   = 'error'
    duplicates = $dupIds
  })

# 3) Bundles sanity (scopes + coverage)
$missingScopes = @(Validate-BundlesScopes -Bundles $bundles -Scopes $scopes)
$missingIntents = @(Validate-BundlesIntentCoverage -Bundles $bundles -IntentNames $intentNames)
$bundlesOk = ($missingScopes.Count -eq 0 -and $missingIntents.Count -eq 0)
$results.Add([ordered]@{
    id             = 'retrieval.bundles.valid'
    ok             = $bundlesOk
    severity       = 'error'
    missingScopes  = @($missingScopes)
    missingIntents = @($missingIntents)
  })

# 4) KB recipes jsonl parse
$kb = Test-JsonLineFile -p $kbRecipesPath
$results.Add([ordered]@{ id = 'kb.recipes.jsonl'; ok = [bool]$kb.ok; severity = 'error'; details = $kb })

$resultsArray = @($results.ToArray())
$errors = @($resultsArray | Where-Object { -not $_.ok -and $_.severity -eq 'error' })
$warnings = @($resultsArray | Where-Object { -not $_.ok -and $_.severity -eq 'warning' })
$summary = [pscustomobject]@{
  ok      = ($errors.Count -eq 0)
  mode    = $Mode
  scopes  = @($scopeSet)
  rubric  = $RubricPath
  counts  = [pscustomobject]@{ errors = $errors.Count; warnings = $warnings.Count; checks = $resultsArray.Count }
  results = $resultsArray
}

$jsonOut = $summary | ConvertTo-Json -Depth 8
Set-Content -LiteralPath $SummaryOut -Value $jsonOut -Encoding utf8
Write-Output $jsonOut
if ($FailOnError -and -not $summary.ok) { exit 1 }
