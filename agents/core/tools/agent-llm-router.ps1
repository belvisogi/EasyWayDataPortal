param(
    [ValidateSet("invoke", "request-approval", "approve", "reject", "status")]
    [string]$Action = "invoke",
    [string]$Prompt = "",
    [string]$TaskType = "generic",
    [ValidateSet("none", "push", "merge", "delete", "force")]
    [string]$CriticalAction = "none",
    [string]$AgentId = "",
    [string]$RagEvidenceId = "",
    [string]$ApprovalId = "",
    [string]$Approver = "",
    [string]$ConfigPath = ".\scripts\pwsh\llm-router.config.ps1",
    [string]$StatePath = "docs/ops/llm-router-state.json",
    [string]$EventLogPath = "docs/ops/logs/llm-router-events.jsonl",
    [string]$ApprovalDir = "docs/ops/approvals",
    [switch]$BypassRagEvidence,
    [switch]$JsonOutput,
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"

function Ensure-Dir {
    param([string]$Path)
    if (-not [string]::IsNullOrWhiteSpace($Path) -and -not (Test-Path -LiteralPath $Path)) {
        New-Item -ItemType Directory -Path $Path -Force | Out-Null
    }
}

function Load-Config {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) {
        throw "Config not found: $Path (copy llm-router.config.example.ps1)"
    }
    $cfg = & $Path
    if ($null -eq $cfg) {
        throw "Invalid config file: $Path"
    }
    if ($cfg.ContainsKey("Providers")) {
        $cfg.Providers = @($cfg.Providers | ForEach-Object {
                if ($_ -is [hashtable]) { [PSCustomObject]$_ } else { $_ }
            })
    }
    return $cfg
}

function New-RunId {
    return ("run-{0}-{1}" -f (Get-Date -Format "yyyyMMddHHmmss"), ([guid]::NewGuid().ToString("N").Substring(0, 10)))
}

function Write-Event {
    param([hashtable]$EventObj, [string]$Path)
    $dir = Split-Path -Parent $Path
    Ensure-Dir -Path $dir
    ($EventObj | ConvertTo-Json -Depth 12 -Compress) | Add-Content -Path $Path -Encoding utf8
}

function Get-State {
    param([string]$Path, $Providers)
    $dir = Split-Path -Parent $Path
    Ensure-Dir -Path $dir

    if (-not (Test-Path -LiteralPath $Path)) {
        $obj = @{
            providers = @{}
            updatedAt = (Get-Date).ToString("o")
        }
        foreach ($p in $Providers) {
            $obj.providers[$p.name] = @{
                failureCount = 0
                circuitUntil = $null
                lastError    = $null
                lastSuccess  = $null
            }
        }
        $obj | ConvertTo-Json -Depth 12 | Set-Content -Path $Path -Encoding utf8
    }

    $state = Get-Content -Path $Path -Raw | ConvertFrom-Json -AsHashtable
    foreach ($p in $Providers) {
        if (-not $state.providers.ContainsKey($p.name)) {
            $state.providers[$p.name] = @{
                failureCount = 0
                circuitUntil = $null
                lastError    = $null
                lastSuccess  = $null
            }
        }
    }
    return $state
}

function Save-State {
    param($State, [string]$Path)
    $State.updatedAt = (Get-Date).ToString("o")
    $State | ConvertTo-Json -Depth 12 | Set-Content -Path $Path -Encoding utf8
}

function Get-ProviderCandidates {
    param($Config, $State)
    $now = Get-Date
    $enabled = @($Config.Providers | Where-Object { $_.enabled } | Sort-Object priority)
    $candidates = @()
    foreach ($p in $enabled) {
        $ps = $State.providers[$p.name]
        $circuitOpen = $false
        if ($ps.circuitUntil) {
            $until = [datetime]$ps.circuitUntil
            if ($until -gt $now) {
                $circuitOpen = $true
            }
        }
        if (-not $circuitOpen) {
            $candidates += $p
        }
    }
    return $candidates
}

function Get-ResponseText {
    param([string]$ApiStyle, $Raw)
    switch ($ApiStyle) {
        "openai_responses" {
            if ($Raw.output_text) { return [string]$Raw.output_text }
            if ($Raw.output -and $Raw.output.Count -gt 0) {
                $parts = @()
                foreach ($o in $Raw.output) {
                    if ($o.content) {
                        foreach ($c in $o.content) {
                            if ($c.text) { $parts += [string]$c.text }
                        }
                    }
                }
                return ($parts -join "`n").Trim()
            }
            return ""
        }
        "anthropic_messages" {
            if ($Raw.content -and $Raw.content.Count -gt 0) {
                $parts = @($Raw.content | ForEach-Object { $_.text } | Where-Object { $_ })
                return ($parts -join "`n").Trim()
            }
            return ""
        }
        "ollama_generate" {
            if ($Raw.response) { return [string]$Raw.response }
            return ""
        }
        default {
            return [string]$Raw
        }
    }
}

function Invoke-Provider {
    param(
        $Provider,
        [string]$PromptText,
        [string]$TaskKind,
        [string]$Agent,
        [switch]$PlanOnly
    )

    if ($Provider.mode -eq "mock" -or $PlanOnly) {
        return @{
            provider    = $Provider.name
            model       = $Provider.model
            output      = "[mock/$($Provider.name)] task=$TaskKind agent=$Agent prompt='$PromptText'"
            rawResponse = @{
                mode = "mock"
            }
        }
    }

    if ($Provider.mode -ne "rest") {
        throw "Unsupported provider mode '$($Provider.mode)' for provider '$($Provider.name)'"
    }

    $headers = @{}
    $apiKey = ""
    if ($Provider.apiKeyEnv) {
        $apiKey = [Environment]::GetEnvironmentVariable([string]$Provider.apiKeyEnv)
    }

    $body = $null
    switch ($Provider.apiStyle) {
        "openai_responses" {
            if ([string]::IsNullOrWhiteSpace($apiKey)) { throw "Missing API key env: $($Provider.apiKeyEnv)" }
            $headers["Authorization"] = "Bearer $apiKey"
            $body = @{
                model = $Provider.model
                input = $PromptText
            }
        }
        "anthropic_messages" {
            if ([string]::IsNullOrWhiteSpace($apiKey)) { throw "Missing API key env: $($Provider.apiKeyEnv)" }
            $headers["x-api-key"] = $apiKey
            $headers["anthropic-version"] = "2023-06-01"
            $body = @{
                model = $Provider.model
                max_tokens = 800
                messages = @(
                    @{
                        role = "user"
                        content = $PromptText
                    }
                )
            }
        }
        "ollama_generate" {
            $body = @{
                model = $Provider.model
                prompt = $PromptText
                stream = $false
            }
        }
        default {
            throw "Unsupported apiStyle '$($Provider.apiStyle)'"
        }
    }

    $jsonBody = $body | ConvertTo-Json -Depth 20
    $timeoutSec = if ($Provider.timeoutSec) { [int]$Provider.timeoutSec } else { 45 }
    $raw = Invoke-RestMethod -Method Post -Uri $Provider.endpoint -Headers $headers -Body $jsonBody -ContentType "application/json" -TimeoutSec $timeoutSec
    $text = Get-ResponseText -ApiStyle $Provider.apiStyle -Raw $raw

    return @{
        provider    = $Provider.name
        model       = $Provider.model
        output      = $text
        rawResponse = $raw
    }
}

function New-ApprovalRequest {
    param(
        [string]$Dir,
        [string]$RunId,
        [string]$ActionName,
        [string]$PromptText,
        [string]$Agent,
        [string]$TaskKind,
        [string]$RagId
    )
    Ensure-Dir -Path $Dir
    $id = ("apr-{0}-{1}" -f (Get-Date -Format "yyyyMMddHHmmss"), ([guid]::NewGuid().ToString("N").Substring(0, 8)))
    $file = Join-Path $Dir "$id.json"
    $obj = @{
        id             = $id
        runId          = $RunId
        status         = "pending"
        requestedAt    = (Get-Date).ToString("o")
        criticalAction = $ActionName
        taskType       = $TaskKind
        agentId        = $Agent
        ragEvidenceId  = $RagId
        prompt         = $PromptText
    }
    $obj | ConvertTo-Json -Depth 12 | Set-Content -Path $file -Encoding utf8
    return $obj
}

function Get-Approval {
    param([string]$Dir, [string]$Id)
    $file = Join-Path $Dir "$Id.json"
    if (-not (Test-Path -LiteralPath $file)) {
        throw "Approval not found: $file"
    }
    $obj = Get-Content -Path $file -Raw | ConvertFrom-Json -AsHashtable
    return $obj
}

function Save-Approval {
    param([string]$Dir, $Approval)
    $file = Join-Path $Dir "$($Approval.id).json"
    $Approval | ConvertTo-Json -Depth 12 | Set-Content -Path $file -Encoding utf8
}

function Write-OutputObj {
    param($Obj)
    if ($JsonOutput) {
        $Obj | ConvertTo-Json -Depth 12
    } else {
        $Obj
    }
}

$cfg = Load-Config -Path $ConfigPath
$agent = if ([string]::IsNullOrWhiteSpace($AgentId)) { "$env:COMPUTERNAME-$env:USERNAME".ToLower() } else { $AgentId.Trim() }
$runId = New-RunId
$state = Get-State -Path $StatePath -Providers $cfg.Providers
$criticalNeedsApproval = ($cfg.CriticalActionsRequireApproval -contains $CriticalAction)
$requireRag = [bool]$cfg.RequireRagEvidence

switch ($Action) {
    "request-approval" {
        if ($CriticalAction -eq "none") {
            throw "request-approval requires -CriticalAction push|merge|delete|force"
        }
        $approval = New-ApprovalRequest -Dir $ApprovalDir -RunId $runId -ActionName $CriticalAction -PromptText $Prompt -Agent $agent -TaskKind $TaskType -RagId $RagEvidenceId
        Write-Event -Path $EventLogPath -EventObj @{
            timestamp = (Get-Date).ToString("o")
            runId = $runId
            type = "approval_requested"
            approvalId = $approval.id
            criticalAction = $CriticalAction
            taskType = $TaskType
            agentId = $agent
        }
        Write-OutputObj @{
            status = "pending"
            approvalId = $approval.id
            message = "Approval requested."
        }
        break
    }
    "approve" {
        if ([string]::IsNullOrWhiteSpace($ApprovalId)) { throw "approve requires -ApprovalId" }
        if ([string]::IsNullOrWhiteSpace($Approver)) { throw "approve requires -Approver" }
        $approval = Get-Approval -Dir $ApprovalDir -Id $ApprovalId
        $approval.status = "approved"
        $approval.approvedBy = $Approver
        $approval.approvedAt = (Get-Date).ToString("o")
        Save-Approval -Dir $ApprovalDir -Approval $approval
        Write-Event -Path $EventLogPath -EventObj @{
            timestamp = (Get-Date).ToString("o")
            runId = $runId
            type = "approval_granted"
            approvalId = $ApprovalId
            approver = $Approver
        }
        Write-OutputObj @{
            status = "approved"
            approvalId = $ApprovalId
        }
        break
    }
    "reject" {
        if ([string]::IsNullOrWhiteSpace($ApprovalId)) { throw "reject requires -ApprovalId" }
        if ([string]::IsNullOrWhiteSpace($Approver)) { throw "reject requires -Approver" }
        $approval = Get-Approval -Dir $ApprovalDir -Id $ApprovalId
        $approval.status = "rejected"
        $approval.rejectedBy = $Approver
        $approval.rejectedAt = (Get-Date).ToString("o")
        Save-Approval -Dir $ApprovalDir -Approval $approval
        Write-Event -Path $EventLogPath -EventObj @{
            timestamp = (Get-Date).ToString("o")
            runId = $runId
            type = "approval_rejected"
            approvalId = $ApprovalId
            approver = $Approver
        }
        Write-OutputObj @{
            status = "rejected"
            approvalId = $ApprovalId
        }
        break
    }
    "status" {
        Ensure-Dir -Path $ApprovalDir
        $pending = @(
            Get-ChildItem -Path $ApprovalDir -Filter "*.json" -File -ErrorAction SilentlyContinue |
                ForEach-Object { Get-Content $_.FullName -Raw | ConvertFrom-Json -AsHashtable } |
                Where-Object { $_.status -eq "pending" } |
                Sort-Object requestedAt
        )
        $providerStatus = @()
        foreach ($p in $cfg.Providers) {
            $ps = $state.providers[$p.name]
            $providerStatus += @{
                name = $p.name
                enabled = [bool]$p.enabled
                priority = [int]$p.priority
                failureCount = [int]$ps.failureCount
                circuitUntil = $ps.circuitUntil
                lastSuccess = $ps.lastSuccess
                lastError = $ps.lastError
            }
        }
        Write-OutputObj @{
            pendingApprovals = $pending
            providers = $providerStatus
            stateUpdatedAt = $state.updatedAt
        }
        break
    }
    "invoke" {
        if ([string]::IsNullOrWhiteSpace($Prompt)) {
            throw "invoke requires -Prompt"
        }

        if ($requireRag -and -not $BypassRagEvidence -and [string]::IsNullOrWhiteSpace($RagEvidenceId)) {
            Write-Event -Path $EventLogPath -EventObj @{
                timestamp = (Get-Date).ToString("o")
                runId = $runId
                type = "invoke_blocked"
                reason = "missing_rag_evidence"
                agentId = $agent
                taskType = $TaskType
            }
            throw "RAG evidence is required. Provide -RagEvidenceId (or use -BypassRagEvidence for exceptional local tests)."
        }

        if ($criticalNeedsApproval) {
            if ([string]::IsNullOrWhiteSpace($ApprovalId)) {
                $approval = New-ApprovalRequest -Dir $ApprovalDir -RunId $runId -ActionName $CriticalAction -PromptText $Prompt -Agent $agent -TaskKind $TaskType -RagId $RagEvidenceId
                Write-Event -Path $EventLogPath -EventObj @{
                    timestamp = (Get-Date).ToString("o")
                    runId = $runId
                    type = "approval_required"
                    approvalId = $approval.id
                    criticalAction = $CriticalAction
                    agentId = $agent
                    taskType = $TaskType
                }
                Write-OutputObj @{
                    status = "approval_required"
                    approvalId = $approval.id
                    message = "Critical action requires human approval."
                }
                break
            }

            $approval = Get-Approval -Dir $ApprovalDir -Id $ApprovalId
            if ($approval.status -ne "approved") {
                throw "Approval '$ApprovalId' is not approved (status=$($approval.status))."
            }
        }

        $candidates = Get-ProviderCandidates -Config $cfg -State $state
        if ($candidates.Count -eq 0) {
            throw "No provider available (all disabled or circuit-open)."
        }

        $chosen = $candidates[0]
        $providerState = $state.providers[$chosen.name]

        try {
            $result = Invoke-Provider -Provider $chosen -PromptText $Prompt -TaskKind $TaskType -Agent $agent -PlanOnly:$DryRun
            $providerState.failureCount = 0
            $providerState.circuitUntil = $null
            $providerState.lastError = $null
            $providerState.lastSuccess = (Get-Date).ToString("o")
            Save-State -State $state -Path $StatePath

            Write-Event -Path $EventLogPath -EventObj @{
                timestamp = (Get-Date).ToString("o")
                runId = $runId
                type = "invoke_success"
                provider = $result.provider
                model = $result.model
                taskType = $TaskType
                criticalAction = $CriticalAction
                agentId = $agent
                approvalId = $ApprovalId
                ragEvidenceId = $RagEvidenceId
                dryRun = [bool]$DryRun
            }

            Write-OutputObj @{
                status = "ok"
                runId = $runId
                provider = $result.provider
                model = $result.model
                output = $result.output
            }
        }
        catch {
            $providerState.failureCount = [int]$providerState.failureCount + 1
            $providerState.lastError = $_.Exception.Message
            $threshold = if ($chosen.failureThreshold) { [int]$chosen.failureThreshold } else { 3 }
            $cooldown = if ($chosen.cooldownMinutes) { [int]$chosen.cooldownMinutes } else { 5 }
            if ($providerState.failureCount -ge $threshold) {
                $providerState.circuitUntil = (Get-Date).AddMinutes($cooldown).ToString("o")
            }
            Save-State -State $state -Path $StatePath

            Write-Event -Path $EventLogPath -EventObj @{
                timestamp = (Get-Date).ToString("o")
                runId = $runId
                type = "invoke_failed"
                provider = $chosen.name
                model = $chosen.model
                error = $_.Exception.Message
                taskType = $TaskType
                criticalAction = $CriticalAction
                agentId = $agent
            }

            throw
        }
        break
    }
}
