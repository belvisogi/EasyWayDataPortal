Param(
  [ValidateSet('kv-secret:set','kv-secret:reference','access-registry:propose')]
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

function Write-Event($obj) {
  $logDir = Join-Path 'agents' 'logs'
  if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Force -Path $logDir | Out-Null }
  $logPath = Join-Path $logDir 'events.jsonl'
  ($obj | ConvertTo-Json -Depth 10) | Out-File -FilePath $logPath -Append -Encoding utf8
  return $logPath
}

function Out-Result($obj) { $obj | ConvertTo-Json -Depth 10 | Write-Output }

function Build-SecretUri([string]$vaultName, [string]$secretName, [string]$version) {
  $base = "https://$vaultName.vault.azure.net/secrets/$secretName"
  if ($version) { return "$base/$version" }
  return $base
}

function KeyVault-Reference([string]$secretUri) {
  return "@Microsoft.KeyVault(SecretUri=$secretUri)"
}

$intent = Read-Intent $IntentPath
$p = $intent?.params
$now = (Get-Date).ToUniversalTime().ToString('o')

switch ($Action) {
  'kv-secret:set' {
    $vault = [string]$p.vaultName
    $name = [string]$p.secretName
    $value = [string]$p.secretValue
    $tags = $p.tags

    if ([string]::IsNullOrWhiteSpace($vault) -or [string]::IsNullOrWhiteSpace($name) -or [string]::IsNullOrWhiteSpace($value)) {
      Out-Result ([ordered]@{ action=$Action; ok=$false; error='vaultName/secretName/secretValue required' })
      exit 1
    }

    $executed = $false
    $errorMsg = $null
    $secretUri = Build-SecretUri -vaultName $vault -secretName $name -version $null
    $ref = KeyVault-Reference -secretUri $secretUri

    if (-not $WhatIf) {
      if (-not (Get-Command az -ErrorAction SilentlyContinue)) {
        $errorMsg = 'az CLI not found in PATH'
      } else {
        try {
          $args = @('keyvault','secret','set','--vault-name',$vault,'--name',$name,'--value',$value)
          if ($tags) {
            foreach ($k in $tags.PSObject.Properties.Name) {
              $args += @('--tags', ("{0}={1}" -f $k, $tags.$k))
            }
          }
          & az @args | Out-Null
          if ($LASTEXITCODE -ne 0) { throw "az keyvault secret set failed with exit $LASTEXITCODE" }
          $executed = $true
        } catch { $errorMsg = $_.Exception.Message }
      }
    }

    $result = [ordered]@{
      action = $Action
      ok = ($errorMsg -eq $null)
      whatIf = [bool]$WhatIf
      nonInteractive = [bool]$NonInteractive
      correlationId = ($intent?.correlationId ?? $p?.correlationId)
      startedAt = $now
      finishedAt = (Get-Date).ToUniversalTime().ToString('o')
      output = [ordered]@{
        vaultName = $vault
        secretName = $name
        executed = $executed
        secretUri = $secretUri
        appSettingReference = $ref
        note = 'Il valore del secret non viene mai stampato nei log/output.'
      }
      error = $errorMsg
    }
    $result.contractId = 'action-result'
    $result.contractVersion = '1.0'
    if ($LogEvent) {
      $evt = $result + @{ event='agent-security'; govApproved=$false }
      $null = Write-Event $evt
    }
    Out-Result $result
  }
  'kv-secret:reference' {
    $vault = [string]$p.vaultName
    $name = [string]$p.secretName
    $version = if ($p.version) { [string]$p.version } else { $null }
    if ([string]::IsNullOrWhiteSpace($vault) -or [string]::IsNullOrWhiteSpace($name)) {
      Out-Result ([ordered]@{ action=$Action; ok=$false; error='vaultName/secretName required' })
      exit 1
    }
    $secretUri = Build-SecretUri -vaultName $vault -secretName $name -version $version
    $ref = KeyVault-Reference -secretUri $secretUri
    $result = [ordered]@{
      action=$Action; ok=$true; whatIf=[bool]$WhatIf; nonInteractive=[bool]$NonInteractive; correlationId=($intent?.correlationId ?? $p?.correlationId);
      startedAt=$now; finishedAt=(Get-Date).ToUniversalTime().ToString('o');
      output=[ordered]@{ vaultName=$vault; secretName=$name; version=$version; secretUri=$secretUri; appSettingReference=$ref }
    }
    $result.contractId = 'action-result'
    $result.contractVersion = '1.0'
    if ($LogEvent) { $null = Write-Event ($result + @{ event='agent-security'; govApproved=$false }) }
    Out-Result $result
  }
  'access-registry:propose' {
    $access = $p.access
    if (-not $access) {
      Out-Result ([ordered]@{ action=$Action; ok=$false; error='params.access required' })
      exit 1
    }
    if ($access.PSObject.Properties.Name -contains 'secretValue') {
      Out-Result ([ordered]@{ action=$Action; ok=$false; error='Do not include secretValue in access registry' })
      exit 1
    }
    $result = [ordered]@{
      action=$Action; ok=$true; whatIf=[bool]$WhatIf; nonInteractive=[bool]$NonInteractive; correlationId=($intent?.correlationId ?? $p?.correlationId);
      startedAt=$now; finishedAt=(Get-Date).ToUniversalTime().ToString('o');
      output=[ordered]@{
        proposedAccess = $access
        targets = [ordered]@{
          wiki = 'Wiki/EasyWayData.wiki/security/segreti-e-accessi.md'
          csvTemplate = 'docs/agentic/templates/sheets/access-registry.csv'
        }
        note = 'Inserire solo metadati (secret_ref), mai valori segreti.'
      }
    }
    $result.contractId = 'action-result'
    $result.contractVersion = '1.0'
    if ($LogEvent) { $null = Write-Event ($result + @{ event='agent-security'; govApproved=$false }) }
    Out-Result $result
  }
}
