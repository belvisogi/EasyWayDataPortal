#Requires -Version 5.1
<#
.SYNOPSIS
    Level 3 runner for agent_security (The Elite Security Engineer).

.DESCRIPTION
    Implements the L3 pattern: Evaluator-Optimizer + dual CVE scanning + Working Memory.

    Gap 1 - Evaluator-Optimizer: activated on security:analyze and security:owasp-check
            via -EnableEvaluator with AC-04/05/07 predicates.
    Gap 2 - Working Memory: session.json tracks audit state across steps.
    Gap 3 - CVE scanning: docker-scout + trivy run sequentially when ScanTarget is provided.

    Actions:
      security:analyze        - AI threat assessment (L3: Evaluator-Optimizer, CVE scan, session)
      security:owasp-check    - OWASP Top 10 evaluation (L3: Evaluator-Optimizer)
      kv-secret:set           - Set/update secret in Azure Key Vault (scripted)
      kv-secret:reference     - Generate Key Vault reference string (scripted)
      access-registry:propose - Propose access registry entry (scripted)

.PARAMETER Action
    Action to perform. Default: security:analyze.

.PARAMETER Query
    Analysis context for LLM-based actions.

.PARAMETER ScanTarget
    Docker image name for dual CVE scan (docker-scout + trivy). Optional.

.PARAMETER SessionFile
    Optional path to an existing session JSON. If empty, a new session is created
    for security:analyze.

.PARAMETER NoEvaluator
    Disable the Evaluator-Optimizer loop (single-shot generation).

.EXAMPLE
    pwsh Invoke-AgentSecurity.ps1 -Query "Analyze: Qdrant 6333 no auth, MinIO 9000 exposed"
    pwsh Invoke-AgentSecurity.ps1 -Query "OWASP check on portal API" -Action security:owasp-check
    pwsh Invoke-AgentSecurity.ps1 -Query "..." -ScanTarget "easyway-runner:latest" -JsonOutput

.NOTES
    Evolution Level: 3 (LLM + RAG + Evaluator-Optimizer + Working Memory + CVE Scan)
    Session 13 - agent_security L3 promotion
    Confidence threshold: 0.70 (below => requires_human_review = true)
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [ValidateSet('security:analyze', 'security:owasp-check', 'kv-secret:set', 'kv-secret:reference', 'access-registry:propose')]
    [string]$Action = 'security:analyze',

    [Parameter(Mandatory = $false)] [string]$Query,
    [Parameter(Mandatory = $false)] [string]$ScanTarget,
    [Parameter(Mandatory = $false)] [string]$IntentPath,

    # KV secret params (scripted actions)
    [Parameter(Mandatory = $false)] [string]$VaultName,
    [Parameter(Mandatory = $false)] [string]$SecretName,
    [Parameter(Mandatory = $false)] [string]$SecretValue,
    [Parameter(Mandatory = $false)] [hashtable]$Tags,
    [Parameter(Mandatory = $false)] [string]$Version,
    [Parameter(Mandatory = $false)] [pscustomobject]$Access,

    # L3 controls
    [Parameter(Mandatory = $false)] [string]$SessionFile = '',
    [Parameter(Mandatory = $false)] [switch]$NoEvaluator,
    [Parameter(Mandatory = $false)] [ValidateRange(1,5)] [int]$MaxIterations = 2,
    [Parameter(Mandatory = $false)] [int]$TopK = 5,

    # Operational flags
    [Parameter(Mandatory = $false)] [string]$ApiKey = $env:DEEPSEEK_API_KEY,
    [switch]$WhatIf,
    [bool]$LogEvent = $true,
    [switch]$JsonOutput
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ─── Constants ─────────────────────────────────────────────────────────────────
$CONFIDENCE_THRESHOLD = 0.70
$KV_NAME_PATTERN      = '^[a-z0-9]+-{2}[a-z0-9]+-{2}[a-z0-9]+$'

# ─── Paths ─────────────────────────────────────────────────────────────────────
$AgentDir     = $PSScriptRoot
$SkillsDir    = Join-Path $AgentDir '..' 'skills'
$LLMWithRAG   = Join-Path $SkillsDir 'retrieval' 'Invoke-LLMWithRAG.ps1'
$SessionSkill = Join-Path $SkillsDir 'session'   'Manage-AgentSession.ps1'
$CVEScanSkill = Join-Path $SkillsDir 'security'  'Invoke-CVEScan.ps1'
$PromptsFile  = Join-Path $AgentDir  'PROMPTS.md'

foreach ($required in @($LLMWithRAG, $PromptsFile)) {
    if (-not (Test-Path $required)) {
        Write-Error "Required file not found: $required"
        exit 1
    }
}

# ─── Injection patterns (PS-level defense in depth) ────────────────────────────
$InjectionPatterns = @(
    '(?i)ignore\s+(all\s+)?(previous\s+)?instructions?',
    '(?i)override\s+(rules?|system|prompt)',
    '(?i)you\s+are\s+now\s+',
    '(?i)forget\s+(everything|all(\s+previous)?)',
    '(?i)new\s+(mission|instructions?)\s*:',
    '(?i)pretend\s+you\s+are',
    '(?i)disregard\s+(previous|instructions?)'
)

# ─── Helper functions ──────────────────────────────────────────────────────────
function Read-Intent($path) {
    if (-not $path) { return $null }
    if (-not (Test-Path $path)) { throw "Intent file not found: $path" }
    (Get-Content -Raw -Path $path) | ConvertFrom-Json
}

function Test-Injection([string]$text) {
    foreach ($pattern in $InjectionPatterns) {
        if ($text -match $pattern) { return $Matches[0] }
    }
    return $null
}

function Build-SecretUri([string]$vaultName, [string]$secretName, [string]$version) {
    $base = "https://$vaultName.vault.azure.net/secrets/$secretName"
    if ($version) { return "$base/$version" }
    return $base
}

function Get-KVReference([string]$secretUri) { return "@Microsoft.KeyVault(SecretUri=$secretUri)" }

function Get-SecurityOutput([string]$raw) {
    $json = ($raw -replace '(?s)```json\s*', '' -replace '(?s)```\s*', '').Trim()
    try {
        return $json | ConvertFrom-Json
    } catch {
        return [PSCustomObject]@{
            status                = 'WARNING'
            risk_level            = 'MEDIUM'
            confidence            = 0.5
            requires_human_review = $true
            findings              = @()
            summary               = $raw.Substring(0, [Math]::Min(500, $raw.Length))
            parse_error           = $true
        }
    }
}

function Write-AgentLog {
    param($EventData)
    if (-not $LogEvent) { return }
    $logDir = Join-Path $AgentDir '..\..\..' 'agents' 'logs'
    if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir -Force | Out-Null }
    $entry = [ordered]@{ timestamp = (Get-Date).ToString('o'); agent = 'agent_security'; data = $EventData }
    ($entry | ConvertTo-Json -Depth 5) | Out-File (Join-Path $logDir 'agent-history.jsonl') -Append -Encoding utf8
}

function Out-Result($obj) {
    if ($JsonOutput) { $obj | ConvertTo-Json -Depth 10 | Write-Output }
    else { $obj | ConvertTo-Json -Depth 5 | Write-Output }
}

# ─── Init ──────────────────────────────────────────────────────────────────────
$intent = Read-Intent $IntentPath
if ($intent) {
    if ($intent.PSObject.Properties['action'] -and -not $PSBoundParameters.ContainsKey('Action')) { $Action = $intent.action }
    $p = if ($intent.PSObject.Properties['params']) { $intent.params } else { [PSCustomObject]@{} }
    if (-not $Query      -and $p.PSObject.Properties['query'])       { $Query      = $p.query }
    if (-not $ScanTarget -and $p.PSObject.Properties['scan_target']) { $ScanTarget = $p.scan_target }
    if (-not $VaultName  -and $p.PSObject.Properties['vaultName'])   { $VaultName  = $p.vaultName }
    if (-not $SecretName -and $p.PSObject.Properties['secretName'])  { $SecretName = $p.secretName }
    if (-not $SecretValue -and $p.PSObject.Properties['secretValue']) { $SecretValue = $p.secretValue }
    if (-not $Version    -and $p.PSObject.Properties['version'])     { $Version    = $p.version }
    if (-not $Access     -and $p.PSObject.Properties['access'])      { $Access     = $p.access }
}

$now       = (Get-Date).ToUniversalTime().ToString('o')
$startTime = Get-Date
$llmActions = @('security:analyze', 'security:owasp-check')

# ─── Header ────────────────────────────────────────────────────────────────────
Write-Host ''
Write-Host '=============================================' -ForegroundColor Cyan
Write-Host ' Agent Security (Elite Security Engineer) L3' -ForegroundColor Cyan
Write-Host " Action   : $Action"                          -ForegroundColor Cyan
if ($Action -in $llmActions) {
    Write-Host " Evaluator: $(-not $NoEvaluator) | MaxIter: $MaxIterations" -ForegroundColor Cyan
    if ($ScanTarget) { Write-Host " ScanTarget: $ScanTarget" -ForegroundColor Cyan }
}
Write-Host '=============================================' -ForegroundColor Cyan
Write-Host ''

# ─── Execution ─────────────────────────────────────────────────────────────────
try {
    $Result = $null

    switch ($Action) {

        # ── LLM actions: security:analyze + security:owasp-check ─────────────
        { $_ -in $llmActions } {

            # 0. Injection check (PS-level defense in depth)
            if ($Query) {
                $injMatch = Test-Injection -text $Query
                if ($injMatch) {
                    $Result = [ordered]@{
                        action       = $Action
                        ok           = $false
                        status       = 'SECURITY_VIOLATION'
                        reason       = "Injection pattern detected: '$injMatch'"
                        action_taken = 'REJECT'
                    }
                    Write-AgentLog -EventData @{ success = $false; security_violation = $true; pattern = $injMatch }
                    Out-Result $Result
                    exit 0
                }
            }
            if ([string]::IsNullOrWhiteSpace($Query)) { throw "Query required for action '$Action'" }

            # 1. Load system prompt
            $systemPrompt = Get-Content $PromptsFile -Raw -Encoding UTF8

            # 2. Session start (security:analyze only, non-blocking)
            $sessionCreated = $false
            $activeSession  = $SessionFile
            if ($Action -eq 'security:analyze' -and (Test-Path $SessionSkill)) {
                try {
                    $sessionResult  = & $SessionSkill -Operation New -AgentId 'agent_security' -Intent $Action
                    $activeSession  = $sessionResult.SessionFile
                    $sessionCreated = $true
                    Write-Host "[Session] Started: $activeSession" -ForegroundColor DarkGray
                } catch {
                    Write-Warning "[Session] Could not start (non-blocking): $_"
                }
            }

            # 3. CVE scan block (when ScanTarget provided, security:analyze only)
            $cveResults  = @{}
            $cveJobCount = 0
            $cveContext  = ''
            if ($Action -eq 'security:analyze' -and $ScanTarget -and (Test-Path $CVEScanSkill)) {
                Write-Host '[1/3] Running dual CVE scan (docker-scout + trivy)...' -ForegroundColor Yellow
                . $CVEScanSkill
                foreach ($scanner in @('docker-scout', 'trivy')) {
                    try {
                        $scan = Invoke-CVEScan -ImageName $ScanTarget -Scanner $scanner -OutputFormat 'object'
                        $cveResults[$scanner] = $scan
                        $cveJobCount++
                        Write-Host "  [$scanner] $($scan.TotalCount) vulns (C:$($scan.Summary.critical) H:$($scan.Summary.high) M:$($scan.Summary.medium))" -ForegroundColor DarkGray
                        $cveContext += "Scanner $scanner`: $($scan.TotalCount) vulnerabilities found (Critical:$($scan.Summary.critical) High:$($scan.Summary.high) Medium:$($scan.Summary.medium) Low:$($scan.Summary.low)). "
                    } catch {
                        Write-Warning "  [$scanner] scan failed (non-blocking): $_"
                        $cveResults[$scanner] = @{ error = $_.Exception.Message }
                        $cveContext += "Scanner $scanner`: scan failed. "
                        $cveJobCount++
                    }
                }
                if ($cveContext) {
                    $Query += "`n`n[CVE_SCAN_RESULTS]`n$($cveContext.Trim())`n[END_CVE_SCAN]"
                }
                if ($sessionCreated -and $activeSession) {
                    try {
                        & $SessionSkill -Operation Update -SessionFile $activeSession `
                            -CompletedStep 'cve-scan' `
                            -StepResult @{ scan_target = $ScanTarget; job_count = $cveJobCount } | Out-Null
                    } catch { Write-Warning '[Session] Update cve-scan failed (non-blocking): $_' }
                }
            }

            # 4. LLM + RAG with Evaluator-Optimizer
            $llmStep = if ($ScanTarget -and $Action -eq 'security:analyze') { '[2/3]' } else { '[1/2]' }
            Write-Host "$llmStep Calling Invoke-LLMWithRAG (Evaluator-Optimizer)..." -ForegroundColor Yellow

            if ($sessionCreated -and $activeSession) {
                try { & $SessionSkill -Operation SetStep -SessionFile $activeSession -StepName 'llm-analysis' | Out-Null } catch { Write-Verbose "Session step tracking failed (non-critical): $_" }
            }

            . $LLMWithRAG

            $acPredicates = @(
                "AC-04: The output JSON must contain 'risk_level' with exactly one of: CRITICAL, HIGH, MEDIUM, LOW, INFO",
                "AC-05: The output JSON must contain a numeric 'confidence' field between 0.0 and 1.0",
                "AC-07: If risk_level is CRITICAL, HIGH, or MEDIUM, 'findings' must be a non-empty array with at least one entry containing severity and description"
            )

            $invokeParams = @{
                Query        = $Query
                AgentId      = 'agent_security'
                SystemPrompt = $systemPrompt
                TopK         = $TopK
                SecureMode   = $true
                MaxTokens    = 1500
            }
            if (-not $NoEvaluator) {
                $invokeParams['EnableEvaluator']    = $true
                $invokeParams['AcceptanceCriteria'] = $acPredicates
                $invokeParams['MaxIterations']      = $MaxIterations
            }
            if ($activeSession -and (Test-Path $activeSession)) {
                $invokeParams['SessionFile'] = $activeSession
            }

            $llmResult = Invoke-LLMWithRAG @invokeParams
            if (-not $llmResult.Success) { throw "LLM call failed: $($llmResult.Error)" }

            # 5. Parse output + confidence gating
            $parsed     = Get-SecurityOutput -raw $llmResult.Answer
            $riskLevel  = if ($parsed.PSObject.Properties['risk_level'])  { [string]$parsed.risk_level } else { 'UNKNOWN' }
            $confidence = if ($parsed.PSObject.Properties['confidence'])  { [double]$parsed.confidence } else { 0.5 }
            $findings   = if ($parsed.PSObject.Properties['findings'])    { $parsed.findings }           else { @() }
            $llmStatus  = if ($parsed.PSObject.Properties['status'])      { [string]$parsed.status }     else { 'WARNING' }
            $summary    = if ($parsed.PSObject.Properties['summary'])     { [string]$parsed.summary }    else { $llmResult.Answer.Substring(0, [Math]::Min(300, $llmResult.Answer.Length)) }

            $requiresHumanReview = $confidence -lt $CONFIDENCE_THRESHOLD
            if ($requiresHumanReview) {
                Write-Host "  [!] Confidence $confidence < $CONFIDENCE_THRESHOLD - escalating to human review" -ForegroundColor Yellow
            }

            # 6. Session close
            if ($sessionCreated -and $activeSession) {
                try {
                    & $SessionSkill -Operation Update -SessionFile $activeSession `
                        -CompletedStep 'llm-analysis' `
                        -StepResult @{ risk_level = $riskLevel; confidence = $confidence; escalated = $requiresHumanReview } `
                        -Confidence $confidence | Out-Null
                    & $SessionSkill -Operation Close -SessionFile $activeSession | Out-Null
                } catch { Write-Warning '[Session] Close failed (non-blocking): $_' }
            }

            $durationSec = [Math]::Round(((Get-Date) - $startTime).TotalSeconds, 2)
            $llmStep2    = if ($ScanTarget -and $Action -eq 'security:analyze') { '[3/3]' } else { '[2/2]' }
            Write-Host "$llmStep2 Analysis complete. Risk: $riskLevel | Confidence: $confidence" -ForegroundColor Green

            $parallelScanMeta = $null
            if ($Action -eq 'security:analyze' -and $ScanTarget) {
                $parallelScanMeta = [ordered]@{
                    scan_target   = $ScanTarget
                    job_count     = $cveJobCount
                    scanners_used = @('docker-scout', 'trivy')
                }
            }

            $Result = [ordered]@{
                action                = $Action
                ok                    = $true
                status                = $llmStatus
                risk_level            = $riskLevel
                confidence            = $confidence
                requires_human_review = $requiresHumanReview
                findings              = $findings
                summary               = $summary
                meta                  = [ordered]@{
                    evaluator_enabled    = (-not $NoEvaluator)
                    evaluator_iterations = if ($llmResult.PSObject.Properties['EvaluatorIterations']) { $llmResult.EvaluatorIterations } else { 1 }
                    evaluator_passed     = if ($llmResult.PSObject.Properties['EvaluatorPassed'])    { $llmResult.EvaluatorPassed }    else { $true }
                    rag_chunks           = $llmResult.RAGChunks
                    tokens_in            = $llmResult.TokensIn
                    tokens_out           = $llmResult.TokensOut
                    cost_usd             = $llmResult.CostUSD
                    duration_sec         = $durationSec
                    parallel_scan        = $parallelScanMeta
                }
                startedAt             = $now
                finishedAt            = (Get-Date).ToUniversalTime().ToString('o')
            }
        }

        # ── kv-secret:set ─────────────────────────────────────────────────────
        'kv-secret:set' {
            if ([string]::IsNullOrWhiteSpace($VaultName) -or [string]::IsNullOrWhiteSpace($SecretName) -or [string]::IsNullOrWhiteSpace($SecretValue)) {
                throw 'vaultName, secretName, and secretValue are required'
            }
            # AC-08: naming convention check
            if ($SecretName -notmatch $KV_NAME_PATTERN) {
                $Result = [ordered]@{
                    action       = $Action
                    ok           = $false
                    status       = 'ERROR'
                    reason       = "Naming convention violation: '$SecretName' must follow pattern <system>--<area>--<name> (e.g. db--portal--connstring)"
                    action_taken = 'REJECT'
                }
                Write-AgentLog -EventData @{ success = $false; naming_violation = $SecretName }
                Out-Result $Result
                exit 0
            }
            $executed  = $false
            $secretUri = Build-SecretUri -vaultName $VaultName -secretName $SecretName -version $null
            $ref       = Get-KVReference -secretUri $secretUri
            if (-not $WhatIf) {
                if (-not (Get-Command az -ErrorAction SilentlyContinue)) { throw 'az CLI not found in PATH' }
                $azArgs = @('keyvault', 'secret', 'set', '--vault-name', $VaultName, '--name', $SecretName, '--value', $SecretValue)
                if ($Tags) { foreach ($k in $Tags.Keys) { $azArgs += @('--tags', "$k=$($Tags[$k])") } }
                & az @azArgs | Out-Null
                if ($LASTEXITCODE -ne 0) { throw "az keyvault secret set failed (exit $LASTEXITCODE)" }
                $executed = $true
            }
            $Result = [ordered]@{
                action = $Action; ok = $true; status = 'OK'; whatIf = [bool]$WhatIf
                output = [ordered]@{
                    vaultName = $VaultName; secretName = $SecretName; executed = $executed
                    secretUri = $secretUri; appSettingReference = $ref; note = 'Secret value hidden.'
                }
            }
        }

        # ── kv-secret:reference ───────────────────────────────────────────────
        'kv-secret:reference' {
            if ([string]::IsNullOrWhiteSpace($VaultName) -or [string]::IsNullOrWhiteSpace($SecretName)) { throw 'vaultName and secretName required' }
            $secretUri = Build-SecretUri -vaultName $VaultName -secretName $SecretName -version $Version
            $ref = Get-KVReference -secretUri $secretUri
            $Result = [ordered]@{
                action = $Action; ok = $true; status = 'OK'
                output = [ordered]@{ vaultName = $VaultName; secretName = $SecretName; secretUri = $secretUri; appSettingReference = $ref }
            }
        }

        # ── access-registry:propose ───────────────────────────────────────────
        'access-registry:propose' {
            if (-not $Access) { throw 'Access object required' }
            $Result = [ordered]@{
                action = $Action; ok = $true; status = 'OK'
                output = [ordered]@{
                    proposedAccess = $Access
                    targets = [ordered]@{ wiki = 'Wiki/EasyWayData.wiki/security/segreti-e-accessi.md' }
                }
            }
        }

        default { throw "Action '$Action' not implemented." }
    }

    Write-AgentLog -EventData @{ success = $true; agent = 'agent_security'; action = $Action; result = $Result }
    Out-Result $Result

} catch {
    $errMsg = $_.Exception.Message
    Write-Error "Security Error: $errMsg"
    Write-AgentLog -EventData @{ success = $false; error = $errMsg }
    exit 1
}
