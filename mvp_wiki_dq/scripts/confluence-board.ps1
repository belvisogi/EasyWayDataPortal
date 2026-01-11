param(
  [string]$IntentPath = "intents/confluence.params.json",
  [switch]$Export,
  [switch]$PlanOnly,
  [switch]$UpdateBoard,
  [switch]$WhatIf
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

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

function Invoke-Conf([string]$Method,[string]$Url,[hashtable]$Headers,[object]$Body=$null) {
  $params = @{ Method=$Method; Uri=$Url; Headers=$Headers; ErrorAction='Stop' }
  if ($null -ne $Body) { $params.ContentType='application/json'; $params.Body=($Body|ConvertTo-Json -Depth 10) }
  return Invoke-RestMethod @params
}

function Update-AutoSection([string]$Text,[string]$AutoContent,[string]$Start,[string]$End) {
  if ($null -eq $Text) { $Text = '' }
  $s = $Text.IndexOf($Start, [System.StringComparison]::Ordinal)
  $e = $Text.IndexOf($End, [System.StringComparison]::Ordinal)
  if ($s -lt 0 -or $e -lt 0 -or $e -lt $s) { return ($Text.TrimEnd()+"`n`n$Start`n$AutoContent`n$End`n") }
  return ($Text.Substring(0,$s+$Start.Length) + "`n" + $AutoContent + "`n" + $Text.Substring($e))
}

if (-not $Export -and -not $UpdateBoard) { if ($PlanOnly) { } else { $Export = $true } }

$i = Read-Json $IntentPath
$c = $i.confluence
$baseUrl = [string]$c.baseUrl
$spaceKey = [string]$c.spaceKey
$boardTitle = [string]$c.board.title
$parentPageId = [string]$c.board.parentPageId
$boardPageId = [string]$c.board.pageId
$emailEnv = [string]$c.auth.emailEnv
$tokenEnv = [string]$c.auth.apiTokenEnv
$outDir = [string]$i.export.outDir
$limit = [int]$i.export.pageLimit
$startMarker = [string]$i.markers.start
$endMarker = [string]$i.markers.end

$plan = [pscustomobject]@{
  ok = $true
  intent_id = $i.intent_id
  export = [bool]$Export
  updateBoard = [bool]$UpdateBoard
  whatIf = [bool]$WhatIf
  baseUrl = $baseUrl
  spaceKey = $spaceKey
  boardTitle = $boardTitle
  boardPageId = $boardPageId
  outDir = $outDir
}
if ($PlanOnly) { Write-Output ($plan | ConvertTo-Json -Depth 5); return }

$email = Get-EnvOrThrow $emailEnv
$token = Get-EnvOrThrow $tokenEnv
$headers = New-BasicAuthHeader -email $email -token $token
New-Item -ItemType Directory -Force -Path $outDir | Out-Null

if ($Export) {
  if ($limit -lt 1) { $limit = 250 }
  $start = 0
  $all = New-Object System.Collections.Generic.List[object]
  while ($true) {
    $url = "$baseUrl/rest/api/content?spaceKey=$spaceKey&type=page&limit=$limit&start=$start&expand=metadata.labels,version"
    $resp = Invoke-Conf -Method 'GET' -Url $url -Headers $headers
    foreach ($p in @($resp.results)) {
      $all.Add([pscustomobject]@{ id=[string]$p.id; title=[string]$p.title; updated=[string]$p.version.when; url="$baseUrl/pages/$($p.id)" }) | Out-Null
    }
    if ($resp.size -lt $limit) { break }
    $start += $limit
  }
  $jsonl = @($all | ForEach-Object { $_ | ConvertTo-Json -Compress -Depth 5 }) -join "`n"
  Set-Content -LiteralPath (Join-Path $outDir 'pages.jsonl') -Value $jsonl -Encoding utf8
}

if ($UpdateBoard) {
  $auto = "<h2>Snapshot DQ (auto)</h2><p>TODO: integrare backlog Confluence.</p>"
  $html = "<h1>Docs DQ Kanban</h1>`n$startMarker`n$auto`n$endMarker"
  if ($WhatIf) { Write-Output ([pscustomobject]@{ ok=$true; whatIf=$true; wouldUpdate=$true; boardTitle=$boardTitle } | ConvertTo-Json -Depth 4); return }

  if ([string]::IsNullOrWhiteSpace($boardPageId)) {
    $body = @{ type='page'; title=$boardTitle; space=@{ key=$spaceKey }; body=@{ storage=@{ value=$html; representation='storage' } } }
    if (-not [string]::IsNullOrWhiteSpace($parentPageId)) { $body.ancestors=@(@{ id=$parentPageId }) }
    $created = Invoke-Conf -Method 'POST' -Url "$baseUrl/rest/api/content" -Headers $headers -Body $body
    Write-Output ([pscustomobject]@{ ok=$true; created=$true; pageId=[string]$created.id; url="$baseUrl/pages/$($created.id)" } | ConvertTo-Json -Depth 5)
    return
  }

  $current = Invoke-Conf -Method 'GET' -Url "$baseUrl/rest/api/content/$boardPageId?expand=body.storage,version" -Headers $headers
  $curHtml = [string]$current.body.storage.value
  $newHtml = Update-AutoSection -Text $curHtml -AutoContent $auto -Start $startMarker -End $endMarker
  $nextVer = [int]$current.version.number + 1
  $put = @{ id=$boardPageId; type='page'; title=$current.title; version=@{ number=$nextVer }; body=@{ storage=@{ value=$newHtml; representation='storage' } } }
  $updated = Invoke-Conf -Method 'PUT' -Url "$baseUrl/rest/api/content/$boardPageId" -Headers $headers -Body $put
  Write-Output ([pscustomobject]@{ ok=$true; updated=$true; pageId=[string]$updated.id; url="$baseUrl/pages/$($updated.id)" } | ConvertTo-Json -Depth 5)
}

