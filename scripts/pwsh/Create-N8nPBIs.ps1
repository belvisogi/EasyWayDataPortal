<#
  Create-N8nPBIs.ps1
  Crea Feature + 7 PBI per l'integrazione n8n ADO PR Conflict Resolver su Azure DevOps.
  Usa ADO_WORKITEMS_PAT (scope: Work Items R/W).
  Initiative: INIT-20260301-n8n-webhook-integration
#>
Param(
    [switch] $WhatIf
)

$ErrorActionPreference = 'Stop'
$Pat = (Get-Content 'C:\old\.env.local' | Where-Object { $_ -match '^ADO_WORKITEMS_PAT=' } | ForEach-Object { ($_ -split '=', 2)[1].Trim().Trim('"') })
$bytes = [System.Text.Encoding]::UTF8.GetBytes(":$Pat")
$b64   = [System.Convert]::ToBase64String($bytes)
$h     = @{ Authorization = "Basic $b64"; 'Content-Type' = 'application/json-patch+json' }

$orgUrl  = 'https://dev.azure.com/EasyWayData'
$project = 'EasyWay-DataPortal'
$tag     = 'n8n; INIT-20260301-n8n-webhook-integration'
$epicId  = 4  # Epic "agent"

function New-WorkItem {
    param([string]$Type, [string]$Title, [string]$Description, [string]$Tags, [int]$ParentId = 0)

    $body = @(
        @{ op = 'add'; path = '/fields/System.Title';       value = $Title }
        @{ op = 'add'; path = '/fields/System.Description'; value = $Description }
        @{ op = 'add'; path = '/fields/System.Tags';        value = $Tags }
    )
    if ($ParentId -gt 0) {
        $body += @{
            op    = 'add'
            path  = '/relations/-'
            value = @{
                rel        = 'System.LinkTypes.Hierarchy-Reverse'
                url        = "$orgUrl/$project/_apis/wit/workitems/$ParentId"
                attributes = @{ comment = 'Parent' }
            }
        }
    }

    $json = $body | ConvertTo-Json -Depth 5
    $uri  = "$orgUrl/$project/_apis/wit/workitems/`$$($Type)?api-version=7.1"

    if ($WhatIf) {
        Write-Host "  [WhatIf] POST $Type : $Title"
        return [PSCustomObject]@{ id = 0 }
    }

    $r = Invoke-RestMethod -Uri $uri -Method POST -Headers $h -Body $json
    Write-Host "  Creato #$($r.id) [$Type] $Title"
    return $r
}

# ── Feature ────────────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "=== Creazione Feature n8n ==="
$feature = New-WorkItem `
    -Type 'Feature' `
    -Title '[Feature] n8n ADO PR Conflict Resolver' `
    -Description 'Integrazione n8n per risolvere automaticamente i conflitti di merge nelle PR ADO. ADO Service Hook → n8n webhook → Resolve-PRConflicts.ps1 → ADO comment.' `
    -Tags $tag `
    -ParentId $epicId

$featureId = $feature.id

# ── 7 PBI ─────────────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "=== Creazione 7 PBI ==="

$pbis = @(
    @{
        Title       = '[PBI] Setup e verifica istanza n8n locale'
        Description = 'Verificare che n8n sia in esecuzione in /c/old/n8n-workspace. Documentare porta (5678), URL webhook base (http://localhost:5678/webhook/), credenziali admin. Test: curl al health endpoint n8n risponde 200. Acceptance: webhook test raggiungibile da browser locale.'
    }
    @{
        Title       = '[PBI] Creare workflow n8n ado-pr-conflict-resolver.json'
        Description = 'Progettare e implementare il workflow n8n in agents/n8n/ado-pr-conflict-resolver.json. Struttura: Webhook (trigger) → Code node (parse payload) → Execute Command (pwsh Resolve-PRConflicts.ps1 -Json) → IF (resolved vs escalated) → due rami: success e escalation. Acceptance: file JSON importabile in n8n senza errori.'
    }
    @{
        Title       = '[PBI] Parse payload ADO Service Hook nella PR'
        Description = 'Implementare Code node n8n che estrae dal payload ADO Service Hook: pullRequestId, sourceRefName (→ sourceBranch), targetRefName (→ targetBranch), mergeStatus. Filtro: continuare solo se mergeStatus = "conflicts". Acceptance: test con payload simulato → parametri corretti in output.'
    }
    @{
        Title       = '[PBI] Execute Resolve-PRConflicts.ps1 via n8n Execute Command'
        Description = 'Nodo Execute Command che chiama: pwsh C:/old/EasyWayDataPortal/agents/skills/git/Resolve-PRConflicts.ps1 -PRId {{prId}} -Json. Cattura stdout (JSON report), stderr, exit code. Timeout 120s. Acceptance: esecuzione dry-run su PR reale → report JSON in output nodo.'
    }
    @{
        Title       = '[PBI] Post ADO PR comment con resolution report'
        Description = 'Dopo esecuzione Resolve-PRConflicts.ps1, postare un comment thread sulla PR ADO via REST API: POST .../pullrequests/{id}/threads. Formato Markdown: stato (RESOLVED/ESCALATED), file risolti, file escalated, branch creato. Usa AZURE_DEVOPS_EXT_PAT. Acceptance: comment visibile su ADO PR dopo trigger.'
    }
    @{
        Title       = '[PBI] Handle escalation - notifica team per conflitti non risolti'
        Description = 'Ramo escalation del workflow: se escalated.Count > 0, il comment ADO deve menzionare @giuseppe.belviso e indicare i file che richiedono intervento manuale. Opzionale: aggiungere nodo Slack/Teams. Log evento in file locale /c/old/n8n-workspace/escalation-log.jsonl. Acceptance: simulazione con file sconosciuto → comment con escalation.'
    }
    @{
        Title       = '[PBI] Configurare ADO Service Hook subscription per PR conflict'
        Description = 'In ADO Project Settings → Service Hooks: creare subscription per evento "Pull request updated", filtro mergeStatus = conflicts, URL = http://localhost:5678/webhook/ado-pr-conflict (o IP server se n8n su OCI). Documentare i passi in Wiki agents/n8n-pr-conflict-setup.md. Acceptance: ADO invia webhook → n8n riceve → log visibile.'
    }
)

$created = @()
foreach ($pbi in $pbis) {
    $wi = New-WorkItem `
        -Type 'Product Backlog Item' `
        -Title $pbi.Title `
        -Description $pbi.Description `
        -Tags $tag `
        -ParentId $featureId
    $created += $wi
}

Write-Host ""
Write-Host "=== RIEPILOGO ==="
Write-Host "Feature : #$featureId"
Write-Host "PBI creati: $($created.Count)"
$created | ForEach-Object { Write-Host "  #$($_.id)" }
