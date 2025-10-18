<#!
.SYNOPSIS
  Append a CSV-friendly activity log line to ACTIVITY_LOG.md

.DESCRIPTION
  Writes a single line in the format:
    yyyyMMddHHmmssZ¦type¦scope¦status¦owner¦message
  - UTC timestamp with trailing Z
  - Broken bar delimiter (¦) for safe CSV import

.PARAMETER Type
  Logical action type (e.g., SCAN, DOC, DATA, RENAME, ADD, UPDATE, INDEX, CHECK, EXPORT, LINT)

.PARAMETER Scope
  Area or component affected (e.g., wiki, endpoint, conventions, entities, links, dataset, api, db, etl, ops, bi)

.PARAMETER Status
  Outcome: success | warn | error

.PARAMETER Owner
  Team or role (e.g., team-docs, team-api, team-data, team-ops)

.PARAMETER Message
  Short description without newlines (they will be stripped). The pipe-broken delimiter will be sanitized to '/'.

.PARAMETER LogPath
  Optional path to the log file. Defaults to ../ACTIVITY_LOG.md next to this script.

.EXAMPLE
  ./add-log.ps1 -Type DOC -Scope conventions -Status success -Owner team-docs -Message "Aggiornata guida naming"

.EXAMPLE
  ./add-log.ps1 -Type RENAME -Scope endpoint -Status success -Owner team-api -Message "Rinominato endp-002-get-api-branding.md"
#>

[CmdletBinding()]
param(
  [Parameter(Mandatory=$true)][string]$Type,
  [Parameter(Mandatory=$true)][string]$Scope,
  [Parameter(Mandatory=$true)][ValidateSet('success','warn','error')][string]$Status,
  [Parameter(Mandatory=$true)][string]$Owner,
  [Parameter(Mandatory=$true)][string]$Message,
  [ValidateSet('none','monthly','scope')][string]$Split = 'none',
  [bool]$MirrorToMaster = $true,
  [string]$LogPath = (Join-Path $PSScriptRoot '..\ACTIVITY_LOG.md'),
  [string]$LogsRoot = (Join-Path $PSScriptRoot '..\logs')
)

function Sanitize([string]$s) {
  if ($null -eq $s) { return '' }
  $s = $s -replace "\r|\n", ' '
  $s = $s -replace '¦', '/'
  return $s.Trim()
}

$ts = (Get-Date).ToUniversalTime().ToString('yyyyMMddHHmmss') + 'Z'
$type = Sanitize $Type
$scope = Sanitize $Scope
$status = Sanitize $Status
$owner = Sanitize $Owner
$msg = Sanitize $Message

$line = '{0}¦{1}¦{2}¦{3}¦{4}¦{5}' -f $ts, $type, $scope, $status, $owner, $msg

function Ensure-File([string]$path) {
  $d = Split-Path -Parent $path
  if ($d -and !(Test-Path -LiteralPath $d)) { New-Item -ItemType Directory -Path $d | Out-Null }
  if (!(Test-Path -LiteralPath $path)) { New-Item -ItemType File -Path $path -Force | Out-Null }
}

if ($MirrorToMaster) {
  Ensure-File -path $LogPath
  Add-Content -LiteralPath $LogPath -Value $line
}

switch ($Split) {
  'monthly' {
    $yyyymm = (Get-Date).ToUniversalTime().ToString('yyyyMM')
    $monthlyPath = Join-Path $LogsRoot (Join-Path 'date' ("${yyyymm}.log"))
    Ensure-File -path $monthlyPath
    Add-Content -LiteralPath $monthlyPath -Value $line
  }
  'scope' {
    $sc = ($scope -replace '[^a-z0-9\-_.]','-')
    if (-not $sc) { $sc = 'misc' }
    $scopePath = Join-Path $LogsRoot (Join-Path 'scope' ("${sc}.log"))
    Ensure-File -path $scopePath
    Add-Content -LiteralPath $scopePath -Value $line
  }
}

Write-Host "Appended: $line"
