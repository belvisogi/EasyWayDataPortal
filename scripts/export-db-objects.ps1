Param(
  [string]$Server = $env:SQLSERVER_HOST,
  [string]$Database = $env:SQLSERVER_DATABASE,
  [string]$User = $env:SQLSERVER_USER,
  [string]$Password = $env:SQLSERVER_PASSWORD
)

Write-Host "[export-db-objects] Exporting DB objects from $Server/$Database" -ForegroundColor Cyan

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$repo = Resolve-Path (Join-Path $root "..")
$outRoot = Join-Path $repo "DataBase/programmability"
$spDir = Join-Path $outRoot "sp"
$fnDir = Join-Path $outRoot "fn"
$vwDir = Join-Path $outRoot "vw"
$tbDir = Join-Path $outRoot "tables"

New-Item -ItemType Directory -Force -Path $spDir,$fnDir,$vwDir,$tbDir | Out-Null

function Ensure-SqlServerModule {
  if (-not (Get-Module -ListAvailable -Name SqlServer)) {
    Write-Host "Installing SqlServer module (CurrentUser)..." -ForegroundColor Yellow
    Install-Module SqlServer -Scope CurrentUser -Force -AllowClobber
  }
  Import-Module SqlServer -ErrorAction Stop
}

Ensure-SqlServerModule

$conn = New-Object Microsoft.SqlServer.Management.Common.ServerConnection
$conn.ServerInstance = $Server
if ($User -and $Password) {
  $conn.LoginSecure = $false
  $conn.Login = $User
  $conn.Password = $Password
} else {
  $conn.LoginSecure = $true
}

$server = New-Object Microsoft.SqlServer.Management.Smo.Server $conn
$db = $server.Databases[$Database]
if (-not $db) { throw "Database not found: $Database" }

# Export Stored Procedures
foreach ($sp in $db.StoredProcedures | Where-Object { -not $_.IsSystemObject }) {
  $scripter = New-Object Microsoft.SqlServer.Management.Smo.Scripter ($server)
  $scripter.Options.IncludeIfNotExists = $false
  $scripter.Options.AnsiFile = $true
  $scripter.Options.SchemaQualify = $true
  $scripter.Options.NoCollation = $true
  $scripter.Options.DriAll = $false
  $scripter.Options.AppendToFile = $false
  $script = ($scripter.Script($sp))[0]
  $script = $script -replace "^CREATE PROCEDURE", "CREATE OR ALTER PROCEDURE"
  $file = Join-Path $spDir ("{0}.{1}.sql" -f $sp.Schema, $sp.Name)
  Set-Content -Path $file -Value $script -Encoding UTF8
}

# Export Functions
foreach ($fn in $db.UserDefinedFunctions | Where-Object { -not $_.IsSystemObject }) {
  $scripter = New-Object Microsoft.SqlServer.Management.Smo.Scripter ($server)
  $scripter.Options.SchemaQualify = $true
  $script = ($scripter.Script($fn))[0]
  $script = $script -replace "^CREATE FUNCTION", "CREATE OR ALTER FUNCTION"
  $file = Join-Path $fnDir ("{0}.{1}.sql" -f $fn.Schema, $fn.Name)
  Set-Content -Path $file -Value $script -Encoding UTF8
}

# Export Views
foreach ($vw in $db.Views | Where-Object { -not $_.IsSystemObject }) {
  $scripter = New-Object Microsoft.SqlServer.Management.Smo.Scripter ($server)
  $scripter.Options.SchemaQualify = $true
  $script = ($scripter.Script($vw))[0]
  $script = $script -replace "^CREATE VIEW", "CREATE OR ALTER VIEW"
  $file = Join-Path $vwDir ("{0}.{1}.sql" -f $vw.Schema, $vw.Name)
  Set-Content -Path $file -Value $script -Encoding UTF8
}

# Export Tables (CREATE only)
foreach ($tb in $db.Tables | Where-Object { -not $_.IsSystemObject }) {
  $scripter = New-Object Microsoft.SqlServer.Management.Smo.Scripter ($server)
  $scripter.Options.SchemaQualify = $true
  $scripter.Options.DriAll = $true
  $scripter.Options.Indexes = $true
  $scripter.Options.Triggers = $true
  $script = ($scripter.Script($tb)) -join "`r`n"
  $file = Join-Path $tbDir ("{0}.{1}.sql" -f $tb.Schema, $tb.Name)
  Set-Content -Path $file -Value $script -Encoding UTF8
}

Write-Host "[export-db-objects] Done. Files under $outRoot" -ForegroundColor Green

