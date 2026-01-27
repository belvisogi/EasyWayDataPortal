<#
.SYNOPSIS
    Agent Chronicler: The Historian of EasyWay (Portable Brain Standard)
.DESCRIPTION
    Manages the "Diario di Bordo" (Daily Logbook).
    Capabilities:
    - chronicler:write (Add entry to today's log)
    - chronicler:read (Read today's log)
    - chronicler:summarize (Use LLM to generate daily summary from events)
#>
[CmdletBinding()]
Param(
    # --- Standard Input ---
    [Parameter(Mandatory = $false)]
    [ValidateSet('chronicler:write', 'chronicler:read', 'chronicler:summarize')]
    [string]$Action,

    [Parameter(Mandatory = $false)] [string]$Query,       # Content for write, or context
    [Parameter(Mandatory = $false)] [string]$IntentPath,

    # --- Portable Brain Config (Standard) ---
    [ValidateSet("Ollama", "DeepSeek", "OpenAI", "AzureOpenAI")]
    [string]$Provider = "Ollama",

    [string]$Model = "deepseek-r1:7b",
    [string]$ApiKey = $env:EASYWAY_LLM_KEY,
    [string]$ApiEndpoint = "https://api.deepseek.com/chat/completions",

    # --- Agent Specific ---
    [string]$Title,
    [string]$Section = "Note",
    [string]$LogRoot = "$PSScriptRoot/../../", # Root of the repo

    # --- Flags ---
    [switch]$NonInteractive,
    [switch]$LogEvent = $true,
    [switch]$JsonOutput
)

$ErrorActionPreference = 'Stop'

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

function Write-AgentLog {
    param($EventData)
    if (-not $LogEvent) { return }
    $logDir = Join-Path $PSScriptRoot "../../logs/agents"
    if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir -Force | Out-Null }
    $entry = [ordered]@{ timestamp = (Get-Date).ToString("o"); agent = "agent_chronicler"; provider = $Provider; data = $EventData }
    ($entry | ConvertTo-Json -Depth 5) | Out-File (Join-Path $logDir "agent-history.jsonl") -Append
}

function Out-Result($obj) { 
    if ($JsonOutput) { $obj | ConvertTo-Json -Depth 10 | Write-Output }
    else { Write-Output ($obj | ConvertTo-Json -Depth 5) }
}

# --- 2. INPUT NORMALIZATION ---

if ($IntentPath -and (Test-Path $IntentPath)) {
    $IntentData = Get-Content $IntentPath -Raw | ConvertFrom-Json
    if (-not $Action) { $Action = $IntentData.action }
    if (-not $Query) { $Query = $IntentData.query }
    if (-not $Title) { $Title = $IntentData.title }
}

if (-not $Action) { Write-Error "Action required"; exit 1 }

$DateTag = (Get-Date).ToString("yyyyMMdd")
$LogFile = Join-Path $LogRoot "DIARIO_DI_BORDO_$DateTag.md"

# --- 3. EXECUTION ---

try {
    $Result = $null

    switch ($Action) {
        'chronicler:write' {
            if (-not $Query) { throw "Query (Entry Content) is required." }
            
            # Init File if new
            if (-not (Test-Path $LogFile)) {
                $Header = "# 📔 DIARIO DI BORDO - $((Get-Date).ToString('yyyy-MM-dd'))`n`n"
                Set-Content -Path $LogFile -Value $Header -Encoding UTF8
            }
            
            # Format Entry
            $Time = (Get-Date).ToString("HH:mm")
            $Entry = "## $Time - $Title`n$Query`n"
            
            Add-Content -Path $LogFile -Value $Entry -Encoding UTF8
            $Result = @{ ok = $true; file = $LogFile; entry = $Entry }
        }

        'chronicler:read' {
            if (-not (Test-Path $LogFile)) { throw "No logbook for today ($LogFile)." }
            $Content = Get-Content $LogFile -Raw -Encoding UTF8
            $Result = @{ ok = $true; file = $LogFile; content = $Content }
        }

        'chronicler:summarize' {
            # Advanced: Read agent logs and write a summary
            # Reading last 50 lines of agent history for context (Simulated)
            $logDir = Join-Path $PSScriptRoot "../../logs/agents"
            $historyFile = Join-Path $logDir "agent-history.jsonl"
            if (-not (Test-Path $historyFile)) { throw "No agent history found." }
            
            $history = Get-Content $historyFile -Tail 50 | ForEach-Object { $_ }
            $sysPrompt = "You are Agent Chronicler. Summarize the following JSON agent logs into a concise 'Diario di Bordo' entry (Markdown)."
            $summary = Get-LLMResponse -Prompt ($history -join "`n") -SystemPrompt $sysPrompt
            
            # Write Summary
            if (-not (Test-Path $LogFile)) {
                Set-Content -Path $LogFile -Value "# 📔 DIARIO DI BORDO - $((Get-Date).ToString('yyyy-MM-dd'))`n`n" -Encoding UTF8
            }
            Add-Content -Path $LogFile -Value "## 🤖 AI Summary`n$summary`n" -Encoding UTF8
            
            $Result = @{ ok = $true; summary = $summary; file = $LogFile }
        }
        
        default { throw "Action '$Action' not implemented." }
    }

    $Output = @{ success = $true; agent = "agent_chronicler"; result = $Result; metadata = @{ provider = $Provider } }
    Write-AgentLog -EventData $Output
    Out-Result $Result

}
catch {
    $ErrorMsg = $_.Exception.Message
    Write-Error "Chronicler Error: $ErrorMsg"
    Write-AgentLog -EventData @{ success = $false; error = $ErrorMsg }
    exit 1
}
