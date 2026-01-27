<#
.SYNOPSIS
    EasyWay Master Agent Template (Portable Brain Standard)
.DESCRIPTION
    Standard template for all EasyWay Agents.
    Supports:
    - Provider Switching (Ollama / DeepSeek / OpenAI)
    - Intent-based Execution (n8n ready)
    - Direct Query Execution
    - Standardized Logging & Output
#>
[CmdletBinding()]
Param(
  # --- Standard Input ---
  [Parameter(Mandatory = $false)] [string]$Query,
  [Parameter(Mandatory = $false)] [string]$Action,
  [Parameter(Mandatory = $false)] [string]$IntentPath,

  # --- Portable Brain Config (The "Socket") ---
  [ValidateSet("Ollama", "DeepSeek", "OpenAI", "AzureOpenAI")]
  [string]$Provider = "Ollama",

  [string]$Model = "deepseek-r1:7b",
    
  [string]$ApiKey = $env:EASYWAY_LLM_KEY,
  [string]$ApiEndpoint = "https://api.deepseek.com/chat/completions",

  # --- Flags ---
  [switch]$NonInteractive,
  [switch]$WhatIf,
  [switch]$LogEvent = $true,
  [switch]$JsonOutput
)

$ErrorActionPreference = 'Stop'

# --- 1. HELPER FUNCTIONS ---

function Get-LLMResponse {
  param($Prompt, $SystemPrompt)

  Write-Verbose "🧠 Thinking with Provider: $Provider (Model: $Model)..."

  if ($Provider -eq "Ollama") {
    # --- OLLAMA ADAPTER ---
    $body = @{
      model  = $Model
      prompt = $Prompt
      stream = $false
    }
    if ($SystemPrompt) { $body["system"] = $SystemPrompt }
        
    try {
      $response = Invoke-RestMethod -Uri "http://localhost:11434/api/generate" -Method Post -Body ($body | ConvertTo-Json) -ContentType "application/json"
      return $response.response
    }
    catch { throw "Ollama Error: $($_.Exception.Message)" }
  }
  elseif ($Provider -in @("DeepSeek", "OpenAI")) {
    # --- OPENAI-COMPATIBLE ADAPTER ---
    if (-not $ApiKey) { throw "ApiKey required for $Provider" }

    $messages = @(
      @{ role = "user"; content = $Prompt }
    )
    if ($SystemPrompt) { $messages = @(@{ role = "system"; content = $SystemPrompt }) + $messages }

    $body = @{
      model       = $Model
      messages    = $messages
      temperature = 0.1
    }

    try {
      $response = Invoke-RestMethod -Uri $ApiEndpoint -Method Post -Headers @{Authorization = "Bearer $ApiKey" } -Body ($body | ConvertTo-Json -Depth 10) -ContentType "application/json" -TimeoutSec 120
      return $response.choices[0].message.content
    }
    catch { throw "API Error: $($_.Exception.Message) - $($_.ErrorDetails.Message)" }
  }
  else {
    throw "Provider '$Provider' not implemented."
  }
}

function Write-AgentLog {
  param($EventData)
  if (-not $LogEvent) { return }
    
  $logDir = Join-Path $PSScriptRoot "..\..\logs\agents"
  if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir -Force | Out-Null }
    
  $entry = [ordered]@{
    timestamp = (Get-Date).ToString("o")
    agent     = $MyInvocation.MyCommand.Name
    provider  = $Provider
    model     = $Model
    data      = $EventData
  }
  ($entry | ConvertTo-Json -Depth 5) | Out-File (Join-Path $logDir "agent-history.jsonl") -Append
}

# --- 2. INPUT NORMALIZATION ---

# Support n8n Intent inputs (JSON file)
$IntentData = $null
if ($IntentPath -and (Test-Path $IntentPath)) {
  $IntentData = Get-Content $IntentPath -Raw | ConvertFrom-Json
  if (-not $Query) { $Query = $IntentData.query }
  if (-not $Action) { $Action = $IntentData.action }
}

if (-not $Query -and -not $Action) {
  Write-Error "Either -Query or -Action (or Intent file) must be provided."
  exit 1
}

# --- 3. EXECUTION LOGIC ---

$AgentName = "TemplateAgent"
$Result = $null

try {
  # EXAMPLE: Simple Echo/LLM Logic
  if ($Action -eq "echo") {
    $Result = "Echo: $Query"
  }
  elseif ($Query) {
    # LLM Call
    $Result = Get-LLMResponse -Prompt $Query -SystemPrompt "You are an EasyWay Agent."
  }

  # --- 4. OUTPUT & LOGGING ---
    
  $Output = @{
    success  = $true
    agent    = $AgentName
    result   = $Result
    metadata = @{
      provider   = $Provider
      latency_ms = 0 # Todo: measure
    }
  }

  Write-AgentLog -EventData $Output

  if ($JsonOutput) {
    $Output | ConvertTo-Json -Depth 5
  }
  else {
    Write-Host "✅ $Result" -ForegroundColor Green
  }

}
catch {
  $ErrorMsg = $_.Exception.Message
  Write-Error "Agent Failed: $ErrorMsg"
    
  $Output = @{
    success = $false
    error   = $ErrorMsg
  }
  Write-AgentLog -EventData $Output
  exit 1
}


