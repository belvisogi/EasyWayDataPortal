#Requires -Version 5.1
<#
.SYNOPSIS
    Level 2 runner for agent_frontend (Portal Craftsman).

.DESCRIPTION
    Implements the L2 pattern: LLM + RAG + structured JSON output + Import-AgentSecrets.

    Actions:
      frontend:build-check  - Verifica stato build frontend (deterministic, no LLM)
      frontend:ux-review    - Analizza componenti UI contro linee guida UX via LLM+RAG

.PARAMETER Action
    Action to perform. Default: frontend:build-check.

.PARAMETER FrontendPath
    Percorso custom alla directory frontend. Default: apps/portal-frontend relativo alla repo root.

.PARAMETER DryRun
    Show output without writing files.

.EXAMPLE
    pwsh agents/agent_frontend/Invoke-AgentFrontend.ps1 -Action frontend:build-check
    pwsh agents/agent_frontend/Invoke-AgentFrontend.ps1 -Action frontend:ux-review -DryRun

.NOTES
    Evolution Level: 2 (LLM + RAG + structured JSON output)
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [ValidateSet('frontend:build-check', 'frontend:ux-review')]
    [string]$Action = 'frontend:build-check',

    [Parameter(Mandatory = $false)] [string]$FrontendPath = '',
    [Parameter(Mandatory = $false)] [string]$ApiKey = $env:DEEPSEEK_API_KEY,
    [Parameter(Mandatory = $false)] [int]$TopK = 5,
    [Parameter(Mandatory = $false)] [switch]$DryRun,
    [Parameter(Mandatory = $false)] [bool]$LogEvent = $true
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# --- Paths ----------------------------------------------------------------------
$AgentDir    = $PSScriptRoot
$RepoRoot    = (Get-Item $AgentDir).Parent.Parent.FullName
$SkillsDir   = Join-Path $AgentDir '..' 'skills'
$LLMWithRAG  = Join-Path $SkillsDir 'retrieval' 'Invoke-LLMWithRAG.ps1'
$PromptsFile = Join-Path $AgentDir 'PROMPTS.md'

if (-not (Test-Path $PromptsFile)) {
    Write-Error "Required file not found: $PromptsFile"
    exit 1
}

# Resolve frontend path
$resolvedFrontendPath = if ($FrontendPath) { $FrontendPath }
                        else { Join-Path $RepoRoot 'apps' 'portal-frontend' }

# --- Bootstrap: load platform secrets -------------------------------------------
$importSecretsSkill = Join-Path $SkillsDir 'utilities' 'Import-AgentSecrets.ps1'
if (Test-Path $importSecretsSkill) {
    . $importSecretsSkill
    Import-AgentSecrets -AgentId 'agent_frontend' | Out-Null
}
if (-not $ApiKey) { $ApiKey = $env:DEEPSEEK_API_KEY }

function Write-AgentLog {
    param($EventData)
    if (-not $LogEvent) { return }
    $logDir = Join-Path $AgentDir '..' 'logs'
    if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir -Force | Out-Null }
    $entry = [ordered]@{ timestamp = (Get-Date).ToString('o'); agent = 'agent_frontend'; data = $EventData }
    ($entry | ConvertTo-Json -Depth 5) | Out-File (Join-Path $logDir 'agent-history.jsonl') -Append -Encoding utf8
}

# --- Header ---------------------------------------------------------------------
$startTime = Get-Date
$now = (Get-Date).ToUniversalTime().ToString('o')

Write-Host ''
Write-Host '=============================================' -ForegroundColor Cyan
Write-Host ' Agent Frontend (Portal Craftsman) L2'       -ForegroundColor Cyan
Write-Host " Action : $Action"                           -ForegroundColor Cyan
Write-Host '=============================================' -ForegroundColor Cyan
Write-Host ''

# --- Execution ------------------------------------------------------------------
try {
    $Result = $null

    switch ($Action) {

        # ==========================================================================
        # ACTION: frontend:build-check (deterministic - no LLM)
        # ==========================================================================
        'frontend:build-check' {
            Write-Host '[1/1] Checking frontend build state...' -ForegroundColor Yellow

            $status  = 'ok'
            $details = [System.Collections.Generic.List[string]]::new()

            $nodeAvailable = $null -ne (Get-Command node -ErrorAction SilentlyContinue)
            $npmAvailable  = $null -ne (Get-Command npm  -ErrorAction SilentlyContinue)

            if (-not $nodeAvailable) {
                $status = 'degraded'
                $details.Add('node not found in PATH')
            }

            $pkgJsonPath = Join-Path $resolvedFrontendPath 'package.json'
            $pkgExists   = Test-Path $pkgJsonPath

            $srcPath     = Join-Path $resolvedFrontendPath 'src'
            $srcExists   = Test-Path $srcPath

            # Count source files
            $sourceFiles = @()
            if ($srcExists) {
                $sourceFiles = Get-ChildItem $srcPath -Recurse -Include '*.ts','*.tsx','*.js','*.jsx','*.vue' -ErrorAction SilentlyContinue
            }
            $sourceCount = $sourceFiles.Count

            # Check for dist/build artifacts
            $distPath      = Join-Path $resolvedFrontendPath 'dist'
            $distExists    = Test-Path $distPath
            $distFileCount = if ($distExists) { (Get-ChildItem $distPath -Recurse -File -ErrorAction SilentlyContinue).Count } else { 0 }

            if (-not $pkgExists) {
                $status = 'degraded'
                $details.Add('package.json not found')
            }
            if (-not $srcExists) {
                $status = 'degraded'
                $details.Add('src/ directory not found')
            }
            if (-not $distExists) {
                if ($status -eq 'ok') { $status = 'degraded' }
                $details.Add('dist/ not found (build not executed)')
            }

            $detail = if ($details.Count -gt 0) { $details -join '; ' }
                      else { "Frontend stack OK: src=$sourceCount files, dist=$distFileCount artifacts" }

            $durationSec = [Math]::Round(((Get-Date) - $startTime).TotalSeconds, 2)
            Write-Host "[1/1] Done. Status: $status (src=$sourceCount files, dist=$distFileCount artifacts)" `
                -ForegroundColor $(if ($status -eq 'ok') { 'Green' } else { 'Yellow' })

            $Result = [ordered]@{
                action              = $Action
                ok                  = ($status -ne 'error')
                status              = $status
                dependency          = 'portal-frontend'
                source_files_count  = $sourceCount
                build_artifacts     = $distFileCount
                build_dir_exists    = $distExists
                detail              = $detail
                dryRun              = $DryRun.IsPresent
                meta                = [ordered]@{
                    node_available  = $nodeAvailable
                    npm_available   = $npmAvailable
                    pkg_json_exists = $pkgExists
                    src_exists      = $srcExists
                    frontend_path   = $resolvedFrontendPath
                    duration_sec    = $durationSec
                }
                startedAt           = $now
                finishedAt          = (Get-Date).ToUniversalTime().ToString('o')
                contractId          = 'action-result'
                contractVersion     = '1.0'
            }
        }

        # ==========================================================================
        # ACTION: frontend:ux-review (LLM + RAG)
        # ==========================================================================
        'frontend:ux-review' {
            if (-not (Test-Path $LLMWithRAG)) {
                Write-Error "Invoke-LLMWithRAG.ps1 not found at: $LLMWithRAG"
                exit 1
            }
            if (-not $ApiKey) {
                Write-Error 'DEEPSEEK_API_KEY not set. Add to /opt/easyway/.env.secrets or pass -ApiKey.'
                exit 1
            }

            . $LLMWithRAG

            # Scan component files (first 15)
            $srcPath = Join-Path $resolvedFrontendPath 'src'
            $componentFiles = @()
            if (Test-Path $srcPath) {
                $componentFiles = Get-ChildItem $srcPath -Recurse `
                    -Include '*.ts','*.tsx','*.js','*.jsx','*.vue' -ErrorAction SilentlyContinue |
                    Select-Object -First 15
            }
            $componentCount = $componentFiles.Count

            # Build sample of file names + first 30 lines each
            $componentSample = if ($componentCount -gt 0) {
                ($componentFiles | ForEach-Object {
                    $lines = (Get-Content $_.FullName -TotalCount 30 -Encoding UTF8 -ErrorAction SilentlyContinue) -join "`n"
                    "=== $($_.Name) ===`n$lines"
                }) -join "`n`n"
            } else { '(no component files found)' }

            Write-Host "[1/2] Reviewing $componentCount frontend components for UX issues..." -ForegroundColor Yellow

            $query = @"
Analizza i componenti frontend EasyWay per problemi UX, accessibilita' e pattern.

Frontend path: $resolvedFrontendPath
Componenti trovati: $componentCount

Estratto componenti (primi $componentCount file):
$($componentSample | Select-Object -First 200)

Valuta:
1. Accessibilita' WCAG: aria-label, role, keyboard navigation
2. Responsive design: breakpoint handling, mobile viewports
3. Riutilizzo componenti: duplicazioni evidenti
4. Performance: import non necessari, bundle size red flags
5. Feature flags: uso corretto di window.SOVEREIGN_CONFIG

Genera JSON frontend:ux-review con:
- 'issues': array di {component, category (accessibility/performance/pattern/responsiveness), severity (HIGH/MEDIUM/LOW), description, fix}
- 'compliant_count': componenti senza problemi rilevati
- 'summary': valutazione complessiva
- 'confidence': 0.0-1.0
"@

            $invokeParams = @{
                Query        = $query
                AgentId      = 'agent_frontend'
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
                    issues = @(); confidence = 0.5; summary = 'Parse error'; compliant_count = 0
                }
            }

            $confidence = if ($parsed.PSObject.Properties['confidence']) { [double]$parsed.confidence } else { 0.5 }
            $durationSec = [Math]::Round(((Get-Date) - $startTime).TotalSeconds, 2)

            Write-Host "[2/2] Done. Components: $componentCount | Confidence: $confidence" -ForegroundColor Green

            $Result = [ordered]@{
                action                = $Action
                ok                    = $true
                components_reviewed   = $componentCount
                issues_found          = if ($parsed.PSObject.Properties['issues']) { @($parsed.issues).Count } else { 0 }
                confidence            = $confidence
                requires_human_review = ($confidence -lt 0.80)
                summary               = if ($parsed.PSObject.Properties['summary']) { $parsed.summary } else { 'UX review completata.' }
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

    Write-AgentLog -EventData @{ success = $true; agent = 'agent_frontend'; action = $Action; result = $Result }
    $Result | ConvertTo-Json -Depth 10 | Write-Output

} catch {
    $errMsg = $_.Exception.Message
    Write-Error "Frontend Agent Error: $errMsg"
    Write-AgentLog -EventData @{ success = $false; error = $errMsg }
    exit 1
}
