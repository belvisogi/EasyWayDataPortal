Param(
  [ValidateSet('ado:bestpractice.prefetch','ado:bootstrap','ado:userstory.create')]
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
  ($obj | ConvertTo-Json -Depth 20 -Compress) | Out-File -FilePath $logPath -Append -Encoding utf8
  return $logPath
}

function Out-Result($obj) { $obj | ConvertTo-Json -Depth 20 -Compress | Write-Output }

function Get-DefaultExternalSources {
  return @(
    'https://learn.microsoft.com/azure/devops/boards/backlogs/create-your-backlog?view=azure-devops',
    'https://learn.microsoft.com/azure/devops/boards/work-items/guidance/create-work-items?view=azure-devops',
    'https://learn.microsoft.com/azure/devops/boards/work-items/guidance/user-stories?view=azure-devops',
    'https://learn.microsoft.com/azure/devops/boards/boards/boards?view=azure-devops'
  )
}

function Ensure-Dir($path) {
  if (-not (Test-Path $path)) { New-Item -ItemType Directory -Force -Path $path | Out-Null }
}

function Get-LocalBestPractices($wikiRoot) {
  if (-not (Test-Path $wikiRoot)) { throw "Wiki root not found: $wikiRoot" }
  $files = Get-ChildItem -Path $wikiRoot -Recurse -File | Where-Object { $_.Name -match 'best-practice|best-practices' }
  $items = @()
  foreach ($f in $files) {
    $title = $null
    try {
      $content = Get-Content -Raw -Path $f.FullName
      $titleLine = ($content -split "`n" | Where-Object { $_ -match '^# ' } | Select-Object -First 1)
      if ($titleLine) { $title = ($titleLine -replace '^#\s*','').Trim() }
    } catch {}
    if (-not $title) { $title = $f.BaseName }
    $items += [ordered]@{
      path = $f.FullName
      title = $title
      updated = $f.LastWriteTimeUtc.ToString('o')
    }
  }
  return $items
}

function Write-Jsonl($path, $items) {
  if ($null -eq $items) { return }
  foreach ($item in $items) {
    ($item | ConvertTo-Json -Depth 10 -Compress) | Out-File -FilePath $path -Append -Encoding utf8
  }
}

function Get-SafeName($url) {
  $name = $url -replace '^https?://',''
  $name = $name -replace '[^a-zA-Z0-9]+','-'
  return $name.Trim('-')
}

function Download-ExternalSources($urls, $outDir, $whatIf) {
  $results = @()
  foreach ($url in $urls) {
    if ($whatIf) {
      $results += [ordered]@{ url=$url; ok=$true; skipped=$true; reason='WhatIf' }
      continue
    }
    $safeName = Get-SafeName $url
    $filePath = Join-Path $outDir ($safeName + '.html')
    try {
      $resp = Invoke-WebRequest -Uri $url -Method Get -Headers @{ 'User-Agent' = 'EasyWayAgent/1.0' } -TimeoutSec 60
      $resp.Content | Set-Content -Path $filePath -Encoding UTF8
      $results += [ordered]@{ url=$url; ok=$true; status=$resp.StatusCode; path=$filePath }
    } catch {
      $results += [ordered]@{ url=$url; ok=$false; error=$_.Exception.Message }
    }
  }
  return $results
}

function Get-AdoAuthHeader([string]$pat) {
  $token = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":" + $pat))
  return @{ Authorization = "Basic $token" }
}

function Get-AdoApiVersion($ado) {
  if ($ado -and $ado.apiVersion) { return [string]$ado.apiVersion }
  return '7.1-preview.3'
}

function Join-AdoUrl([string]$orgUrl, [string]$project, [string]$pathAndQuery) {
  $base = $orgUrl.TrimEnd('/')
  return ("{0}/{1}{2}" -f $base, $project, $pathAndQuery)
}

function Get-NodeChildren([string]$orgUrl, [string]$project, [string]$group, [string]$parentPath, [hashtable]$headers, [string]$apiVersion) {
  $pathSeg = if ($parentPath) { "/" + [uri]::EscapeDataString($parentPath) } else { "" }
  $url = Join-AdoUrl $orgUrl $project ("/_apis/wit/classificationnodes/{0}{1}?`$depth=1&api-version={2}" -f $group, $pathSeg, $apiVersion)
  return Invoke-RestMethod -Method Get -Uri $url -Headers $headers
}

function Ensure-ClassificationNode([string]$orgUrl, [string]$project, [string]$group, [string]$fullPath, [hashtable]$headers, [string]$apiVersion, [hashtable]$attributes, [bool]$whatIf) {
  if (-not $fullPath) { return }
  $segments = $fullPath -split '\\\\' | Where-Object { $_ -and $_.Trim() -ne '' }
  $parent = ''
  foreach ($seg in $segments) {
    $children = $null
    try { $children = Get-NodeChildren $orgUrl $project $group $parent $headers $apiVersion } catch { $children = $null }
    $exists = $false
    if ($children -and $children.children) {
      $exists = [bool](($children.children | Where-Object { $_.name -eq $seg } | Select-Object -First 1))
    }
    if (-not $exists) {
      if (-not $whatIf) {
        $parentSeg = if ($parent) { "/" + [uri]::EscapeDataString($parent) } else { "" }
        $postUrl = Join-AdoUrl $orgUrl $project ("/_apis/wit/classificationnodes/{0}{1}?api-version={2}" -f $group, $parentSeg, $apiVersion)
        $body = [ordered]@{ name = $seg }
        if ($attributes) { $body.attributes = $attributes }
        $json = $body | ConvertTo-Json -Depth 10
        $null = Invoke-RestMethod -Method Post -Uri $postUrl -Headers $headers -ContentType 'application/json' -Body $json
      }
    }
    $parent = if ($parent) { $parent + '\' + $seg } else { $seg }
  }
}

function Create-WorkItem([string]$orgUrl, [string]$project, [string]$workItemType, [array]$patch, [hashtable]$headers, [string]$apiVersion, [bool]$whatIf) {
  $typeSeg = '$' + [uri]::EscapeDataString($workItemType)
  $url = Join-AdoUrl $orgUrl $project ("/_apis/wit/workitems/{0}?api-version={1}" -f $typeSeg, $apiVersion)
  if ($whatIf) { return [ordered]@{ id=$null; url=$url; skipped=$true; reason='WhatIf' } }
  $body = $patch | ConvertTo-Json -Depth 12
  $resp = Invoke-RestMethod -Method Post -Uri $url -Headers $headers -ContentType 'application/json-patch+json' -Body $body
  return [ordered]@{ id=$resp.id; url=$resp.url; skipped=$false }
}

function Build-JsonPatch($p) {
  $patch = @()
  if ($p.title) { $patch += @{ op='add'; path='/fields/System.Title'; value=[string]$p.title } }
  if ($p.description) { $patch += @{ op='add'; path='/fields/System.Description'; value=[string]$p.description } }
  if ($p.acceptanceCriteria) { $patch += @{ op='add'; path='/fields/Microsoft.VSTS.Common.AcceptanceCriteria'; value=[string]$p.acceptanceCriteria } }
  if ($p.areaPath) { $patch += @{ op='add'; path='/fields/System.AreaPath'; value=[string]$p.areaPath } }
  if ($p.iterationPath) { $patch += @{ op='add'; path='/fields/System.IterationPath'; value=[string]$p.iterationPath } }
  if ($p.tags) { $patch += @{ op='add'; path='/fields/System.Tags'; value=([string[]]$p.tags -join '; ') } }
  if ($p.fields) {
    foreach ($prop in $p.fields.PSObject.Properties) {
      if ($null -ne $prop.Value) {
        $patch += @{ op='add'; path=("/fields/" + $prop.Name); value=$prop.Value }
      }
    }
  }
  return $patch
}

$intent = Read-Intent $IntentPath
$p = if ($null -ne $intent) { $intent.params } else { $null }
$correlationId = $intent?.correlationId ?? $p?.correlationId
$now = (Get-Date).ToUniversalTime().ToString('o')

switch ($Action) {
  'ado:bestpractice.prefetch' {
    $wikiRoot = if ($p?.wikiRoot) { [string]$p.wikiRoot } else { 'Wiki/EasyWayData.wiki' }
    $outDir = if ($p?.outDir) { [string]$p.outDir } else { 'out/ado-best-practices' }
    $downloadExternal = if ($null -ne $p?.downloadExternal) { [bool]$p.downloadExternal } else { $true }
    $externalSources = if ($p?.externalSources) { [string[]]$p.externalSources } else { Get-DefaultExternalSources }

    $artifacts = @()
    $errorMsg = $null
    $executed = $false
    $localItems = @()
    $externalResults = @()

    try {
      $localItems = Get-LocalBestPractices $wikiRoot
      if (-not $WhatIf) {
        Ensure-Dir $outDir
        $localPath = Join-Path $outDir 'local-best-practices.jsonl'
        if (Test-Path $localPath) { Remove-Item -Force $localPath }
        Write-Jsonl $localPath $localItems
        $artifacts += $localPath
      }
      if ($downloadExternal) {
        if (-not $WhatIf) { Ensure-Dir $outDir }
        $externalResults = Download-ExternalSources $externalSources $outDir $WhatIf
        if (-not $WhatIf) {
          $externalIndex = Join-Path $outDir 'external-best-practices.jsonl'
          if (Test-Path $externalIndex) { Remove-Item -Force $externalIndex }
          Write-Jsonl $externalIndex $externalResults
          $artifacts += $externalIndex
        }
      }
      $executed = $true
    } catch {
      $errorMsg = $_.Exception.Message
    }

    $result = [ordered]@{
      action=$Action
      ok=($errorMsg -eq $null)
      whatIf=[bool]$WhatIf
      nonInteractive=[bool]$NonInteractive
      correlationId=$correlationId
      startedAt=$now
      finishedAt=(Get-Date).ToUniversalTime().ToString('o')
      output=[ordered]@{
        wikiRoot=$wikiRoot
        outDir=$outDir
        executed=$executed
        localCount=($localItems | Measure-Object).Count
        externalCount=($externalResults | Measure-Object).Count
        artifacts=$artifacts
        externalResults=$externalResults
      }
      error=$errorMsg
    }
    $result.contractId='action-result'
    $result.contractVersion='1.0'
    if ($LogEvent) { $null = Write-Event ($result + @{ event='agent-ado-userstory'; govApproved=$false }) }
    Out-Result $result
  }

  'ado:bootstrap' {
    $errorMsg = $null
    $executed = $false
    $artifacts = @()
    $planned = [ordered]@{ areas=@(); iterations=@(); backlog=@() }
    $created = [ordered]@{ areas=@(); iterations=@(); workItems=@() }
    $warnings = @()

    try {
      if (-not $p) { throw 'Intent params missing' }
      $ado = $p.ado
      $orgUrl = $ado?.orgUrl
      $project = $ado?.project
      $pat = $ado?.pat
      if (-not $pat) { $pat = $env:ADO_PAT }
      $apiVersion = Get-AdoApiVersion $ado

      $areas = @()
      if ($p.areas) { $areas = [string[]]$p.areas }
      $iterations = @()
      if ($p.iterations) { $iterations = @($p.iterations) }
      $backlog = @()
      if ($p.backlog) { $backlog = @($p.backlog) }

      foreach ($a in $areas) { $planned.areas += $a }
      foreach ($it in $iterations) { $planned.iterations += $it.path }
      foreach ($wi in $backlog) { $planned.backlog += ($wi.key ?? $wi.title) }

      if ($WhatIf) {
        if (-not $orgUrl) { $warnings += 'Missing params.ado.orgUrl (ok in WhatIf)' }
        if (-not $project) { $warnings += 'Missing params.ado.project (ok in WhatIf)' }
        if (-not $pat) { $warnings += 'Missing ADO PAT (ok in WhatIf)' }
        $executed = $true
      } else {
        if (-not $orgUrl) { throw 'params.ado.orgUrl is required' }
        if (-not $project) { throw 'params.ado.project is required' }
        if (-not $pat) { throw 'ADO PAT missing. Provide params.ado.pat or env ADO_PAT' }

        $headers = Get-AdoAuthHeader $pat

        foreach ($a in $areas) {
          Ensure-ClassificationNode $orgUrl $project 'areas' $a $headers $apiVersion $null ([bool]$WhatIf)
          $created.areas += [ordered]@{ path=$a; created=(!$WhatIf) }
        }

        foreach ($it in $iterations) {
          $attrs = $null
          if ($it.startDate -or $it.finishDate) {
            $attrs = @{}
            if ($it.startDate) { $attrs.startDate = [string]$it.startDate }
            if ($it.finishDate) { $attrs.finishDate = [string]$it.finishDate }
          }
          Ensure-ClassificationNode $orgUrl $project 'iterations' ([string]$it.path) $headers $apiVersion $attrs ([bool]$WhatIf)
          $created.iterations += [ordered]@{ path=$it.path; created=(!$WhatIf) }
        }

        if ($backlog.Count -gt 0) {
          $createdMap = @{}
          $pending = New-Object System.Collections.Generic.List[object]
          foreach ($wi in $backlog) { $pending.Add($wi) }

          $safety = 0
          while ($pending.Count -gt 0) {
            $progress = $false
            $toRemove = New-Object System.Collections.Generic.List[object]
            foreach ($wi in $pending) {
              $key = [string]$wi.key
              if (-not $key) { throw 'Each backlog item must have key' }
              $parentKey = [string]$wi.parentKey
              if ($parentKey -and (-not $createdMap.ContainsKey($parentKey))) { continue }

              $wiParams = [ordered]@{
                title = $wi.title
                description = $wi.description
                acceptanceCriteria = $wi.acceptanceCriteria
                areaPath = $wi.areaPath
                iterationPath = $wi.iterationPath
                tags = $wi.tags
                fields = $wi.fields
              }
              $patch = Build-JsonPatch $wiParams
              if ($parentKey) {
                $parentUrl = $createdMap[$parentKey].url
                $patch += @{
                  op='add'
                  path='/relations/-'
                  value=@{
                    rel='System.LinkTypes.Hierarchy-Reverse'
                    url=$parentUrl
                    attributes=@{ comment='parent' }
                  }
                }
              }
              $type = if ($wi.workItemType) { [string]$wi.workItemType } else { 'Task' }
              $resp = Create-WorkItem $orgUrl $project $type $patch $headers $apiVersion ([bool]$WhatIf)
              $createdMap[$key] = $resp
              $created.workItems += [ordered]@{ key=$key; type=$type; id=$resp.id; url=$resp.url; skipped=[bool]$resp.skipped }
              $toRemove.Add($wi) | Out-Null
              $progress = $true
            }
            foreach ($wi in $toRemove) { $pending.Remove($wi) | Out-Null }
            $safety++
            if (-not $progress) { throw 'Backlog has unresolved dependencies (missing parentKey?)' }
            if ($safety -gt 2000) { throw 'Backlog resolution exceeded safety limit' }
          }
        }

        $executed = $true
      }
    } catch {
      $errorMsg = $_.Exception.Message
    }

    $result = [ordered]@{
      action=$Action
      ok=($errorMsg -eq $null)
      whatIf=[bool]$WhatIf
      nonInteractive=[bool]$NonInteractive
      correlationId=$correlationId
      startedAt=$now
      finishedAt=(Get-Date).ToUniversalTime().ToString('o')
      output=[ordered]@{
        executed=$executed
        planned=$planned
        created=$created
        artifacts=$artifacts
        warnings=$warnings
        hint='Usare Wiki/ado-operating-model.md come policy; per apply serve PAT con permessi Work Items + Classification Nodes.'
      }
      error=$errorMsg
    }
    $result.contractId='action-result'
    $result.contractVersion='1.0'
    if ($LogEvent) { $null = Write-Event ($result + @{ event='agent-ado-userstory'; govApproved=$false }) }
    Out-Result $result
  }

  'ado:userstory.create' {
    $errorMsg = $null
    $artifacts = @()
    $executed = $false
    $workItemId = $null
    $workItemUrl = $null
    $bestPracticeOut = $null

    try {
      if (-not $p) { throw 'Intent params missing' }
      if (-not $p.title) { throw 'params.title is required' }

      $prefetch = if ($null -ne $p.prefetchBestPractices) { [bool]$p.prefetchBestPractices } else { $true }
      if ($prefetch) {
        $prefetchIntent = [ordered]@{
          params = [ordered]@{
            wikiRoot = $p.wikiRoot
            outDir = $p.outDir
            downloadExternal = if ($null -ne $p.downloadExternal) { [bool]$p.downloadExternal } else { $true }
            externalSources = $p.externalSources
          }
        }
        $prefetchResult = $null
        $prefetchParams = $prefetchIntent.params
        $wikiRoot = if ($prefetchParams.wikiRoot) { [string]$prefetchParams.wikiRoot } else { 'Wiki/EasyWayData.wiki' }
        $outDir = if ($prefetchParams.outDir) { [string]$prefetchParams.outDir } else { 'out/ado-best-practices' }
        $downloadExternal = if ($null -ne $prefetchParams.downloadExternal) { [bool]$prefetchParams.downloadExternal } else { $true }
        $externalSources = if ($prefetchParams.externalSources) { [string[]]$prefetchParams.externalSources } else { Get-DefaultExternalSources }

        $localItems = Get-LocalBestPractices $wikiRoot
        if (-not $WhatIf) {
          Ensure-Dir $outDir
          $localPath = Join-Path $outDir 'local-best-practices.jsonl'
          if (Test-Path $localPath) { Remove-Item -Force $localPath }
          Write-Jsonl $localPath $localItems
          $artifacts += $localPath
        }
        $externalResults = @()
        if ($downloadExternal) {
          if (-not $WhatIf) { Ensure-Dir $outDir }
          $externalResults = Download-ExternalSources $externalSources $outDir $WhatIf
          if (-not $WhatIf) {
            $externalIndex = Join-Path $outDir 'external-best-practices.jsonl'
            if (Test-Path $externalIndex) { Remove-Item -Force $externalIndex }
            Write-Jsonl $externalIndex $externalResults
            $artifacts += $externalIndex
          }
        }
        $bestPracticeOut = [ordered]@{
          wikiRoot=$wikiRoot
          outDir=$outDir
          localCount=($localItems | Measure-Object).Count
          externalCount=($externalResults | Measure-Object).Count
          artifacts=$artifacts
          externalResults=$externalResults
        }
      }

      $patch = Build-JsonPatch $p
      $workItemType = if ($p.workItemType) { [string]$p.workItemType } else { 'User Story' }
      $ado = $p.ado
      $orgUrl = $ado?.orgUrl
      $project = $ado?.project
      $pat = $ado?.pat
      if (-not $pat) { $pat = $env:ADO_PAT }
      $apiVersion = if ($ado?.apiVersion) { [string]$ado.apiVersion } else { '7.1-preview.3' }

      if (-not $orgUrl) { throw 'params.ado.orgUrl is required' }
      if (-not $project) { throw 'params.ado.project is required' }
      if (-not $pat -and -not $WhatIf) { throw 'ADO PAT missing. Provide params.ado.pat or env ADO_PAT' }

      $workItemTypeSegment = '$' + [uri]::EscapeDataString($workItemType)
      $requestUrl = "{0}/{1}/_apis/wit/workitems/{2}?api-version={3}" -f $orgUrl.TrimEnd('/'), $project, $workItemTypeSegment, $apiVersion

      if (-not $WhatIf) {
        $headers = Get-AdoAuthHeader $pat
        $body = $patch | ConvertTo-Json -Depth 10
        $resp = Invoke-RestMethod -Method Post -Uri $requestUrl -Headers $headers -ContentType 'application/json-patch+json' -Body $body
        $workItemId = $resp.id
        $workItemUrl = $resp.url
        $executed = $true
      }

    } catch {
      $errorMsg = $_.Exception.Message
    }

    $result = [ordered]@{
      action=$Action
      ok=($errorMsg -eq $null)
      whatIf=[bool]$WhatIf
      nonInteractive=[bool]$NonInteractive
      correlationId=$correlationId
      startedAt=$now
      finishedAt=(Get-Date).ToUniversalTime().ToString('o')
      output=[ordered]@{
        executed=$executed
        workItemId=$workItemId
        workItemUrl=$workItemUrl
        bestPractices=$bestPracticeOut
        artifacts=$artifacts
      }
      error=$errorMsg
    }
    $result.contractId='action-result'
    $result.contractVersion='1.0'
    if ($LogEvent) { $null = Write-Event ($result + @{ event='agent-ado-userstory'; govApproved=$false }) }
    Out-Result $result
  }
}
