<#
.SYNOPSIS
  Seed Azure Boards with Epics/Features for the EasyWay roadmap.

.DESCRIPTION
  Creates Epics and Features with acceptance criteria and links Features to their parent Epic.
  Safe to run multiple times: checks for existing items by Title+Type via WIQL before creating.

.PREREQUISITES
  - Azure CLI installed: az --version
  - Azure DevOps extension: az extension add --name azure-devops
  - Logged in: az login (or az devops login with PAT)
  - Defaults configured (or pass -OrgUrl/-Project):
      az devops configure --defaults organization=https://dev.azure.com/<org> project=<project>

.EXAMPLE
  pwsh scripts/ado/boards-seed.ps1 -OrgUrl https://dev.azure.com/<org> -Project <project>

.EXAMPLE
  pwsh scripts/ado/boards-seed.ps1 -DryRun
#>

[CmdletBinding()]
param(
  [string]$OrgUrl,
  [string]$Project,
  [string]$AreaPath,
  [string]$IterationPath,
  [switch]$DryRun
)

Set-StrictMode -Version Latest
$PSDefaultParameterValues['*:ErrorAction'] = 'Stop'

function Ensure-AzCli() {
  if (-not (Get-Command az -ErrorAction SilentlyContinue)) {
    throw "Azure CLI 'az' not found. Install Azure CLI before running this script."
  }
}

function Ensure-DevOpsExt() {
  $ext = az extension show --name azure-devops 2>$null | Out-String
  if (-not $ext) { Write-Host "Installing azure-devops extension..." -ForegroundColor Yellow; az extension add --name azure-devops | Out-Null }
}

function Set-Defaults([string]$org,[string]$proj){
  if ($org) { az devops configure --defaults organization=$org | Out-Null }
  if ($proj) { az devops configure --defaults project=$proj | Out-Null }
}

function Escape-Newlines([string]$s){ if ($null -eq $s) { return '' } return ($s -replace "\r?\n","\n") }

function Find-WorkItemByTitleType([string]$title,[string]$type){
  $wiql = @"
SELECT [System.Id]
FROM WorkItems
WHERE [System.TeamProject] = @project
  AND [System.WorkItemType] = '$type'
  AND [System.Title] = '$title'
"@
  $res = az boards query --wiql $wiql --output json | ConvertFrom-Json
  if ($res.workItems -and $res.workItems.Count -gt 0) { return $res.workItems[0].id }
  return $null
}

function New-WorkItem([string]$type,[string]$title,[string]$description,[string]$tags){
  $desc = Escape-Newlines $description
  $fields = @("System.Description=$desc")
  if ($AreaPath) { $fields += "System.AreaPath=$AreaPath" }
  if ($IterationPath) { $fields += "System.IterationPath=$IterationPath" }
  if ($tags) { $fields += "System.Tags=$tags" }
  if ($DryRun) {
    Write-Host "(dry-run) create $type: $title" -ForegroundColor DarkGray
    return $null
  }
  $out = az boards work-item create --type $type --title $title --fields $fields --output json | ConvertFrom-Json
  return $out.id
}

function Ensure-WorkItem([string]$type,[string]$title,[string]$description,[string]$tags){
  $existing = Find-WorkItemByTitleType -title $title -type $type
  if ($existing) { Write-Host "Exists: $type #$existing - $title" -ForegroundColor Green; return $existing }
  $id = New-WorkItem -type $type -title $title -description $description -tags $tags
  if ($id) { Write-Host "Created: $type #$id - $title" -ForegroundColor Cyan }
  return $id
}

function Link-Parent([int]$childId,[int]$parentId){
  if ($DryRun) { Write-Host "(dry-run) link $childId -> parent $parentId" -ForegroundColor DarkGray; return }
  az boards work-item relation add --id $childId --relation-type "System.LinkTypes.Hierarchy-Reverse" --target-id $parentId | Out-Null
}

Ensure-AzCli
Ensure-DevOpsExt
Set-Defaults -org $OrgUrl -proj $Project

# Roadmap Epics
$epics = @(
  @{ title='F0 – Quick Wins'; tags='roadmap;f0;quality'; desc='Test API (auth/error/rate limit), OpenAPI completa + Try it, pre-commit hooks (lint/test), KB ricette operative.' },
  @{ title='F1 – Robustezza Prod'; tags='roadmap;f1;prod'; desc='Versioning API (path /v1 o header x-api-version) + deprecations; observability (log strutturati, correlation id, tracing base); health/readiness estesi; rate limit hardening; secret mgmt centralizzato.' },
  @{ title='F2 – Data & Governance'; tags='roadmap;f2;governance'; desc='Flyway/Drift con rollback smoke; backup/restore scriptati; activity/audit con filtri (tenant, esito, govApproved); gates parametrici e KB exception path.' },
  @{ title='F3 – DevEx & Delivery'; tags='roadmap;f3;cicd'; desc='CI/CD: env PR o smoke gates; contract tests; IaC hardening (slot/alert); qualità pipeline (SAST/DAST light) e badge stato.' },
  @{ title='F4 – AI/Docs Evolution'; tags='roadmap;f4;ai-docs'; desc='Wiki: entities.yaml + linking; embeddings pipeline su chunks_master.jsonl con llm.include; ricerca/assistente (endpoint /search o integrazione Teams).' },
  @{ title='F5 – Performance & Scalabilità'; tags='roadmap;f5;perf'; desc='Benchmark/SLO (p95/throughput); caching mirata; hardening multitenant (limiti per tenant, concorrenza).' }
)

$epicIds = @{}
foreach($e in $epics){ $id = Ensure-WorkItem -type 'Epic' -title $e.title -description $e.desc -tags $e.tags; if($id){ $epicIds[$e.title] = $id } }

# Features per Epic
$features = @(
  # F0
  @{ epic='F0 – Quick Wins'; title='F0: Copertura test API 70%'; tags='f0;tests'; desc='Aggiungere test per auth, error handling, rate limit. DoD: coverage >= 70% sui moduli core; tests verdi in CI.' },
  @{ epic='F0 – Quick Wins'; title='F0: OpenAPI completa + Try it'; tags='f0;openapi'; desc='Completare/validare OpenAPI per tutte le rotte, aggiungere esempi request/response e Try it in dev.' },
  @{ epic='F0 – Quick Wins'; title='F0: Pre-commit hooks'; tags='f0;devex'; desc='Abilitare pre-commit per lint/test API e naming linter Wiki.' },
  @{ epic='F0 – Quick Wins'; title='F0: KB ricette operative'; tags='f0;kb'; desc='Aggiungere ricette per deploy, rollback, backup.' },
  # F1
  @{ epic='F1 – Robustezza Prod'; title='F1: Versioning API v1 + deprecations'; tags='f1;api'; desc='Introdurre path /v1 o header x-api-version e stabilire policy deprecazioni.' },
  @{ epic='F1 – Robustezza Prod'; title='F1: Observability base'; tags='f1;observability'; desc='Log strutturati coerenti, correlation id, tracing base, dashboard req/s error% p95.' },
  @{ epic='F1 – Robustezza Prod'; title='F1: Rate limit hardening + secrets'; tags='f1;security'; desc='Test di carico e tuning rate limit per key/tenant; secret management centralizzato.' },
  @{ epic='F1 – Robustezza Prod'; title='F1: Health/readiness estesi'; tags='f1;ops'; desc='Endpoint di health con check DB, storage, config.' },
  # F2
  @{ epic='F2 – Data & Governance'; title='F2: Flyway rollback + Drift smoke'; tags='f2;db'; desc='Script/strategie rollback e smoke test per drift.' },
  @{ epic='F2 – Data & Governance'; title='F2: Backup/restore scriptato'; tags='f2;ops'; desc='Procedure e test end-to-end di backup/restore.' },
  @{ epic='F2 – Data & Governance'; title='F2: Audit model + filtri'; tags='f2;audit'; desc='Estendere modello eventi e filtri (tenant/esito/govApproved) via API/Wiki.' },
  @{ epic='F2 – Data & Governance'; title='F2: Gates parametrici + KB exception path'; tags='f2;governance'; desc='Parametrizzare gates (Checklist/Drift/KB) con variabili e documentare gli exception path.' },
  # F3
  @{ epic='F3 – DevEx & Delivery'; title='F3: PR env / smoke gates'; tags='f3;cicd'; desc='Ambienti effimeri per PR o smoke gates robusti su branch.' },
  @{ epic='F3 – DevEx & Delivery'; title='F3: IaC hardening + alerts'; tags='f3;iac'; desc='Hardening App Service/infra e alert minimi.' },
  @{ epic='F3 – DevEx & Delivery'; title='F3: Qualità pipeline (SAST/DAST) + badge'; tags='f3;quality'; desc='Aggiungere SAST/DAST leggeri e badge stato in README.' },
  # F4
  @{ epic='F4 – AI/Docs Evolution'; title='F4: entities.yaml + linking'; tags='f4;docs'; desc='Ampliare tassonomia e linkarla nei front matter.' },
  @{ epic='F4 – AI/Docs Evolution'; title='F4: Embeddings pipeline'; tags='f4;ai'; desc='Pipeline embeddings su chunks_master.jsonl con esclusioni llm.include.' },
  @{ epic='F4 – AI/Docs Evolution'; title='F4: Ricerca / Teams MVP'; tags='f4;ai'; desc='Endpoint /search su chunks o integrazione Teams minima.' },
  # F5
  @{ epic='F5 – Performance & Scalabilità'; title='F5: Benchmark + SLO'; tags='f5;perf'; desc='Benchmark p95/throughput e definizione SLO.' },
  @{ epic='F5 – Performance & Scalabilità'; title='F5: Caching mirata'; tags='f5;perf'; desc='Introdurre caching sui percorsi critici.' },
  @{ epic='F5 – Performance & Scalabilità'; title='F5: Hardening multitenant'; tags='f5;security'; desc='Validazioni/limiti per tenant e test concorrenza.' }
)

$created = @()
foreach($f in $features){
  $parentTitle = $f.epic
  if (-not $epicIds.ContainsKey($parentTitle)) { Write-Warning "Parent epic not found for feature: $($f.title)"; continue }
  $pid = $epicIds[$parentTitle]
  $fid = Ensure-WorkItem -type 'Feature' -title $f.title -description $f.desc -tags $f.tags
  if ($fid) { Link-Parent -childId $fid -parentId $pid; $created += @{ feature=$fid; epic=$pid; title=$f.title; parent=$parentTitle } }
}

if ($created.Count) {
  Write-Host "Summary (Feature -> Epic):" -ForegroundColor Green
  $created | ForEach-Object { Write-Host (" - #{0} {1} -> #{2} {3}" -f $_.feature,$_.title, $_.epic, $_.parent) }
}

Write-Host "Done." -ForegroundColor Green

