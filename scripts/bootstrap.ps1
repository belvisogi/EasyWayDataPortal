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
$prov = Join-Path $repo "DataBase/provisioning"

if (-not (Test-Path $prov)) { throw "Provisioning folder not found: $prov" }

function Invoke-WithSqlCmd {
  param([string]$file)
  $trust = if ($TrustServerCertificate) { "-C" } else { "" }
  & sqlcmd -S $Server -d $Database -U $User -P $Password -b -i $file $trust
  if ($LASTEXITCODE -ne 0) { throw "sqlcmd failed for $file" }
}

function Invoke-WithInvokeSqlcmd {
  param([string]$file)
  if (-not (Get-Module -ListAvailable -Name SqlServer)) {
    Write-Host "Module SqlServer not found. Install-Module SqlServer -Scope CurrentUser" -ForegroundColor Yellow
    throw "Invoke-Sqlcmd unavailable"
  }
  $content = Get-Content -Path $file -Raw
  Invoke-Sqlcmd -ServerInstance $Server -Database $Database -Username $User -Password $Password -Query $content -Encrypt
}

$files = @(
  "00_schema.sql",
  "10_tables.sql",
  "20_fk_indexes.sql",
  "30_seed_minimal.sql",
  "40_extended_properties.sql"
) | ForEach-Object { Join-Path $prov $_ }

foreach ($f in $files) {
  if (-not (Test-Path $f)) { throw "Missing file $f" }
}

try {
  if (Get-Command sqlcmd -ErrorAction SilentlyContinue) {
    foreach ($f in $files) { Write-Host "sqlcmd: $f"; Invoke-WithSqlCmd -file $f }
  } else {
    foreach ($f in $files) { Write-Host "Invoke-Sqlcmd: $f"; Invoke-WithInvokeSqlcmd -file $f }
  }
  # Apply programmability scripts if present
  $prog = Join-Path $repo "DataBase/programmability"
  if (Test-Path $prog) {
    $progFiles = Get-ChildItem -Path $prog -Recurse -Filter *.sql | Sort-Object FullName
    foreach ($pf in $progFiles) {
      Write-Host "[programmability] $($pf.FullName)"
      if (Get-Command sqlcmd -ErrorAction SilentlyContinue) {
        Invoke-WithSqlCmd -file $pf.FullName
      } else {
        Invoke-WithInvokeSqlcmd -file $pf.FullName
      }
    }
  }
  Write-Host "[bootstrap] Done." -ForegroundColor Green
} catch {
  Write-Error $_
  exit 1
}
