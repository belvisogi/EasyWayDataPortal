Param(
  [string]$ConnString,
  [string]$Server,
  [string]$Database,
  [string]$AdminUser,
  [string]$AdminPassword,
  [switch]$AAD,
  [string]$CheckUser
)

$ErrorActionPreference = 'Stop'

function Parse-ConnString([string]$conn) {
  if (-not $conn) { return $null }
  $obj = @{}
  foreach ($pair in $conn.Split(';') | Where-Object { $_ -and $_.Contains('=') }) {
    $k,$v = $pair.Split('=',2)
    $obj[$k.Trim()] = $v.Trim()
  }
  return [ordered]@{
    Server = ($obj['Server'] ?? $obj['Data Source'])
    Database = ($obj['Database'] ?? $obj['Initial Catalog'])
    UserId = ($obj['User Id'] ?? $obj['UID'])
    Password = ($obj['Password'] ?? $obj['PWD'])
  }
}

function Invoke-SqlcmdQuery($server,$db,$user,$pass,[switch]$UseAAD,$query){
  $args=@(); if ($server){$args+@('-S',$server)}; if ($db){$args+@('-d',$db)}; if ($UseAAD){$args+@('-G')} elseif ($user){$args+@('-U',$user,'-P',$pass)}; $args+=@('-b','-W','-s',',','-h','-1','-Q',$query)
  $out = & sqlcmd @args 2>&1; if ($LASTEXITCODE -ne 0){ throw "sqlcmd failed: $out" }; return ($out -join "\n")
}

$conn = Parse-ConnString $ConnString
$server = if ($Server){$Server}elseif($conn){$conn.Server}else{$null}
$db = if ($Database){$Database}elseif($conn){$conn.Database}else{$null}
$u = if ($AdminUser){$AdminUser}elseif($conn){$conn.UserId}else{$null}
$p = if ($AdminPassword){$AdminPassword}elseif($conn){$conn.Password}else{$null}
$useAAD = [bool]$AAD
if (-not $u -and -not $p){ $useAAD = $true }

$ok=$false; $err=$null; $roles=@{reader=$false;writer=$false}; $userExists=$null
try {
  $probe = Invoke-SqlcmdQuery -server $server -db $db -user $u -pass $p -UseAAD:$useAAD -query "SELECT TOP 1 name FROM sys.objects" | Out-String
  $ok = $true
  $qRoles = @"
SELECT
  readerExists = CASE WHEN EXISTS(SELECT 1 FROM sys.database_principals WHERE name=N'portal_reader') THEN 1 ELSE 0 END,
  writerExists = CASE WHEN EXISTS(SELECT 1 FROM sys.database_principals WHERE name=N'portal_writer') THEN 1 ELSE 0 END
"@
  $r = Invoke-SqlcmdQuery -server $server -db $db -user $u -pass $p -UseAAD:$useAAD -query $qRoles
  $parts = ($r -split ',') | ForEach-Object { $_.Trim() }
  if ($parts.Count -ge 2){ $roles.reader = ($parts[0] -eq '1'); $roles.writer = ($parts[1] -eq '1') }
  if ($CheckUser){
    $cu = Invoke-SqlcmdQuery -server $server -db $db -user $u -pass $p -UseAAD:$useAAD -query "SELECT CASE WHEN EXISTS(SELECT 1 FROM sys.database_principals WHERE name=N'$CheckUser') THEN 1 ELSE 0 END"
    $userExists = ($cu.Trim() -eq '1')
  }
} catch {
  $err = $_.Exception.Message
}

$lint = @()
if ($CheckUser) {
  # Naming advisory: prefer 'svc_<tenant>_(reader|writer|admin)'
  if ($CheckUser -notmatch '^(svc|USR|user)[-_].+') {
    $lint += @{ id='naming'; severity='advisory'; ok=$false; message='Consigliato prefisso svc_ per utenze applicative (es. svc_tenant01_writer)' }
  } else { $lint += @{ id='naming'; severity='advisory'; ok=$true; message='Naming conforme o accettabile' } }
}
if (-not $roles.reader) { $lint += @{ id='role-reader-missing'; severity='mandatory'; ok=$false; message='Ruolo portal_reader non presente' } } else { $lint += @{ id='role-reader-present'; severity='info'; ok=$true; message='portal_reader presente' } }
if (-not $roles.writer) { $lint += @{ id='role-writer-missing'; severity='advisory'; ok=$false; message='Ruolo portal_writer non presente (richiesto solo per scritture)' } } else { $lint += @{ id='role-writer-present'; severity='info'; ok=$true; message='portal_writer presente' } }

$out = [ordered]@{
  ok = $ok
  auth = ($useAAD ? 'aad' : 'sql')
  server = $server
  database = $db
  roles = $roles
  userExists = $userExists
  lint = $lint
  error = $err
}
$out | ConvertTo-Json -Depth 6 | Write-Output
