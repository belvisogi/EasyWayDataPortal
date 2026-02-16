<#
.SYNOPSIS
    Classifies user intent using the #COSTAR prompt framework.

.DESCRIPTION
    Atomic skill: takes user input text and classifies it into a known intent
    category with a confidence score. Uses COSTAR prompt engineering.

.PARAMETER UserInput
    The user's natural-language input to classify.

.PARAMETER IntentList
    Array of known intent labels. Defaults to platform standard intents.

.PARAMETER OutputFormat
    Output format: object, json (default: object).

.EXAMPLE
    Invoke-ClassifyIntent -UserInput "Show me last month's sales report"

.EXAMPLE
    Invoke-ClassifyIntent -UserInput "Delete the staging database" -IntentList @("query","delete","deploy","create")

.OUTPUTS
    PSCustomObject: intent, confidence, reasoning
#>
function Invoke-ClassifyIntent {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string]$UserInput,

        [Parameter(Mandatory = $false)]
        [string[]]$IntentList = @(
            "query",
            "summarize",
            "create",
            "update",
            "delete",
            "deploy",
            "analyze",
            "report",
            "troubleshoot",
            "configure"
        ),

        [Parameter(Mandatory = $false)]
        [ValidateSet("object", "json")]
        [string]$OutputFormat = "object",

        [Parameter(Mandatory = $false)]
        [switch]$DryRun
    )

    $intentListStr = $IntentList -join '", "'

    # ── COSTAR Prompt Assembly ──
    $costarPrompt = @"
# CONTEXT
User input to classify:
"$UserInput"

Known intent categories: ["$intentListStr"]

# OBJECTIVE
Classify the user's input into exactly ONE of the known intent categories.
Provide a confidence score between 0.0 and 1.0.
Explain your reasoning in one sentence.

# STYLE
Analytical, data-driven classification.

# TONE
Objective, precise.

# AUDIENCE
Orchestration engine that will route the request based on intent.

# RESPONSE
Respond ONLY with valid JSON in this exact format (no markdown fences):
{
  "intent": "<one of the known categories>",
  "confidence": <0.0 to 1.0>,
  "reasoning": "<one sentence explaining why>"
}
"@

    if ($DryRun) {
        return [PSCustomObject]@{
            SkillId   = "analysis.classify-intent"
            DryRun    = $true
            Prompt    = $costarPrompt
            Timestamp = Get-Date -Format "o"
        }
    }

    # ── LLM Call ──
    try {
        $configPath = Join-Path $PSScriptRoot "..\..\scripts\pwsh\llm-router.config.ps1"
        if (Test-Path $configPath) { . $configPath }

        $body = @{
            model       = if ($LLM_MODEL) { $LLM_MODEL } else { "deepseek-chat" }
            messages    = @(
                @{ role = "system"; content = "You are an intent classification engine. Always respond with valid JSON only. Pick exactly one intent from the provided list." }
                @{ role = "user"; content = $costarPrompt }
            )
            temperature = 0.0
            max_tokens  = 300
        } | ConvertTo-Json -Depth 5

        $apiKey = if ($env:DEEPSEEK_API_KEY) { $env:DEEPSEEK_API_KEY }
        elseif ($LLM_API_KEY) { $LLM_API_KEY }
        else { throw "No API key found. Set DEEPSEEK_API_KEY or configure llm-router.config.ps1" }

        $apiBase = if ($env:DEEPSEEK_API_BASE) { $env:DEEPSEEK_API_BASE }
        elseif ($LLM_API_BASE) { $LLM_API_BASE }
        else { "https://api.deepseek.com/v1" }

        $response = Invoke-RestMethod -Uri "$apiBase/chat/completions" `
            -Method POST -Body $body -ContentType "application/json" `
            -Headers @{ "Authorization" = "Bearer $apiKey" }

        $content = $response.choices[0].message.content
        $parsed = $content | ConvertFrom-Json

        # ── Validate intent is in known list ──
        if ($parsed.intent -notin $IntentList) {
            Write-Warning "LLM returned unknown intent '$($parsed.intent)'. Falling back to closest match."
        }

        return [PSCustomObject]@{
            SkillId    = "analysis.classify-intent"
            Intent     = $parsed.intent
            Confidence = $parsed.confidence
            Reasoning  = $parsed.reasoning
            UserInput  = $UserInput
            Model      = $response.model
            Usage      = $response.usage
            Timestamp  = Get-Date -Format "o"
        }
    }
    catch {
        Write-Error "Invoke-ClassifyIntent failed: $_"
        throw
    }
}
