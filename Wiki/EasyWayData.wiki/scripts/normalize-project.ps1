[CmdletBinding()]
param(
  [Parameter(Mandatory=$true)][string]$Root,
  [ValidateSet('scan','apply')][string]$Mode = 'apply',
  [string[]]$DefaultSqlPatterns = @(
    '**/programmability/*.md',
    '**/programmability/**/*.md',
    '**/stored-procedure/*.md',
    '**/stored-procedure/**/*.md'
  ),
  [string[]]$AllowedFenceLangs = @('sql','sh','bash','powershell','json','text','js','ts','tsx','python','yaml','yml'),
  [switch]$EnsureArtifactTags = $true,
  [switch]$EnsureIndexQA = $true,
  [switch]$EnsureFrontMatter = $false,
  [string]$EntitiesYaml = '',
  [string]$ReportPath = '' ,
  [string]$DefaultIndexQAText = "## Domande a cui risponde`n- Che cosa raccoglie questo indice?`n- Dove sono i documenti principali collegati?`n- Come verificare naming e ancore per questa cartella?`n- Dove trovare entità e guide correlate?`n"
)

Set-StrictMode -Version Latest
$PSDefaultParameterValues['*:ErrorAction'] = 'Stop'

$Root = (Resolve-Path $Root)
$normFence = Join-Path $PSScriptRoot 'normalize-code-fences.ps1'
$bulkFM = Join-Path $PSScriptRoot 'bulk-frontmatter.ps1'
$entitiesScript = Join-Path $PSScriptRoot 'generate-entities-index.ps1'

function Resolve-Glob([string]$root,[string]$glob){
  $pattern = $glob -replace '\*\*','*'
  Get-ChildItem -Path $root -Recurse -File -Filter *.md | Where-Object {
    $rel = [System.IO.Path]::GetRelativePath($root, $_.FullName) -replace '\\','/'
    switch -Wildcard ($glob) {
      '**/*.md' { return $true }
      default { return ($rel -like ($glob -replace '\\','/')) }
    }
  } | ForEach-Object { $_.FullName }
}

function Has-FrontMatter {
  param([string]$Text)
  return ($Text -match '^(?s)---\s*\n.*?\n---\s*\n')
}

function QA-Count {
  param([string]$Text)
  $lines = $Text -split "\r?\n"
  $hit = $lines | Select-String -SimpleMatch '## Domande a cui risponde' | Select-Object -First 1
  if (-not $hit) { return 0 }
  $start = $hit.LineNumber
  $count = 0
  for($i=$start; $i -lt $lines.Count; $i++){
    $line = $lines[$i]
    if ($i -ne $start -and $line -match '^#'){ break }
    if ($line -match '^\s*[-*]\s+.+$'){ $count++ }
  }
  return $count
}

function Fence-Issues {
  param([string]$Text,[string[]]$Allowed)
  $missing = New-Object System.Collections.Generic.List[int]
  $bad = New-Object System.Collections.Generic.List[string]
  $lines = $Text -split "\r?\n"
  for($i=0; $i -lt $lines.Count; $i++){
    $l = $lines[$i]
    if ($l -match '^```(.*)$'){
      $rest = $Matches[1].Trim()
      if (-not $rest){ $missing.Add($i+1) | Out-Null }
      elseif ($Allowed -and ($rest -notin $Allowed)){ $bad.Add(("{0}:{1}" -f ($i+1), $rest)) | Out-Null }
    }
  }
  return @{ missing = $missing; bad = $bad }
}

function Load-EntitiesMap {
  param([string]$YamlPath,[string]$Root)
  $map = @{}
  if (-not (Test-Path -LiteralPath $YamlPath)) { return $map }
  . $entitiesScript
  $raw = Get-Content -LiteralPath $YamlPath -Raw -Encoding UTF8
  $doc = Parse-YamlSimple -text $raw
  foreach($section in @('endpoints','db_storeprocedures','db_sequences','policies','flows','data','standards','guides')){
    $items = $doc[$section]
    if (-not $items) { continue }
    foreach($it in $items){
      $p = $it.path
      if ($p){
        $rel = $p -replace '^EasyWayData\.wiki/',''
        $rel = $rel -replace '\\','/'
        $map[$rel] = $it.id
      }
    }
  }
  return $map
}

if (-not $ReportPath) {
  $ts = (Get-Date).ToString('yyyyMMddHHmmss')
  $ReportPath = Join-Path $Root ("logs/reports/normalize-" + $ts + ".md")
}

# SCAN phase (always runs first)
$files = Get-ChildItem -Path $Root -Recurse -File -Filter *.md | Where-Object { $_.FullName -notmatch '\\logs\\reports\\' -and $_.FullName -notmatch '\\.attachments\\' }
$entitiesYamlPath = if ($EntitiesYaml){ $EntitiesYaml } else { Join-Path $Root 'entities.yaml' }
$emap = Load-EntitiesMap -YamlPath $entitiesYamlPath -Root $Root

$rows = New-Object System.Collections.Generic.List[object]
foreach($f in $files){
  $rel = [System.IO.Path]::GetRelativePath($Root, $f.FullName) -replace '\\','/'
  $text = Get-Content -LiteralPath $f.FullName -Raw -Encoding UTF8
  $fm = Has-FrontMatter -Text $text
  $qac = QA-Count -Text $text
  $fences = Fence-Issues -Text $text -Allowed $AllowedFenceLangs
  $needsArtifact = $false
  if ($rel -like '*/programmability/function.md') { $needsArtifact = ($text -notmatch 'artifact/function') }
  if ($rel -like '*/programmability/sequence.md') { $needsArtifact = ($text -notmatch 'artifact/sequence') }
  if ($rel -match '/stored-procedure/' -and $text -notmatch 'artifact/stored-procedure') { $needsArtifact = $true }
  $needsEntity = $false
  if ($emap.ContainsKey($rel) -and $text -notmatch '(?m)^entities:\s*\[.*\]') { $needsEntity = $true }
  $rows.Add([pscustomobject]@{
    path=$rel; front_matter=$fm; qa_count=$qac; fences_missing= ($fences.missing -join ';'); fences_bad= ($fences.bad -join ';'); needs_artifact_tag=$needsArtifact; suggest_entity= ($emap[$rel])
  }) | Out-Null
}

# Write scan report
$sb = New-Object System.Text.StringBuilder
$null = $sb.AppendLine('# Normalize Scan Report')
$null = $sb.AppendLine('')
$null = $sb.AppendLine('| path | front_matter | qa_count | fences_missing | fences_bad | needs_artifact_tag | suggest_entity |')
$null = $sb.AppendLine('|---|---|---|---|---|---|---|')
foreach($r in $rows){ $null = $sb.AppendLine("| $($r.path) | $($r.front_matter) | $($r.qa_count) | $($r.fences_missing) | $($r.fences_bad) | $($r.needs_artifact_tag) | $($r.suggest_entity) |") }
New-Item -ItemType Directory -Force -Path (Split-Path -Parent $ReportPath) | Out-Null
Set-Content -LiteralPath $ReportPath -Value $sb.ToString() -Encoding UTF8

if ($Mode -eq 'scan'){
  . (Join-Path $PSScriptRoot 'add-log.ps1') -Type LINT -Scope normalize-project -Status success -Owner team-docs -Message ("Scan only: report=" + ([IO.Path]::GetFileName($ReportPath))) -Split monthly | Out-Host
  Write-Host "Scan complete. Report: $ReportPath"
  return
}

# APPLY phase
if ($EnsureFrontMatter){ . $bulkFM -Root $Root -DefaultTag 'layer/reference' | Out-Host }

# Normalize fences for SQL-centric areas
$include = New-Object System.Collections.Generic.List[string]
foreach($g in $DefaultSqlPatterns){ (Resolve-Glob -root $Root -glob $g) | ForEach-Object { $include.Add($_) | Out-Null } }
if ($include.Count -gt 0){ . $normFence -Root $Root -Include $include -DefaultLang 'sql' | Out-Host }

function Ensure-YamlTag([string]$file,[string]$tag){
  $raw = Get-Content -LiteralPath $file -Raw -Encoding UTF8
  if ($raw -notmatch '^(?s)---\s*\n'){ return }
  if ($raw -match '(?m)^tags:\s*$'){
    if ($raw -notmatch [regex]::Escape($tag)){
      $raw = $raw -replace '(?m)^tags:\s*$', "tags:`n  - $tag"
      Set-Content -LiteralPath $file -Value $raw -Encoding UTF8
    }
  } elseif ($raw -match '(?m)^tags:\s*\n(?:\s*-.*\n)+'){
    if ($raw -notmatch [regex]::Escape($tag)){
      $raw = $raw -replace '(?m)^(tags:\s*\n)', "$1  - $tag`n"
      Set-Content -LiteralPath $file -Value $raw -Encoding UTF8
    }
  } else {
    # no tags block, insert minimal
    $raw = $raw -replace '^(?m)---\s*\n', "---`ntags:`n  - $tag`n"
    Set-Content -LiteralPath $file -Value $raw -Encoding UTF8
  }
}

if ($EnsureArtifactTags){
  # programmability function/sequence/stored-procedure
  Get-ChildItem -Path $Root -Recurse -File -Filter function.md | ForEach-Object { Ensure-YamlTag -file $_.FullName -tag 'artifact/function' }
  Get-ChildItem -Path $Root -Recurse -File -Filter sequence.md | ForEach-Object { Ensure-YamlTag -file $_.FullName -tag 'artifact/sequence' }
  Get-ChildItem -Path $Root -Recurse -File -Filter *.md | Where-Object { $_.FullName -match '/stored-procedure/' -or $_.FullName -match '\\stored-procedure\\' } | ForEach-Object { Ensure-YamlTag -file $_.FullName -tag 'artifact/stored-procedure' }
}

if ($EnsureIndexQA){
  $indexes = Get-ChildItem -Path $Root -Recurse -File -Filter index.md
  foreach($idx in $indexes){
    $txt = Get-Content -LiteralPath $idx.FullName -Raw -Encoding UTF8
    if ($txt -notmatch '(?m)^##\s+Domande a cui risponde\s*$'){
      Add-Content -LiteralPath $idx.FullName -Value ("`n" + $DefaultIndexQAText) -Encoding UTF8
    }
  }
}

# Add entities from map when missing
foreach($r in $rows){
  if ($r.suggest_entity){
    $dest = Join-Path $Root $r.path
    if (Test-Path -LiteralPath $dest){
      $raw = Get-Content -LiteralPath $dest -Raw -Encoding UTF8
      if ($raw -notmatch '(?m)^entities:\s*\['){
        $raw = $raw -replace '^(?m)entities:\s*\[.*\]\s*$', ''
        $raw = $raw -replace '^(?m)---\s*\n', ("---`nentities: [" + $r.suggest_entity + "]`n")
        Set-Content -LiteralPath $dest -Value $raw -Encoding UTF8
      }
    }
  }
}

. (Join-Path $PSScriptRoot 'add-log.ps1') -Type LINT -Scope normalize-project -Status success -Owner team-docs -Message ("Apply done; scan report=" + ([IO.Path]::GetFileName($ReportPath))) -Split monthly | Out-Host
Write-Host "Normalization apply complete. Report: $ReportPath"
