param(
  [string]$Path = "Wiki/EasyWayData.wiki",
  [string[]]$ExcludePaths = @('logs/reports', 'old', '.attachments'),
  [string]$ScopesPath = "docs/agentic/templates/docs/tag-taxonomy.scopes.json",
  [string]$ScopeName = "",
  [switch]$EnsureRunbookHowtoSections,
  [switch]$EnsureQuestionsSection,
  [switch]$Apply,
  [string]$SummaryOut = "wiki-sections-patch.json"
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
  $rel = $full.Substring($rootFull.Length).TrimStart('/',[char]92)
  return $rel.Replace([char]92,'/')
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
    $p = $p.Replace('\\','/')
    if ($p.EndsWith('/')) {
      if ($RelPath.StartsWith($p, [System.StringComparison]::OrdinalIgnoreCase)) { return $true }
    } else {
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

function Parse-LayerFromFrontMatter([string]$FrontMatter) {
  if (-not $FrontMatter) { return '' }
  if ($FrontMatter -match 'layer/(?<v>[a-zA-Z0-9_-]+)') { return [string]$Matches['v'] }
  return ''
}

function Has-Heading([string]$Text, [string]$Heading) {
  return [regex]::IsMatch($Text, "(?im)^##\s+$([regex]::Escape($Heading))\b")
}

function Ensure-TrailingNewLine([string]$Text) {
  if ([string]::IsNullOrEmpty($Text)) { return "`n" }
  if ($Text.EndsWith("`n")) { return $Text }
  return $Text + "`n"
}

function Append-SectionBlock {
  param(
    [string]$Text,
    [string[]]$Lines
  )
  $t = Ensure-TrailingNewLine $Text
  if (-not $t.EndsWith("`n`n")) { $t += "`n" }
  return $t + ($Lines -join "`n") + "`n"
}

$excludePrefixes = Resolve-ExcludePrefixes -Root $Path -Exclude $ExcludePaths
$scopeEntries = Load-ScopeEntries -ScopesPath $ScopesPath -ScopeName $ScopeName

$results = @()

$files = Get-ChildItem -LiteralPath $Path -Recurse -File -Filter '*.md' |
  Where-Object { -not (Is-Excluded -FullName ($_.FullName) -Prefixes $excludePrefixes) }

foreach ($f in $files) {
  $rel = Get-RelPath -Root $Path -FullName $f.FullName
  if (-not (Is-InScope -RelPath $rel -ScopeEntries $scopeEntries)) { continue }

  $text = Get-Content -LiteralPath $f.FullName -Raw -Encoding UTF8
  $fm = Extract-FrontMatter $text
  $layer = Parse-LayerFromFrontMatter $fm

  $changes = New-Object System.Collections.Generic.List[string]
  $newText = $text

  $needQuestions = $EnsureQuestionsSection -and ($layer -in @('runbook','howto','orchestration','intent')) -and (-not (Has-Heading $newText 'Domande a cui risponde'))
  if ($needQuestions) {
    $newText = Append-SectionBlock -Text $newText -Lines @(
      '## Domande a cui risponde',
      "- Qual e' l'obiettivo di questa procedura e quando va usata?",
      "- Quali prerequisiti servono (accessi, strumenti, permessi)?",
      "- Quali sono i passi minimi e quali sono i punti di fallimento piu comuni?",
      "- Come verifico l'esito e dove guardo log/artifact in caso di problemi?"
    )
    $changes.Add('added_domande')
  }

  if ($EnsureRunbookHowtoSections -and ($layer -in @('runbook','howto'))) {
    if (-not (Has-Heading $newText 'Prerequisiti')) {
      $newText = Append-SectionBlock -Text $newText -Lines @(
        '## Prerequisiti',
        "- Accesso al repository e al contesto target (subscription/tenant/ambiente) se applicabile.",
        "- Strumenti necessari installati (es. pwsh, az, sqlcmd, ecc.) in base ai comandi presenti nella pagina.",
        "- Permessi coerenti con il dominio (almeno read per verifiche; write solo se whatIf=false/approvato)."
      )
      $changes.Add('added_prerequisiti')
    }
    if (-not (Has-Heading $newText 'Passi')) {
      $newText = Append-SectionBlock -Text $newText -Lines @(
        '## Passi',
        '1. Raccogli gli input richiesti (parametri, file, variabili) e verifica i prerequisiti.',
        '2. Esegui i comandi/azioni descritti nella pagina in modalita non distruttiva (whatIf=true) quando disponibile.',
        "3. Se l'anteprima e' corretta, riesegui in modalita applicativa (solo con approvazione) e salva gli artifact prodotti."
      )
      $changes.Add('added_passi')
    }
    if (-not (Has-Heading $newText 'Verify')) {
      $newText = Append-SectionBlock -Text $newText -Lines @(
        '## Verify',
        "- Controlla che l'output atteso (file generati, risorse create/aggiornate, response API) sia presente e coerente.",
        "- Verifica log/artifact e, se previsto, che i gate (Checklist/Drift/KB) risultino verdi.",
        "- Se qualcosa fallisce, raccogli errori e contesto minimo (command line, parametri, correlationId) prima di riprovare."
      )
      $changes.Add('added_verify')
    }
  }

  $changed = ($newText -ne $text)
  if ($Apply -and $changed) {
    Set-Content -LiteralPath $f.FullName -Value $newText -Encoding utf8
  }

  $results += [pscustomobject]@{
    file = $rel
    layer = $layer
    changed = $changed
    applied = [bool]($Apply -and $changed)
    changes = @($changes.ToArray())
  }
}

$summary = [pscustomobject]@{
  applied = [bool]$Apply
  path = $Path
  excluded = @($ExcludePaths)
  scopesPath = $ScopesPath
  scopeName = $ScopeName
  ensureRunbookHowtoSections = [bool]$EnsureRunbookHowtoSections
  ensureQuestionsSection = [bool]$EnsureQuestionsSection
  files = $results.Count
  changed = (@($results | Where-Object { $_.changed })).Count
  results = $results
}

$json = $summary | ConvertTo-Json -Depth 6
Set-Content -LiteralPath $SummaryOut -Value $json -Encoding utf8
Write-Output $json
