$ErrorActionPreference = "Stop"

param(
    [string]$ConfigPath = "C:\\old\\EasyWayDataPortal\\scripts\\infra\\remote\\remote.config.ps1",
    [string]$IP,
    [string]$Key,
    [switch]$WhatIf
)

# Config
if (Test-Path $ConfigPath) { . $ConfigPath }
if (-not $IP -and $RemoteConfig) { $IP = $RemoteConfig.IP }
if (-not $Key -and $RemoteConfig) { $Key = $RemoteConfig.Key }
if (-not $IP) { throw "IP non configurato (parametro -IP o remote.config.ps1)" }
if (-not $Key) { throw "Key non configurata (parametro -Key o remote.config.ps1)" }

# Preflight
if (-not (Test-Path $Key)) { throw "SSH key non trovata: $Key" }
if (-not $WhatIf) {
    ssh -i $Key -o StrictHostKeyChecking=no ubuntu@$IP "echo ok" | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "SSH non raggiungibile: $IP" }
    ssh -i $Key -o StrictHostKeyChecking=no ubuntu@$IP "test -d EasyWayDataPortal" | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "Repo non trovata sul server. Esegui prima deploy_easyway.ps1" }
}

Write-Host "Checking Remote Status..."

# Use simplified commands without complex quoting to avoid SSH issues
$Cmd1 = "echo '[1] Directory Link Check:' && ls -l /opt/easyway/current"
$Cmd2 = "echo '[2] Docker Status:' && sudo docker ps -a"
$Cmd3 = "echo '[3] Agent Logs:' && sudo docker logs --tail 10 easyway-runner 2>&1"

if ($WhatIf) {
    Write-Host "WHATIF: ssh -i $Key -o StrictHostKeyChecking=no ubuntu@$IP <status-checks>" -ForegroundColor Yellow
    return
}

# Run them sequentially
ssh -i $Key -o StrictHostKeyChecking=no ubuntu@$IP "$Cmd1; echo ''; $Cmd2; echo ''; $Cmd3"
