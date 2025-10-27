param(
  [string]$Path = "Wiki/EasyWayData.wiki",
  [string]$Owner = "team-platform",
  [string[]]$Tags = @("wiki","language/it"),
  [string]$ChunkHint = "250-400",
  [switch]$Apply,
  [switch]$ForceReplace,
  [string]$SummaryOut = "wiki-frontmatter-autofix.json"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function New-KebabId {
  param([string]$Root,[string]$File)
  $rel = Resolve-Path -LiteralPath $File | ForEach-Object { $_.Path }
  $rootPath = Resolve-Path -LiteralPath $Root | ForEach-Object { $_.Path }
  $rel = $rel.Substring($rootPath.Length).TrimStart('/','\\')
  $rel = $rel.Replace('\\','/').ToLower()
  $name = [System.IO.Path]::GetFileNameWithoutExtension($rel)
  $dir = [System.IO.Path]::GetDirectoryName($rel).Replace('/','-')
  $raw = if ([string]::IsNullOrWhiteSpace($dir)) { $name } else { "$dir-$name" }
  $raw = ($raw -replace "[^a-z0-9]+","-").Trim('-')
  return "ew-$raw"
}

function Get-FirstHeadingOrName {
  param([string]$File)
  $lines = Get-Content -LiteralPath $File -TotalCount 50
  foreach ($l in $lines) {
    if ($l.Trim().StartsWith('#')) {
      return ($l -replace '^#+\s*','').Trim()
    }
  }
  $base = [System.IO.Path]::GetFileNameWithoutExtension($File)
  return ($base -replace '[_\-]+',' ') 
}

function Has-FrontMatter {
  param([string]$Text)
  return ($Text.StartsWith("---`n") -or $Text.StartsWith("---`r`n"))
}

function Parse-FrontMatterBlock {
  param([string]$Text)
  if (-not (Has-FrontMatter -Text $Text)) { return @{ exists=$false } }
  $end = ($Text.IndexOf("`n---", 4))
  if ($end -lt 0) { return @{ exists=$true; terminated=$false } }
  $block = $Text.Substring(4, $end - 4)
  return @{ exists=$true; terminated=$true; block=$block; endIndex=$end+4+3 }
}

function New-FrontMatter {
  param([string]$Id,[string]$Title,[string]$Summary)
  $tagsYaml = "[" + ($Tags -join ', ') + "]"
  @"
---
id: $Id
title: $Title
summary: $Summary
status: draft
owner: $Owner
tags: $tagsYaml
llm:
  include: true
  pii: none
  chunk_hint: $ChunkHint
  redaction: [email, phone]
entities: []
---
"@
}

function Ensure-FrontMatter {
  param([string]$File)
  $text = Get-Content -LiteralPath $File -Raw
  $inspect = Parse-FrontMatterBlock -Text $text
  $id = New-KebabId -Root $Path -File $File
  $title = Get-FirstHeadingOrName -File $File
  $summary = "Pagina Wiki EasyWay – aggiungere un sommario breve."
  if (-not $inspect.exists) {
    $fm = New-FrontMatter -Id $id -Title $title -Summary $summary
    $newText = $fm + $text
    return @{ action='inserted'; id=$id; title=$title; content=$newText }
  }
  if ($inspect.exists -and -not $inspect.terminated) {
    if ($ForceReplace) {
      $fm = New-FrontMatter -Id $id -Title $title -Summary $summary
      $rest = $text
      $newText = $fm + $rest
      return @{ action='replaced_unterminated'; id=$id; title=$title; content=$newText }
    } else {
      return @{ action='skip_unterminated'; id=$id; title=$title }
    }
  }
  # front-matter exists and is terminated; optionally patch missing keys if ForceReplace
  if ($ForceReplace) {
    $fm = New-FrontMatter -Id $id -Title $title -Summary $summary
    $rest = $text.Substring($inspect.endIndex + 1)
    $newText = $fm + $rest
    return @{ action='replaced_existing'; id=$id; title=$title; content=$newText }
  }
  return @{ action='present'; id=$id; title=$title }
}

$results = @()
Get-ChildItem -LiteralPath $Path -Recurse -Filter *.md | ForEach-Object {
  $res = Ensure-FrontMatter -File $_.FullName
  $entry = @{ file = $_.FullName; action = $res.action; id = $res.id; title = $res.title }
  if ($Apply -and $res.content) {
    Set-Content -LiteralPath $_.FullName -Value $res.content -Encoding utf8
    $entry.changed = $true
  } else {
    $entry.changed = $false
  }
  $results += $entry
}

$summary = @{ applied = [bool]$Apply; forceReplace = [bool]$ForceReplace; results = $results }
$json = $summary | ConvertTo-Json -Depth 6
Set-Content -LiteralPath $SummaryOut -Value $json -Encoding utf8
Write-Output $json

