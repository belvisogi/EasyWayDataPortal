Param(
  [ValidateSet('ado:bestpractice.prefetch', 'ado:bootstrap', 'ado:pbi.children', 'ado:userstory.create', 'ado:userstory.export', 'ado:check', 'ado:testcase.create', 'ado:pbi.get', 'ado:pipeline.get-runs', 'ado:pipeline.list', 'ado:pipeline.history')]
  [string]$Action,
  [string]$IntentPath,
  [switch]$NonInteractive,
  [switch]$WhatIf,
  [switch]$LogEvent,
  [switch]$Print,
  [string]$Query,
  [string]$WorkItemType,
  [string]$OutPath,
  [switch]$Force,
  [int]$Id
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
      if ($titleLine) { $title = ($titleLine -replace '^#\s*', '').Trim() }
    }
    catch {}
    if (-not $title) { $title = $f.BaseName }
    $items += [ordered]@{
      path    = $f.FullName
      title   = $title
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
  $name = $url -replace '^https?://', ''
  $name = $name -replace '[^a-zA-Z0-9]+', '-'
  return $name.Trim('-')
}

function Download-ExternalSources($urls, $outDir, $whatIf) {
  $results = @()
  foreach ($url in $urls) {
    if ($whatIf) {
      $results += [ordered]@{ url = $url; ok = $true; skipped = $true; reason = 'WhatIf' }
      continue
    }
    $safeName = Get-SafeName $url
    $filePath = Join-Path $outDir ($safeName + '.html')
    try {
      $resp = Invoke-WebRequest -Uri $url -Method Get -Headers @{ 'User-Agent' = 'Agent/1.0' } -TimeoutSec 60
      $resp.Content | Set-Content -Path $filePath -Encoding UTF8
      $results += [ordered]@{ url = $url; ok = $true; status = $resp.StatusCode; path = $filePath }
    }
    catch {
      $results += [ordered]@{ url = $url; ok = $false; error = $_.Exception.Message }
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
  return '7.0'
}

function Join-AdoUrl([string]$orgUrl, [string]$project, [string]$pathAndQuery) {
  $base = $orgUrl.TrimEnd('/')
  $projEnc = [uri]::EscapeDataString($project)
  return ("{0}/{1}{2}" -f $base, $projEnc, $pathAndQuery)
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
  if ($whatIf) { return [ordered]@{ id = $null; url = $url; skipped = $true; reason = 'WhatIf' } }
  $body = $patch | ConvertTo-Json -Depth 12
  $resp = Invoke-RestMethod -Method Post -Uri $url -Headers $headers -ContentType 'application/json-patch+json' -Body $body
  return [ordered]@{ id = $resp.id; url = $resp.url; skipped = $false }
}

function Get-WorkItemsByQuery([string]$orgUrl, [string]$project, [string]$wiql, [hashtable]$headers, [string]$apiVersion) {
  $postUrl = Join-AdoUrl $orgUrl $project ("/_apis/wit/wiql?api-version={0}" -f $apiVersion)
  Write-Host "DEBUG: POST $postUrl" -ForegroundColor Cyan
  $body = @{ query = $wiql } | ConvertTo-Json
  $resp = Invoke-RestMethod -Method Post -Uri $postUrl -Headers $headers -ContentType 'application/json' -Body $body
  
  $ids = @()
  if ($resp.workItems) { $ids = $resp.workItems.id }
  
  if ($ids.Count -eq 0) { return @() }
  
  # Chunk IDs (max 200 per call usually, keeping it safe with 50)
  $results = @()
  for ($i = 0; $i -lt $ids.Count; $i += 50) {
    $chunk = $ids[$i..([math]::Min($i + 49, $ids.Count - 1))]
    $idsStr = $chunk -join ','
    $getUrl = Join-AdoUrl $orgUrl $project ("/_apis/wit/workitems?ids={0}&api-version={1}&`$expand=all" -f $idsStr, $apiVersion)
    $batch = Invoke-RestMethod -Method Get -Uri $getUrl -Headers $headers
    if ($batch.value) { $results += $batch.value }
  }
  return $results
}

function Build-JsonPatch($p) {
  $patch = @()
  if ($p.title) { $patch += @{ op = 'add'; path = '/fields/System.Title'; value = [string]$p.title } }
  if ($p.description) { $patch += @{ op = 'add'; path = '/fields/System.Description'; value = [string]$p.description } }
  if ($p.acceptanceCriteria) { $patch += @{ op = 'add'; path = '/fields/Microsoft.VSTS.Common.AcceptanceCriteria'; value = [string]$p.acceptanceCriteria } }
  if ($p.areaPath) { $patch += @{ op = 'add'; path = '/fields/System.AreaPath'; value = [string]$p.areaPath } }
  if ($p.iterationPath) { $patch += @{ op = 'add'; path = '/fields/System.IterationPath'; value = [string]$p.iterationPath } }
  if ($p.tags) { $patch += @{ op = 'add'; path = '/fields/System.Tags'; value = ([string[]]$p.tags -join '; ') } }
  if ($p.fields) {
    foreach ($prop in $p.fields.PSObject.Properties) {
      if ($null -ne $prop.Value) {
        $patch += @{ op = 'add'; path = ("/fields/" + $prop.Name); value = $prop.Value }
      }
    }
  }
  return $patch
}

$intent = Read-Intent $IntentPath
$p = if ($null -ne $intent) { $intent.params } else { @{} }
if ($Query) { $p.query = $Query }
if ($WorkItemType) { $p.workItemType = $WorkItemType }
if ($OutPath) { $p.outPath = $OutPath }
$correlationId = $intent?.correlationId ?? $p?.correlationId
$now = (Get-Date).ToUniversalTime().ToString('o')

$now = (Get-Date).ToUniversalTime().ToString('o')

# --- GEDI OODA INTEGRATION ---
function Invoke-GediCheck($context, $intent) {
    if (-not (Test-Path "scripts/agent-gedi.ps1")) { return }
    if ($Action -match 'get|list|history|prefetch') { return } # Skip read-only actions to reduce noise
    
    Write-Host "`n🧭 GEDI Consultation (Agile Wisdom)..." -ForegroundColor Cyan
    try {
        $gediJson = & pwsh scripts/agent-gedi.ps1 -Context $context -Intent $intent -DryRun:$true | ConvertFrom-Json
    } catch {
        Write-Warning "GEDI is silent (Error contacting GEDI)."
    }
}

Invoke-GediCheck -context "ScrumMaster performing '$Action' on ADO project '$($p.ado?.project)'" -intent "Modify Project State"
# -----------------------------

switch ($Action) {
  'ado:bestpractice.prefetch' {
    # ... invariato ...
  }

  'ado:bootstrap' {
    # ... invariato ...
  }

  'ado:userstory.create' {
    # ... invariato ...
  }

  'ado:userstory.export' {
    # Discovery connection
    $orgUrl = $p.ado?.org
    $project = $p.ado?.project
    $pat = $p.ado?.pat
    
    if (-not $orgUrl -or -not $project -or -not $pat) {
      $configDir = Join-Path (Split-Path $PSScriptRoot -Parent) '../config'
      $connPath = Join-Path $configDir 'connections.json'; $secPath = Join-Path $configDir 'secrets.json'
      if (Test-Path $connPath) {
        $conns = (Get-Content $connPath -Raw | ConvertFrom-Json); $connDict = if ($conns.connections) { $conns.connections } else { $conns }
        foreach ($key in $connDict.PSObject.Properties.Name) { if ($connDict.$key.type -eq 'ado') { if (-not $orgUrl) { $orgUrl = $connDict.$key.org }; if (-not $project) { $project = $connDict.$key.project }; break } }
      }
      if (Test-Path $secPath) {
        $secs = (Get-Content $secPath -Raw | ConvertFrom-Json); $secDict = if ($secs.secrets) { $secs.secrets } else { $secs }
        foreach ($key in $secDict.PSObject.Properties.Name) { if ($secDict.$key.pat -and -not $pat) { $pat = $secDict.$key.pat; break } }
      }
      if (-not $pat) { $pat = $env:ADO_PAT }
    }
    if (-not $orgUrl) { throw 'ADO org URL missing' }
    if (-not $pat) { throw 'ADO PAT missing' }
    if (-not $project) { throw 'ADO Project missing' }

    $headers = Get-AdoAuthHeader $pat
    $apiVersion = '7.0'

    $wiql = if ($p.query) { $p.query } elseif ($Query) { $Query } else { 
      # Default Broad Query to trigger Guardrail/Suggestions 
      "SELECT [System.Id], [System.Title], [System.State] FROM WorkItems WHERE [System.TeamProject] = @project AND [System.WorkItemType] = '$($WorkItemType ?? 'Product Backlog Item')'" 
    }
    $wiql = $wiql -replace "@project", "'$project'"

    # --- GUARDRAIL REMOVED ---
    # Logic moved to agent-ado-governance.ps1 (Decision Layer)
    # Scrum Master is now a pure executor.
    # -------------------------
    # -------------------------------------


    try {
      $items = Get-WorkItemsByQuery $orgUrl $project $wiql $headers $apiVersion
        
      $export = $items | ForEach-Object {
        [ordered]@{
          id    = $_.id
          title = $_.fields.'System.Title'
          state = $_.fields.'System.State'
          tags  = $_.fields.'System.Tags'
        }
      }
        
      $result = [ordered]@{
        action = 'ado:userstory.export'
        ok     = $true
        count  = $items.Count
        items  = $export
      }
        
      if ($Print) {
        # Pretty print for simple usage
        $export | Format-Table -AutoSize | Out-String | Write-Host
      }
      else {
        Out-Result $result
      }
    }
    catch {
      $result = [ordered]@{ ok = $false; error = $_.Exception.Message }
      Out-Result $result
    }
  }

  'ado:pbi.children' {
    $workItemId = if ($Id) { $Id } elseif ($p.id) { $p.id } else { throw 'ID is required' }
    
    # Discovery connection
    $orgUrl = $p.ado?.org
    $project = $p.ado?.project
    $pat = $p.ado?.pat
    
    # (Fallback logic shared with get-pbi - ideally factored out, but duplicated for safety here)
    if (-not $orgUrl -or -not $project -or -not $pat) {
      $configDir = Join-Path (Split-Path $PSScriptRoot -Parent) '../config'
      $connPath = Join-Path $configDir 'connections.json'; $secPath = Join-Path $configDir 'secrets.json'
      if (Test-Path $connPath) {
        $conns = (Get-Content $connPath -Raw | ConvertFrom-Json); $connDict = if ($conns.connections) { $conns.connections } else { $conns }
        foreach ($key in $connDict.PSObject.Properties.Name) { if ($connDict.$key.type -eq 'ado') { if (-not $orgUrl) { $orgUrl = $connDict.$key.org }; if (-not $project) { $project = $connDict.$key.project }; break } }
      }
      if (Test-Path $secPath) {
        $secs = (Get-Content $secPath -Raw | ConvertFrom-Json); $secDict = if ($secs.secrets) { $secs.secrets } else { $secs }
        foreach ($key in $secDict.PSObject.Properties.Name) { if ($secDict.$key.pat -and -not $pat) { $pat = $secDict.$key.pat; break } }
      }
      if (-not $pat) { $pat = $env:ADO_PAT }
    }
    if (-not $orgUrl) { throw 'ADO org URL missing' }
    if (-not $pat) { throw 'ADO PAT missing' }

    $headers = Get-AdoAuthHeader $pat
    $apiVersion = '7.0'
    $url = "$orgUrl/_apis/wit/workitems/$workItemId`?`$expand=relations&api-version=$apiVersion"
    
    try {
      $wi = Invoke-RestMethod -Uri $url -Headers $headers -Method Get
      $childrenIds = @()
      if ($wi.relations) {
        foreach ($rel in $wi.relations) {
          if ($rel.rel -eq 'System.LinkTypes.Hierarchy-Forward') {
            $childrenIds += $rel.url.Split('/')[-1]
          }
        }
      }

      $childrenItems = @()
      if ($childrenIds.Count -gt 0) {
        $idsStr = $childrenIds -join ','
        $getUrl = "$orgUrl/_apis/wit/workitems?ids=$idsStr&api-version=$apiVersion"
        $batch = Invoke-RestMethod -Method Get -Uri $getUrl -Headers $headers
        $childrenItems = $batch.value | ForEach-Object {
          [ordered]@{
            id         = $_.id
            title      = $_.fields.'System.Title'
            type       = $_.fields.'System.WorkItemType'
            state      = $_.fields.'System.State'
            assignedTo = $_.fields.'System.AssignedTo'.displayName
            url        = $_.url
          }
        }
      }
        
      $result = [ordered]@{
        action   = 'ado:pbi.children'
        ok       = $true
        parentId = $workItemId
        count    = $childrenItems.Count
        children = $childrenItems
      }
    }
    catch {
      $result = [ordered]@{ ok = $false; error = $_.Exception.Message }
    }
    Out-Result $result
  }

  'ado:pbi.get' {
    # Query single PBI by ID and display on screen with full relations
    $workItemId = if ($Id) { $Id } elseif ($p.id) { $p.id } else { throw 'ID is required. Use -Id parameter or params.id' }
    
    # Auto-discover ADO connection
    $orgUrl = $p.ado?.org
    $project = $p.ado?.project
    $pat = $p.ado?.pat
    
    if (-not $orgUrl -or -not $project -or -not $pat) {
      $configDir = Join-Path (Split-Path $PSScriptRoot -Parent) '../config'
      $connPath = Join-Path $configDir 'connections.json'
      $secPath = Join-Path $configDir 'secrets.json'
      
      if (Test-Path $connPath) {
        $conns = (Get-Content $connPath -Raw | ConvertFrom-Json)
        $connDict = if ($conns.connections) { $conns.connections } else { $conns }
        foreach ($key in $connDict.PSObject.Properties.Name) {
          $c = $connDict.$key
          if ($c.type -eq 'ado') {
            if (-not $orgUrl) { $orgUrl = $c.org }
            if (-not $project) { $project = $c.project }
            break
          }
        }
      }
      if (Test-Path $secPath) {
        $secs = (Get-Content $secPath -Raw | ConvertFrom-Json)
        $secDict = if ($secs.secrets) { $secs.secrets } else { $secs }
        foreach ($key in $secDict.PSObject.Properties.Name) {
          $s = $secDict.$key
          if ($s.pat -and -not $pat) { $pat = $s.pat; break }
        }
      }
      if (-not $pat) { $pat = $env:ADO_PAT }
    }
    
    if (-not $orgUrl) { throw 'ADO org URL missing' }
    if (-not $pat) { throw 'ADO PAT missing' }
    
    $headers = Get-AdoAuthHeader $pat
    $apiVersion = '7.0'
    $url = "$orgUrl/_apis/wit/workitems/$workItemId`?`$expand=all&api-version=$apiVersion"
    
    Write-Host "`n========== PBI #$workItemId ==========`n" -ForegroundColor Cyan
    
    try {
      $wi = Invoke-RestMethod -Uri $url -Headers $headers -Method Get
      $f = $wi.fields
      
      # Core info
      Write-Host "ID:          " -NoNewline; Write-Host "$($f.'System.Id')" -ForegroundColor Yellow
      Write-Host "Title:       " -NoNewline; Write-Host "$($f.'System.Title')" -ForegroundColor White
      Write-Host "Type:        $($f.'System.WorkItemType')"
      Write-Host "State:       " -NoNewline
      $stateColor = switch ($f.'System.State') { 'Done' { 'Green' } 'In Progress' { 'Yellow' } 'New' { 'Cyan' } default { 'White' } }
      Write-Host "$($f.'System.State')" -ForegroundColor $stateColor
      Write-Host "Priority:    $($f.'Microsoft.VSTS.Common.Priority')"
      Write-Host "Assigned:    $($f.'System.AssignedTo'.displayName)"
      Write-Host "Area:        $($f.'System.AreaPath')"
      Write-Host "Iteration:   $($f.'System.IterationPath')"
      Write-Host "Tags:        $($f.'System.Tags')"
      Write-Host "Created:     $($f.'System.CreatedDate') by $($f.'System.CreatedBy'.displayName)"
      Write-Host "Changed:     $($f.'System.ChangedDate') by $($f.'System.ChangedBy'.displayName)"
      
      # Parse relations
      $parentIds = @()
      $childrenIds = @()
      $testCaseIds = @()
      $buildLinks = @()
      $releaseLinks = @()
      
      if ($wi.relations) {
        foreach ($rel in $wi.relations) {
          switch ($rel.rel) {
            'System.LinkTypes.Hierarchy-Reverse' {
              # Parent
              $parentId = $rel.url.Split('/')[-1]
              $parentIds += $parentId
            }
            'System.LinkTypes.Hierarchy-Forward' {
              # Children
              $childId = $rel.url.Split('/')[-1]
              $childrenIds += $childId
            }
            'Microsoft.VSTS.Common.TestedBy-Forward' {
              # Test Cases
              $tcId = $rel.url.Split('/')[-1]
              $testCaseIds += $tcId
            }
            'ArtifactLink' {
              # Build/Release links
              if ($rel.url -match 'vstfs:///Build/Build') {
                $buildLinks += $rel.url
              }
              elseif ($rel.url -match 'vstfs:///ReleaseManagement') {
                $releaseLinks += $rel.url
              }
            }
          }
        }
      }
      
      # Fetch and display Parent
      if ($parentIds.Count -gt 0) {
        Write-Host "`nParent:" -ForegroundColor Magenta
        $idsStr = $parentIds -join ','
        $getUrl = "$orgUrl/_apis/wit/workitems?ids=$idsStr&api-version=$apiVersion"
        $parents = Invoke-RestMethod -Method Get -Uri $getUrl -Headers $headers
        foreach ($p in $parents.value) {
          $pf = $p.fields
          Write-Host "  #$($pf.'System.Id') " -NoNewline -ForegroundColor Yellow
          Write-Host "($($pf.'System.WorkItemType')) - " -NoNewline -ForegroundColor Gray
          Write-Host "$($pf.'System.Title')"
        }
      }
      
      # Fetch and display Children
      if ($childrenIds.Count -gt 0) {
        Write-Host "`nChildren:" -ForegroundColor Magenta
        $idsStr = $childrenIds -join ','
        $getUrl = "$orgUrl/_apis/wit/workitems?ids=$idsStr&api-version=$apiVersion"
        $children = Invoke-RestMethod -Method Get -Uri $getUrl -Headers $headers
        foreach ($c in $children.value) {
          $cf = $c.fields
          $cStateColor = switch ($cf.'System.State') { 'Done' { 'Green' } 'In Progress' { 'Yellow' } 'New' { 'Cyan' } default { 'White' } }
          Write-Host "  #$($cf.'System.Id') " -NoNewline -ForegroundColor Yellow
          Write-Host "($($cf.'System.WorkItemType')) " -NoNewline -ForegroundColor Gray
          Write-Host "[$($cf.'System.State')] " -NoNewline -ForegroundColor $cStateColor
          Write-Host "$($cf.'System.Title')"
        }
      }
      
      # Fetch and display Test Cases
      if ($testCaseIds.Count -gt 0) {
        Write-Host "`nTest Cases:" -ForegroundColor Magenta
        $idsStr = $testCaseIds -join ','
        $getUrl = "$orgUrl/_apis/wit/workitems?ids=$idsStr&api-version=$apiVersion"
        $testCases = Invoke-RestMethod -Method Get -Uri $getUrl -Headers $headers
        foreach ($tc in $testCases.value) {
          $tcf = $tc.fields
          Write-Host "  #$($tcf.'System.Id') " -NoNewline -ForegroundColor Yellow
          Write-Host "(Test Case) " -NoNewline -ForegroundColor Gray
          Write-Host "$($tcf.'System.Title')"
        }
      }
      
      # Display Build/Release links (artifact links - just show count for now)
      if ($buildLinks.Count -gt 0 -or $releaseLinks.Count -gt 0) {
        Write-Host "`nDeployments:" -ForegroundColor Magenta
        if ($buildLinks.Count -gt 0) {
          Write-Host "  Builds: $($buildLinks.Count) linked" -ForegroundColor Gray
        }
        if ($releaseLinks.Count -gt 0) {
          Write-Host "  Releases: $($releaseLinks.Count) linked" -ForegroundColor Gray
        }
      }

      # Show all related (raw, for debug)
      if ($wi.relations) {
        Write-Host "`nAll Related:" -ForegroundColor Magenta
        foreach ($rel in $wi.relations) {
          Write-Host " - $($rel.rel): $($rel.url)"
        }
      }
      
      # Show description/criteria
      if ($f.'Microsoft.VSTS.Common.AcceptanceCriteria') {
        Write-Host "`nAcceptance Criteria:" -ForegroundColor Magenta
        $ac = $f.'Microsoft.VSTS.Common.AcceptanceCriteria' -replace '<[^>]+>', '' -replace '&nbsp;', ' '
        Write-Host $ac
      }
      
      if ($f.'System.Description') {
        Write-Host "`nDescription:" -ForegroundColor Magenta
        $desc = $f.'System.Description' -replace '<[^>]+>', '' -replace '&nbsp;', ' '
        Write-Host ($desc.Substring(0, [Math]::Min(500, $desc.Length))) 
        if ($desc.Length -gt 500) { Write-Host "..." }
      }
      
      Write-Host "`n========================================`n" -ForegroundColor Cyan
      
      $result = [ordered]@{
        action = $Action
        ok     = $true
        output = [ordered]@{
          id        = $workItemId
          title     = $f.'System.Title'
          state     = $f.'System.State'
          type      = $f.'System.WorkItemType'
          parent    = $parentIds
          children  = $childrenIds
          testCases = $testCaseIds
        }
        error  = $null
      }
    }
    catch {
      Write-Host "Error: $_" -ForegroundColor Red
      $result = [ordered]@{
        action = $Action
        ok     = $false
        output = @{}
        error  = $_.Exception.Message
      }
    }
    
    Out-Result $result
  }

  'ado:pipeline.get-runs' {
    # ... invariato ...
  }

  'ado:testcase.create' {
    # ... invariato ...
  }

  'ado:pipeline.list' {
    # ... invariato ...
  }

  'ado:pipeline.history' {
    # ... invariato ...
  }
}
