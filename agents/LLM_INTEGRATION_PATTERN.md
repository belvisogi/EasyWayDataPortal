# 🧠 LLM Integration Pattern for EasyWay Agents

**Version:** 1.0.0
**Created:** 2026-02-08
**Purpose:** How to add LLM reasoning to agents (Level 2+ capability)

---

## 🎯 Overview

This guide shows how to transform agents from **static script executors** (Level 1) to **intelligent decision makers** (Level 2+) by integrating LLM reasoning.

---

## 🏗️ Architecture

```
User Intent
    ↓
[LLM Planner] ← manifest.json (available actions)
    ↓          ← memory/context.json (past results)
Action Plan     ← PROMPTS.md (system instructions)
    ↓
[Executor] → Skills
    ↓
Results → [LLM Analyzer]
    ↓
Update Memory
```

---

## 📝 Step 1: Add LLM Config to Manifest

**File:** `agents/agent_xxx/manifest.json`

```json
{
  "id": "agent_xxx",
  "llm_config": {
    "model": "gpt-4-turbo",
    "temperature": 0.0,
    "system_prompt": "agents/agent_xxx/PROMPTS.md",
    "tools": ["function_calling"],
    "max_tokens": 4096
  },
  "actions": [
    {
      "name": "xxx:action1",
      "description": "Clear description for LLM to understand when to use this"
    },
    {
      "name": "xxx:action2",
      "description": "Another action with different use case"
    }
  ]
}
```

---

## 📝 Step 2: Create System Prompt

**File:** `agents/agent_xxx/PROMPTS.md`

```markdown
# Agent XXX - System Prompt

You are **agent_xxx**, an autonomous agent specialized in [domain].

## Your Role
[Describe what the agent does, its expertise, and responsibilities]

## Available Actions
You can perform these actions:
1. **xxx:action1** - [When to use this]
2. **xxx:action2** - [When to use this]

## Decision Guidelines
- Always check memory/context.json for past results before acting
- If unsure, prefer safer/faster actions first
- Use xxx:action1 for [specific scenario]
- Use xxx:action2 for [specific scenario]

## Output Format
Always return your plan as JSON:
```json
{
  "reasoning": "Why I chose this approach",
  "actions": [
    { "name": "xxx:action1", "params": {...} }
  ],
  "expected_outcome": "What I expect to happen"
}
```

## Error Handling
If an action fails:
1. Analyze the error message
2. Check if there's a different action that could work
3. Retry with adjusted parameters if appropriate
4. Escalate to user if unrecoverable
```

---

## 📝 Step 3: Implement LLM Caller

**File:** `agents/agent_xxx/llm-client.ps1`

```powershell
function Invoke-LLM {
    param(
        [Parameter(Mandatory = $true)]
        [array]$Messages,

        [Parameter(Mandatory = $false)]
        [string]$Model = "gpt-4-turbo",

        [Parameter(Mandatory = $false)]
        [double]$Temperature = 0.0
    )

    # Build API request
    $body = @{
        model = $Model
        messages = $Messages
        temperature = $Temperature
        max_tokens = 4096
    } | ConvertTo-Json -Depth 10

    # Call OpenAI API (or Ollama, Claude, etc.)
    $apiKey = $env:OPENAI_API_KEY
    if (-not $apiKey) {
        throw "OPENAI_API_KEY environment variable not set"
    }

    $headers = @{
        "Content-Type" = "application/json"
        "Authorization" = "Bearer $apiKey"
    }

    try {
        $response = Invoke-RestMethod -Uri "https://api.openai.com/v1/chat/completions" `
            -Method POST `
            -Headers $headers `
            -Body $body

        return $response.choices[0].message.content

    } catch {
        Write-Error "LLM API call failed: $_"
        throw
    }
}
```

---

## 📝 Step 4: Implement Smart Execution

**File:** `scripts/pwsh/agent-xxx.ps1`

```powershell
# Load LLM client
. "$PSScriptRoot/../agents/agent_xxx/llm-client.ps1"

# Load manifest
$manifest = Get-Content "$PSScriptRoot/../agents/agent_xxx/manifest.json" | ConvertFrom-Json

# Load system prompt
$systemPrompt = Get-Content "$PSScriptRoot/../agents/agent_xxx/PROMPTS.md" -Raw

# Load memory
$memoryPath = "$PSScriptRoot/../agents/agent_xxx/memory/context.json"
$memory = if (Test-Path $memoryPath) {
    Get-Content $memoryPath | ConvertFrom-Json
} else {
    @{ stats = @{}; knowledge = @{} }
}

function Invoke-SmartAction {
    param(
        [Parameter(Mandatory = $true)]
        [object]$Intent
    )

    # Build conversation
    $messages = @(
        @{
            role = "system"
            content = $systemPrompt
        },
        @{
            role = "user"
            content = @"
User Request: $($Intent.goal)

Available Actions:
$($manifest.actions | ForEach-Object { "- $($_.name): $($_.description)" } | Out-String)

Memory (past results):
$($memory | ConvertTo-Json -Depth 3)

Create a plan to fulfill this request. Return JSON with: reasoning, actions, expected_outcome.
"@
        }
    )

    # LLM creates plan
    Write-Host "🧠 LLM is planning..." -ForegroundColor Cyan
    $planJson = Invoke-LLM -Messages $messages -Model $manifest.llm_config.model -Temperature $manifest.llm_config.temperature

    Write-Verbose "LLM Plan: $planJson"

    $plan = $planJson | ConvertFrom-Json

    Write-Host "📋 Plan: $($plan.reasoning)" -ForegroundColor Yellow
    Write-Host "📋 Actions: $($plan.actions.Count)" -ForegroundColor Yellow

    # Execute actions
    $results = @()
    foreach ($action in $plan.actions) {
        Write-Host "▶️  Executing: $($action.name)" -ForegroundColor Green

        try {
            $result = Invoke-Action -Name $action.name -Params $action.params

            $results += @{
                Action = $action.name
                Status = "success"
                Result = $result
            }

        } catch {
            Write-Host "❌ Action failed: $_" -ForegroundColor Red

            # LLM analyzes error and suggests fix
            $messages += @{
                role = "assistant"
                content = $planJson
            }
            $messages += @{
                role = "user"
                content = "Action $($action.name) failed with error: $_. How should I fix this? Return JSON with: analysis, retry_action."
            }

            $fix = Invoke-LLM -Messages $messages | ConvertFrom-Json

            Write-Host "🔧 LLM suggests: $($fix.analysis)" -ForegroundColor Yellow

            if ($fix.retry_action) {
                Write-Host "🔁 Retrying with: $($fix.retry_action.name)" -ForegroundColor Cyan
                $result = Invoke-Action -Name $fix.retry_action.name -Params $fix.retry_action.params

                $results += @{
                    Action = $action.name
                    Status = "success_after_retry"
                    Result = $result
                    OriginalError = $_.Exception.Message
                    Fix = $fix.analysis
                }
            } else {
                $results += @{
                    Action = $action.name
                    Status = "failed"
                    Error = $_.Exception.Message
                    Analysis = $fix.analysis
                }
            }
        }
    }

    # Update memory with results
    Update-Memory -Results $results

    return @{
        Plan = $plan
        Results = $results
    }
}

function Update-Memory {
    param($Results)

    # Update stats
    $memory.stats.total_runs++
    $memory.stats.last_run = Get-Date -Format "o"

    # Extract learnings
    foreach ($result in $Results) {
        if ($result.Status -eq "failed") {
            $memory.stats.errors++

            # Save error for future reference
            if (-not $memory.knowledge.known_errors) {
                $memory.knowledge.known_errors = @()
            }
            $memory.knowledge.known_errors += @{
                Action = $result.Action
                Error = $result.Error
                Date = Get-Date -Format "o"
            }
        }

        if ($result.Fix) {
            # Save successful fix
            if (-not $memory.knowledge.fixes) {
                $memory.knowledge.fixes = @()
            }
            $memory.knowledge.fixes += @{
                Problem = $result.OriginalError
                Solution = $result.Fix
                Date = Get-Date -Format "o"
            }
        }
    }

    # Save memory
    $memory | ConvertTo-Json -Depth 10 | Set-Content $memoryPath
}
```

---

## 📝 Step 5: Ollama Integration (Local LLM)

For running agents with local LLM (Ollama):

**Update `llm-client.ps1`:**

```powershell
function Invoke-LLM {
    param(
        [Parameter(Mandatory = $true)]
        [array]$Messages,

        [Parameter(Mandatory = $false)]
        [string]$Model = "gpt-4-turbo"
    )

    # Check if using Ollama
    if ($Model -eq "ollama") {
        return Invoke-OllamaLLM -Messages $Messages
    }

    # Otherwise use OpenAI
    # ... (previous implementation)
}

function Invoke-OllamaLLM {
    param([array]$Messages)

    # Combine messages into single prompt for Ollama
    $prompt = ""
    foreach ($msg in $Messages) {
        if ($msg.role -eq "system") {
            $prompt += "SYSTEM: $($msg.content)`n`n"
        } elseif ($msg.role -eq "user") {
            $prompt += "USER: $($msg.content)`n`n"
        } elseif ($msg.role -eq "assistant") {
            $prompt += "ASSISTANT: $($msg.content)`n`n"
        }
    }

    $prompt += "ASSISTANT:"

    # Call Ollama API
    $body = @{
        model = "llama2"  # or "mistral", "codellama", etc.
        prompt = $prompt
        stream = $false
    } | ConvertTo-Json

    try {
        $response = Invoke-RestMethod -Uri "http://localhost:11434/api/generate" `
            -Method POST `
            -ContentType "application/json" `
            -Body $body

        return $response.response

    } catch {
        Write-Error "Ollama API call failed: $_"
        throw
    }
}
```

**Update manifest.json:**

```json
{
  "llm_config": {
    "model": "ollama",
    "temperature": 0.0,
    "system_prompt": "agents/agent_xxx/PROMPTS.md"
  }
}
```

---

## 🧪 Testing LLM Integration

**Test script:** `agents/agent_xxx/test-llm.ps1`

```powershell
# Load agent
. "$PSScriptRoot/../../scripts/pwsh/agent-xxx.ps1"

# Test intent
$testIntent = @{
    goal = "Scan all Docker images for vulnerabilities"
    context = "Production environment, weekly check"
}

# Execute with LLM
$result = Invoke-SmartAction -Intent $testIntent

# Verify
Write-Host "`n=== RESULTS ===" -ForegroundColor Cyan
$result | ConvertTo-Json -Depth 10
```

---

## 📈 Benefits of LLM Integration

| Before (Level 1) | After (Level 2) |
|------------------|-----------------|
| Static action mapping | Dynamic action selection |
| No error recovery | Intelligent retry with fixes |
| Same approach every time | Adapts based on context |
| Manual parameter tuning | LLM adjusts parameters |
| No learning | Builds knowledge over time |

---

## 🎯 Next Steps

1. Add LLM config to manifest
2. Create PROMPTS.md with system instructions
3. Implement LLM client (OpenAI or Ollama)
4. Update agent script to use LLM planning
5. Test with various intents
6. Monitor and improve prompts based on results

---

**Status:** ✅ Production Standard (Level 2)
**Owner:** EasyWay Platform Team
**Last Updated:** 2026-02-08
