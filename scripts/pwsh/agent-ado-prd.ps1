Param(
  [ValidateSet('ado:prd.decompose')]
  [string]$Action = 'ado:prd.decompose',
  [string]$IntentPath,
  [switch]$WhatIf,
  [switch]$LogEvent
)

$ErrorActionPreference = 'Stop'

function Read-Intent([string]$path) {
  if (-not $path) { return $null }
  if (-not (Test-Path $path)) { throw "Intent file not found: $path" }
  return (Get-Content -Raw -Path $path | ConvertFrom-Json)
}

function Out-Result($obj) {
  $obj | ConvertTo-Json -Depth 30 -Compress | Write-Output
}

function Write-Event($obj) {
  $logDir = Join-Path 'agents' 'logs'
  if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Force -Path $logDir | Out-Null }
  $logPath = Join-Path $logDir 'events.jsonl'
  ($obj | ConvertTo-Json -Depth 20 -Compress) | Out-File -FilePath $logPath -Append -Encoding utf8
  return $logPath
}

function Get-AdoAuthHeader([string]$pat) {
  $token = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":" + $pat))
  return @{ Authorization = "Basic $token" }
}

function Join-AdoUrl([string]$orgUrl, [string]$project, [string]$pathAndQuery) {
  $base = $orgUrl.TrimEnd('/')
  $projEnc = [uri]::EscapeDataString($project)
  return ("{0}/{1}{2}" -f $base, $projEnc, $pathAndQuery)
}

function Get-ExistingWorkItemByTitle([string]$orgUrl, [string]$project, [string]$workItemType, [string]$title, [string]$prdId, [hashtable]$headers, [string]$apiVersion) {
  $safeTitle = $title.Replace("'", "''")
  $wiql = "SELECT [System.Id] FROM WorkItems WHERE [System.TeamProject] = @project AND [System.WorkItemType] = '$workItemType' AND [System.Title] = '$safeTitle'"
  if ($prdId) {
    $wiql += " AND [System.Tags] CONTAINS 'PRD:$prdId'"
  }
  $postUrl = Join-AdoUrl $orgUrl $project ("/_apis/wit/wiql?api-version={0}" -f $apiVersion)
  $body = @{ query = $wiql } | ConvertTo-Json
  $resp = Invoke-RestMethod -Method Post -Uri $postUrl -Headers $headers -ContentType 'application/json' -Body $body
  if ($resp.workItems -and $resp.workItems.Count -gt 0) {
    return [int]$resp.workItems[0].id
  }
  return $null
}

function Create-WorkItem([string]$orgUrl, [string]$project, [string]$workItemType, [array]$patch, [hashtable]$headers, [string]$apiVersion) {
  $typeSeg = '$' + [uri]::EscapeDataString($workItemType)
  $url = Join-AdoUrl $orgUrl $project ("/_apis/wit/workitems/{0}?api-version={1}" -f $typeSeg, $apiVersion)
  $body = $patch | ConvertTo-Json -Depth 20
  return Invoke-RestMethod -Method Post -Uri $url -Headers $headers -ContentType 'application/json-patch+json' -Body $body
}

function Link-ParentChild([string]$orgUrl, [string]$project, [int]$childId, [int]$parentId, [hashtable]$headers, [string]$apiVersion) {
  $url = Join-AdoUrl $orgUrl $project ("/_apis/wit/workitems/{0}?api-version={1}" -f $childId, $apiVersion)
  $patch = @(
    @{
      op = 'add'
      path = '/relations/-'
      value = @{
        rel = 'System.LinkTypes.Hierarchy-Reverse'
        url = "$($orgUrl.TrimEnd('/'))/_apis/wit/workItems/$parentId"
      }
    }
  )
  $body = $patch | ConvertTo-Json -Depth 20
  $null = Invoke-RestMethod -Method Patch -Uri $url -Headers $headers -ContentType 'application/json-patch+json' -Body $body
}

function Build-JsonPatch([string]$title, [string]$description, [string]$acceptanceCriteria, [string]$areaPath, [string]$iterationPath, [string[]]$tags) {
  $patch = @(
    @{ op = 'add'; path = '/fields/System.Title'; value = $title }
  )
  if ($description) { $patch += @{ op = 'add'; path = '/fields/System.Description'; value = $description } }
  if ($acceptanceCriteria) { $patch += @{ op = 'add'; path = '/fields/Microsoft.VSTS.Common.AcceptanceCriteria'; value = $acceptanceCriteria } }
  if ($areaPath) { $patch += @{ op = 'add'; path = '/fields/System.AreaPath'; value = $areaPath } }
  if ($iterationPath) { $patch += @{ op = 'add'; path = '/fields/System.IterationPath'; value = $iterationPath } }
  if ($tags -and $tags.Count -gt 0) { $patch += @{ op = 'add'; path = '/fields/System.Tags'; value = ($tags -join '; ') } }
  return $patch
}

function Parse-Prd([string]$path) {
  if (-not (Test-Path $path)) { throw "PRD file not found: $path" }
  $lines = Get-Content -Path $path -Encoding UTF8

  $title = [IO.Path]::GetFileNameWithoutExtension($path)
  $prdId = $null
  $epics = New-Object System.Collections.Generic.List[object]
  $currentEpic = $null
  $currentFeature = $null

  foreach ($raw in $lines) {
    $line = $raw.Trim()
    if (-not $line) { continue }

    if ($line -match '^#\s+(.+)$') {
      $title = $Matches[1].Trim()
      continue
    }

    if ($line -match '^PRD-ID:\s*(.+)$') {
      $prdId = $Matches[1].Trim()
      continue
    }

    if ($line -match '^##\s*(Epic|EPIC)\s*:\s*(.+)$') {
      $currentEpic = [ordered]@{
        title = $Matches[2].Trim()
        description = ""
        features = New-Object System.Collections.Generic.List[object]
      }
      $epics.Add($currentEpic)
      $currentFeature = $null
      continue
    }

    if ($line -match '^###\s*(Feature|FEATURE)\s*:\s*(.+)$') {
      if ($null -eq $currentEpic) {
        $currentEpic = [ordered]@{
          title = "Auto Epic"
          description = ""
          features = New-Object System.Collections.Generic.List[object]
        }
        $epics.Add($currentEpic)
      }
      $currentFeature = [ordered]@{
        title = $Matches[2].Trim()
        description = ""
        pbis = New-Object System.Collections.Generic.List[object]
      }
      $currentEpic.features.Add($currentFeature)
      continue
    }

    if ($line -match '^-+\s*(PBI|Story|User Story)\s*:\s*(.+)$') {
      $pbiTitle = $Matches[2].Trim()
      if ($null -eq $currentEpic) {
        $currentEpic = [ordered]@{
          title = "Auto Epic"
          description = ""
          features = New-Object System.Collections.Generic.List[object]
        }
        $epics.Add($currentEpic)
      }
      if ($null -eq $currentFeature) {
        $currentFeature = [ordered]@{
          title = "Auto Feature"
          description = ""
          pbis = New-Object System.Collections.Generic.List[object]
        }
        $currentEpic.features.Add($currentFeature)
      }
      $currentFeature.pbis.Add([ordered]@{
        title = $pbiTitle
        acceptanceCriteria = "Given PRD requirement, when implemented, then expected behavior is met."
      })
      continue
    }

    if ($null -ne $currentFeature) {
      if (-not $currentFeature.description) { $currentFeature.description = $line }
      continue
    }
    if ($null -ne $currentEpic) {
      if (-not $currentEpic.description) { $currentEpic.description = $line }
      continue
    }
  }

  if ($epics.Count -eq 0) {
    # Fallback: generate one simple hierarchy from headings
    $fallbackEpic = [ordered]@{
      title = $title
      description = "Generated from PRD fallback parsing."
      features = @(
        [ordered]@{
          title = "Core Delivery"
          description = "Auto-generated feature."
          pbis = @(
            [ordered]@{
              title = "Implement core scope from PRD"
              acceptanceCriteria = "Given PRD, when scope is implemented, then acceptance criteria are satisfied."
            }
          )
        }
      )
    }
    $epics.Add($fallbackEpic)
  }

  return [ordered]@{
    prdTitle = $title
    prdId = $prdId
    epics = $epics
  }
}

$intent = Read-Intent $IntentPath
$p = if ($intent) { $intent.params } else { @{} }
$timestamp = (Get-Date).ToUniversalTime().ToString('o')
$effectiveWhatIf = $true
if ($WhatIf) { $effectiveWhatIf = $true }
elseif ($null -ne $p.whatIf) { $effectiveWhatIf = [bool]$p.whatIf }

if ($Action -eq 'ado:prd.decompose') {
  $prdPath = [string]($p.prdPath ?? '')
  if (-not $prdPath) { throw "params.prdPath is required" }

  $model = Parse-Prd -path $prdPath
  $prdId = $model.prdId
  if (-not $prdId -or $prdId -eq '[AUTO]') {
      $prdId = [IO.Path]::GetFileNameWithoutExtension($prdPath)
  }
  
  $epicCount = 0
  $featureCount = 0
  $pbiCount = 0
  foreach ($e in $model.epics) {
      $epicCount++
      foreach ($f in $e.features) { $featureCount++; $pbiCount += $f.pbis.Count }
  }

  $result = [ordered]@{
    action = $Action
    ok = $true
    whatIf = $effectiveWhatIf
    counts = [ordered]@{ epics = $epicCount; features = $featureCount; pbis = $pbiCount }
    prdId = $prdId
    generated = $model
    created = @()
    error = $null
  }

  if (-not $effectiveWhatIf) {
    $ado = $p.ado
    $orgUrl = [string]($ado.orgUrl ?? $ado.org ?? '')
    $project = [string]($ado.project ?? '')
    $pat = [string]($ado.pat ?? $env:ADO_PAT ?? '')
    $areaPath = [string]($p.areaPath ?? $ado.areaPath ?? '')
    $iterationPath = [string]($p.iterationPath ?? $ado.iterationPath ?? '')
    $apiVersion = [string]($ado.apiVersion ?? '7.0')
    $globalTags = @()
    if ($p.tags) { $globalTags = @($p.tags | ForEach-Object { [string]$_ }) }

    if (-not $orgUrl -or -not $project -or -not $pat) {
      throw "Apply mode requires params.ado.orgUrl, params.ado.project and ADO PAT (params.ado.pat or env ADO_PAT)"
    }

    $headers = Get-AdoAuthHeader $pat
    $prdTag = "PRD:$prdId"
    foreach ($epic in $model.epics) {
      $epicTitle = [string]$epic.title
      $epicId = Get-ExistingWorkItemByTitle -orgUrl $orgUrl -project $project -workItemType 'Epic' -title $epicTitle -prdId $prdId -headers $headers -apiVersion $apiVersion
      $epicCreated = $false
      if (-not $epicId) {
        $epicPatch = Build-JsonPatch -title $epicTitle -description $epic.description -acceptanceCriteria '' -areaPath $areaPath -iterationPath $iterationPath -tags ($globalTags + @('AutoPRD', $prdTag))
        $epicResp = Create-WorkItem -orgUrl $orgUrl -project $project -workItemType 'Epic' -patch $epicPatch -headers $headers -apiVersion $apiVersion
        $epicId = [int]$epicResp.id
        $epicCreated = $true
      }
      $result.created += [ordered]@{ type = 'Epic'; title = $epicTitle; id = $epicId; created = $epicCreated }

      foreach ($feature in $epic.features) {
        $featureTitle = [string]$feature.title
        $featureId = Get-ExistingWorkItemByTitle -orgUrl $orgUrl -project $project -workItemType 'Feature' -title $featureTitle -prdId $prdId -headers $headers -apiVersion $apiVersion
        $featureCreated = $false
        if (-not $featureId) {
          $featurePatch = Build-JsonPatch -title $featureTitle -description $feature.description -acceptanceCriteria '' -areaPath $areaPath -iterationPath $iterationPath -tags ($globalTags + @('AutoPRD', $prdTag))
          $featureResp = Create-WorkItem -orgUrl $orgUrl -project $project -workItemType 'Feature' -patch $featurePatch -headers $headers -apiVersion $apiVersion
          $featureId = [int]$featureResp.id
          Link-ParentChild -orgUrl $orgUrl -project $project -childId $featureId -parentId $epicId -headers $headers -apiVersion $apiVersion
          $featureCreated = $true
        }
        $result.created += [ordered]@{ type = 'Feature'; title = $featureTitle; id = $featureId; parentId = $epicId; created = $featureCreated }

        foreach ($pbi in $feature.pbis) {
          $pbiTitle = [string]$pbi.title
          $pbiId = Get-ExistingWorkItemByTitle -orgUrl $orgUrl -project $project -workItemType 'Product Backlog Item' -title $pbiTitle -prdId $prdId -headers $headers -apiVersion $apiVersion
          $pbiCreated = $false
          if (-not $pbiId) {
            $pbiPatch = Build-JsonPatch -title $pbiTitle -description '' -acceptanceCriteria $pbi.acceptanceCriteria -areaPath $areaPath -iterationPath $iterationPath -tags ($globalTags + @('AutoPRD', $prdTag))
            $pbiResp = Create-WorkItem -orgUrl $orgUrl -project $project -workItemType 'Product Backlog Item' -patch $pbiPatch -headers $headers -apiVersion $apiVersion
            $pbiId = [int]$pbiResp.id
            Link-ParentChild -orgUrl $orgUrl -project $project -childId $pbiId -parentId $featureId -headers $headers -apiVersion $apiVersion
            $pbiCreated = $true
          }
          $result.created += [ordered]@{ type = 'Product Backlog Item'; title = $pbiTitle; id = $pbiId; parentId = $featureId; created = $pbiCreated }
        }
      }
    }
  }

  if ($LogEvent) {
    $event = [ordered]@{
      ts = $timestamp
      agent = 'agent_ado_userstory'
      action = $Action
      ok = $result.ok
      whatIf = $result.whatIf
      correlationId = ($intent.correlationId ?? $p.correlationId)
    }
    $eventPath = Write-Event $event
    $result.eventLog = $eventPath
  }

  Out-Result $result
}
