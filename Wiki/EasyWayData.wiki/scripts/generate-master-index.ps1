[CmdletBinding()]
param(
  [Parameter(Mandatory=$true)][string]$Root,
  [string]$Output = '',
  [string]$JsonlOutput = '',
  [string]$AnchorsCsv = ''
)

Set-StrictMode -Version Latest
$PSDefaultParameterValues['*:ErrorAction'] = 'Stop'

if (-not $Output) { $Output = Join-Path $Root 'index_master.csv' }
if (-not $JsonlOutput) { $JsonlOutput = Join-Path $Root 'index_master.jsonl' }
if (-not $AnchorsCsv) { $AnchorsCsv = Join-Path $Root 'anchors_master.csv' }

function Parse-FrontMatter {
  param([string]$Text)
  $res = @{}
  $tags = New-Object System.Collections.Generic.List[string]
  $entities = New-Object System.Collections.Generic.List[string]
  $in = $false; $done = $false
  $ctx = ''
  $lines = $Text -split "`n"
  for($i=0; $i -lt $lines.Count; $i++){
    $line = $lines[$i].TrimEnd("`r")
    if (-not $in) {
      if ($line -match '^---\s*$') { $in = $true }
      else { break }
      continue
    }
    if ($line -match '^---\s*$') { $done = $true; break }
    if ($line -match '^\s*$') { continue }
    if ($line -match '^([a-zA-Z0-9_.-]+):\s*(.*)$'){
      $key = $Matches[1]; $val = $Matches[2]
      switch -Regex ($key) {
        '^tags$'      { $ctx = 'tags'; continue }
        '^entities$'  { $ctx = 'entities'; continue }
        '^llm$'       { $ctx = 'llm'; continue }
        default {
          if ($ctx -eq 'llm' -and $key -match '^llm\.(include|pii|chunk_hint)$'){
            $res[$key] = $val.Trim()
          } else {
            $res[$key] = $val.Trim('", ''')
            $ctx = ''
          }
        }
      }
      continue
    }
    if ($ctx -in @('tags','entities')){
      if ($line -match '^\s*-\s*(.+)$'){
        $item = $Matches[1].Trim('"', "'", ' ')
        if ($ctx -eq 'tags') { $tags.Add($item) } else { $entities.Add($item) }
      } elseif ($line -match '^\s*\[(.*)\]\s*$'){
        $raw = $Matches[1]
        foreach($p in ($raw -split ',')){
          $t = $p.Trim(' ', '"', "'")
          if ($t) { if ($ctx -eq 'tags'){ $tags.Add($t) } else { $entities.Add($t) } }
        }
      } else {
        $ctx = ''
      }
    }
  }
  if ($tags.Count) { $res['tags'] = $tags }
  if ($entities.Count) { $res['entities'] = $entities }
  return $res
}

function FirstHeading {
  param([string]$Path)
  $m = Select-String -Path $Path -Pattern '^[#]+\s+(.+)$' -Encoding utf8 -List | Select-Object -First 1
  if ($m) { return $m.Matches[0].Groups[1].Value }
  return $null
}

function TagGroups([string[]]$tags){
  if (-not $tags) { return @() }
  $groups = @{}
  foreach($t in $tags){
    if ($t -match '^(?<g>[^/]+)/.+$'){ $groups[$Matches['g']] = $true }
  }
  return $groups.Keys
}

function Slug([string]$t){
  if ($null -eq $t) { return '' }
  $s = $t.ToLower()
  $s = $s -replace "[`*_~]", ''
  $s = $s -replace "\s+", '-'
  $s = $s -replace "[^a-z0-9\-]", ''
  $s = $s -replace "-+", '-'
  $s = $s -replace "^-|-$", ''
  return $s
}

function Extract-Headings {
  param([string]$Path)
  $heads = New-Object System.Collections.Generic.List[object]
  Get-Content -LiteralPath $Path -Encoding UTF8 | ForEach-Object {
    if ($_ -match '^(#+)\s+(.+)$'){
      $level = $Matches[1].Length
      $text = $Matches[2]
      if ($level -ge 2 -and $level -le 3){
        $heads.Add([pscustomobject]@{ level=$level; text=$text; slug=(Slug $text) }) | Out-Null
      }
    }
  }
  return $heads
}

function Extract-QuestionsAnswered {
  param([string]$Path)
  $lines = Get-Content -LiteralPath $Path -Encoding UTF8
  $hit = $lines | Select-String -SimpleMatch '## Domande a cui risponde' | Select-Object -First 1
  if (-not $hit) { return @() }
  $start = $hit.LineNumber
  $qa = New-Object System.Collections.Generic.List[string]
  for($i=$start; $i -lt $lines.Count; $i++){
    $line = $lines[$i]
    if ($i -ne $start -and $line -match '^#'){ break }
    if ($line -match '^\s*[-*]\s+(.+)$'){
      $qa.Add($Matches[1].Trim()) | Out-Null
      if ($qa.Count -ge 7) { break }
    }
  }
  return $qa
}

$rows = New-Object System.Collections.Generic.List[object]
$files = Get-ChildItem -Path $Root -Recurse -File -Filter *.md
if (Test-Path -LiteralPath $JsonlOutput) { Remove-Item -LiteralPath $JsonlOutput -Force }
if (Test-Path -LiteralPath $AnchorsCsv) { Remove-Item -LiteralPath $AnchorsCsv -Force }
"path,level,slug,text" | Set-Content -LiteralPath $AnchorsCsv -Encoding UTF8
foreach($f in $files){
  # skip generated logs and .attachments
  if ($f.FullName -match '\\logs\\reports\\' -or $f.FullName -match '\\.attachments\\') { continue }
  $content = Get-Content -LiteralPath $f.FullName -Raw -Encoding UTF8
  $fm = Parse-FrontMatter -Text $content
  $h1 = FirstHeading -Path $f.FullName
  $id = if ($fm.ContainsKey('id')) { $fm['id'] } else { [IO.Path]::GetFileNameWithoutExtension($f.Name).ToLower() }
  $title = if ($fm.ContainsKey('title')) { $fm['title'] } elseif ($h1) { $h1 } else { [IO.Path]::GetFileNameWithoutExtension($f.Name) }
  $summary = if ($fm.ContainsKey('summary')) { $fm['summary'] } else { '' }
  $owner = if ($fm.ContainsKey('owner')) { $fm['owner'] } else { '' }
  $tags = @()
  if ($fm.ContainsKey('tags')) { $tags = [string[]]$fm['tags'] }
  $tagStr = if ($tags) { ($tags -join ';') } else { '' }
  $groups = TagGroups $tags
  $grpStr = if ($groups) { ($groups -join ';') } else { '' }
  $llmInclude = if ($fm.ContainsKey('llm.include')) { $fm['llm.include'] } else { '' }
  $llmPii = if ($fm.ContainsKey('llm.pii')) { $fm['llm.pii'] } else { '' }
  $chunkHint = if ($fm.ContainsKey('llm.chunk_hint')) { $fm['llm.chunk_hint'] } else { '' }
  $entities = @()
  if ($fm.ContainsKey('entities')) { $entities = [string[]]$fm['entities'] }
  $entStr = if ($entities) { ($entities -join ';') } else { '' }
  $rel = [System.IO.Path]::GetRelativePath($Root, $f.FullName) -replace '\\','/'
  $updated = (Get-Item -LiteralPath $f.FullName).LastWriteTime.ToString('yyyy-MM-ddTHH:mm:ssK')

  # headings and anchors
  $heads = Extract-Headings -Path $f.FullName
  foreach($h in $heads){
    $csv = '{0},{1},{2},"{3}"' -f $rel, $h.level, $h.slug, ($h.text -replace '"','''')
    Add-Content -LiteralPath $AnchorsCsv -Value $csv -Encoding UTF8
  }

  # questions answered
  $qa = Extract-QuestionsAnswered -Path $f.FullName
  $rows.Add([pscustomobject]@{
    path = $rel
    id = $id
    title = $title
    summary = $summary
    owner = $owner
    tag_groups = $grpStr
    tags = $tagStr
    llm_include = $llmInclude
    llm_pii = $llmPii
    entities = $entStr
  }) | Out-Null

  $jsonObj = [ordered]@{
    id = $id
    title = $title
    summary = $summary
    path = $rel
    format = 'md'
    owner = $owner
    tags = $tags
    entities = $entities
    'llm.include' = $llmInclude
    'llm.pii' = $llmPii
    chunk_hint = $chunkHint
    updated = $updated
    questions_answered = $qa
    anchors = $heads
  }
  ($jsonObj | ConvertTo-Json -Depth 6 -Compress) | Add-Content -LiteralPath $JsonlOutput -Encoding UTF8
}

$rows | Sort-Object path | Export-Csv -Path $Output -NoTypeInformation -Encoding UTF8
Write-Host "Generato: $Output"
Write-Host "Generato: $JsonlOutput"
Write-Host "Generato: $AnchorsCsv"
