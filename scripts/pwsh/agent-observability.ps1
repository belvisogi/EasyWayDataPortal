Param(
  [ValidateSet('obs:healthcheck', 'obs:check-logs')]
  [string]$Action,
  [string]$IntentPath,
  [switch]$NonInteractive,
  [switch]$WhatIf,
  [switch]$LogEvent,
  [switch]$AutoFix
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
  ($obj | ConvertTo-Json -Depth 10) | Out-File -FilePath $logPath -Append -Encoding utf8
  return $logPath
}

function Out-Result($obj) { $obj | ConvertTo-Json -Depth 10 | Write-Output }

$intent = Read-Intent $IntentPath
$p = $intent.params
$now = (Get-Date).ToUniversalTime().ToString('o')

switch ($Action) {
  'obs:healthcheck' {
    $paths = @()
    if ($p.paths) { $paths = @($p.paths) } else { $paths = @('agents/logs/events.jsonl', 'Wiki/EasyWayData.wiki/chunks_master.jsonl') }
    $checks = @()
    foreach ($pp in $paths) {
      $exists = Test-Path $pp
      $checks += [ordered]@{ path = $pp; exists = [bool]$exists }
    }
    $result = [ordered]@{
      action = $Action; ok = $true; whatIf = [bool]$WhatIf; nonInteractive = [bool]$NonInteractive;
      correlationId = ($intent?.correlationId ?? $p?.correlationId); startedAt = $now; finishedAt = (Get-Date).ToUniversalTime().ToString('o');
      output = [ordered]@{ checks = $checks; hint = 'Healthcheck locale file-based; per runtime aggiungere endpoint/metrics.' }
    }
    $result.contractId = 'action-result'; $result.contractVersion = '1.0'
    if ($LogEvent) { $null = Write-Event ($result + @{ event = 'agent-observability'; govApproved = $false }) }
    Out-Result $result
  }

  'obs:check-logs' {
    $hours = if ($p.hours) { [double]$p.hours } else { 1 }
    $cutoff = (Get-Date).ToUniversalTime().AddHours(-$hours)
    
    $logFiles = @(
      'portal-api/logs/business.log.json',
      'portal-api/logs/error.log.json'
    )
    if ($p.logFiles) { $logFiles = $p.logFiles }
    
    $errorsFound = @()
    $analyzedCount = 0
    
    foreach ($file in $logFiles) {
      if (Test-Path $file) {
        # Read last 1000 lines to avoid reading massive files
        $lines = Get-Content $file -Tail 1000 -ErrorAction SilentlyContinue
        foreach ($line in $lines) {
          try {
            if ([string]::IsNullOrWhiteSpace($line)) { continue }
            $entry = $line | ConvertFrom-Json
            if ($entry.timestamp) {
              $ts = $null
              if ($entry.timestamp -is [DateTime]) {
                $ts = $entry.timestamp
              }
              else {
                $ts = [DateTime]::Parse($entry.timestamp, $null, 'RoundtripKind')
              }
              
              if ($ts.ToUniversalTime() -ge $cutoff) {
                $analyzedCount++
                if ($entry.level -match 'error|warn') {
                  $errorsFound += $entry
                }
              }
            }
          }
          catch { }
        }
      }
    }
    
    $topErrors = $errorsFound | Group-Object message | Sort-Object Count -Descending | Select-Object -First 5
    
    $analysis = $null
    if ($p.analyze -and $errorsFound.Count -gt 0) {
      Write-Host "Analyzing errors with LLM..."
      
      # Load Redaction Skill
      $redactScript = Join-Path $PSScriptRoot "Redact-Log.ps1"
      if (Test-Path $redactScript) { . $redactScript }
      else { function Redact-SensitiveData($t) { return $t } }
      
      $skillPath = Join-Path $PSScriptRoot "../../agents/skills/retrieval/Invoke-LLMWithRAG.ps1"
      if ($p.skillPath) { $skillPath = $p.skillPath }
      
      if (Test-Path $skillPath) {
        . $skillPath
            
        $errorSummary = $topErrors | ForEach-Object { "- ($($_.Count)x) $($_.Name)" } | Out-String
        
        # Redact before sending to LLM
        $redactedSummary = Redact-SensitiveData -InputText $errorSummary
        
        $promptInfo = "Analyze these application errors found in the last $hours hours:\n$redactedSummary\nSuggest root cause and potential fixes based on the project context."
        $promptInstruction = "If you are 100% confident in a code fix, provide the response in JSON format: { ""analysis"": ""..."", ""fixable"": true, ""fix"": { ""filePath"": ""path/to/file"", ""newContent"": ""full content"" } } OR { ""analysis"": ""..."", ""fixable"": true, ""fix"": { ""filePath"": ""path/to/file"", ""search"": ""exact string to replace"", ""replace"": ""replacement string"" } }. If not fixable, just return text analysis."

        $prompt = "$promptInfo\n\n$promptInstruction"
            
        $llmResult = Invoke-LLMWithRAG -Query $prompt -AgentId "agent_observability" -SystemPrompt "You are an SRE assistant."
        if ($llmResult.Success) {
          $output = $llmResult.Answer
          
          # Try parse JSON
          $fixData = $null
          try { 
            $cleanJson = $output -replace '^```json\s*', '' -replace '\s*```$', ''
            $parsed = $cleanJson | ConvertFrom-Json 
            if ($parsed.analysis) { $analysis = $parsed.analysis } else { $analysis = $output }
            
            if ($parsed.fixable -and $parsed.fix) {
              Write-Host "💡 Fix proposed by LLM: $($parsed.fix.filePath)" -ForegroundColor Yellow
              $fixData = $parsed.fix
            }
          }
          catch {
            $analysis = $output
          }
          
          # Auto-Fix Trigger
          if ($AutoFix -and $fixData) {
            Write-Host "🚀 Auto-Fix Enabled: Triggering Agent Developer..." -ForegroundColor Cyan
            $devScript = Join-Path $PSScriptRoot "agent-developer.ps1"
            & $devScript -Action "dev:implement-fix" -FixData ($fixData | ConvertTo-Json -Depth 10) -PBI "AUTOFIX" -Desc "sre-repair"
            $analysis += "`n`n✅ AUTO-FIX INITIATED: PR Created."
          }
        }
        else {
          $analysis = "LLM Analysis Failed: $($llmResult.Error)"
        }
      }
      else {
        $analysis = "Skill not found: $skillPath"
      }
    }
    
    $result = [ordered]@{
      action = $Action; ok = $true;
      output = [ordered]@{ 
        windowHours     = $hours; 
        analyzedEntries = $analyzedCount; 
        errorCount      = $errorsFound.Count; 
        topErrors       = $topErrors;
        analysis        = $analysis
      }
    }
    Out-Result $result
  }
}
