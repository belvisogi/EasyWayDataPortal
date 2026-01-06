Param(
  [string]$Server = $env:SQLSERVER_HOST, 
  [string]$Database = $env:SQLSERVER_DATABASE, 
  [string]$User = $env:SQLSERVER_USER, 
  [string]$Password = $env:SQLSERVER_PASSWORD,
  [switch]$TrustServerCertificate
)

Write-Host "[bootstrap] Provisioning DB schema, tables, FKs and seed..." -ForegroundColor Cyan

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$repo = Resolve-Path (Join-Path $root "..")
$prov = Join-Path $repo "db/provisioning"

if (-not (Test-Path $prov)) { throw "Provisioning folder not found: $prov" }

try {
  $flywayWrapper = Join-Path $prov "apply-flyway.ps1"
  if (-not (Test-Path $flywayWrapper)) { throw "Flyway provisioning wrapper not found: $flywayWrapper" }

  $env:FLYWAY_URL = if ($env:FLYWAY_URL) { $env:FLYWAY_URL } else { ("jdbc:sqlserver://{0}:1433;databaseName={1};encrypt=true;trustServerCertificate={2}" -f $Server, $Database, ($TrustServerCertificate ? 'true' : 'false')) }
  if (-not $env:FLYWAY_USER) { $env:FLYWAY_USER = $User }
  if (-not $env:FLYWAY_PASSWORD) { $env:FLYWAY_PASSWORD = $Password }

  Write-Host "[bootstrap] Flyway validate..." -ForegroundColor Cyan
  pwsh -NoProfile -File $flywayWrapper -Action validate | Out-Host

  Write-Host "[bootstrap] Flyway migrate (will prompt for confirmation)..." -ForegroundColor Cyan
  pwsh -NoProfile -File $flywayWrapper -Action migrate | Out-Host

  Write-Host "[bootstrap] Done." -ForegroundColor Green
} catch {
  Write-Error $_
  exit 1
}
