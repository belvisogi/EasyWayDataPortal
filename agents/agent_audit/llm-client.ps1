<#
.SYNOPSIS
    Antifragile LLM client with DeepSeek API, OpenAI, and Ollama support

.DESCRIPTION
    Unified LLM client supporting:
    - DeepSeek API (primary, economico)
    - OpenAI API (fallback)
    - Ollama local (fallback)

    Features:
    - Automatic fallback on timeout/error
    - JSONL logging (tempo, provider, model, status)
    - Configurable via environment variables
    - Antifragile: retry, degrade, fallback

.EXAMPLE
    $messages = @(
        @{ role = "system"; content = "You are an auditor" },
        @{ role = "user"; content = "Audit this agent" }
    )
    $response = Invoke-LLM -Messages $messages
#>

#
# Helper: JSONL Logging
#

function Write-JsonlLog {
    param(
        [string]$LogPath = "C:\old\EasyWayDataPortal\logs\agent_audit_llm.jsonl",
        [hashtable]$Obj
    )

    $dir = Split-Path $LogPath -Parent
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }

    ($Obj | ConvertTo-Json -Compress) + "`n" | Add-Content -Path $LogPath -Encoding UTF8 -NoNewline
}

#
# Main LLM Router
#

function Invoke-LLM {
    <#
    .SYNOPSIS
        Antifragile LLM call with automatic fallback
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [array]$Messages,

        [Parameter(Mandatory = $false)]
        [string]$Model = $null,  # auto-detect from env

        [Parameter(Mandatory = $false)]
        [double]$Temperature = 0.0,

        [Parameter(Mandatory = $false)]
        [int]$MaxTokens = 4096,

        [Parameter(Mandatory = $false)]
        [string]$AgentName = "agent_audit"
    )

    # Read config from env vars
    $provider = $env:EASYWAY_LLM_PROVIDER ?? "auto"  # api, local, auto
    $modelEnv = $env:EASYWAY_LLM_MODEL ?? "deepseek-chat"
    $fallbackModel = $env:EASYWAY_LLM_MODEL_FALLBACK ?? "qwen3:latest"
    $timeoutSec = [int]($env:EASYWAY_LLM_TIMEOUT_SEC ?? 120)
    $useStream = ($env:EASYWAY_LLM_STREAM ?? "false") -eq "true"

    # Override with parameter if provided
    if ($Model) { $modelEnv = $Model }

    Write-Verbose "LLM Call - Provider: $provider, Model: $modelEnv, Timeout: ${timeoutSec}s"

    # Strategy: try primary, fallback on error
    $strategies = @()

    switch ($provider) {
        "api" {
            # API only
            if ($env:DEEPSEEK_API_KEY) {
                $strategies += @{ provider = "deepseek-api"; model = "deepseek-chat" }
            }
            if ($env:OPENAI_API_KEY) {
                $strategies += @{ provider = "openai"; model = "gpt-4o-mini" }
            }
        }
        "local" {
            # Ollama only
            $strategies += @{ provider = "ollama"; model = $modelEnv }
            $strategies += @{ provider = "ollama"; model = $fallbackModel }
        }
        "auto" {
            # Try DeepSeek API first (cheap), fallback to Ollama
            if ($env:DEEPSEEK_API_KEY) {
                $strategies += @{ provider = "deepseek-api"; model = "deepseek-chat" }
            }
            if ($env:OPENAI_API_KEY) {
                $strategies += @{ provider = "openai"; model = "gpt-4o-mini" }
            }
            $strategies += @{ provider = "ollama"; model = $fallbackModel }
        }
    }

    if ($strategies.Count -eq 0) {
        throw "No LLM provider available. Set DEEPSEEK_API_KEY, OPENAI_API_KEY, or run Ollama."
    }

    $lastError = $null

    foreach ($strategy in $strategies) {
        try {
            Write-Verbose "Trying: $($strategy.provider) / $($strategy.model)"

            switch ($strategy.provider) {
                "deepseek-api" {
                    return Invoke-DeepSeekAPI -Messages $Messages -Model $strategy.model `
                        -Temperature $Temperature -MaxTokens $MaxTokens `
                        -TimeoutSec $timeoutSec -AgentName $AgentName
                }
                "openai" {
                    return Invoke-OpenAILLM -Messages $Messages -Model $strategy.model `
                        -Temperature $Temperature -MaxTokens $MaxTokens `
                        -TimeoutSec $timeoutSec -AgentName $AgentName
                }
                "ollama" {
                    if ($useStream) {
                        return Invoke-OllamaStream -Messages $Messages -Model $strategy.model `
                            -Temperature $Temperature -MaxTokens $MaxTokens `
                            -TimeoutSec $timeoutSec -AgentName $AgentName
                    } else {
                        return Invoke-OllamaLLM -Messages $Messages -OllamaModel $strategy.model `
                            -Temperature $Temperature -MaxTokens $MaxTokens `
                            -TimeoutSec $timeoutSec -AgentName $AgentName
                    }
                }
            }
        }
        catch {
            $lastError = $_
            Write-Warning "Failed with $($strategy.provider)/$($strategy.model): $($_.Exception.Message)"
            Write-Verbose "Trying next strategy..."
            continue
        }
    }

    # All strategies failed
    throw "All LLM providers failed. Last error: $lastError"
}

#
# DeepSeek API
#

function Invoke-DeepSeekAPI {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [array]$Messages,

        [Parameter(Mandatory = $false)]
        [string]$Model = "deepseek-chat",

        [Parameter(Mandatory = $false)]
        [double]$Temperature = 0.0,

        [Parameter(Mandatory = $false)]
        [int]$MaxTokens = 4096,

        [Parameter(Mandatory = $false)]
        [int]$TimeoutSec = 120,

        [Parameter(Mandatory = $false)]
        [string]$AgentName = "agent_audit",

        [Parameter(Mandatory = $false)]
        [string]$LogPath = "C:\old\EasyWayDataPortal\logs\agent_audit_llm.jsonl"
    )

    $tsStart = Get-Date
    $sw = [System.Diagnostics.Stopwatch]::StartNew()

    try {
        # Check API key
        $apiKey = $env:DEEPSEEK_API_KEY
        if (-not $apiKey) {
            throw "DEEPSEEK_API_KEY environment variable not set"
        }

        # Build request (OpenAI-compatible)
        $body = @{
            model = $Model
            messages = $Messages
            temperature = $Temperature
            max_tokens = $MaxTokens
        } | ConvertTo-Json -Depth 10

        $headers = @{
            "Content-Type" = "application/json"
            "Authorization" = "Bearer $apiKey"
        }

        Write-Verbose "Calling DeepSeek API ($Model)..."

        # Call API
        $response = Invoke-RestMethod -Uri "https://api.deepseek.com/v1/chat/completions" `
            -Method POST `
            -Headers $headers `
            -Body $body `
            -TimeoutSec $TimeoutSec

        if (-not $response.choices -or $response.choices.Count -eq 0) {
            throw "DeepSeek returned no choices"
        }

        $sw.Stop()
        $tsEnd = Get-Date
        $responseText = $response.choices[0].message.content

        # Log success
        Write-JsonlLog -LogPath $LogPath -Obj @{
            ts_start = $tsStart.ToString("o")
            ts_end = $tsEnd.ToString("o")
            duration_ms = $sw.ElapsedMilliseconds
            agent = $AgentName
            provider = "deepseek-api"
            model = $Model
            timeout_sec = $TimeoutSec
            stream = $false
            prompt_chars = ($Messages | ConvertTo-Json -Compress).Length
            response_chars = $responseText.Length
            status = "ok"
            tokens_used = $response.usage.total_tokens
            cost_estimate = ($response.usage.total_tokens * 0.00000014)  # $0.14 per 1M tokens
        }

        Write-Verbose "✅ DeepSeek response: $($responseText.Length) chars, $($response.usage.total_tokens) tokens"

        return $responseText

    } catch {
        $sw.Stop()
        $tsEnd = Get-Date
        $msg = $_.Exception.Message
        $isTimeout = $msg -match "timed out|timeout"

        # Log error
        Write-JsonlLog -LogPath $LogPath -Obj @{
            ts_start = $tsStart.ToString("o")
            ts_end = $tsEnd.ToString("o")
            duration_ms = $sw.ElapsedMilliseconds
            agent = $AgentName
            provider = "deepseek-api"
            model = $Model
            timeout_sec = $TimeoutSec
            stream = $false
            prompt_chars = ($Messages | ConvertTo-Json -Compress).Length
            status = ($isTimeout ? "timeout" : "error")
            error = $msg
        }

        Write-Error "DeepSeek API call failed: $msg"
        throw
    }
}

#
# OpenAI API (fallback)
#

function Invoke-OpenAILLM {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [array]$Messages,

        [Parameter(Mandatory = $false)]
        [string]$Model = "gpt-4o-mini",

        [Parameter(Mandatory = $false)]
        [double]$Temperature = 0.0,

        [Parameter(Mandatory = $false)]
        [int]$MaxTokens = 4096,

        [Parameter(Mandatory = $false)]
        [int]$TimeoutSec = 60,

        [Parameter(Mandatory = $false)]
        [string]$AgentName = "agent_audit",

        [Parameter(Mandatory = $false)]
        [string]$LogPath = "C:\old\EasyWayDataPortal\logs\agent_audit_llm.jsonl"
    )

    $tsStart = Get-Date
    $sw = [System.Diagnostics.Stopwatch]::StartNew()

    try {
        # Check API key
        $apiKey = $env:OPENAI_API_KEY
        if (-not $apiKey) {
            throw "OPENAI_API_KEY environment variable not set"
        }

        # Build request
        $body = @{
            model = $Model
            messages = $Messages
            temperature = $Temperature
            max_tokens = $MaxTokens
        } | ConvertTo-Json -Depth 10

        $headers = @{
            "Content-Type" = "application/json"
            "Authorization" = "Bearer $apiKey"
        }

        Write-Verbose "Calling OpenAI API ($Model)..."

        # Call API
        $response = Invoke-RestMethod -Uri "https://api.openai.com/v1/chat/completions" `
            -Method POST `
            -Headers $headers `
            -Body $body `
            -TimeoutSec $TimeoutSec

        if (-not $response.choices -or $response.choices.Count -eq 0) {
            throw "OpenAI returned no choices"
        }

        $sw.Stop()
        $tsEnd = Get-Date
        $responseText = $response.choices[0].message.content

        # Log success
        Write-JsonlLog -LogPath $LogPath -Obj @{
            ts_start = $tsStart.ToString("o")
            ts_end = $tsEnd.ToString("o")
            duration_ms = $sw.ElapsedMilliseconds
            agent = $AgentName
            provider = "openai"
            model = $Model
            timeout_sec = $TimeoutSec
            stream = $false
            prompt_chars = ($Messages | ConvertTo-Json -Compress).Length
            response_chars = $responseText.Length
            status = "ok"
            tokens_used = $response.usage.total_tokens
        }

        Write-Verbose "✅ OpenAI response: $($responseText.Length) chars, $($response.usage.total_tokens) tokens"

        return $responseText

    } catch {
        $sw.Stop()
        $tsEnd = Get-Date
        $msg = $_.Exception.Message
        $isTimeout = $msg -match "timed out|timeout"

        # Log error
        Write-JsonlLog -LogPath $LogPath -Obj @{
            ts_start = $tsStart.ToString("o")
            ts_end = $tsEnd.ToString("o")
            duration_ms = $sw.ElapsedMilliseconds
            agent = $AgentName
            provider = "openai"
            model = $Model
            timeout_sec = $TimeoutSec
            stream = $false
            prompt_chars = ($Messages | ConvertTo-Json -Compress).Length
            status = ($isTimeout ? "timeout" : "error")
            error = $msg
        }

        Write-Error "OpenAI API call failed: $msg"
        throw
    }
}

#
# Ollama Local (non-stream fallback)
#

function Invoke-OllamaLLM {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [array]$Messages,

        [Parameter(Mandatory = $false)]
        [double]$Temperature = 0.0,

        [Parameter(Mandatory = $false)]
        [int]$MaxTokens = 4096,

        [Parameter(Mandatory = $false)]
        [string]$OllamaModel = "qwen3:latest",

        [Parameter(Mandatory = $false)]
        [string]$OllamaUrl = "http://localhost:11434",

        [Parameter(Mandatory = $false)]
        [int]$TimeoutSec = 120,

        [Parameter(Mandatory = $false)]
        [string]$AgentName = "agent_audit",

        [Parameter(Mandatory = $false)]
        [string]$LogPath = "C:\old\EasyWayDataPortal\logs\agent_audit_llm.jsonl"
    )

    $tsStart = Get-Date
    $sw = [System.Diagnostics.Stopwatch]::StartNew()

    try {
        # Test Ollama availability
        try {
            $null = Invoke-RestMethod -Uri "$OllamaUrl/api/tags" -Method GET -TimeoutSec 2 -ErrorAction Stop
            Write-Verbose "✅ Ollama available at $OllamaUrl"
        } catch {
            throw "Ollama not available at $OllamaUrl. Is it running? Start with: ollama serve"
        }

        # Combine messages into single prompt for Ollama
        $prompt = ""
        foreach ($msg in $Messages) {
            $role = $msg.role.ToUpper()
            $content = $msg.content

            if ($role -eq "SYSTEM") {
                $prompt += "SYSTEM: $content`n`n"
            } elseif ($role -eq "USER") {
                $prompt += "USER: $content`n`n"
            } elseif ($role -eq "ASSISTANT") {
                $prompt += "ASSISTANT: $content`n`n"
            }
        }

        $prompt += "ASSISTANT:"

        Write-Verbose "Prompt length: $($prompt.Length) characters"

        # Build request body
        $body = @{
            model = $OllamaModel
            prompt = $prompt
            stream = $false
            options = @{
                temperature = $Temperature
                num_predict = $MaxTokens
            }
        } | ConvertTo-Json -Depth 10

        Write-Verbose "Calling Ollama API ($OllamaModel)..."

        # Call Ollama
        $response = Invoke-RestMethod -Uri "$OllamaUrl/api/generate" `
            -Method POST `
            -ContentType "application/json" `
            -Body $body `
            -TimeoutSec $TimeoutSec

        if (-not $response.response) {
            throw "Ollama returned empty response"
        }

        $sw.Stop()
        $tsEnd = Get-Date

        # Log success
        Write-JsonlLog -LogPath $LogPath -Obj @{
            ts_start = $tsStart.ToString("o")
            ts_end = $tsEnd.ToString("o")
            duration_ms = $sw.ElapsedMilliseconds
            agent = $AgentName
            provider = "local"
            model = $OllamaModel
            timeout_sec = $TimeoutSec
            stream = $false
            prompt_chars = $prompt.Length
            response_chars = $response.response.Length
            status = "ok"
        }

        Write-Verbose "✅ Ollama response: $($response.response.Length) characters"

        return $response.response

    } catch {
        $sw.Stop()
        $tsEnd = Get-Date
        $msg = $_.Exception.Message
        $isTimeout = $msg -match "timed out|timeout"

        # Log error
        Write-JsonlLog -LogPath $LogPath -Obj @{
            ts_start = $tsStart.ToString("o")
            ts_end = $tsEnd.ToString("o")
            duration_ms = $sw.ElapsedMilliseconds
            agent = $AgentName
            provider = "local"
            model = $OllamaModel
            timeout_sec = $TimeoutSec
            stream = $false
            status = ($isTimeout ? "timeout" : "error")
            error = $msg
        }

        Write-Error "Ollama LLM call failed: $msg"
        throw
    }
}

#
# Ollama Streaming (for reasoning models)
#

function Invoke-OllamaStream {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [array]$Messages,

        [Parameter(Mandatory = $false)]
        [string]$Model = "deepseek-r1:7b",

        [Parameter(Mandatory = $false)]
        [double]$Temperature = 0.0,

        [Parameter(Mandatory = $false)]
        [int]$MaxTokens = 4096,

        [Parameter(Mandatory = $false)]
        [string]$OllamaUrl = "http://localhost:11434",

        [Parameter(Mandatory = $false)]
        [int]$TimeoutSec = 300,

        [Parameter(Mandatory = $false)]
        [string]$AgentName = "agent_audit",

        [Parameter(Mandatory = $false)]
        [string]$LogPath = "C:\old\EasyWayDataPortal\logs\agent_audit_llm.jsonl"
    )

    $tsStart = Get-Date
    $sw = [System.Diagnostics.Stopwatch]::StartNew()

    # Combine messages into prompt
    $prompt = ""
    foreach ($msg in $Messages) {
        $role = $msg.role.ToUpper()
        $content = $msg.content
        if ($role -eq "SYSTEM") { $prompt += "SYSTEM: $content`n`n" }
        elseif ($role -eq "USER") { $prompt += "USER: $content`n`n" }
        elseif ($role -eq "ASSISTANT") { $prompt += "ASSISTANT: $content`n`n" }
    }
    $prompt += "ASSISTANT:"

    $payload = @{
        model = $Model
        prompt = $prompt
        stream = $true
        options = @{
            temperature = $Temperature
            num_predict = $MaxTokens
        }
    } | ConvertTo-Json -Depth 10

    $client = New-Object System.Net.Http.HttpClient
    $client.Timeout = [TimeSpan]::FromSeconds($TimeoutSec)

    $req = New-Object System.Net.Http.HttpRequestMessage([System.Net.Http.HttpMethod]::Post, "$OllamaUrl/api/generate")
    $req.Content = New-Object System.Net.Http.StringContent($payload, [System.Text.Encoding]::UTF8, "application/json")

    $full = New-Object System.Text.StringBuilder

    try {
        $resp = $client.SendAsync($req, [System.Net.Http.HttpCompletionOption]::ResponseHeadersRead).Result
        $resp.EnsureSuccessStatusCode() | Out-Null

        $stream = $resp.Content.ReadAsStreamAsync().Result
        $reader = New-Object System.IO.StreamReader($stream)

        while (-not $reader.EndOfStream) {
            $line = $reader.ReadLine()
            if ([string]::IsNullOrWhiteSpace($line)) { continue }

            $obj = $null
            try { $obj = $line | ConvertFrom-Json } catch { continue }

            if ($obj.response) {
                [void]$full.Append($obj.response)
                Write-Verbose -Message "." -Verbose:$false  # Progress indicator
            }

            if ($obj.done -eq $true) { break }
        }

        $sw.Stop()
        $tsEnd = Get-Date
        $text = $full.ToString()

        # Log success
        Write-JsonlLog -LogPath $LogPath -Obj @{
            ts_start = $tsStart.ToString("o")
            ts_end = $tsEnd.ToString("o")
            duration_ms = $sw.ElapsedMilliseconds
            agent = $AgentName
            provider = "local"
            model = $Model
            timeout_sec = $TimeoutSec
            stream = $true
            prompt_chars = $prompt.Length
            response_chars = $text.Length
            status = "ok"
        }

        Write-Verbose "✅ Ollama stream complete: $($text.Length) characters"

        return $text

    } catch {
        $sw.Stop()
        $tsEnd = Get-Date
        $msg = $_.Exception.Message
        $isTimeout = $msg -match "timed out|timeout"

        # Log error
        Write-JsonlLog -LogPath $LogPath -Obj @{
            ts_start = $tsStart.ToString("o")
            ts_end = $tsEnd.ToString("o")
            duration_ms = $sw.ElapsedMilliseconds
            agent = $AgentName
            provider = "local"
            model = $Model
            timeout_sec = $TimeoutSec
            stream = $true
            prompt_chars = $prompt.Length
            status = ($isTimeout ? "timeout" : "error")
            error = $msg
        }

        Write-Error "Ollama stream failed: $msg"
        throw

    } finally {
        if ($client) { $client.Dispose() }
    }
}

#
# Test Ollama Availability
#

function Test-OllamaAvailability {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$OllamaUrl = "http://localhost:11434",

        [Parameter(Mandatory = $false)]
        [string]$RequiredModel = "qwen3:latest"
    )

    try {
        # Check if Ollama is running
        $tags = Invoke-RestMethod -Uri "$OllamaUrl/api/tags" -Method GET -TimeoutSec 2

        Write-Host "✅ Ollama is running at $OllamaUrl" -ForegroundColor Green

        # Check if required model is available
        $models = $tags.models | ForEach-Object { $_.name }

        if ($models -contains $RequiredModel) {
            Write-Host "✅ Model '$RequiredModel' is available" -ForegroundColor Green
            return $true
        } else {
            Write-Warning "⚠️  Model '$RequiredModel' not found. Available models: $($models -join ', ')"
            Write-Host "Pull the model with: ollama pull $RequiredModel" -ForegroundColor Yellow
            return $false
        }

    } catch {
        Write-Error "❌ Ollama not available at $OllamaUrl"
        Write-Host "Start Ollama with: ollama serve" -ForegroundColor Yellow
        return $false
    }
}

# Functions are available when dot-sourced
# No Export-ModuleMember needed for dot-sourcing pattern
