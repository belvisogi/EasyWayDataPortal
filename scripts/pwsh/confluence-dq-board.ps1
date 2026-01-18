param(
  [string]$IntentPath = "scripts/intents/docs-dq-confluence-cloud-001.json",
  [string]$OutDir = "",
  [switch]$Export,
  [switch]$PlanOnly,
  [switch]$UpdateBoard,
  [switch]$NonInteractive,
  [switch]$WhatIf,
  [switch]$FailOnError
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Ensure-Dir([string]$p) {
  if ([string]::IsNullOrWhiteSpace($p)) { return }
  New-Item -ItemType Directory -Force -Path $p | Out-Null
}

function Read-Json([string]$p) {
  if (-not (Test-Path -LiteralPath $p)) { throw "Intent not found: $p" }
  return (Get-Content -LiteralPath $p -Raw | ConvertFrom-Json)
}

function Get-EnvOrThrow([string]$name) {
  $v = [Environment]::GetEnvironmentVariable($name)
  if ([string]::IsNullOrWhiteSpace($v)) { throw "Missing env var: $name" }
  return $v
}

function New-BasicAuthHeader([string]$email, [string]$token) {
  $bytes = [System.Text.Encoding]::UTF8.GetBytes("$email`:$token")
  $b64 = [Convert]::ToBase64String($bytes)
  return @{ Authorization = "Basic $b64"; Accept = "application/json" }
}

function Invoke-Conf {
  param(
    [string]$Method,
    [string]$Url,
    [hashtable]$Headers,
    [object]$Body = $null
  )
  $params = @{
    Method = $Method
    Uri = $Url
    Headers = $Headers
    ErrorAction = 'Stop'
  }
  if ($null -ne $Body) {
    $params.ContentType = 'application/json'
    $params.Body = ($Body | ConvertTo-Json -Depth 10)
  }
  return Invoke-RestMethod @params
}

function Update-AutoSection {
  param(
    [string]$Text,
    [string]$AutoContent,
    [string]$StartMarker,
    [string]$EndMarker
  )
  if ($null -eq $Text) { $Text = '' }
  $start = $Text.IndexOf($StartMarker, [System.StringComparison]::Ordinal)
  $end = $Text.IndexOf($EndMarker, [System.StringComparison]::Ordinal)
  if ($start -lt 0 -or $end -lt 0 -or $end -lt $start) {
    return ($Text.TrimEnd() + "`n`n$StartMarker`n$AutoContent`n$EndMarker`n")
  }
  $before = $Text.Substring(0, $start + $StartMarker.Length)
  $after = $Text.Substring($end)
  return ($before + "`n" + $AutoContent + "`n" + $after)
}

function Build-KanbanHtml {
  param(
    [object]$Backlog,
    [string]$StartMarker,
    [string]$EndMarker
  )
  $today = (Get-Date).ToString('yyyy-MM-dd')
  $items = @($Backlog.cards | Select-Object -First 60 | ForEach-Object {
    $sev = [string]$_.severity
    $title = [System.Web.HttpUtility]::HtmlEncode([string]$_.title)
    "<li>[$sev] $title</li>"
  })
  $auto = @(
    "<h2>Snapshot DQ (auto) - $today</h2>",
    "<p>Generato da <code>scripts/confluence-dq-board.ps1</code>.</p>",
    "<h3>Backlog</h3>",
    "<ul>",
    ($items -join "`n"),
    "</ul>"
  ) -join "`n"

  $html = @(
    "<h1>Docs DQ Kanban</h1>",
    "<p>Board dedicata: Backlog / Next / Doing / Done.</p>",
    $StartMarker,
    $auto,
    $EndMarker,
    "<h2>Next</h2><ul></ul>",
    "<h2>Doing</h2><ul></ul>",
    "<h2>Done</h2><ul></ul>"
  ) -join "`n"
  return $html
}

$intent = Read-Json $IntentPath
$conf = $intent.confluence
if ($null -eq $conf) { throw "Invalid intent: missing confluence object in $IntentPath" }

$baseUrl = [string]$conf.baseUrl
$spaceKey = [string]$conf.spaceKey
$boardTitle = [string]$conf.boardPage.title
$parentPageId = [string]$conf.boardPage.parentPageId
$boardPageId = [string]$conf.boardPage.pageId

$startMarker = [string]$intent.kanban.autoSectionMarkers.start
$endMarker = [string]$intent.kanban.autoSectionMarkers.end

$emailEnv = [string]$conf.auth.emailEnv
$tokenEnv = [string]$conf.auth.apiTokenEnv

$outDir = if ($OutDir) { $OutDir } else { [string]$intent.export.outDir }
if ([string]::IsNullOrWhiteSpace($outDir)) { $outDir = 'out/confluence' }
$outDir = $outDir.Replace([char]92,'/')

if (-not $Export -and -not $UpdateBoard) {
  if ($PlanOnly) { } else { $Export = $true }
}

$plan = [pscustomobject]@{
  ok = $true
  intent_id = $intent.intent_id
  actions = @(
    [pscustomobject]@{ id='export.pages'; enabled=[bool]$Export; what='Export lista pagine (metadata) dallo space'; out="$outDir/pages.jsonl" },
    [pscustomobject]@{ id='update.board'; enabled=[bool]$UpdateBoard; what='Crea/aggiorna pagina Kanban dedicata in Confluence'; whatIf=[bool]$WhatIf }
  )
  inputs = [pscustomobject]@{
    baseUrl = $baseUrl
    spaceKey = $spaceKey
    boardTitle = $boardTitle
    parentPageId = $parentPageId
    boardPageId = $boardPageId
    emailEnv = $emailEnv
    apiTokenEnv = $tokenEnv
  }
}

if ($PlanOnly) { Write-Output ($plan | ConvertTo-Json -Depth 6); return }

# NOTE: network operations require the caller environment to allow network access.
$email = Get-EnvOrThrow $emailEnv
$token = Get-EnvOrThrow $tokenEnv
$headers = New-BasicAuthHeader -email $email -token $token

Ensure-Dir $outDir

if ($Export) {
  $limit = [int]$intent.export.pageLimit
  if ($limit -lt 1) { $limit = 250 }

  # Confluence Cloud v1 API: list content by spaceKey (paged)
  $start = 0
  $all = New-Object System.Collections.Generic.List[object]
  while ($true) {
    $url = "$baseUrl/rest/api/content?spaceKey=$spaceKey&type=page&limit=$limit&start=$start&expand=metadata.labels,version"
    $resp = Invoke-Conf -Method 'GET' -Url $url -Headers $headers
    foreach ($p in @($resp.results)) {
      $all.Add([pscustomobject]@{
        id = [string]$p.id
        title = [string]$p.title
        url = "$baseUrl/pages/$($p.id)"
        updated = [string]$p.version.when
        labels = @($p.metadata.labels.results | ForEach-Object { $_.name })
      }) | Out-Null
    }
    if ($resp.size -lt $limit) { break }
    $start += $limit
  }

  $jsonl = @($all | ForEach-Object { $_ | ConvertTo-Json -Compress -Depth 6 }) -join "`n"
  Set-Content -LiteralPath (Join-Path $outDir 'pages.jsonl') -Value $jsonl -Encoding utf8
}

if ($UpdateBoard) {
  # Minimal: generate backlog from existing docs-dq-scorecard (if present) else empty.
  $backlogOut = Join-Path $outDir 'docs-dq-backlog.confluence.json'
  $backlog = if (Test-Path -LiteralPath $backlogOut) { Get-Content -LiteralPath $backlogOut -Raw | ConvertFrom-Json } else { [pscustomobject]@{ cards = @() } }

  $html = Build-KanbanHtml -Backlog $backlog -StartMarker $startMarker -EndMarker $endMarker

  if ($WhatIf) {
    Write-Output ([pscustomobject]@{ ok=$true; whatIf=$true; wouldUpdate=$true; boardTitle=$boardTitle; boardPageId=$boardPageId } | ConvertTo-Json -Depth 5)
    return
  }

  if ([string]::IsNullOrWhiteSpace($boardPageId)) {
    # Create new page
    $body = @{
      type = 'page'
      title = $boardTitle
      space = @{ key = $spaceKey }
      body = @{ storage = @{ value = $html; representation = 'storage' } }
    }
    if (-not [string]::IsNullOrWhiteSpace($parentPageId)) {
      $body.ancestors = @(@{ id = $parentPageId })
    }
    $created = Invoke-Conf -Method 'POST' -Url "$baseUrl/rest/api/content" -Headers $headers -Body $body
    Write-Output ([pscustomobject]@{ ok=$true; created=$true; pageId=[string]$created.id; url="$baseUrl/pages/$($created.id)" } | ConvertTo-Json -Depth 6)
    return
  }

  # Update existing page: read current to get version
  $current = Invoke-Conf -Method 'GET' -Url "$baseUrl/rest/api/content/$boardPageId?expand=body.storage,version" -Headers $headers
  $curHtml = [string]$current.body.storage.value
  $newHtml = Update-AutoSection -Text $curHtml -AutoContent $html -StartMarker $startMarker -EndMarker $endMarker
  $nextVer = [int]$current.version.number + 1

  $put = @{
    id = $boardPageId
    type = 'page'
    title = $current.title
    version = @{ number = $nextVer }
    body = @{ storage = @{ value = $newHtml; representation = 'storage' } }
  }
  $updated = Invoke-Conf -Method 'PUT' -Url "$baseUrl/rest/api/content/$boardPageId" -Headers $headers -Body $put
  Write-Output ([pscustomobject]@{ ok=$true; updated=$true; pageId=[string]$updated.id; url="$baseUrl/pages/$($updated.id)" } | ConvertTo-Json -Depth 6)
}

