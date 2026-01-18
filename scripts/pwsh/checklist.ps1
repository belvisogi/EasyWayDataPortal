Param(
  [string]$ApiPath = "EasyWay-DataPortal/easyway-portal-api",
  [switch]$JsonOnly
)

Write-Host "[Checklist] Running pre-deploy checks..." -ForegroundColor Cyan
Push-Location $ApiPath
try {
  $env:CHECKLIST_OUTPUT = if ($JsonOnly) { 'json' } else { 'both' }
  if (-not (Test-Path package.json)) { throw "package.json not found in $ApiPath" }
  npm run -s check:predeploy
  $exit = $LASTEXITCODE
} catch {
  Write-Error $_
  $exit = 1
} finally {
  Pop-Location
}
exit $exit

