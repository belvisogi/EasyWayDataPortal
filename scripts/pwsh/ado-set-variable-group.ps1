Param(
  [Parameter(Mandatory=$true)] [string]$OrgUrl,                 # es. https://dev.azure.com/contoso
  [Parameter(Mandatory=$true)] [string]$Project,                # es. easyway
  [Parameter(Mandatory=$true)] [string]$Pat,                    # Azure DevOps PAT (con permessi Variable Groups)
  [Parameter(Mandatory=$true)] [string]$GroupName,              # es. EasyWay-Secrets
  [string]$Description = "Managed by script",
  [string]$VariablesJsonPath,                                  # percorso a JSON semplice { "KEY":"VALUE", ... }
  [hashtable]$Variables,                                       # alternativa: passare variabili inline
  [string]$SecretsKeys                                         # CSV di chiavi da marcare come segrete
)

$ErrorActionPreference = 'Stop'

function Get-AuthHeader($pat) {
  $pair = ":$pat"
  $bytes = [System.Text.Encoding]::UTF8.GetBytes($pair)
  $token = [System.Convert]::ToBase64String($bytes)
  return @{ Authorization = "Basic $token"; 'Content-Type'='application/json' }
}

function Load-Variables($path, $inlineHash) {
  if ($inlineHash) { return $inlineHash }
  if (-not $path) { return @{} }
  if (-not (Test-Path $path)) { throw "VariablesJsonPath not found: $path" }
  $json = Get-Content $path -Raw | ConvertFrom-Json
  # support both {"variables": {k:v}} and flat {k:v}
  if ($json.variables) { return @{} + $json.variables }
  return @{} + $json
}

$headers = Get-AuthHeader $Pat
$apiVersion = '7.1-preview.2'
$listUrl = "$OrgUrl/$Project/_apis/distributedtask/variablegroups?api-version=$apiVersion"
$existing = Invoke-RestMethod -Headers $headers -Method Get -Uri $listUrl
$vg = $existing.value | Where-Object { $_.name -eq $GroupName } | Select-Object -First 1

$varsFlat = Load-Variables -path $VariablesJsonPath -inlineHash $Variables
$secretSet = @{}
if ($SecretsKeys) {
  foreach ($k in ($SecretsKeys -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ })) {
    $secretSet[$k] = $true
  }
}

$variablesObj = @{}
foreach ($k in $varsFlat.Keys) {
  $isSecret = $false
  if ($secretSet.ContainsKey($k)) { $isSecret = $true }
  $variablesObj[$k] = @{ value = [string]$varsFlat[$k]; isSecret = [bool]$isSecret }
}

$body = @{ name = $GroupName; description = $Description; type = 'Vsts'; variables = $variablesObj } | ConvertTo-Json -Depth 10

if ($vg) {
  $updateUrl = "$OrgUrl/$Project/_apis/distributedtask/variablegroups/$($vg.id)?api-version=$apiVersion"
  Write-Host "Updating Variable Group '$GroupName' (id=$($vg.id))" -ForegroundColor Cyan
  $res = Invoke-RestMethod -Headers $headers -Method Put -Uri $updateUrl -Body $body
} else {
  Write-Host "Creating Variable Group '$GroupName'" -ForegroundColor Cyan
  $createUrl = $listUrl
  $res = Invoke-RestMethod -Headers $headers -Method Post -Uri $createUrl -Body $body
}

$out = @{ status = 'ok'; group = $res.name; id = $res.id; variables = ($res.variables | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name) } | ConvertTo-Json -Depth 5
Write-Output $out

