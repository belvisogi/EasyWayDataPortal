<#
Upload opzionale di artifact locali (`out/`) verso Azure Storage (Blob) come run artifacts.

Scopo:
- Pubblicare intent/summary/lint/runlog per n8n/ops senza versionarli in git.
- Il canonico resta nel repo (`db/`, `Wiki/`).

Requisiti:
- `az` CLI autenticata (idealmente Managed Identity in CI).
- Network/permessi su Storage.

Uso (WhatIf):
  pwsh scripts/out-upload-datalake.ps1 -StorageAccount <name> -Container <container> -Prefix "<env>/<tenant>/<correlationId>" -WhatIf
#>

[CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
  [string]$SourceDir = 'out',
  [Parameter(Mandatory=$true)][string]$StorageAccount,
  [Parameter(Mandatory=$true)][string]$Container,
  [Parameter(Mandatory=$true)][string]$Prefix,
  [switch]$WhatIf
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if (-not (Test-Path -LiteralPath $SourceDir)) { throw "SourceDir not found: $SourceDir" }
if (-not (Get-Command az -ErrorAction SilentlyContinue)) { throw "az CLI not found in PATH" }

$dest = ("https://{0}.blob.core.windows.net/{1}/{2}" -f $StorageAccount, $Container, ($Prefix.Trim('/')))

if ($PSCmdlet.ShouldProcess($dest, "Upload directory '$SourceDir'")) {
  & az storage blob upload-batch `
    --account-name $StorageAccount `
    --destination $Container `
    --destination-path ($Prefix.Trim('/')) `
    --source $SourceDir `
    --overwrite true | Out-Null
  if ($LASTEXITCODE -ne 0) { throw "az storage blob upload-batch failed with exit $LASTEXITCODE" }
}

[ordered]@{
  ok = $true
  source = $SourceDir.Replace([char]92,'/')
  destination = $dest
  prefix = $Prefix.Trim('/')
} | ConvertTo-Json -Depth 6

