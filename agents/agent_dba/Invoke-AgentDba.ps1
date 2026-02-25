#Requires -Version 5.1
<#
.SYNOPSIS
    Level 2 runner for agent_dba (DBA Agent).

.DESCRIPTION
    Implements the L2 pattern: LLM + RAG + structured JSON output + Import-AgentSecrets.

    Actions:
      dba:check-health    - Verifica connettivita' DB (deterministic, no LLM)
      db-guardrails:check - Valida SQL patterns contro GUARDRAILS.md via LLM+RAG

.PARAMETER Action
    Action to perform. Default: dba:check-health.

.PARAMETER Scope
    Per db-guardrails:check: scope di analisi ('all', 'tables', 'procedures'). Default: 'all'.

.PARAMETER Database
    Nome database target (opzionale, legge da env DB_DATABASE).

.PARAMETER DryRun
    Show output without writing files.

.EXAMPLE
    pwsh agents/agent_dba/Invoke-AgentDba.ps1 -Action dba:check-health
    pwsh agents/agent_dba/Invoke-AgentDba.ps1 -Action db-guardrails:check -Scope tables -DryRun

.NOTES
    Evolution Level: 2 (LLM + RAG + structured JSON output)
    Predecessor: run-with-rag.ps1 (deprecated)
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [ValidateSet('dba:check-health', 'db-guardrails:check')]
    [string]$Action = 'dba:check-health',

    [Parameter(Mandatory = $false)]
    [ValidateSet('all', 'tables', 'procedures', 'functions')]
    [string]$Scope = 'all',

    [Parameter(Mandatory = $false)] [string]$Database = '',
    [Parameter(Mandatory = $false)] [string]$ApiKey = $env:DEEPSEEK_API_KEY,
    [Parameter(Mandatory = $false)] [int]$TopK = 5,
    [Parameter(Mandatory = $false)] [switch]$DryRun,
    [Parameter(Mandatory = $false)] [bool]$LogEvent = $true
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# --- Paths ----------------------------------------------------------------------
$AgentDir    = $PSScriptRoot
$SkillsDir   = Join-Path $AgentDir '..' 'skills'
$LLMWithRAG  = Join-Path $SkillsDir 'retrieval' 'Invoke-LLMWithRAG.ps1'
$PromptsFile  = Join-Path $AgentDir 'PROMPTS.md'
$GuardrailsFile = Join-Path $AgentDir 'GUARDRAILS.md'

foreach ($required in @($PromptsFile, $GuardrailsFile)) {
    if (-not (Test-Path $required)) {
        Write-Error "Required file not found: $required"
        exit 1
    }
}

# --- Bootstrap: load platform secrets -------------------------------------------
$importSecretsSkill = Join-Path $SkillsDir 'utilities' 'Import-AgentSecrets.ps1'
if (Test-Path $importSecretsSkill) {
    . $importSecretsSkill
    Import-AgentSecrets -AgentId 'agent_dba' | Out-Null
}
if (-not $ApiKey) { $ApiKey = $env:DEEPSEEK_API_KEY }

# DB connection from env (best-effort — check-health may fail gracefully)
$dbServer   = if ($env:DB_SERVER)   { $env:DB_SERVER }   else { 'localhost,1433' }
$dbDatabase = if ($Database)        { $Database }
              elseif ($env:DB_DATABASE) { $env:DB_DATABASE }
              else { 'EasyWayDB' }

function Write-AgentLog {
    param($EventData)
    if (-not $LogEvent) { return }
    $logDir = Join-Path $AgentDir '..' 'logs'
    if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir -Force | Out-Null }
    $entry = [ordered]@{ timestamp = (Get-Date).ToString('o'); agent = 'agent_dba'; data = $EventData }
    ($entry | ConvertTo-Json -Depth 5) | Out-File (Join-Path $logDir 'agent-history.jsonl') -Append -Encoding utf8
}

# --- Header ---------------------------------------------------------------------
$startTime = Get-Date
$now = (Get-Date).ToUniversalTime().ToString('o')

Write-Host ''
Write-Host '=============================================' -ForegroundColor Cyan
Write-Host ' Agent DBA (Database Guardian) L2'           -ForegroundColor Cyan
Write-Host " Action  : $Action"                          -ForegroundColor Cyan
Write-Host " Database: $dbDatabase"                      -ForegroundColor Cyan
Write-Host '=============================================' -ForegroundColor Cyan
Write-Host ''

# --- Execution ------------------------------------------------------------------
try {
    $Result = $null

    switch ($Action) {

        # ==========================================================================
        # ACTION: dba:check-health (deterministic — no LLM)
        # ==========================================================================
        'dba:check-health' {
            Write-Host '[1/1] Checking DB connectivity...' -ForegroundColor Yellow

            $status = 'ok'
            $detail = ''
            $sqlcmdAvailable = $null -ne (Get-Command sqlcmd -ErrorAction SilentlyContinue)

            if (-not $sqlcmdAvailable) {
                $status = 'degraded'
                $detail = 'sqlcmd not found in PATH; connectivity check skipped'
                Write-Warning "[DBA] $detail"
            } else {
                try {
                    $testQuery = "SELECT 1 AS health_check"
                    $output = sqlcmd -S $dbServer -d $dbDatabase -Q $testQuery -b 2>&1
                    if ($LASTEXITCODE -ne 0) {
                        $status = 'error'
                        $detail = "sqlcmd exit code $LASTEXITCODE"
                    } else {
                        $detail = "SELECT 1 succeeded on $dbServer/$dbDatabase"
                    }
                } catch {
                    $status = 'error'
                    $detail = $_.Exception.Message
                }
            }

            $durationSec = [Math]::Round(((Get-Date) - $startTime).TotalSeconds, 2)
            Write-Host "[1/1] Done. Status: $status" -ForegroundColor $(if ($status -eq 'ok') { 'Green' } else { 'Yellow' })

            $Result = [ordered]@{
                action       = $Action
                ok           = ($status -eq 'ok' -or $status -eq 'degraded')
                status       = $status
                dependency   = 'database'
                server       = $dbServer
                database     = $dbDatabase
                detail       = $detail
                dryRun       = $DryRun.IsPresent
                meta         = [ordered]@{
                    sqlcmd_available = $sqlcmdAvailable
                    duration_sec     = $durationSec
                }
                startedAt    = $now
                finishedAt   = (Get-Date).ToUniversalTime().ToString('o')
                contractId   = 'action-result'
                contractVersion = '1.0'
            }
        }

        # ==========================================================================
        # ACTION: db-guardrails:check (LLM + RAG)
        # ==========================================================================
        'db-guardrails:check' {
            if (-not (Test-Path $LLMWithRAG)) {
                Write-Error "Invoke-LLMWithRAG.ps1 not found at: $LLMWithRAG"
                exit 1
            }
            if (-not $ApiKey) {
                Write-Error 'DEEPSEEK_API_KEY not set. Add to /opt/easyway/.env.secrets or pass -ApiKey.'
                exit 1
            }

            . $LLMWithRAG

            # Load GUARDRAILS.md for LLM context
            $guardrailsContent = Get-Content $GuardrailsFile -Raw -Encoding UTF8

            # Scan SQL files for analysis (best-effort)
            $dbDir = Join-Path $AgentDir '..' '..' 'db'
            $sqlFiles = @()
            if (Test-Path $dbDir) {
                $sqlFiles = Get-ChildItem $dbDir -Recurse -Filter '*.sql' -ErrorAction SilentlyContinue |
                            Select-Object -First 20
            }
            $sqlCount = $sqlFiles.Count
            $sqlSample = if ($sqlCount -gt 0) {
                ($sqlFiles | Select-Object -First 5 | ForEach-Object { "- $($_.Name)" }) -join "`n"
            } else { "(nessun file SQL trovato nella directory db/)" }

            Write-Host "[1/2] Analyzing $sqlCount SQL files against GUARDRAILS.md..." -ForegroundColor Yellow

            $query = @"
Analizza la conformita' degli oggetti DB ai GUARDRAILS EasyWay.

Scope: $Scope
Database: $dbDatabase
File SQL trovati ($sqlCount):
$sqlSample

GUARDRAILS da rispettare (estratto):
$(($guardrailsContent | Select-Object -First 100) -join "`n")

Genera il JSON db-guardrails:check con:
- 'violations': array di oggetti {file, rule_violated, severity (HIGH/MEDIUM/LOW), description, fix}
- 'compliant_count': numero oggetti conformi
- 'summary': valutazione complessiva
- 'confidence': 0.0-1.0
"@

            $invokeParams = @{
                Query        = $query
                AgentId      = 'agent_dba'
                SystemPrompt = (Get-Content $PromptsFile -Raw -Encoding UTF8)
                TopK         = $TopK
                SecureMode   = $true
                MaxTokens    = 1200
            }

            $llmResult = Invoke-LLMWithRAG @invokeParams
            if (-not $llmResult.Success) { throw "LLM call failed: $($llmResult.Error)" }

            $json = ($llmResult.Answer -replace '(?s)```json\s*', '' -replace '(?s)```\s*', '').Trim()
            try { $parsed = $json | ConvertFrom-Json }
            catch {
                $parsed = [PSCustomObject]@{ violations = @(); confidence = 0.5; summary = "Parse error"; compliant_count = 0 }
            }

            $confidence = if ($parsed.PSObject.Properties['confidence']) { [double]$parsed.confidence } else { 0.5 }
            $durationSec = [Math]::Round(((Get-Date) - $startTime).TotalSeconds, 2)

            Write-Host "[2/2] Done. SQL files: $sqlCount | Confidence: $confidence" -ForegroundColor Green

            $Result = [ordered]@{
                action                = $Action
                ok                    = $true
                scope                 = $Scope
                sql_files_analyzed    = $sqlCount
                violations_found      = if ($parsed.PSObject.Properties['violations']) { @($parsed.violations).Count } else { 0 }
                confidence            = $confidence
                requires_human_review = ($confidence -lt 0.80)
                summary               = if ($parsed.PSObject.Properties['summary']) { $parsed.summary } else { "Analisi guardrails completata." }
                dryRun                = $DryRun.IsPresent
                meta                  = [ordered]@{
                    rag_chunks   = $llmResult.RAGChunks
                    tokens_in    = $llmResult.TokensIn
                    tokens_out   = $llmResult.TokensOut
                    cost_usd     = $llmResult.CostUSD
                    duration_sec = $durationSec
                }
                startedAt             = $now
                finishedAt            = (Get-Date).ToUniversalTime().ToString('o')
                contractId            = 'action-result'
                contractVersion       = '1.0'
            }
        }

        default { throw "Action '$Action' not implemented." }
    }

    Write-AgentLog -EventData @{ success = $true; agent = 'agent_dba'; action = $Action; result = $Result }
    $Result | ConvertTo-Json -Depth 10 | Write-Output

} catch {
    $errMsg = $_.Exception.Message
    Write-Error "DBA Agent Error: $errMsg"
    Write-AgentLog -EventData @{ success = $false; error = $errMsg }
    exit 1
}
