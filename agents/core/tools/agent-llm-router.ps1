param(
    [ValidateSet("invoke", "request-approval", "approve", "reject", "status", "feedback")]
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
    [string]$FeedbackLogPath = "docs/ops/logs/llm-router-feedback.jsonl",
    [string]$ApprovalDir = "docs/ops/approvals",
    [string]$Preference = "",
    [int]$Rating = 0,
    [string]$Comment = "",
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

function Get-ProviderByPreference {
    param($Candidates, $Preference, $Config)
    
    if (-not $Preference -or -not $Config.Profiles) {
        return $Candidates
    }

    if (-not $Config.Profiles.ContainsKey($Preference)) {
        Write-Warning "Preference profile '$Preference' not found. Using default routing."
        return $Candidates
    }

    $profile = $Config.Profiles[$Preference]
    $allowedTags = $profile.allowedTags

    # Filter candidates by tags
    $filtered = @($Candidates | Where-Object {
            $p = $_
            $isFound = $false
            if ($p.tags) {
                foreach ($t in $allowedTags) {
                    if ($p.tags -contains $t) { $isFound = $true; break }
                }
            }
            $isFound
        })

    if ($filtered.Count -eq 0) {
        if ($profile.fallback -eq "block") {
            throw "No providers available for preference '$Preference' (tags: $($allowedTags -join ', ')). Fallback is block."
        }
        Write-Warning "No providers found for preference '$Preference'. Fallback to best effort."
        return $Candidates
    }

    return $filtered
}

function Get-ResponseText {
    param([string]$ApiStyle, $Raw)
    switch ($ApiStyle) {
        "openai_responses" {
            # Handle Chat Completions (choices[0].message.content)
            if ($Raw.choices -and $Raw.choices.Count -gt 0) {
                return [string]$Raw.choices[0].message.content
            }
            # Handle Legacy Completions (output_text or choices[0].text)
            if ($Raw.output_text) { return [string]$Raw.output_text }
            return ""
        }
        "deepseek_chat" {
            if ($Raw.choices -and $Raw.choices.Count -gt 0) {
                return [string]$Raw.choices[0].message.content
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

function Estimate-Cost {
    param($Provider, $PromptText, $OutputText, $RawResponse)
    
    $cost = 0.0
    $inTokens = 0
    $outTokens = 0
    
    # Attempt to extract usage from provider response
    if ($Provider.apiStyle -eq "openai_responses" -and $RawResponse.usage) {
        $inTokens = $RawResponse.usage.prompt_tokens
        $outTokens = $RawResponse.usage.completion_tokens
    } 
    elseif ($Provider.apiStyle -eq "anthropic_messages" -and $RawResponse.usage) {
        $inTokens = $RawResponse.usage.input_tokens
        $outTokens = $RawResponse.usage.output_tokens
    }
    else {
        # Fallback heuristic: 1 token ~= 4 chars
        if ($PromptText) { $inTokens = [Math]::Ceiling($PromptText.Length / 4) }
        if ($OutputText) { $outTokens = [Math]::Ceiling($OutputText.Length / 4) }
    }

    # Rates per 1k tokens
    $rateIn = if ($Provider.costInput) { [double]$Provider.costInput } else { 0.0 }
    $rateOut = if ($Provider.costOutput) { [double]$Provider.costOutput } else { 0.0 }
    
    $cost = ($inTokens / 1000.0 * $rateIn) + ($outTokens / 1000.0 * $rateOut)
    
    return @{
        costUSD   = $cost
        tokensIn  = $inTokens
        tokensOut = $outTokens
        estimated = (-not ($RawResponse.usage))
    }
}

function Invoke-Provider {
    param(
        $Provider,
        [string]$PromptText,
        [string]$TaskKind,
        [string]$Agent,
        [switch]$PlanOnly,
        [array]$Tools
    )

    if ($Provider.mode -eq "mock" -or $PlanOnly) {
        $mockOut = "[mock/$($Provider.name)] task=$TaskKind agent=$Agent prompt='$PromptText'"
        if ($Tools) {
            $mockOut += " (Tools: $($Tools.Count))"
        }
        
        # Mock Tool Call Simulation
        $mockRaw = @{
            usage   = @{ prompt_tokens = 10; completion_tokens = 5 }
            choices = @(
                @{
                    message = @{
                        content = $mockOut
                    }
                }
            )
        }

        if ($PromptText -match "TRIGGER_TOOL:Invoke_SubAgent:(.+):(.+)") {
            $target = $matches[1]
            $prmpt = $matches[2]
            $mockRaw.choices[0].message.tool_calls = @(
                @{
                    function = @{
                        name      = "Invoke_SubAgent"
                        arguments = ('{{"TargetAgent": "{0}", "Prompt": "{1}"}}' -f $target, $prmpt)
                    }
                }
            )
            $mockOut = " Tool Call Triggered" 
        }

        $usage = Estimate-Cost -Provider $Provider -PromptText $PromptText -OutputText $mockOut -RawResponse $mockRaw
        
        return @{
            provider    = $Provider.name
            model       = $Provider.model
            output      = $mockOut
            rawResponse = $mockRaw
            usage       = $usage
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
                model    = $Provider.model
                messages = @(
                    @{ role = "user"; content = $PromptText }
                )
            }
            if ($Tools) { $body.tools = $Tools }
            # DeepSeek/OpenAI compatibility often uses 'messages' not 'input' for chat/completions
        }
        "deepseek_chat" {
            if ([string]::IsNullOrWhiteSpace($apiKey)) { throw "Missing API key env: $($Provider.apiKeyEnv)" }
            $headers["Authorization"] = "Bearer $apiKey"
            $body = @{
                model    = $Provider.model
                messages = @(
                    @{ role = "system"; content = "You are a helpful assistant." },
                    @{ role = "user"; content = $PromptText }
                )
                stream   = $false
            }
            if ($Tools) { $body.tools = $Tools }
        }
        "anthropic_messages" {
            if ([string]::IsNullOrWhiteSpace($apiKey)) { throw "Missing API key env: $($Provider.apiKeyEnv)" }
            $headers["x-api-key"] = $apiKey
            $headers["anthropic-version"] = "2023-06-01"
            $body = @{
                model      = $Provider.model
                max_tokens = 800
                messages   = @(
                    @{
                        role    = "user"
                        content = $PromptText
                    }
                )
            }
        }
        "ollama_generate" {
            $body = @{
                model  = $Provider.model
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
    
    $usage = Estimate-Cost -Provider $Provider -PromptText $PromptText -OutputText $text -RawResponse $raw

    return @{
        provider    = $Provider.name
        model       = $Provider.model
        output      = $text
        rawResponse = $raw
        usage       = $usage
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
    }
    else {
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
            timestamp      = (Get-Date).ToString("o")
            runId          = $runId
            type           = "approval_requested"
            approvalId     = $approval.id
            criticalAction = $CriticalAction
            taskType       = $TaskType
            agentId        = $agent
        }
        Write-OutputObj @{
            status     = "pending"
            approvalId = $approval.id
            message    = "Approval requested."
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
            timestamp  = (Get-Date).ToString("o")
            runId      = $runId
            type       = "approval_granted"
            approvalId = $ApprovalId
            approver   = $Approver
        }
        Write-OutputObj @{
            status     = "approved"
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
            timestamp  = (Get-Date).ToString("o")
            runId      = $runId
            type       = "approval_rejected"
            approvalId = $ApprovalId
            approver   = $Approver
        }
        Write-OutputObj @{
            status     = "rejected"
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
                name         = $p.name
                enabled      = [bool]$p.enabled
                priority     = [int]$p.priority
                failureCount = [int]$ps.failureCount
                circuitUntil = $ps.circuitUntil
                lastSuccess  = $ps.lastSuccess
                lastError    = $ps.lastError
            }
        }
        Write-OutputObj @{
            pendingApprovals = $pending
            providers        = $providerStatus
            stateUpdatedAt   = $state.updatedAt
        }
        break
    }
    "feedback" {
        if (-not $AgentId) { throw "feedback requires -AgentId (RunId)" }
        if ($Rating -lt 1 -or $Rating -gt 5) { throw "feedback requires -Rating (1-5)" }

        Write-Event -Path $FeedbackLogPath -EventObj @{
            timestamp = (Get-Date).ToString("o")
            runId     = $AgentId # Reusing AgentId param for RunId in feedback context to avoid breaking signature
            rating    = $Rating
            comment   = $Comment
        }
        
        Write-OutputObj @{
            status  = "ok"
            message = "Feedback recorded"
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
                runId     = $runId
                type      = "invoke_blocked"
                reason    = "missing_rag_evidence"
                agentId   = $agent
                taskType  = $TaskType
            }
            throw "RAG evidence is required. Provide -RagEvidenceId (or use -BypassRagEvidence for exceptional local tests)."
        }

        if ($criticalNeedsApproval) {
            if ([string]::IsNullOrWhiteSpace($ApprovalId)) {
                $approval = New-ApprovalRequest -Dir $ApprovalDir -RunId $runId -ActionName $CriticalAction -PromptText $Prompt -Agent $agent -TaskKind $TaskType -RagId $RagEvidenceId
                Write-Event -Path $EventLogPath -EventObj @{
                    timestamp      = (Get-Date).ToString("o")
                    runId          = $runId
                    type           = "approval_required"
                    approvalId     = $approval.id
                    criticalAction = $CriticalAction
                    agentId        = $agent
                    taskType       = $TaskType
                }
                Write-OutputObj @{
                    status     = "approval_required"
                    approvalId = $approval.id
                    message    = "Critical action requires human approval."
                }
                break
            }

            $approval = Get-Approval -Dir $ApprovalDir -Id $ApprovalId
            if ($approval.status -ne "approved") {
                throw "Approval '$ApprovalId' is not approved (status=$($approval.status))."
            }
        }

        # Sub-Agent Orchestration Tool Definition
        $orchestrationTools = @(
            @{
                type     = "function"
                function = @{
                    name        = "Invoke_SubAgent"
                    description = "Delegates a task to another specialized agent. Use this when the request requires capabilities of another agent."
                    parameters  = @{
                        type       = "object"
                        properties = @{
                            TargetAgent = @{
                                type        = "string"
                                description = "The ID of the agent to call (e.g., 'agent_dqf', 'agent_release')."
                            }
                            Prompt      = @{
                                type        = "string"
                                description = "The specific instruction for the child agent."
                            }
                        }
                        required   = @("TargetAgent", "Prompt")
                    }
                }
            }
        )

        $candidates = Get-ProviderCandidates -Config $cfg -State $state
        if ($Preference) {
            $candidates = Get-ProviderByPreference -Candidates $candidates -Preference $Preference -Config $cfg
        }

        if ($candidates.Count -eq 0) {
            throw "No provider available (all disabled, circuit-open, or filtered by preference)."
        }

        $chosen = $candidates[0]
        $providerState = $state.providers[$chosen.name]

        try {
            $result = Invoke-Provider -Provider $chosen -PromptText $Prompt -TaskKind $TaskType -Agent $agent -Tools $orchestrationTools -PlanOnly:$DryRun
            $providerState.failureCount = 0
            $providerState.circuitUntil = $null
            $providerState.lastError = $null
            $providerState.lastSuccess = (Get-Date).ToString("o")
            Save-State -State $state -Path $StatePath

            Write-Event -Path $EventLogPath -EventObj @{
                timestamp      = (Get-Date).ToString("o")
                runId          = $runId
                type           = "invoke_success"
                provider       = $result.provider
                model          = $result.model
                taskType       = $TaskType
                criticalAction = $CriticalAction
                agentId        = $agent
                approvalId     = $ApprovalId
                ragEvidenceId  = $RagEvidenceId
                dryRun         = [bool]$DryRun
                usage          = $result.usage
                toolCalls      = if ($result.rawResponse.choices[0].message.tool_calls) { $true } else { $false }
            }

            # Check for Tool Calls (Orchestration)
            $finalOutput = $result.output
            if ($result.rawResponse.choices[0].message.tool_calls) {
                foreach ($tc in $result.rawResponse.choices[0].message.tool_calls) {
                    if ($tc.function.name -eq "Invoke_SubAgent") {
                        $toolArgs = $tc.function.arguments | ConvertFrom-Json
                        $subAgent = $toolArgs.TargetAgent
                        $subPrompt = $toolArgs.Prompt
                        
                        Write-Output "    >>> ORCHESTRATION: Delegating to '$subAgent'..."

                        # Recursive Call (using the core script directly as we are in it)
                        # MUST propagate all context paths and flags to ensure child behaves consistently
                        $subResultJson = & pwsh -NoProfile -File $PSCommandPath `
                            -Action invoke `
                            -AgentId $subAgent `
                            -Prompt $subPrompt `
                            -ConfigPath $ConfigPath `
                            -StatePath $StatePath `
                            -EventLogPath $EventLogPath `
                            -FeedbackLogPath $FeedbackLogPath `
                            -ApprovalDir $ApprovalDir `
                            -BypassRagEvidence:$BypassRagEvidence `
                            -JsonOutput

                        try {
                            $subResult = $subResultJson | ConvertFrom-Json
                            $finalOutput += "`n`n[SubAgent '$subAgent' Result]:`n$($subResult.output)"
                        }
                        catch {
                            $finalOutput += "`n`n[SubAgent '$subAgent' Failed]: $_"
                        }
                    }
                }
            }

            Write-OutputObj @{
                status   = "ok"
                runId    = $runId
                provider = $result.provider
                model    = $result.model
                output   = $finalOutput
                usage    = $result.usage
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
                timestamp      = (Get-Date).ToString("o")
                runId          = $runId
                type           = "invoke_failed"
                provider       = $chosen.name
                model          = $chosen.model
                error          = $_.Exception.Message
                taskType       = $TaskType
                criticalAction = $CriticalAction
                agentId        = $agent
            }

            throw
        }
        break
    }
}
