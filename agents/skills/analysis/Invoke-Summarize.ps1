<#
.SYNOPSIS
    Summarizes text using the #COSTAR prompt framework.

.DESCRIPTION
    Atomic skill: takes text/file content and produces a structured summary
    using a COSTAR-engineered prompt (Context, Objective, Style, Tone, Audience, Response).

.PARAMETER InputText
    The text content to summarize.

.PARAMETER MaxWords
    Maximum words for the summary (default: 150).

.PARAMETER Style
    Writing style: business, technical, conversational (default: business).

.PARAMETER OutputFormat
    Output format: object, json, markdown (default: object).

.EXAMPLE
    $result = Invoke-Summarize -InputText (Get-Content report.md -Raw)
    $result.summary

.OUTPUTS
    PSCustomObject: summary, key_points, word_count
#>
function Invoke-Summarize {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string]$InputText,

        [Parameter(Mandatory = $false)]
        [ValidateRange(50, 1000)]
        [int]$MaxWords = 150,

        [Parameter(Mandatory = $false)]
        [ValidateSet("business", "technical", "conversational")]
        [string]$Style = "business",

        [Parameter(Mandatory = $false)]
        [ValidateSet("object", "json", "markdown")]
        [string]$OutputFormat = "object",

        [Parameter(Mandatory = $false)]
        [switch]$DryRun
    )

    # ── COSTAR Prompt Assembly ──
    $styleMap = @{
        business       = "Professional, business-oriented, clear and actionable"
        technical      = "Technical, precise, with jargon appropriate for engineers"
        conversational = "Conversational, friendly, easy to understand"
    }

    $audienceMap = @{
        business       = "Executive stakeholders and business decision-makers"
        technical      = "Software engineers and technical leads"
        conversational = "General audience, non-technical readers"
    }

    $costarPrompt = @"
# CONTEXT
You are given the following document to analyze:

---
$InputText
---

# OBJECTIVE
Produce a concise summary of the document in no more than $MaxWords words.
Extract the most important key points as a bullet list.

# STYLE
$($styleMap[$Style])

# TONE
Neutral, informative, factual.

# AUDIENCE
$($audienceMap[$Style])

# RESPONSE
Respond ONLY with valid JSON in this exact format (no markdown fences):
{
  "summary": "<concise summary here>",
  "key_points": ["point 1", "point 2", "point 3"],
  "word_count": <number of words in summary>
}
"@

    if ($DryRun) {
        return [PSCustomObject]@{
            SkillId   = "analysis.summarize"
            DryRun    = $true
            Prompt    = $costarPrompt
            Timestamp = Get-Date -Format "o"
        }
    }

    # ── LLM Call via Invoke-Provider (if available) ──
    try {
        $configPath = Join-Path $PSScriptRoot "..\..\scripts\pwsh\llm-router.config.ps1"
        if (Test-Path $configPath) { . $configPath }

        $body = @{
            model       = if ($LLM_MODEL) { $LLM_MODEL } else { "deepseek-chat" }
            messages    = @(
                @{ role = "system"; content = "You are a precise summarization engine. Always respond with valid JSON only." }
                @{ role = "user"; content = $costarPrompt }
            )
            temperature = 0.1
            max_tokens  = 1000
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

        return [PSCustomObject]@{
            SkillId   = "analysis.summarize"
            Summary   = $parsed.summary
            KeyPoints = $parsed.key_points
            WordCount = $parsed.word_count
            Style     = $Style
            Model     = $response.model
            Usage     = $response.usage
            Timestamp = Get-Date -Format "o"
        }
    }
    catch {
        Write-Error "Invoke-Summarize failed: $_"
        throw
    }
}
