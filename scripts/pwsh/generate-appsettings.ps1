Param(
  [string]$ApiPath = "EasyWay-DataPortal/easyway-portal-api",
  [string]$OutDir = "./out"
)

$ErrorActionPreference = 'Stop'
$envFile = Join-Path $ApiPath ".env.local"
if (-not (Test-Path $envFile)) { throw ".env.local non trovato in $ApiPath" }

if (-not (Test-Path $OutDir)) { New-Item -ItemType Directory -Force -Path $OutDir | Out-Null }

# Parse .env.local (KEY=VALUE)
$pairs = @{}
Get-Content $envFile | ForEach-Object {
  $line = $_.Trim()
  if (-not $line) { return }
  if ($line.StartsWith('#')) { return }
  $idx = $line.IndexOf('=')
  if ($idx -lt 1) { return }
  $k = $line.Substring(0,$idx).Trim()
  $v = $line.Substring($idx+1).Trim()
  $pairs[$k] = $v
}

# Build CLI JSON (object)
$cliObj = [ordered]@{}
foreach ($k in $pairs.Keys) { $cliObj[$k] = [string]$pairs[$k] }
$cliJson = ($cliObj | ConvertTo-Json -Depth 5)
Set-Content -Encoding UTF8 -Path (Join-Path $OutDir 'appsettings.cli.json') -Value $cliJson

# Build Task JSON (array of {name,value,slotSetting:false})
$taskArr = @()
foreach ($k in $pairs.Keys) {
  $taskArr += [ordered]@{ name=$k; value=[string]$pairs[$k]; slotSetting=$false }
}
$taskJson = ($taskArr | ConvertTo-Json -Depth 5)
Set-Content -Encoding UTF8 -Path (Join-Path $OutDir 'appsettings.task.json') -Value $taskJson

Write-Host "Creati:" -ForegroundColor Green
Write-Host (Resolve-Path (Join-Path $OutDir 'appsettings.cli.json'))
Write-Host (Resolve-Path (Join-Path $OutDir 'appsettings.task.json'))

