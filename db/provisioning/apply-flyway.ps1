[CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
param(
  [ValidateSet('validate','migrate','baseline')][string]$Action = 'validate',
  [string]$FlywayConfig = 'db/flyway/flyway.conf',
  [string]$FlywaySqlDir = 'db/flyway/sql',
  [string]$Url = $env:FLYWAY_URL,
  [string]$User = $env:FLYWAY_USER,
  [string]$Password = $env:FLYWAY_PASSWORD,
  [string]$BaselineVersion = '1',
  [switch]$PassEnvOnly
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Resolve-RepoRoot {
  $here = Split-Path -Parent $MyInvocation.MyCommand.Path
  return (Resolve-Path (Join-Path $here '../..')).Path
}

$repoRoot = Resolve-RepoRoot
$configPath = Join-Path $repoRoot $FlywayConfig
$sqlDirPath = Join-Path $repoRoot $FlywaySqlDir

if (-not (Test-Path -LiteralPath $configPath)) { throw "Flyway config not found: $configPath" }
if (-not (Test-Path -LiteralPath $sqlDirPath)) { throw "Flyway sql dir not found: $sqlDirPath" }

if (-not (Get-Command flyway -ErrorAction SilentlyContinue)) {
  throw "Flyway CLI not found. Install Flyway and ensure 'flyway' is in PATH."
}

if (-not $PassEnvOnly) {
  if ([string]::IsNullOrWhiteSpace($Url)) { throw "Missing Flyway URL. Provide -Url or set env FLYWAY_URL." }
  if ([string]::IsNullOrWhiteSpace($User)) { throw "Missing Flyway USER. Provide -User or set env FLYWAY_USER." }
  if ([string]::IsNullOrWhiteSpace($Password)) { throw "Missing Flyway PASSWORD. Provide -Password or set env FLYWAY_PASSWORD." }
}

$args = @(
  "-configFiles=$configPath",
  "-locations=filesystem:$sqlDirPath"
)

if (-not $PassEnvOnly) {
  $args += @(
    "-url=$Url",
    "-user=$User",
    "-password=$Password"
  )
}

switch ($Action) {
  'validate' {
    & flyway @args validate
    if ($LASTEXITCODE -ne 0) { throw "flyway validate failed ($LASTEXITCODE)" }
  }
  'baseline' {
    if (-not $PSCmdlet.ShouldProcess("Flyway baseline on $Url", "baseline -baselineVersion=$BaselineVersion")) { return }
    & flyway @args baseline "-baselineVersion=$BaselineVersion"
    if ($LASTEXITCODE -ne 0) { throw "flyway baseline failed ($LASTEXITCODE)" }
  }
  'migrate' {
    if (-not $PSCmdlet.ShouldProcess("Flyway migrate on $Url", "migrate")) { return }
    & flyway @args migrate
    if ($LASTEXITCODE -ne 0) { throw "flyway migrate failed ($LASTEXITCODE)" }
  }
}
