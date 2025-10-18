[CmdletBinding()]
param(
  [Parameter(Mandatory=$true)][string]$Root,
  [string[]]$Include = @(),
  [string]$DefaultLang = 'text'
)

Set-StrictMode -Version Latest
$PSDefaultParameterValues['*:ErrorAction'] = 'Stop'

function Normalize-File([string]$file, [string]$lang){
  $lines = Get-Content -LiteralPath $file -Encoding UTF8
  $changed = $false
  for($i=0; $i -lt $lines.Count; $i++){
    $l = $lines[$i]
    if ($l -match '^```\s*$'){
      $lines[$i] = '```' + $lang
      $changed = $true
    }
  }
  if ($changed){ Set-Content -LiteralPath $file -Value ($lines -join "`n") -Encoding UTF8 }
  return $changed
}

$files = @()
if ($Include -and $Include.Count -gt 0){
  foreach($rel in $Include){
    $p = if ([IO.Path]::IsPathRooted($rel)) { $rel } else { Join-Path $Root $rel }
    $files += (Resolve-Path $p)
  }
} else {
  $files = Get-ChildItem -Path $Root -Recurse -File -Filter *.md | ForEach-Object { $_.FullName }
}

$count = 0
foreach($f in $files){
  if (Normalize-File -file $f -lang $DefaultLang){ $count++ }
}
Write-Host ("Code fences normalizzati in {0} file" -f $count)
