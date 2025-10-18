[CmdletBinding()]
param(
  [Parameter(Mandatory=$true)][string[]]$Roots,
  [ValidateSet('scan','apply')][string]$Mode = 'apply',
  [switch]$EnsureFrontMatter,
  [string]$AggregateReport = ''
)

Set-StrictMode -Version Latest
$PSDefaultParameterValues['*:ErrorAction'] = 'Stop'

$single = Join-Path $PSScriptRoot 'normalize-project.ps1'
$ts = (Get-Date).ToString('yyyyMMddHHmmss')
if (-not $AggregateReport) { $AggregateReport = Join-Path (Resolve-Path .) ("normalize-all-" + $ts + ".md") }

$reports = New-Object System.Collections.Generic.List[string]

foreach($r in $Roots){
  $rootPath = Resolve-Path $r
  $name = [IO.Path]::GetFileName($rootPath)
  $rpt = Join-Path $rootPath (Join-Path 'logs/reports' ("normalize-" + $ts + "-" + $name + ".md"))
  if ($Mode -eq 'scan'){
    . $single -Root $rootPath -Mode scan -ReportPath $rpt | Out-Host
  } else {
    . $single -Root $rootPath -Mode apply -EnsureFrontMatter:$EnsureFrontMatter -ReportPath $rpt | Out-Host
  }
  $reports.Add($rpt) | Out-Null
}

$sb = New-Object System.Text.StringBuilder
$null = $sb.AppendLine('# Normalize Multi-Root Summary')
$null = $sb.AppendLine('')
$null = $sb.AppendLine('| root | report |')
$null = $sb.AppendLine('|---|---|')
foreach($i in 0..($Roots.Count-1)){
  $rootDisp = (Resolve-Path $Roots[$i])
  $rel = $reports[$i]
  $null = $sb.AppendLine("| $rootDisp | $rel |")
}
Set-Content -LiteralPath $AggregateReport -Value $sb.ToString() -Encoding UTF8

. (Join-Path $PSScriptRoot 'add-log.ps1') -Type LINT -Scope normalize-project -Status success -Owner team-docs -Message ("Multi-root " + $Mode + ": " + ([IO.Path]::GetFileName($AggregateReport))) -Split monthly | Out-Host
Write-Host "Aggregate report: $AggregateReport"

