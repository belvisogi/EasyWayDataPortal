<#
.SYNOPSIS
    Generates SQL from natural language using the #COSTAR prompt framework.

.DESCRIPTION
    Atomic skill: takes a natural-language question and optional schema context,
    returns a safe, read-only SQL query with explanation. Uses COSTAR prompt engineering.

.PARAMETER Question
    The natural-language question to convert to SQL.

.PARAMETER SchemaContext
    Database schema description (DDL, table list, etc.). If omitted, a generic prompt is used.

.PARAMETER Execute
    If set, executes the generated SQL (requires Server/Database params).

.PARAMETER Server
    SQL Server hostname (required if -Execute).

.PARAMETER Database
    Database name (required if -Execute).

.PARAMETER OutputFormat
    Output format: object, json (default: object).

.EXAMPLE
    Invoke-SQLQuery -Question "How many users signed up last month?"

.EXAMPLE
    Invoke-SQLQuery -Question "Top 5 tables by row count" -SchemaContext (Get-Content schema.sql -Raw)

.OUTPUTS
    PSCustomObject: sql, explanation, tables_used
#>
function Invoke-SQLQuery {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Question,

        [Parameter(Mandatory = $false)]
        [string]$SchemaContext = "",

        [Parameter(Mandatory = $false)]
        [switch]$Execute,

        [Parameter(Mandatory = $false)]
        [string]$Server,

        [Parameter(Mandatory = $false)]
        [string]$Database,

        [Parameter(Mandatory = $false)]
        [ValidateSet("object", "json")]
        [string]$OutputFormat = "object",

        [Parameter(Mandatory = $false)]
        [switch]$DryRun
    )

    # ── Schema Context Fallback ──
    $schemaBlock = if ([string]::IsNullOrWhiteSpace($SchemaContext)) {
        "No specific schema provided. Generate a plausible SQL query using standard T-SQL syntax."
    }
    else {
        "Database schema:`n$SchemaContext"
    }

    # ── COSTAR Prompt Assembly ──
    $costarPrompt = @"
# CONTEXT
$schemaBlock

The user is asking the following question:
"$Question"

# OBJECTIVE
Generate a safe, READ-ONLY SQL query (SELECT only, no INSERT/UPDATE/DELETE/DROP)
that answers the user's question accurately.
Include comments in the SQL explaining each section.

# STYLE
Technical SQL with inline comments. Use CTEs for complex queries.

# TONE
Precise, minimal, no unnecessary decoration.

# AUDIENCE
Developer or DBA who will review and optionally execute this query.

# RESPONSE
Respond ONLY with valid JSON in this exact format (no markdown fences):
{
  "sql": "<the SQL query here>",
  "explanation": "<1-2 sentence explanation of what the query does>",
  "tables_used": ["table1", "table2"]
}
"@

    if ($DryRun) {
        return [PSCustomObject]@{
            SkillId   = "analysis.sql-query"
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
                @{ role = "system"; content = "You are a SQL expert. Generate ONLY read-only SELECT queries. Always respond with valid JSON only." }
                @{ role = "user"; content = $costarPrompt }
            )
            temperature = 0.0
            max_tokens  = 1500
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

        # ── Safety Check: no writes ──
        $dangerPatterns = @("INSERT ", "UPDATE ", "DELETE ", "DROP ", "TRUNCATE ", "ALTER ", "EXEC ")
        foreach ($pattern in $dangerPatterns) {
            if ($parsed.sql -match [regex]::Escape($pattern)) {
                throw "SAFETY: Generated SQL contains a write operation ($pattern). Blocked."
            }
        }

        $result = [PSCustomObject]@{
            SkillId     = "analysis.sql-query"
            SQL         = $parsed.sql
            Explanation = $parsed.explanation
            TablesUsed  = $parsed.tables_used
            Question    = $Question
            Model       = $response.model
            Usage       = $response.usage
            Timestamp   = Get-Date -Format "o"
        }

        # ── Optional Execute ──
        if ($Execute) {
            if ([string]::IsNullOrWhiteSpace($Server) -or [string]::IsNullOrWhiteSpace($Database)) {
                Write-Warning "Cannot execute: -Server and -Database parameters required."
            }
            else {
                Write-Host "Executing SQL on $Server/$Database ..." -ForegroundColor Yellow
                $queryResult = Invoke-Sqlcmd -ServerInstance $Server -Database $Database -Query $parsed.sql -ErrorAction Stop
                $result | Add-Member -NotePropertyName "ExecutionResult" -NotePropertyValue $queryResult
                $result | Add-Member -NotePropertyName "Executed" -NotePropertyValue $true
            }
        }

        return $result
    }
    catch {
        Write-Error "Invoke-SQLQuery failed: $_"
        throw
    }
}
