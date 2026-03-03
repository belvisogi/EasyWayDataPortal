<#
  _cleanup-n8n-branches.ps1
  GEDI-approved cleanup (Session 46):
  1. Abandon PR #232 (test only)
  2. Elimina 8 branch orfani dal remote (7 manuali + 1 auto test)
  3. Rinomina PBI 23-29 rimuovendo prefisso [PBI] dal titolo
#>
Param([switch]$WhatIf)

$ErrorActionPreference = 'Stop'
$PatCode = (Get-Content 'C:\old\.env.local' | Where-Object { $_ -match '^AZURE_DEVOPS_EXT_PAT=' } | ForEach-Object { ($_ -split '=', 2)[1].Trim().Trim('"') })
$PatWI   = (Get-Content 'C:\old\.env.local' | Where-Object { $_ -match '^ADO_WORKITEMS_PAT=' }  | ForEach-Object { ($_ -split '=', 2)[1].Trim().Trim('"') })

$b64Code = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes(":$PatCode"))
$b64WI   = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes(":$PatWI"))
$hCode   = @{ Authorization = "Basic $b64Code"; 'Content-Type' = 'application/json' }
$hWI     = @{ Authorization = "Basic $b64WI";   'Content-Type' = 'application/json' }
$hWIPatch= @{ Authorization = "Basic $b64WI";   'Content-Type' = 'application/json-patch+json' }

$org  = 'https://dev.azure.com/EasyWayData'
$proj = 'EasyWay-DataPortal'
$repo = 'EasyWayDataPortal'

# ── 1. Abandon PR #232 ───────────────────────────────────────────────────────
Write-Host "=== 1. Abandon PR #232 ===" -ForegroundColor Cyan
$prBody = '{"status":"abandoned"}'
if ($WhatIf) {
    Write-Host "  [WhatIf] PATCH PR #232 status=abandoned"
} else {
    try {
        Invoke-RestMethod -Uri "$org/$proj/_apis/git/repositories/$repo/pullrequests/232?api-version=7.1" `
            -Method PATCH -Headers $hCode -Body $prBody | Out-Null
        Write-Host "  PR #232 abbandonata" -ForegroundColor Green
    } catch {
        Write-Host "  WARN: $($_.Exception.Message)" -ForegroundColor Yellow
    }
}

# ── 2. Elimina branch orfani dal remote ──────────────────────────────────────
Write-Host ""
Write-Host "=== 2. Elimina branch orfani ===" -ForegroundColor Cyan

$branches = @(
    'feat/PBI-23-n8n-setup-verify'
    'feat/PBI-24-n8n-ado-pr-conflict-resolver-workflow'
    'feat/PBI-25-n8n-parse-ado-service-hook-payload'
    'feat/PBI-26-n8n-execute-resolve-pr-conflicts'
    'feat/PBI-27-n8n-ado-pr-comment'
    'feat/PBI-28-n8n-escalation-notify'
    'feat/PBI-29-n8n-configure-service-hook'
    'feat/PBI-23-pbi-setup-e-verifica-istanza-n8n-lo'
)

foreach ($b in $branches) {
    if ($WhatIf) {
        Write-Host "  [WhatIf] git push origin --delete $b"
    } else {
        $result = git push origin --delete $b 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  Eliminato: $b" -ForegroundColor Green
        } else {
            Write-Host "  SKIP (non trovato): $b" -ForegroundColor DarkGray
        }
    }
}

# ── 3. Rinomina PBI 23-29 (rimuovi prefisso [PBI]) ───────────────────────────
Write-Host ""
Write-Host "=== 3. Rinomina PBI 23-29 ===" -ForegroundColor Cyan

$pbiTitles = @{
    23 = 'Setup e verifica istanza n8n locale'
    24 = 'Creare workflow n8n ado-pr-conflict-resolver'
    25 = 'Parse payload ADO Service Hook nella PR'
    26 = 'Execute Resolve-PRConflicts.ps1 via n8n Execute Command'
    27 = 'Post ADO PR comment con resolution report'
    28 = 'Handle escalation - notifica team per conflitti non risolti'
    29 = 'Configurare ADO Service Hook subscription per PR conflict'
}

foreach ($id in $pbiTitles.Keys | Sort-Object) {
    $newTitle = $pbiTitles[$id]
    if ($WhatIf) {
        Write-Host "  [WhatIf] PATCH #$id → '$newTitle'"
    } else {
        $body = ConvertTo-Json @(@{ op = 'add'; path = '/fields/System.Title'; value = $newTitle })
        $r = Invoke-RestMethod -Uri "$org/$proj/_apis/wit/workitems/$id`?api-version=7.1" `
            -Method PATCH -Headers $hWIPatch -Body $body
        Write-Host "  #$id → $($r.fields.'System.Title')" -ForegroundColor Green
    }
}

Write-Host ""
Write-Host "=== Cleanup completato ===" -ForegroundColor Green
