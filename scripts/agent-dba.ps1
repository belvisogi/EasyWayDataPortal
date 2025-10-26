Param(
  [ValidateSet('db-user:create','db-user:rotate','db-user:revoke')]
  [string]$Action,
  [string]$IntentPath,
  [switch]$NonInteractive,
  [switch]$WhatIf,
  [switch]$LogEvent
)

$ErrorActionPreference = 'Stop'

function Read-Intent($path) {
  if (-not $path) { return $null }
  if (-not (Test-Path $path)) { throw "Intent file not found: $path" }
  (Get-Content -Raw -Path $path) | ConvertFrom-Json
}

function New-StrongPassword([int]$length = 36) {
  $chars = 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz23456789@$!%*?&+-_#'
  -join ((1..$length) | ForEach-Object { $chars[(Get-Random -Max $chars.Length)] })
}

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
    Encrypt = ($obj['Encrypt'] ?? 'true')
    TrustServerCertificate = ($obj['TrustServerCertificate'] ?? 'false')
  }
}

function Invoke-SqlcmdExec($server, $database, $adminUser, $adminPass, [switch]$UseAAD, $tsql) {
  $args = @()
  if ($server) { $args += @('-S', $server) }
  if ($database) { $args += @('-d', $database) }
  if ($UseAAD) { $args += @('-G') }
  elseif ($adminUser) { $args += @('-U', $adminUser, '-P', $adminPass) }
  $tmp = New-TemporaryFile
  Set-Content -Path $tmp -Value $tsql -Encoding UTF8
  try {
    & sqlcmd @args -b -i $tmp
    if ($LASTEXITCODE -ne 0) { throw "sqlcmd failed with exit $LASTEXITCODE" }
  } finally { Remove-Item -Force $tmp -ErrorAction SilentlyContinue }
}

function Invoke-SqlcmdQuery($server, $database, $adminUser, $adminPass, [switch]$UseAAD, $query) {
  $args = @()
  if ($server) { $args += @('-S', $server) }
  if ($database) { $args += @('-d', $database) }
  if ($UseAAD) { $args += @('-G') }
  elseif ($adminUser) { $args += @('-U', $adminUser, '-P', $adminPass) }
  $args += @('-b','-W','-s',',','-h','-1','-Q', $query)
  $out = & sqlcmd @args 2>&1
  if ($LASTEXITCODE -ne 0) { throw "sqlcmd query failed: $out" }
  # Normalize output to single CSV line
  $line = ($out | Where-Object { $_ -and -not ($_ -match "rows affected") } | Select-Object -First 1)
  return ($line -as [string])
}

function Escape-SqlLiteral([string]$s) { if ($null -eq $s) { return '' } return ($s -replace "'", "''") }

function Get-DbUserState($server,$db,$adminUser,$adminPass,[switch]$UseAAD,[string]$username) {
  $u = Escape-SqlLiteral $username
  $tsql = @"
SELECT
  readerExists = CASE WHEN EXISTS(SELECT 1 FROM sys.database_principals WHERE name=N'portal_reader') THEN 1 ELSE 0 END,
  writerExists = CASE WHEN EXISTS(SELECT 1 FROM sys.database_principals WHERE name=N'portal_writer') THEN 1 ELSE 0 END,
  userExists = CASE WHEN EXISTS(SELECT 1 FROM sys.database_principals WHERE name=N'$u') THEN 1 ELSE 0 END,
  memberReader = CASE WHEN EXISTS(
    SELECT 1 FROM sys.database_role_members rm
    JOIN sys.database_principals r ON rm.role_principal_id=r.principal_id
    JOIN sys.database_principals u ON rm.member_principal_id=u.principal_id
    WHERE r.name=N'portal_reader' AND u.name=N'$u') THEN 1 ELSE 0 END,
  memberWriter = CASE WHEN EXISTS(
    SELECT 1 FROM sys.database_role_members rm
    JOIN sys.database_principals r ON rm.role_principal_id=r.principal_id
    JOIN sys.database_principals u ON rm.member_principal_id=u.principal_id
    WHERE r.name=N'portal_writer' AND u.name=N'$u') THEN 1 ELSE 0 END;
"@
  $csv = Invoke-SqlcmdQuery -server $server -database $db -adminUser $adminUser -adminPass $adminPass -UseAAD:$UseAAD -query $tsql
  $parts = ($csv -split ',') | ForEach-Object { $_.Trim() }
  if ($parts.Count -lt 5) { return @{ readerExists=$null; writerExists=$null; userExists=$null; memberReader=$null; memberWriter=$null } }
  return [ordered]@{
    readerExists = ($parts[0] -eq '1')
    writerExists = ($parts[1] -eq '1')
    userExists   = ($parts[2] -eq '1')
    memberReader = ($parts[3] -eq '1')
    memberWriter = ($parts[4] -eq '1')
  }
}

function Write-Event($obj) {
  $logDir = Join-Path 'agents' 'logs'
  if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Force -Path $logDir | Out-Null }
  $logPath = Join-Path $logDir 'events.jsonl'
  ($obj | ConvertTo-Json -Depth 8) | Out-File -FilePath $logPath -Append -Encoding utf8
}

function Out-Result($obj) { $obj | ConvertTo-Json -Depth 8 | Write-Output }

$intent = Read-Intent $IntentPath
$now = (Get-Date).ToUniversalTime().ToString('o')

switch ($Action) {
  'db-user:create' {
    $p = $intent.params
    $username = $p.username
    $database = $p.database
    $roles = @($p.roles)
    $password = New-StrongPassword 40

    # Connection selection: prefer intent.adminConnString, else env DB_ADMIN_CONN_STRING, else env DB_CONN_STRING, else server/user from params
    $adminConn = $p.adminConnString
    if (-not $adminConn) { $adminConn = $env:DB_ADMIN_CONN_STRING }
    if (-not $adminConn) { $adminConn = $env:DB_CONN_STRING }
    $conn = Parse-ConnString $adminConn
    $server = if ($p.server) { $p.server } elseif ($conn) { $conn.Server } else { $null }
    $db = if ($database) { $database } elseif ($conn) { $conn.Database } else { $null }
    $adminUser = $conn?.UserId
    $adminPass = $conn?.Password
    $useAAD = $false
    if ($p.adminAuth -eq 'aad' -or (-not $adminUser -and -not $adminPass)) { $useAAD = $true }

    # Build T-SQL idempotente: ruoli + grants + utente contained + add member
    $tsql = @()
    $tsql += "IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name=N'portal_reader') CREATE ROLE portal_reader;"
    $tsql += "IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name=N'portal_writer') CREATE ROLE portal_writer;"
    if ($roles -contains 'portal_reader') { $tsql += "GRANT SELECT ON SCHEMA::PORTAL TO portal_reader;" }
    if ($roles -contains 'portal_writer') { $tsql += "GRANT INSERT, UPDATE, DELETE ON SCHEMA::PORTAL TO portal_writer;" }
    $tsql += "IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name=N'$username') BEGIN CREATE USER [$username] WITH PASSWORD = '$password'; END ELSE BEGIN ALTER USER [$username] WITH PASSWORD = '$password'; END;"
    if ($roles -contains 'portal_reader') { $tsql += "IF NOT EXISTS (SELECT 1 FROM sys.database_role_members rm JOIN sys.database_principals r ON rm.role_principal_id=r.principal_id JOIN sys.database_principals u ON rm.member_principal_id=u.principal_id WHERE r.name='portal_reader' AND u.name='$username') ALTER ROLE portal_reader ADD MEMBER [$username];" }
    if ($roles -contains 'portal_writer') { $tsql += "IF NOT EXISTS (SELECT 1 FROM sys.database_role_members rm JOIN sys.database_principals r ON rm.role_principal_id=r.principal_id JOIN sys.database_principals u ON rm.member_principal_id=u.principal_id WHERE r.name='portal_writer' AND u.name='$username') ALTER ROLE portal_writer ADD MEMBER [$username];" }
    $tsqlText = ($tsql -join "`n")

    # Pre-check (WhatIf validation): stato attuale di ruoli/utente/membership
    $stateBefore = $null
    try { $stateBefore = Get-DbUserState -server $server -db $db -adminUser $adminUser -adminPass $adminPass -UseAAD:$useAAD -username $username } catch { $stateBefore = $null }
    $preCheck = $null
    if ($WhatIf) {
      try {
        $preJson = & pwsh scripts/db-verify-connect.ps1 -ConnString $adminConn -Server $server -Database $db -AdminUser $adminUser -AdminPassword $adminPass -AAD:($useAAD) -CheckUser $username
        if ($preJson) { $preCheck = $preJson | ConvertFrom-Json }
      } catch { $preCheck = $null }
    }

    $executed = $false
    $errorMsg = $null
    if (-not $WhatIf) {
      try {
        Invoke-SqlcmdExec -server $server -database $db -adminUser $adminUser -adminPass $adminPass -UseAAD:$useAAD -tsql $tsqlText
        $executed = $true
      } catch {
        $errorMsg = $_.Exception.Message
      }
    }

    # Optional Key Vault
    $kvSet = $false
    if ($p.storeInKeyVault -and $p.keyvault?.name -and $p.keyvault?.secretName) {
      if (-not $WhatIf) {
        try {
          & az keyvault secret set --vault-name $p.keyvault.name --name $p.keyvault.secretName --value $password --tags "username=$username" "database=$db" "createdBy=agent_dba"
          if ($LASTEXITCODE -eq 0) { $kvSet = $true }
        } catch { $kvSet = $false }
      }
    }

    # Post-check se eseguito
    $stateAfter = $null
    if ($executed -and -not $errorMsg) { try { $stateAfter = Get-DbUserState -server $server -db $db -adminUser $adminUser -adminPass $adminPass -UseAAD:$useAAD -username $username } catch { $stateAfter = $null } }

    $result = [ordered]@{
      action = $Action
      ok = ($errorMsg -eq $null)
      whatIf = [bool]$WhatIf
      nonInteractive = [bool]$NonInteractive
      correlationId = $intent?.correlationId
      startedAt = $now
      finishedAt = (Get-Date).ToUniversalTime().ToString('o')
      output = [ordered]@{
        server = $server
        database = $db
        username = $username
        roles = $roles
        executed = $executed
        keyVaultSet = $kvSet
        passwordMasked = ($password.Substring(0,4) + '…' + $password.Substring($password.Length-2))
        tsqlPreview = $tsqlText
        auth = ($useAAD ? 'aad' : 'sql')
        stateBefore = $stateBefore
        preCheck = $preCheck
        stateAfter = $stateAfter
        hint = 'WhatIf consigliato: verifica stateBefore/stateAfter prima di applicare in ambienti condivisi.'
        summary = ("create user " + $username + " roles: " + ($roles -join ',') + (if ($WhatIf) { " (whatIf)" } else { " (applied)" }))
      }
      error = $errorMsg
    }
    $result.contractId = 'action-result'
    $result.contractVersion = '1.0'
    if ($LogEvent) { Write-Event ($result + @{ event='agent-dba'; govApproved=$false }) }
    Out-Result $result
  }
  'db-user:rotate' {
    $p = $intent.params
    $username = $p.username
    $database = $p.database
    $password = New-StrongPassword 40
    $adminConn = $p.adminConnString; if (-not $adminConn) { $adminConn = $env:DB_ADMIN_CONN_STRING }
    if (-not $adminConn) { $adminConn = $env:DB_CONN_STRING }
    $conn = Parse-ConnString $adminConn
    $server = if ($p.server) { $p.server } elseif ($conn) { $conn.Server } else { $null }
    $db = if ($database) { $database } elseif ($conn) { $conn.Database } else { $null }
    $adminUser = $conn?.UserId; $adminPass = $conn?.Password
    $useAAD = ($p.adminAuth -eq 'aad' -or (-not $adminUser -and -not $adminPass))

    $tsqlText = "ALTER USER [$username] WITH PASSWORD = '$password';"
    $stateBefore = $null
    try { $stateBefore = Get-DbUserState -server $server -db $db -adminUser $adminUser -adminPass $adminPass -UseAAD:$useAAD -username $username } catch { $stateBefore = $null }
    $preCheck = $null
    if ($WhatIf) {
      try {
        $preJson = & pwsh scripts/db-verify-connect.ps1 -ConnString $adminConn -Server $server -Database $db -AdminUser $adminUser -AdminPassword $adminPass -AAD:($useAAD) -CheckUser $username
        if ($preJson) { $preCheck = $preJson | ConvertFrom-Json }
      } catch { $preCheck = $null }
    }
    $executed = $false; $errorMsg = $null
    if (-not $WhatIf) {
      try { Invoke-SqlcmdExec -server $server -database $db -adminUser $adminUser -adminPass $adminPass -UseAAD:$useAAD -tsql $tsqlText; $executed=$true }
      catch { $errorMsg = $_.Exception.Message }
    }
    $kvSet = $false
    if ($p.storeInKeyVault -and $p.keyvault?.name -and $p.keyvault?.secretName -and -not $WhatIf) {
      try { & az keyvault secret set --vault-name $p.keyvault.name --name $p.keyvault.secretName --value $password --tags "username=$username" "database=$db" "rotatedBy=agent_dba"; if ($LASTEXITCODE -eq 0) { $kvSet = $true } } catch {}
    }
    $stateAfter = $null
    if ($executed -and -not $errorMsg) { try { $stateAfter = Get-DbUserState -server $server -db $db -adminUser $adminUser -adminPass $adminPass -UseAAD:$useAAD -username $username } catch { $stateAfter = $null } }
    $result = [ordered]@{
      action=$Action; ok=($errorMsg -eq $null); whatIf=[bool]$WhatIf; nonInteractive=[bool]$NonInteractive; correlationId=$intent?.correlationId; startedAt=$now; finishedAt=(Get-Date).ToUniversalTime().ToString('o');
      output=[ordered]@{ server=$server; database=$db; username=$username; executed=$executed; keyVaultSet=$kvSet; passwordMasked=($password.Substring(0,4)+'…'+$password.Substring($password.Length-2)); tsqlPreview=$tsqlText; auth=($useAAD?'aad':'sql'); stateBefore=$stateBefore; preCheck=$preCheck; stateAfter=$stateAfter; summary=('rotate password for ' + $username + (if ($WhatIf){' (whatIf)'} else {' (applied)'})) };
      error=$errorMsg }
    $result.contractId = 'action-result'
    $result.contractVersion = '1.0'
    if ($LogEvent) { Write-Event ($result + @{ event='agent-dba'; govApproved=$false }) }
    Out-Result $result
  }
  'db-user:revoke' {
    $p = $intent.params
    $username = $p.username
    $database = $p.database
    $adminConn = $p.adminConnString; if (-not $adminConn) { $adminConn = $env:DB_ADMIN_CONN_STRING }
    if (-not $adminConn) { $adminConn = $env:DB_CONN_STRING }
    $conn = Parse-ConnString $adminConn
    $server = if ($p.server) { $p.server } elseif ($conn) { $conn.Server } else { $null }
    $db = if ($database) { $database } elseif ($conn) { $conn.Database } else { $null }
    $adminUser = $conn?.UserId; $adminPass = $conn?.Password
    $useAAD = ($p.adminAuth -eq 'aad' -or (-not $adminUser -and -not $adminPass))

    $tsql = @()
    $tsql += "IF EXISTS (SELECT 1 FROM sys.database_principals WHERE name=N'portal_reader') BEGIN BEGIN TRY ALTER ROLE portal_reader DROP MEMBER [$username]; END TRY BEGIN CATCH END CATCH END;"
    $tsql += "IF EXISTS (SELECT 1 FROM sys.database_principals WHERE name=N'portal_writer') BEGIN BEGIN TRY ALTER ROLE portal_writer DROP MEMBER [$username]; END TRY BEGIN CATCH END CATCH END;"
    $tsql += "IF EXISTS (SELECT 1 FROM sys.database_principals WHERE name=N'$username') BEGIN DROP USER [$username]; END;"
    $tsqlText = ($tsql -join "`n")

    $stateBefore = $null
    try { $stateBefore = Get-DbUserState -server $server -db $db -adminUser $adminUser -adminPass $adminPass -UseAAD:$useAAD -username $username } catch { $stateBefore = $null }
    $preCheck = $null
    if ($WhatIf) {
      try {
        $preJson = & pwsh scripts/db-verify-connect.ps1 -ConnString $adminConn -Server $server -Database $db -AdminUser $adminUser -AdminPassword $adminPass -AAD:($useAAD) -CheckUser $username
        if ($preJson) { $preCheck = $preJson | ConvertFrom-Json }
      } catch { $preCheck = $null }
    }
    $executed=$false; $errorMsg=$null
    if (-not $WhatIf) {
      try { Invoke-SqlcmdExec -server $server -database $db -adminUser $adminUser -adminPass $adminPass -UseAAD:$useAAD -tsql $tsqlText; $executed=$true }
      catch { $errorMsg = $_.Exception.Message }
    }
    $stateAfter = $null
    if ($executed -and -not $errorMsg) { try { $stateAfter = Get-DbUserState -server $server -db $db -adminUser $adminUser -adminPass $adminPass -UseAAD:$useAAD -username $username } catch { $stateAfter = $null } }
    $result = [ordered]@{
      action=$Action; ok=($errorMsg -eq $null); whatIf=[bool]$WhatIf; nonInteractive=[bool]$NonInteractive; correlationId=$intent?.correlationId; startedAt=$now; finishedAt=(Get-Date).ToUniversalTime().ToString('o');
      output=[ordered]@{ server=$server; database=$db; username=$username; executed=$executed; tsqlPreview=$tsqlText; auth=($useAAD?'aad':'sql'); stateBefore=$stateBefore; preCheck=$preCheck; stateAfter=$stateAfter; summary=('revoke user ' + $username + (if ($WhatIf){' (whatIf)'} else {' (applied)'})) };
      error=$errorMsg }
    $result.contractId = 'action-result'
    $result.contractVersion = '1.0'
    if ($LogEvent) { Write-Event ($result + @{ event='agent-dba'; govApproved=$false }) }
    Out-Result $result
  }
}
