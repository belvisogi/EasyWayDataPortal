Param(
  [switch]$FailOnError
)

$ErrorActionPreference = 'Stop'

function Read-Json($path){ try { return (Get-Content -Raw -Path $path | ConvertFrom-Json) } catch { return $null } }

$repoRoot = (Get-Location).Path
$kbPath = Join-Path $repoRoot 'agents/kb/recipes.jsonl'
$wikiRoot = Join-Path $repoRoot 'Wiki/EasyWayData.wiki'

$kbText = ''; if (Test-Path $kbPath) { $kbText = Get-Content -Raw -Path $kbPath }

$agentsDir = Join-Path $repoRoot 'agents'
$manifests = Get-ChildItem -Path $agentsDir -Depth 1 -Filter manifest.json -Recurse | Select-Object -ExpandProperty FullName

$missingIntentTemplates = @()
$missingKbRecipes = @()
$missingWikiPages = @()

# Simple action->wiki mapping (extend as needed)
$wikiMap = @{
  'agent_dba:db-user:create'   = 'db-user-access-management.md'
  'agent_dba:db-user:rotate'   = 'db-user-access-management.md'
  'agent_dba:db-user:revoke'   = 'db-user-access-management.md'
  'agent_datalake:dlk-ensure-structure' = 'datalake-ensure-structure.md'
  'agent_datalake:dlk-apply-acl'        = 'datalake-apply-acl.md'
  'agent_datalake:dlk-set-retention'    = 'datalake-set-retention.md'
  'agent_datalake:dlk-export-log'       = 'datalake-apply-acl.md'
  # Estendere qui per nuovi domini, es.:
  # 'agent_governance:some-action' = 'agents-governance.md'
  # 'agent_docs_review:some-action' = 'docs-conventions.md'
}

foreach ($man in $manifests) {
  $agentDir = Split-Path -Parent $man
  $agentName = Split-Path -Leaf $agentDir
  $obj = Read-Json $man
  if (-not $obj) { continue }
  if (-not $obj.actions) { continue }
  foreach ($a in $obj.actions) {
    $action = [string]$a.name
    if ([string]::IsNullOrWhiteSpace($action)) { continue }
    # Template path convention
    $tpl = Join-Path $agentDir (Join-Path 'templates' (('intent.' + ($action -replace ':','-') + '.sample.json')))
    if (-not (Test-Path $tpl)) {
      $missingIntentTemplates += [ordered]@{ agent=$agentName; action=$action; expected=$tpl; severity='mandatory' }
    }
    # KB: search for exact intent string
    if ($kbText -notmatch ('"intent"\s*:\s*"' + [regex]::Escape($action) + '"')) {
      $missingKbRecipes += [ordered]@{ agent=$agentName; action=$action; intent=$action; severity='mandatory' }
    }
    # Wiki: best-effort mapping
    $key = ($agentName + ':' + $action)
    $wikiRel = $wikiMap[$key]
    if ($wikiRel) {
      $wikiPath = Join-Path $wikiRoot $wikiRel
      if (-not (Test-Path $wikiPath)) {
        $missingWikiPages += [ordered]@{ agent=$agentName; action=$action; expected=$wikiRel; severity='advisory' }
      }
    }
  }
}

$mandatoryCount = ($missingIntentTemplates.Count + $missingKbRecipes.Count)
$ok = ($mandatoryCount -eq 0)
$out = [ordered]@{
  ok = $ok
  mandatoryMissing = $mandatoryCount
  missingIntentTemplates = $missingIntentTemplates
  missingKbRecipes = $missingKbRecipes
  missingWikiPages = $missingWikiPages
}
$outJson = $out | ConvertTo-Json -Depth 6
Write-Output $outJson
if ($FailOnError -and $mandatoryCount -gt 0) { exit 1 } else { exit 0 }
