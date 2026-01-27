<#
.SYNOPSIS
    Agent GEDI: OODA Loop Implementation (Portable Brain Standard)
    Observe, Orient, Decide, Act - Philosophical Guardian for EasyWay.
.DESCRIPTION
    Operationalizes GEDI philosophy with a Provider-Agnostic design.
    Features:
    - OODA Loop (Observe-Orient-Decide-Act)
    - Hybrid Intelligence (Local/Cloud Provider)
    - n8n Ready (JSON Output)
#>
[CmdletBinding()]
Param(
    # --- Standard Input ---
    [Parameter(Mandatory = $false)] [string]$Query,  # In GEDI terms: "Intent"
    [Parameter(Mandatory = $false)] [string]$Action, # e.g. "validate"
    [Parameter(Mandatory = $false)] [string]$IntentPath,
    [Parameter(Mandatory = $false)] [string]$Context, # Additional context

    # --- Portable Brain Config (Standard) ---
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
$ManifestPath = Join-Path $PSScriptRoot "../../agents/agent_gedi/manifest.json"

# --- 1. HELPER FUNCTIONS (Portable Brain) ---

function Get-LLMResponse {
    param($Prompt, $SystemPrompt)
    Write-Verbose "🧠 Thinking with Provider: $Provider (Model: $Model)..."

    if ($Provider -eq "Ollama") {
        # OLLAMA ADAPTER
        $body = @{ model = $Model; prompt = $Prompt; stream = $false }
        if ($SystemPrompt) { $body["system"] = $SystemPrompt }
        try {
            $response = Invoke-RestMethod -Uri "http://localhost:11434/api/generate" -Method Post -Body ($body | ConvertTo-Json) -ContentType "application/json"
            return $response.response
        }
        catch { throw "Ollama Error: $($_.Exception.Message)" }
    }
    elseif ($Provider -in @("DeepSeek", "OpenAI")) {
        # API ADAPTER
        if (-not $ApiKey) { throw "ApiKey required for $Provider" }
        $messages = @(@{ role = "user"; content = $Prompt })
        if ($SystemPrompt) { $messages = @(@{ role = "system"; content = $SystemPrompt }) + $messages }
        $body = @{ model = $Model; messages = $messages; temperature = 0.1 }
        try {
            $response = Invoke-RestMethod -Uri $ApiEndpoint -Method Post -Headers @{Authorization = "Bearer $ApiKey" } -Body ($body | ConvertTo-Json -Depth 10) -ContentType "application/json" -TimeoutSec 120
            return $response.choices[0].message.content
        }
        catch { throw "API Error: $($_.Exception.Message)" }
    }
}

function Write-AgentLog {
    param($EventData)
    if (-not $LogEvent) { return }
    $logDir = Join-Path $PSScriptRoot "../../logs/agents"
    if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir -Force | Out-Null }
    $entry = [ordered]@{ timestamp = (Get-Date).ToString("o"); agent = "agent_gedi"; provider = $Provider; data = $EventData }
    ($entry | ConvertTo-Json -Depth 5) | Out-File (Join-Path $logDir "agent-history.jsonl") -Append
}

# --- 2. GEDI LOGIC (The Soul) ---

function Get-Principles {
    if (Test-Path $ManifestPath) {
        $m = Get-Content $ManifestPath -Raw | ConvertFrom-Json
        return $m.principles
    }
    return $null
}

function Orient-Principles {
    param($Principles, $Text)
    $foundPrinciples = @()
    if (-not $Principles) { return $foundPrinciples }
    $Text = $Text.ToLower()
    
    # Heuristic Matching (Simple Orient)
    if ($Text -match "speed|fast|quick|rush|deadline|asap") { $foundPrinciples += $Principles.quality_over_speed }
    if ($Text -match "deploy|release|prod|live") { $foundPrinciples += $Principles.measure_twice_cut_once }
    if ($Text -match "doc|wiki|explain|why") { $foundPrinciples += $Principles.journey_matters }
    if ($Text -match "code|refactor|legacy|clean") { $foundPrinciples += $Principles.tangible_legacy }
    if ($Text -match "provider|cloud|lock-in|portabl") { $foundPrinciples += $Principles.electrical_socket_pattern }
    
    # AI Enrichment (Orient-II)
    # If using a Smart Provider (DeepSeek), we can ask it to verify relevance?
    # For now, stick to heuristics to keep it fast/deterministic, LLM used for "Advice Generation".
    
    return $foundPrinciples
}

# --- 3. INPUT NORMALIZATION ---
$IntentData = $null
if ($IntentPath -and (Test-Path $IntentPath)) {
    $IntentData = Get-Content $IntentPath -Raw | ConvertFrom-Json
    if (-not $Query) { $Query = $IntentData.intent } # GEDI specific mapping
    if (-not $Context) { $Context = $IntentData.context }
}

if (-not $Query -and -not $Context) {
    Write-Error "GEDI requires -Query (Intent) or -Context."
    exit 1
}

# --- 4. EXECUTION ---
try {
    Write-Host "🥋 GEDI (Hybrid OODA Loop): Active" -ForegroundColor Cyan
    
    # 1. OBSERVE
    $FullSituation = "Context: $Context | Intent: $Query"
    Write-Host "   👁️  Observe: $FullSituation" -ForegroundColor Gray
    
    # 2. ORIENT
    $Principles = Get-Principles
    $RelevantPrinciples = Orient-Principles -Principles $Principles -Text $FullSituation
    
    $Guidance = @()
    
    # 3. DECIDE & ACT
    foreach ($p in $RelevantPrinciples) {
        Write-Host "   🧭 Orient: Principle Selected - $($p.description)" -ForegroundColor Yellow
        $Prompt = "You are Agent GEDI, guardian of the EasyWay Philosophy.
        Principle to Apply: '$($p.philosophy)'
        Checks available: $($p.checks -join ', ')
        
        Situation: $FullSituation
        
        Task: Provide a short, wise guidance message based ONLY on this principle. Be concise but profound."
        
        # ACT: Use the Portable Brain
        $Advice = Get-LLMResponse -Prompt $Prompt -SystemPrompt "You are a wise Philosophy Guardian."
        
        $Guidance += @{
            principle = $p.description
            advice    = $Advice
        }
        
        Write-Host "   ⚡ Act: $Advice" -ForegroundColor Green
    }
    
    if ($RelevantPrinciples.Count -eq 0) {
        Write-Host "   🧘 No specific principle violated. Proceed with awareness." -ForegroundColor DarkGray
        $Guidance += "No objection."
    }
    
    $Result = @{
        ooda_state = "complete"
        guidance   = $Guidance
    }

    $Output = @{
        success  = $true
        agent    = "agent_gedi"
        result   = $Result
        metadata = @{ provider = $Provider }
    }
    
    Write-AgentLog -EventData $Output
    
    if ($JsonOutput) { $Output | ConvertTo-Json -Depth 5 }

}
catch {
    $ErrorMsg = $_.Exception.Message
    Write-Error "GEDI Error: $ErrorMsg"
    Write-AgentLog -EventData @{ success = $false; error = $ErrorMsg }
    exit 1
}
