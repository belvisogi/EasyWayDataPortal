<#
  _set-pbi-approved.ps1
  Aggiorna PBI ADO a stato "Approved" via PATCH.
  Usa ADO_WORKITEMS_PAT.
#>
Param([int[]]$PbiIds)

$ErrorActionPreference = 'Stop'
$Pat   = (Get-Content 'C:\old\.env.local' | Where-Object { $_ -match '^ADO_WORKITEMS_PAT=' } | ForEach-Object { ($_ -split '=', 2)[1].Trim().Trim('"') })
$b64   = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes(":$Pat"))
$hGet  = @{ Authorization = "Basic $b64"; 'Content-Type' = 'application/json' }
$hPatch= @{ Authorization = "Basic $b64"; 'Content-Type' = 'application/json-patch+json' }
$body  = ConvertTo-Json @(@{ op = 'add'; path = '/fields/System.State'; value = 'Approved' })

foreach ($id in $PbiIds) {
    $detail = Invoke-RestMethod -Uri "https://dev.azure.com/EasyWayData/EasyWay-DataPortal/_apis/wit/workitems/$id`?api-version=7.1" -Headers $hGet
    $before = $detail.fields.'System.State'
    $r = Invoke-RestMethod -Uri "https://dev.azure.com/EasyWayData/EasyWay-DataPortal/_apis/wit/workitems/$id`?api-version=7.1" -Method PATCH -Headers $hPatch -Body $body
    Write-Host "  #$id $($r.fields.'System.Title'.Substring(0,40))... [$before -> $($r.fields.'System.State')]" -ForegroundColor Green
}
