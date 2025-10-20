[CmdletBinding()]
param(
  [Parameter(Mandatory=$true)][string]$Root,
  [string]$Output = '',
  [int]$MinChars = 1600,
  [int]$MaxChars = 2400
)

Set-StrictMode -Version Latest
$PSDefaultParameterValues['*:ErrorAction'] = 'Stop'

if (-not $Output) { $Output = Join-Path $Root 'chunks_master.jsonl' }

function Parse-FrontMatter {
  param([string]$Text)
  $res = @{}
  $tags = New-Object System.Collections.Generic.List[string]
  $entities = New-Object System.Collections.Generic.List[string]
  $in = $false
  $ctx = ''
  $lines = $Text -split "`n"
  for($i=0; $i -lt $lines.Count; $i++){
    $line = $lines[$i].TrimEnd("`r")
    if (-not $in) {
      if ($line -match '^---\s*$') { $in = $true }
      else { break }
      continue
    }
    if ($line -match '^---\s*$') { break }
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
            $v2 = $val.Trim()
            $v2 = $v2 -replace '^["\'']+',''
            $v2 = $v2 -replace '["\'']+$',''
            $res[$key] = $v2
            $ctx = ''
          }
        }
      }
      continue
    }
    if ($ctx -in @('tags','entities')){
      if ($line -match '^\s*-\s*(.+)$'){
        $item = $Matches[1].Trim()
        $item = $item -replace '^["\'']+',''
        $item = $item -replace '["\'']+$',''
        if ($ctx -eq 'tags') { $tags.Add($item) } else { $entities.Add($item) }
      } elseif ($line -match '^\s*\[(.*)\]\s*$'){
        $raw = $Matches[1]
        foreach($p in ($raw -split ',')){
          $t = $p.Trim(' ', '\"', "'")
          if ($t) { if ($ctx -eq 'tags'){ $tags.Add($t) } else { $entities.Add($t) } }
        }
      } else { $ctx = '' }
    }
  }
  if ($tags.Count) { $res['tags'] = $tags }
  if ($entities.Count) { $res['entities'] = $entities }
  return $res
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

function Extract-SectionsFromBody {
  param([string]$Body)
  $rx = [regex]'(?m)^(#{2,3})\s+(.+)$'
  $matches = $rx.Matches($Body)
  $sections = New-Object System.Collections.Generic.List[object]
  if ($matches.Count -eq 0) { return $sections }
  for($i=0; $i -lt $matches.Count; $i++){
    $m = $matches[$i]
    $level = $m.Groups[1].Value.Length
    $text = $m.Groups[2].Value
    $start = $m.Index
    $end = if ($i -lt $matches.Count - 1) { $matches[$i+1].Index } else { $Body.Length }
    $sections.Add([pscustomobject]@{ level=$level; text=$text; slug=(Slug $text); start=$start; end=$end }) | Out-Null
  }
  return $sections
}

function Get-DocTitle {
  param([string]$Path)
  $m = Select-String -Path $Path -Pattern '^[#]+\s+(.+)$' -Encoding utf8 -List | Select-Object -First 1
  if ($m) { return $m.Matches[0].Groups[1].Value }
  return [IO.Path]::GetFileNameWithoutExtension($Path)
}

function Chunk-ByParagraph {
  param([string]$Text, [int]$Min=$MinChars, [int]$Max=$MaxChars)
  $paras = ($Text -split "\r?\n\r?\n")
  $chunks = New-Object System.Collections.Generic.List[string]
  $buf = ''
  foreach($p in $paras){
    $cand = if ($buf) { $buf + "`n`n" + $p } else { $p }
    if ($cand.Length -le $Max) { $buf = $cand; continue }
    if ($buf.Length -ge $Min) { $chunks.Add($buf) | Out-Null; $buf = $p; continue }
    # too short: force split
    $chunks.Add($cand.Substring(0, [Math]::Min($Max, $cand.Length))) | Out-Null
    $buf = $cand.Substring([Math]::Min($Max, $cand.Length)).TrimStart()
  }
  if ($buf) { $chunks.Add($buf) | Out-Null }
  # final normalization: if first chunk is still too long, hard split
  $final = New-Object System.Collections.Generic.List[string]
  foreach($c in $chunks){
    if ($c.Length -le $Max) { $final.Add($c) | Out-Null }
    else {
      $start = 0
      while($start -lt $c.Length){
        $len = [Math]::Min($Max, $c.Length - $start)
        $final.Add($c.Substring($start, $len)) | Out-Null
        $start += $len
      }
    }
  }
  return $final
}

if (Test-Path -LiteralPath $Output) { Remove-Item -LiteralPath $Output -Force }

$files = Get-ChildItem -Path $Root -Recurse -File -Filter *.md
foreach($f in $files){
  if ($f.FullName -match '\\logs\\reports\\' -or $f.FullName -match '\\.attachments\\') { continue }
  if ($f.Name -eq 'ACTIVITY_LOG.md') { continue }
  $content = Get-Content -LiteralPath $f.FullName -Raw -Encoding UTF8
  $fm = Parse-FrontMatter -Text $content
  $title = Get-DocTitle -Path $f.FullName
  $rel = [System.IO.Path]::GetRelativePath($Root, $f.FullName) -replace '\\','/'
  $owner = if ($fm.ContainsKey('owner')) { $fm['owner'] } else { '' }
  $summary = if ($fm.ContainsKey('summary')) { $fm['summary'] } else { '' }
  $id = if ($fm.ContainsKey('id')) { $fm['id'] } else { ([IO.Path]::GetFileNameWithoutExtension($f.Name).ToLower()) }
  $tags = if ($fm.ContainsKey('tags')) { [string[]]$fm['tags'] } else { @() }
  $entities = if ($fm.ContainsKey('entities')) { [string[]]$fm['entities'] } else { @() }
  $llmInclude = if ($fm.ContainsKey('llm.include')) { $fm['llm.include'] } else { '' }
  $llmPii = if ($fm.ContainsKey('llm.pii')) { $fm['llm.pii'] } else { '' }
  $chunkHint = if ($fm.ContainsKey('llm.chunk_hint')) { $fm['llm.chunk_hint'] } else { '' }
  $updated = (Get-Item -LiteralPath $f.FullName).LastWriteTime.ToString('yyyy-MM-ddTHH:mm:ssK')

  # strip front matter block before heading parsing
  $body = $content
  if ($body -match '(?s)^---\s*\n.*?\n---\s*\n'){
    $body = $body.Substring($Matches[0].Length)
  }

  # compute section regions by H2/H3
  $sections = Extract-SectionsFromBody -Body $body
  if (-not $sections -or $sections.Count -eq 0) {
    $sections = @( [pscustomobject]@{ level=2; text=$title; slug=(Slug $title); start=0; end=$body.Length } )
  }

  $chunkIdx = 0
  foreach($sec in $sections){
    $raw = if ($sec.end -gt $sec.start) { $body.Substring($sec.start, $sec.end - $sec.start).Trim() } else { '' }
    if (-not $raw) { continue }
    $pieces = Chunk-ByParagraph -Text $raw -Min $MinChars -Max $MaxChars
    foreach($pc in $pieces){
      $chunkIdx++
      $obj = [ordered]@{
        doc_id = $id
        path = $rel
        title = $title
        owner = $owner
        tags = $tags
        entities = $entities
        'llm.include' = $llmInclude
        'llm.pii' = $llmPii
        chunk_hint = $chunkHint
        updated = $updated
        section_level = $sec.level
        anchor_text = $sec.text
        anchor_slug = $sec.slug
        chunk_index = $chunkIdx
        content = $pc
        size_chars = $pc.Length
        tokens_estimate = [int][Math]::Round($pc.Length / 4.0)
      }
      $line = ($obj | ConvertTo-Json -Depth 6 -Compress)
      Add-Content -LiteralPath $Output -Value $line -Encoding UTF8
    }
  }
}

Write-Host "Generato: $Output"
