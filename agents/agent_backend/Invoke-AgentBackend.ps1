#Requires -Version 5.1
<#
.SYNOPSIS
    Level 2 runner for agent_backend (API Architect).

.DESCRIPTION
    Implements the L2 pattern: LLM + RAG + structured JSON output + Import-AgentSecrets.

    Actions:
      api:health-check      - Verifica disponibilita' portal-api (deterministic, no LLM)
      api:openapi-validate  - Valida openapi.yaml contro best-practice via LLM+RAG

.PARAMETER Action
    Action to perform. Default: api:health-check.

.PARAMETER ApiPath
    Percorso custom all'openapi.yaml. Default: portal-api/openapi/openapi.yaml relativo alla repo root.

.PARAMETER DryRun
    Show output without writing files.

.EXAMPLE
    pwsh agents/agent_backend/Invoke-AgentBackend.ps1 -Action api:health-check
    pwsh agents/agent_backend/Invoke-AgentBackend.ps1 -Action api:openapi-validate -DryRun

.NOTES
    Evolution Level: 2 (LLM + RAG + structured JSON output)
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [ValidateSet('api:health-check', 'api:openapi-validate')]
    [string]$Action = 'api:health-check',

    [Parameter(Mandatory = $false)] [string]$ApiPath = '',
    [Parameter(Mandatory = $false)] [string]$ApiKey = $env:DEEPSEEK_API_KEY,
    [Parameter(Mandatory = $false)] [int]$TopK = 5,
    [Parameter(Mandatory = $false)] [switch]$DryRun,
    [Parameter(Mandatory = $false)] [bool]$LogEvent = $true
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# --- Paths ----------------------------------------------------------------------
$AgentDir   = $PSScriptRoot
$RepoRoot   = (Get-Item $AgentDir).Parent.Parent.FullName
$SkillsDir  = Join-Path $AgentDir '..' 'skills'
$LLMWithRAG = Join-Path $SkillsDir 'retrieval' 'Invoke-LLMWithRAG.ps1'
$PromptsFile = Join-Path $AgentDir 'PROMPTS.md'

if (-not (Test-Path $PromptsFile)) {
    Write-Error "Required file not found: $PromptsFile"
    exit 1
}

# Resolve openapi.yaml path
$resolvedApiPath = if ($ApiPath) { $ApiPath }
                   else { Join-Path $RepoRoot 'portal-api' 'openapi' 'openapi.yaml' }

# --- Bootstrap: load platform secrets -------------------------------------------
$importSecretsSkill = Join-Path $SkillsDir 'utilities' 'Import-AgentSecrets.ps1'
if (Test-Path $importSecretsSkill) {
    . $importSecretsSkill
    Import-AgentSecrets -AgentId 'agent_backend' | Out-Null
}
if (-not $ApiKey) { $ApiKey = $env:DEEPSEEK_API_KEY }

function Write-AgentLog {
    param($EventData)
    if (-not $LogEvent) { return }
    $logDir = Join-Path $AgentDir '..' 'logs'
    if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir -Force | Out-Null }
    $entry = [ordered]@{ timestamp = (Get-Date).ToString('o'); agent = 'agent_backend'; data = $EventData }
    ($entry | ConvertTo-Json -Depth 5) | Out-File (Join-Path $logDir 'agent-history.jsonl') -Append -Encoding utf8
}

# --- Header ---------------------------------------------------------------------
$startTime = Get-Date
$now = (Get-Date).ToUniversalTime().ToString('o')

Write-Host ''
Write-Host '=============================================' -ForegroundColor Cyan
Write-Host ' Agent Backend (API Architect) L2'           -ForegroundColor Cyan
Write-Host " Action : $Action"                           -ForegroundColor Cyan
Write-Host '=============================================' -ForegroundColor Cyan
Write-Host ''

# --- Execution ------------------------------------------------------------------
try {
    $Result = $null

    switch ($Action) {

        # ==========================================================================
        # ACTION: api:health-check (deterministic - no LLM)
        # ==========================================================================
        'api:health-check' {
            Write-Host '[1/1] Checking portal-api availability...' -ForegroundColor Yellow

            $status = 'ok'
            $details = [System.Collections.Generic.List[string]]::new()

            $nodeAvailable = $null -ne (Get-Command node -ErrorAction SilentlyContinue)
            $npmAvailable  = $null -ne (Get-Command npm -ErrorAction SilentlyContinue)

            if (-not $nodeAvailable) {
                $status = 'degraded'
                $details.Add('node not found in PATH')
                Write-Warning '[Backend] node not found in PATH; API checks limited'
            }
            if (-not $npmAvailable) {
                if ($status -ne 'degraded') { $status = 'degraded' }
                $details.Add('npm not found in PATH')
            }

            $pkgJsonPath = Join-Path $RepoRoot 'portal-api' 'package.json'
            $pkgExists = Test-Path $pkgJsonPath
            if (-not $pkgExists) {
                $status = 'degraded'
                $details.Add('portal-api/package.json not found')
                Write-Warning '[Backend] portal-api/package.json not found'
            }

            $openApiExists = Test-Path $resolvedApiPath
            if (-not $openApiExists) {
                if ($status -eq 'ok') { $status = 'degraded' }
                $details.Add("openapi.yaml not found at: $resolvedApiPath")
            }

            $detail = if ($details.Count -gt 0) { $details -join '; ' }
                      else { "portal-api stack available: node=$nodeAvailable, npm=$npmAvailable, pkg=$pkgExists, openapi=$openApiExists" }

            $durationSec = [Math]::Round(((Get-Date) - $startTime).TotalSeconds, 2)
            Write-Host "[1/1] Done. Status: $status" -ForegroundColor $(if ($status -eq 'ok') { 'Green' } else { 'Yellow' })

            $Result = [ordered]@{
                action         = $Action
                ok             = ($status -ne 'error')
                status         = $status
                dependency     = 'portal-api'
                openapi_path   = $resolvedApiPath
                detail         = $detail
                dryRun         = $DryRun.IsPresent
                meta           = [ordered]@{
                    node_available   = $nodeAvailable
                    npm_available    = $npmAvailable
                    pkg_json_exists  = $pkgExists
                    openapi_exists   = $openApiExists
                    duration_sec     = $durationSec
                }
                startedAt       = $now
                finishedAt      = (Get-Date).ToUniversalTime().ToString('o')
                contractId      = 'action-result'
                contractVersion = '1.0'
            }
        }

        # ==========================================================================
        # ACTION: api:openapi-validate (LLM + RAG)
        # ==========================================================================
        'api:openapi-validate' {
            if (-not (Test-Path $LLMWithRAG)) {
                Write-Error "Invoke-LLMWithRAG.ps1 not found at: $LLMWithRAG"
                exit 1
            }
            if (-not $ApiKey) {
                Write-Error 'DEEPSEEK_API_KEY not set. Add to /opt/easyway/.env.secrets or pass -ApiKey.'
                exit 1
            }

            . $LLMWithRAG

            # Load openapi.yaml (best-effort)
            $openApiContent = ''
            $pathsCount = 0
            if (Test-Path $resolvedApiPath) {
                $openApiContent = Get-Content $resolvedApiPath -Raw -Encoding UTF8
                # Count paths (heuristic: lines starting with "  /")
                $pathsCount = ([regex]::Matches($openApiContent, '(?m)^  /\S')).Count
            }

            Write-Host "[1/2] Validating OpenAPI spec ($pathsCount paths)..." -ForegroundColor Yellow

            $query = @"
Valida l'OpenAPI spec EasyWay e riporta le violazioni.

Percorso spec: $resolvedApiPath
Path count: $pathsCount

Spec (estratto, primi 150 righe):
$(($openApiContent -split "`n" | Select-Object -First 150) -join "`n")

Analizza:
1. Ogni path ha operationId? (required per code-gen)
2. Ogni endpoint protetto ha il security scheme BearerAuth?
3. Request/response schemas sono definiti per tutti i path?
4. Breaking changes potenziali rispetto a v0.x (endpoint rimossi, tipi cambiati)?
5. Auth coverage percentuale?

Genera JSON api:openapi-validate con:
- 'violations': array di {path, issue, severity (HIGH/MEDIUM/LOW), fix}
- 'auth_coverage_pct': percentuale endpoint con auth (0-100)
- 'breaking_changes': array di {path, type, description}
- 'compliant_count': numero endpoint conformi
- 'summary': valutazione breve
- 'confidence': 0.0-1.0
"@

            $invokeParams = @{
                Query        = $query
                AgentId      = 'agent_backend'
                SystemPrompt = (Get-Content $PromptsFile -Raw -Encoding UTF8)
                TopK         = $TopK
                SecureMode   = $true
                MaxTokens    = 1400
            }

            $llmResult = Invoke-LLMWithRAG @invokeParams
            if (-not $llmResult.Success) { throw "LLM call failed: $($llmResult.Error)" }

            $json = ($llmResult.Answer -replace '(?s)```json\s*', '' -replace '(?s)```\s*', '').Trim()
            try { $parsed = $json | ConvertFrom-Json }
            catch {
                $parsed = [PSCustomObject]@{
                    violations = @(); confidence = 0.5; summary = 'Parse error'
                    auth_coverage_pct = 0; breaking_changes = @(); compliant_count = 0
                }
            }

            $confidence = if ($parsed.PSObject.Properties['confidence']) { [double]$parsed.confidence } else { 0.5 }
            $durationSec = [Math]::Round(((Get-Date) - $startTime).TotalSeconds, 2)

            Write-Host "[2/2] Done. Paths: $pathsCount | Confidence: $confidence" -ForegroundColor Green

            $Result = [ordered]@{
                action                = $Action
                ok                    = $true
                paths_count           = $pathsCount
                violations_found      = if ($parsed.PSObject.Properties['violations']) { @($parsed.violations).Count } else { 0 }
                auth_coverage_pct     = if ($parsed.PSObject.Properties['auth_coverage_pct']) { [int]$parsed.auth_coverage_pct } else { 0 }
                breaking_changes      = if ($parsed.PSObject.Properties['breaking_changes']) { @($parsed.breaking_changes) } else { @() }
                confidence            = $confidence
                requires_human_review = ($confidence -lt 0.80)
                summary               = if ($parsed.PSObject.Properties['summary']) { $parsed.summary } else { 'OpenAPI validation completata.' }
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

    Write-AgentLog -EventData @{ success = $true; agent = 'agent_backend'; action = $Action; result = $Result }
    $Result | ConvertTo-Json -Depth 10 | Write-Output

} catch {
    $errMsg = $_.Exception.Message
    Write-Error "Backend Agent Error: $errMsg"
    Write-AgentLog -EventData @{ success = $false; error = $errMsg }
    exit 1
}
