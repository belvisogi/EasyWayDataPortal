Param(
  [ValidateSet('api-error:triage')]
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
  ($obj | ConvertTo-Json -Depth 8) | Out-File -FilePath $logPath -Append -Encoding utf8
  return $logPath
}

function Redact-Headers($headers) {
  if (-not $headers) { return $null }
  $blocked = @('authorization','cookie','x-api-key')
  $out = [ordered]@{}
  foreach ($k in $headers.PSObject.Properties.Name) {
    $v = $headers.$k
    if ($blocked -contains ($k.ToLower())) {
      $out[$k] = '[redacted]'
    } else {
      $out[$k] = $v
    }
  }
  return $out
}

function Get-Status($response) {
  if (-not $response) { return $null }
  if ($null -ne $response.status) { return [int]$response.status }
  if ($null -ne $response.statusCode) { return [int]$response.statusCode }
  if ($null -ne $response.code) {
    $parsed = $response.code -as [int]
    if ($parsed -ne $null) { return $parsed }
  }
  return $null
}

function Classify-Error($status, $errorCode, $message) {
  if ($status -eq 429) { return 'rate_limited' }
  if ($status -ge 500) { return 'server_error' }
  if ($status -eq 401 -or $status -eq 403) { return 'auth_error' }
  if ($status -eq 404) { return 'not_found' }
  if ($status -ge 400) { return 'client_error' }
  if ($message -match 'ECONN|ETIMEDOUT|ENOTFOUND|EAI_AGAIN') { return 'network_error' }
  if ($errorCode -match 'ECONN|ETIMEDOUT|ENOTFOUND|EAI_AGAIN') { return 'network_error' }
  if ($status -eq $null) { return 'unknown' }
  return 'none'
}

function Severity-FromClass($class) {
  switch ($class) {
    'server_error' { return 'high' }
    'rate_limited' { return 'medium' }
    'auth_error' { return 'medium' }
    'client_error' { return 'medium' }
    'network_error' { return 'medium' }
    'not_found' { return 'low' }
    default { return 'low' }
  }
}

function Actions-FromClass($class) {
  switch ($class) {
    'server_error' { return @('Verificare log server', 'Aprire issue con correlationId', 'Valutare rollback o feature flag') }
    'rate_limited' { return @('Impostare retry con backoff', 'Ridurre concorrenza in n8n', 'Valutare quota/limiti API') }
    'auth_error' { return @('Verificare token/scopes', 'Controllare config MSAL/authority', 'Rigenerare credenziali se necessario') }
    'client_error' { return @('Validare payload e schema', 'Controllare parametri obbligatori', 'Allineare versioni endpoint') }
    'network_error' { return @('Verificare DNS/firewall', 'Retry con backoff', 'Controllare proxy o VPN') }
    'not_found' { return @('Verificare route/versione', 'Controllare base URL e path', 'Aggiornare docs se deprecato') }
    default { return @('Verificare log client', 'Aprire issue con dettagli') }
  }
}

function Retryable-FromClass($class) {
  return @('server_error','rate_limited','network_error') -contains $class
}

function New-DiaryEntry($stage, $outcome, $reason, $next, $decisionTraceId, $artifacts) {
  return [ordered]@{
    timestamp = (Get-Date).ToUniversalTime().ToString('o')
    stage = $stage
    outcome = $outcome
    reason = $reason
    next = $next
    decision_trace_id = $decisionTraceId
    artifacts = $artifacts
  }
}

$intent = Read-Intent $IntentPath
$now = (Get-Date).ToUniversalTime().ToString('o')

switch ($Action) {
  'api-error:triage' {
    $p = $intent?.params
    $errors = @()
    $diary = @()

    $decisionTraceId = $intent?.decision_trace_id
    if (-not $decisionTraceId) { $decisionTraceId = $p?.decision_trace_id }
    $correlationId = $intent?.correlationId
    if (-not $correlationId) { $correlationId = $p?.correlationId }

    $diary += New-DiaryEntry -stage 'received' -outcome 'ok' -reason 'intent received' -next 'validate' -decisionTraceId $decisionTraceId -artifacts @()

    $method = $p?.request?.method
    $url = $p?.request?.url
    $service = $p?.service
    $environment = $p?.environment

    if (-not $method) { $errors += 'request.method missing' }
    elseif ($method -notmatch '^(GET|POST|PUT|PATCH|DELETE|HEAD|OPTIONS)$') { $errors += 'request.method invalid' }
    if (-not $url) { $errors += 'request.url missing' }
    if (-not $service) { $errors += 'service missing' }
    if (-not $environment) { $errors += 'environment missing' }

    if ($errors.Count -gt 0) {
      $diary += New-DiaryEntry -stage 'validated' -outcome 'error' -reason ($errors -join '; ') -next 'fix input' -decisionTraceId $decisionTraceId -artifacts @()
    } else {
      $diary += New-DiaryEntry -stage 'validated' -outcome 'ok' -reason 'input valid' -next 'triage' -decisionTraceId $decisionTraceId -artifacts @()
    }

    $status = Get-Status $p?.response
    $errorCode = $p?.error?.code
    $errorMessage = $p?.error?.message
    $errorClass = Classify-Error -status $status -errorCode $errorCode -message $errorMessage
    $severity = Severity-FromClass $errorClass
    $retryable = Retryable-FromClass $errorClass
    $actions = Actions-FromClass $errorClass

    $diary += New-DiaryEntry -stage 'triaged' -outcome 'ok' -reason ("class=" + $errorClass) -next 'log' -decisionTraceId $decisionTraceId -artifacts @()

    $normalizedEvent = [ordered]@{
      source = $p?.source
      service = $service
      environment = $environment
      request = [ordered]@{
        method = $method
        url = $url
        headers = (Redact-Headers $p?.request?.headers)
      }
      response = [ordered]@{
        status = $status
        duration_ms = $p?.response?.duration_ms
      }
      error = [ordered]@{
        code = $errorCode
        message = $errorMessage
      }
      correlationId = $correlationId
      decision_trace_id = $decisionTraceId
      classified_as = $errorClass
      severity = $severity
      retryable = $retryable
    }

    $logPath = $null
    if ($LogEvent) {
      $eventObj = [ordered]@{
        event = 'agent-api'
        action = $Action
        ok = ($errors.Count -eq 0)
        correlationId = $correlationId
        startedAt = $now
        finishedAt = (Get-Date).ToUniversalTime().ToString('o')
        diary = $diary
        output = [ordered]@{
          errorClass = $errorClass
          severity = $severity
          retryable = $retryable
          recommendedActions = $actions
          normalizedEvent = $normalizedEvent
        }
      }
      $logPath = Write-Event $eventObj
    }

    $diary += New-DiaryEntry -stage 'logged' -outcome 'ok' -reason 'event stored' -next 'complete' -decisionTraceId $decisionTraceId -artifacts @($logPath)
    $diary += New-DiaryEntry -stage 'completed' -outcome 'ok' -reason 'triage done' -next 'n8n next step' -decisionTraceId $decisionTraceId -artifacts @($logPath)

    $result = [ordered]@{
      action = $Action
      ok = ($errors.Count -eq 0)
      whatIf = [bool]$WhatIf
      nonInteractive = [bool]$NonInteractive
      correlationId = $correlationId
      startedAt = $now
      finishedAt = (Get-Date).ToUniversalTime().ToString('o')
      output = [ordered]@{
        errorClass = $errorClass
        severity = $severity
        retryable = $retryable
        recommendedActions = $actions
        kbRefs = @('Wiki/EasyWayData.wiki/api/rest-errors-qna.md')
        normalizedEvent = $normalizedEvent
        diary = $diary
        logPath = $logPath
      }
      error = if ($errors.Count -gt 0) { $errors -join '; ' } else { $null }
    }
    $result.contractId = 'action-result'
    $result.contractVersion = '1.0'
    $result | ConvertTo-Json -Depth 8 | Write-Output
  }
}
