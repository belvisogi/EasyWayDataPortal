[CmdletBinding()]
param(
  [Parameter(Mandatory=$true)][string]$Root,
  [string]$DefaultTag = 'layer/reference'
)

Set-StrictMode -Version Latest
$PSDefaultParameterValues['*:ErrorAction'] = 'Stop'

$helpers = Join-Path $PSScriptRoot 'review-examples.ps1'
. $helpers

function Get-OwnerForPath([string]$path){
  $p = ($path -replace '\\','/')
  if ($p -match '/easyway_portal_api/') { return 'team-api' }
  if ($p -match '/01_database_architecture/' -or $p -match '/03_datalake_dev/') { return 'team-data' }
  if ($p -match '/logging' -or $p -match '/iac' -or $p -match '/ops') { return 'team-ops' }
  return 'team-docs'
}

function Slugify([string]$name){
  $s = [IO.Path]::GetFileNameWithoutExtension($name).ToLower()
  $s = $s -replace '[^a-z0-9\-]','-'
  $s = $s -replace '-+','-'
  $s = $s.Trim('-')
  if (-not $s) { $s = 'page' }
  return $s
}

function GuessTitle([string]$file){
  $h1 = (Select-String -Path $file -Pattern '^[#]+\s+(.+)$' -Encoding utf8 -List | Select-Object -First 1)
  if ($h1) { return $h1.Matches[0].Groups[1].Value }
  $base = [IO.Path]::GetFileNameWithoutExtension($file)
  return ($base -replace '[-_]',' ') 
}

$files = Get-ChildItem -Path $Root -Recurse -File -Filter *.md
$added = 0
foreach($f in $files){
  $raw = Get-Content -LiteralPath $f.FullName -Raw -Encoding UTF8
  if ($raw -match '^(?s)---\s*\n') { continue }
  $id = Slugify $f.Name
  $title = GuessTitle $f.FullName
  $owner = Get-OwnerForPath $f.FullName
  Add-FrontMatterIfMissing -Path $f.FullName -Id $id -Title $title -Tags $DefaultTag -Owner $owner
  $added++
}

Write-Host ("Front matter aggiunto a {0} file" -f $added)

