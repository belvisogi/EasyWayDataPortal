Param(
  [Parameter(Mandatory=$true)] [string]$Path,
  [switch]$FailOnError
)

$ErrorActionPreference = 'Stop'

function Validate-One($file) {
  try {
    $json = Get-Content -Path $file -Raw
    $res = pwsh scripts/validate-action-output.ps1 -InputJson $json | ConvertFrom-Json
    [PSCustomObject]@{ file=$file; ok=$res.ok; missing=($res.missing -join ', '); schema=$res.schema }
  } catch { [PSCustomObject]@{ file=$file; ok=$false; missing='invalid-json'; schema='n/a' } }
}

if (Test-Path $Path -PathType Leaf) {
  $items = @($Path)
} elseif (Test-Path $Path -PathType Container) {
  $items = Get-ChildItem -Path $Path -Filter *.json -Recurse | Select-Object -ExpandProperty FullName
} else {
  Write-Error "Path not found: $Path"; exit 1
}

$report = @()
foreach ($f in $items) { $report += (Validate-One $f) }
$report | ConvertTo-Json -Depth 6 | Write-Output
if ($FailOnError -and ($report | Where-Object { -not $_.ok }).Count -gt 0) { exit 1 } else { exit 0 }

