[CmdletBinding()]
param(
  [string]$Root = (Join-Path $PSScriptRoot '..' | Resolve-Path -Relative),
  [string]$EntitiesYaml = '',
  [string]$Output = ''
)

Set-StrictMode -Version Latest
$PSDefaultParameterValues['*:ErrorAction'] = 'Stop'

if (-not $EntitiesYaml) { $EntitiesYaml = Join-Path $Root 'entities.yaml' }
if (-not $Output) { $Output = Join-Path $Root 'entities-index.md' }

if (-not (Test-Path -LiteralPath $EntitiesYaml)) { throw "entities.yaml non trovato: $EntitiesYaml" }

$yamlRaw = Get-Content -LiteralPath $EntitiesYaml -Raw -Encoding UTF8

function Parse-YamlSimple([string]$text){
  $result = @{}
  $currentSection = $null
  $currentItem = $null
  $lines = $text -split "`n"
  foreach($l in $lines){
    $line = $l.TrimEnd("`r")
    if ($line -match '^(\w+):\s*$'){
      $currentSection = $Matches[1]
      if (-not $result.ContainsKey($currentSection)) { $result[$currentSection] = New-Object System.Collections.ArrayList }
      $currentItem = $null
      continue
    }
    if (-not $currentSection) { continue }
    if ($line -match '^\s*-\s+id:\s*(.+)$'){
      $currentItem = @{ id = $Matches[1].Trim() }
      [void]$result[$currentSection].Add($currentItem)
      continue
    }
    if ($null -eq $currentItem) { continue }
    if ($line -match '^\s+(name|kind|path|description):\s*(.+)$'){
      $key = $Matches[1]
      $val = $Matches[2].Trim()
      $currentItem[$key] = $val
      continue
    }
    if ($line -match '^\s+aliases:\s*\[(.*)\]'){
      $arr = @()
      $raw = $Matches[1]
      foreach($p in ($raw -split ',')){
        $t = $p.Trim().Trim("'").Trim('"')
        if ($t) { $arr += $t }
      }
      $currentItem['aliases'] = $arr
      continue
    }
  }
  return $result
}

$doc = Parse-YamlSimple $yamlRaw

function LinkFor([string]$path){
  if (-not $path) { return '' }
  $rel = $path -replace '^EasyWayData\.wiki/',''
  return './' + ($rel -replace '\\','/')
}

$sb = New-Object System.Text.StringBuilder
$null = $sb.AppendLine('---')
$null = $sb.AppendLine('id: ew-entities-index')
$null = $sb.AppendLine('title: Entities Index')
$null = $sb.AppendLine('summary: Indice delle entità dichiarate in entities.yaml, raggruppate per categoria.')
$null = $sb.AppendLine('status: draft')
$null = $sb.AppendLine('owner: team-docs')
$null = $sb.AppendLine('tags:')
$null = $sb.AppendLine('  - catalog')
$null = $sb.AppendLine('  - language/it')
$null = $sb.AppendLine('llm:')
$null = $sb.AppendLine('  include: true')
$null = $sb.AppendLine('  pii: none')
$null = $sb.AppendLine('  chunk_hint: 400-600')
$null = $sb.AppendLine('entities: []')
$null = $sb.AppendLine('---')
$null = $sb.AppendLine('# Entities Index')
$null = $sb.AppendLine('')

function Emit-Section([string]$title, $items){
  if (-not $items) { return }
  $null = $sb.AppendLine("## $title")
  $null = $sb.AppendLine('')
  $null = $sb.AppendLine('| id | name | kind | link |')
  $null = $sb.AppendLine('|---|---|---|---|')
  foreach($it in $items){
    $id = $it.id
    $name = $it.name
    $kind = $it.kind
    $href = LinkFor $it.path
    $link = if ($href) { "[$href]($href)" } else { '' }
    $null = $sb.AppendLine("| $id | $name | $kind | $link |")
  }
  $null = $sb.AppendLine('')
}

Emit-Section -title 'Endpoints' -items $doc['endpoints']
Emit-Section -title 'DB Stored Procedures' -items $doc['db_storeprocedures']
Emit-Section -title 'DB Sequences' -items $doc['db_sequences']
Emit-Section -title 'Policies' -items $doc['policies']
Emit-Section -title 'Flows' -items $doc['flows']
Emit-Section -title 'Data' -items $doc['data']
Emit-Section -title 'Standards' -items $doc['standards']
Emit-Section -title 'Guides' -items $doc['guides']

# Append Q&A section for atomicity readiness
$null = $sb.AppendLine('## Domande a cui risponde')
$null = $sb.AppendLine('- Dove trovo l''elenco delle entità e i link rapidi?')
$null = $sb.AppendLine('- Quali categorie di entità sono coperte?')
$null = $sb.AppendLine('- Come navigo verso documenti specifici partendo dall''indice?')
$null = $sb.AppendLine('')

Set-Content -LiteralPath $Output -Value $sb.ToString() -Encoding UTF8
Write-Host "Generato: $Output"
