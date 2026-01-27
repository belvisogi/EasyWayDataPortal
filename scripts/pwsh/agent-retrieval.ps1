<#
.SYNOPSIS
    Agent Retrieval: Memory & Knowledge Base Interface (Portable Brain Standard)
.DESCRIPTION
    Manages interaction with the Vector Database (ChromaDB) and Knowledge Base.
    Capabilities:
    - rag:search (Semantic Search)
    - rag:upsert (Add documents)
    - rag:export (Wiki to chunks)
    - rag:ask (Direct Q&A with RAG)
#>
[CmdletBinding()]
Param(
  # --- Standard Input ---
  [Parameter(Mandatory = $false)]
  [ValidateSet('rag:search', 'rag:upsert', 'rag:export', 'rag:ask')]
  [string]$Action,

  [Parameter(Mandatory = $false)] [string]$Query,       # Search Term or Question
  [Parameter(Mandatory = $false)] [string]$IntentPath,

  # --- Portable Brain Config (Standard) ---
  [ValidateSet("Ollama", "DeepSeek", "OpenAI", "AzureOpenAI")]
  [string]$Provider = "Ollama",

  [string]$Model = "deepseek-r1:7b",
  [string]$ApiKey = $env:EASYWAY_LLM_KEY,
  [string]$ApiEndpoint = "https://api.deepseek.com/chat/completions",

  # --- Options ---
  [int]$TopK = 5,
  [string]$Collection = "easyway_knowledge",
  [string]$WikiRoot, 

  # --- Flags ---
  [switch]$NonInteractive,
  [switch]$LogEvent = $true,
  [switch]$JsonOutput
)

$ErrorActionPreference = 'Stop'
$ChromaBridgeScript = Join-Path $PSScriptRoot "../../scripts/python/chroma_bridge.py"

# --- 1. HELPER FUNCTIONS (Portable Brain) ---

function Get-LLMResponse {
  param($Prompt, $SystemPrompt)
  Write-Verbose "🧠 Thinking with Provider: $Provider (Model: $Model)..."
  if ($Provider -eq "Ollama") {
    $body = @{ model = $Model; prompt = $Prompt; stream = $false }
    if ($SystemPrompt) { $body["system"] = $SystemPrompt }
    try { return (Invoke-RestMethod -Uri "http://localhost:11434/api/generate" -Method Post -Body ($body | ConvertTo-Json) -ContentType "application/json").response } 
    catch { throw "Ollama Error: $($_.Exception.Message)" }
  }
  elseif ($Provider -in @("DeepSeek", "OpenAI")) {
    if (-not $ApiKey) { throw "ApiKey required" }
    $messages = @(@{ role = "user"; content = $Prompt })
    if ($SystemPrompt) { $messages = @(@{ role = "system"; content = $SystemPrompt }) + $messages }
    $body = @{ model = $Model; messages = $messages; temperature = 0.1 }
    try { 
      return (Invoke-RestMethod -Uri $ApiEndpoint -Method Post -Headers @{Authorization = "Bearer $ApiKey" } -Body ($body | ConvertTo-Json -Depth 10) -ContentType "application/json" -TimeoutSec 120).choices[0].message.content
    }
    catch { throw "API Error: $($_.Exception.Message)" }
  }
}

function Invoke-ChromaBridge {
  param($Command, $Payload)
  if (-not (Test-Path $ChromaBridgeScript)) { throw "Chroma Bridge not found at $ChromaBridgeScript" }
    
  $jsonPayload = $Payload | ConvertTo-Json -Depth 10 -Compress
  # Avoid passing huge JSON in args, use pipeline or file? 
  # For now, simple args. In production use stdin.
    
  if ($IsWindows) {
    $res = python $ChromaBridgeScript $Command $jsonPayload
  }
  else {
    $res = python3 $ChromaBridgeScript $Command $jsonPayload
  }
    
  if (-not $res) { return $null }
  try { return ($res | ConvertFrom-Json) } catch { throw "Chroma Bridge Error: $res" }
}

function Write-AgentLog {
  param($EventData)
  if (-not $LogEvent) { return }
  $logDir = Join-Path $PSScriptRoot "../../logs/agents"
  if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir -Force | Out-Null }
  $entry = [ordered]@{ timestamp = (Get-Date).ToString("o"); agent = "agent_retrieval"; provider = $Provider; data = $EventData }
  ($entry | ConvertTo-Json -Depth 5) | Out-File (Join-Path $logDir "agent-history.jsonl") -Append
}

function Out-Result($obj) { 
  if ($JsonOutput) { $obj | ConvertTo-Json -Depth 10 | Write-Output }
  else { 
    if ($obj.answer) { Write-Host "🤖 Answer: $($obj.answer)" -ForegroundColor Cyan }
    if ($obj.results) { 
      Write-Host "📚 Found $($obj.results.Count) docs:" -ForegroundColor Yellow
      foreach ($r in $obj.results) { Write-Host "   - $($r.metadata.source) (score: $($r.distance))" }
    }
  }
}

# --- 2. INPUT NORMALIZATION ---

if ($IntentPath -and (Test-Path $IntentPath)) {
  $IntentData = Get-Content $IntentPath -Raw | ConvertFrom-Json
  if (-not $Query) { $Query = $IntentData.query }
  if (-not $Action) { $Action = $IntentData.action }
}

if (-not $Query -and $Action -in ('rag:search', 'rag:ask')) {
  Write-Error "-Query is required for search/ask."
  exit 1
}

# --- 3. EXECUTION ---

try {
  $Result = $null

  switch ($Action) {
    'rag:search' {
      $Result = @{ results = Invoke-ChromaBridge -Command "query" -Payload @{ query = $Query; n = $TopK } }
    }

    'rag:ask' {
      # 1. Retrieve
      $docs = Invoke-ChromaBridge -Command "query" -Payload @{ query = $Query; n = $TopK }
      $context = ($docs | ForEach-Object { "- $($_.content) (Source: $($_.metadata.source))" }) -join "`n"
            
      # 2. Generate
      $sysPrompt = "You are Agent Retrieval. Answer the query using ONLY the provided Context. If unknown, say 'I don't know'."
      $usrPrompt = "Context:`n$context`n`nQuery: $Query"
            
      $answer = Get-LLMResponse -Prompt $usrPrompt -SystemPrompt $sysPrompt
            
      $Result = @{
        query        = $Query
        context_docs = $docs.Count
        answer       = $answer
        results      = $docs
      }
    }
        
    'rag:export' {
      # Legacy Logic for Wiki Export
      $wikiRoot = if ($WikiRoot) { $WikiRoot } else { 'Wiki/EasyWayData.wiki' }
      if (-not (Test-Path $wikiRoot)) { throw "Wiki root not found: $wikiRoot" }
            
      # Run existing scripts
      $scriptsDir = Join-Path $wikiRoot 'scripts'
      $artifacts = @()
      if (Test-Path (Join-Path $scriptsDir 'generate-master-index.ps1')) {
        pwsh (Join-Path $scriptsDir 'generate-master-index.ps1') -Root $wikiRoot | Out-Null
        $artifacts += "index_master.jsonl"
      }
      if (Test-Path (Join-Path $scriptsDir 'export-chunks-jsonl.ps1')) {
        pwsh (Join-Path $scriptsDir 'export-chunks-jsonl.ps1') -Root $wikiRoot | Out-Null
        $artifacts += "chunks_master.jsonl"
      }
      $Result = @{ executed = $true; artifacts = $artifacts }
    }
        
    default { throw "Action '$Action' not implemented." }
  }

  $Output = @{ success = $true; agent = "agent_retrieval"; result = $Result; metadata = @{ provider = $Provider } }
  Write-AgentLog -EventData $Output
  Out-Result $Result

}
catch {
  $ErrorMsg = $_.Exception.Message
  Write-Error "Retrieval Error: $ErrorMsg"
  Write-AgentLog -EventData @{ success = $false; error = $ErrorMsg }
  exit 1
}
