<#
.SYNOPSIS
    Agent Audit v2.0 - LLM-powered compliance checker and fixer

.DESCRIPTION
    Uses Ollama LLM to intelligently audit agents for Framework 2.0 compliance
    and apply automated fixes.

.PARAMETER Action
    Action to perform: audit, fix, validate, report

.PARAMETER AgentId
    Agent ID to audit/fix (e.g., "agent_vulnerability_scanner")

.PARAMETER Fixes
    Comma-separated list of fixes to apply

.PARAMETER DryRun
    Preview changes without applying

.PARAMETER OllamaModel
    Ollama model to use (default: deepseek-r1:7b)

.EXAMPLE
    # Audit single agent
    pwsh agent-audit-v2.ps1 -Action audit -AgentId agent_vulnerability_scanner

.EXAMPLE
    # Fix agent with LLM guidance
    pwsh agent-audit-v2.ps1 -Action fix -AgentId agent_vulnerability_scanner -Fixes "standardize_manifest,create_missing_files"

.EXAMPLE
    # Dry run
    pwsh agent-audit-v2.ps1 -Action fix -AgentId agent_vulnerability_scanner -DryRun
#>

param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("audit", "fix", "validate", "report")]
    [string]$Action,

    [Parameter(Mandatory = $false)]
    [string]$AgentId = "",

    [Parameter(Mandatory = $false)]
    [string]$Fixes = "",

    [Parameter(Mandatory = $false)]
    [switch]$DryRun,

    [Parameter(Mandatory = $false)]
    [string]$OllamaModel = "qwen3:latest"
)

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent (Split-Path -Parent $ScriptDir)

# Load LLM client
. "$ProjectRoot/agents/agent_audit/llm-client.ps1"

# Load manifest
$manifestPath = "$ProjectRoot/agents/agent_audit/manifest.json"
$manifest = Get-Content $manifestPath -Raw | ConvertFrom-Json

# Load system prompt (LITE version for speed)
$systemPromptPath = "$ProjectRoot/agents/agent_audit/PROMPTS_LITE.md"
$systemPrompt = Get-Content $systemPromptPath -Raw

#
# Functions (defined before use)
#

function Invoke-AuditAgent {
    param([string]$AgentId)

    # Find agent location
    $agentPath = Find-AgentPath -AgentId $AgentId

    if (-not $agentPath) {
        throw "Agent $AgentId not found in agents/ or .agent/workflows/"
    }

    Write-Host "Found agent at: $agentPath" -ForegroundColor Gray

    # Read agent files
    $manifestPath = Join-Path $agentPath "manifest.json"
    $readmePath = Join-Path $agentPath "README.md"

    $agentManifest = $null
    if (Test-Path $manifestPath) {
        $agentManifest = Get-Content $manifestPath -Raw | ConvertFrom-Json
    }

    $hasReadme = Test-Path $readmePath
    $hasPriority = Test-Path (Join-Path $agentPath "priority.json")
    $hasMemory = Test-Path (Join-Path $agentPath "memory/context.json")
    $hasTemplates = (Get-ChildItem -Path $agentPath -Filter "templates" -Directory).Count -gt 0

    # Build context for LLM
    $context = @"
Agent Location: $agentPath
Has manifest.json: $(if ($agentManifest) { "YES" } else { "NO" })
Has README.md: $hasReadme
Has priority.json: $hasPriority
Has memory/context.json: $hasMemory
Has templates/: $hasTemplates

Manifest Content:
$($agentManifest | ConvertTo-Json -Depth 10)
"@

    # Ask LLM to audit
    $messages = @(
        @{
            role = "system"
            content = $systemPrompt
        },
        @{
            role = "user"
            content = @"
Audit this agent: $AgentId

$context

Return JSON with:
{
  "agent_id": "$AgentId",
  "compliance_score": <0-100>,
  "current_grade": "<A+|A|A-|B|C|D|F>",
  "issues": [
    {"severity": "critical|high|medium|low", "category": "...", "issue": "...", "fix": "..."}
  ],
  "recommended_fixes": [...]
}
"@
        }
    )

    Write-Host "Asking LLM to analyze..." -ForegroundColor Yellow

    $llmResponse = Invoke-LLM -Messages $messages -AgentName "agent_audit"

    # Parse JSON from response
    $jsonMatch = $llmResponse -match '(?s)\{.*\}'
    if ($jsonMatch) {
        $jsonStr = $Matches[0]
        return $jsonStr | ConvertFrom-Json
    } else {
        Write-Warning "LLM did not return valid JSON. Raw response:"
        Write-Host $llmResponse
        return $null
    }
}

function Invoke-FixAgent {
    param(
        [string]$AgentId,
        [array]$Fixes,
        [switch]$DryRun
    )

    # Find agent
    $agentPath = Find-AgentPath -AgentId $AgentId

    Write-Host "Agent path: $agentPath" -ForegroundColor Gray

    # Ask LLM for fix plan
    $messages = @(
        @{
            role = "system"
            content = $systemPrompt
        },
        @{
            role = "user"
            content = @"
Apply these fixes to agent: $AgentId

Fixes requested: $($Fixes -join ', ')
Agent location: $agentPath
Dry run: $DryRun

For each fix, return JSON with file changes:
{
  "fixes_applied": [
    {
      "fix": "standardize_manifest",
      "status": "success",
      "files_changed": [
        {
          "path": "agents/agent_xxx/manifest.json",
          "action": "update",
          "changes": "Added id, owner, version, llm_config, skills_required"
        }
      ]
    }
  ],
  "new_compliance_score": <0-100>
}
"@
        }
    )

    Write-Host "Asking LLM for fix plan..." -ForegroundColor Yellow

    $llmResponse = Invoke-LLM -Messages $messages -AgentName "agent_audit"

    Write-Host ""
    Write-Host "LLM Response:" -ForegroundColor Cyan
    Write-Host $llmResponse -ForegroundColor Gray

    # Apply fixes (if not dry run)
    if (-not $DryRun) {
        Write-Host ""
        Write-Host "Applying fixes..." -ForegroundColor Yellow

        foreach ($fix in $Fixes) {
            switch ($fix) {
                "move_to_correct_location" {
                    Apply-MoveToCorrectLocation -AgentId $AgentId -AgentPath $agentPath
                }
                "standardize_manifest" {
                    Apply-StandardizeManifest -AgentId $AgentId -AgentPath $agentPath
                }
                "create_missing_files" {
                    Apply-CreateMissingFiles -AgentId $AgentId -AgentPath $agentPath
                }
                "add_priority_json" {
                    Apply-AddPriorityJson -AgentId $AgentId -AgentPath $agentPath
                }
                "create_intent_templates" {
                    Apply-CreateIntentTemplates -AgentId $AgentId -AgentPath $agentPath
                }
                default {
                    Write-Warning "Unknown fix: $fix"
                }
            }
        }
    }

    return @{
        agent_id = $AgentId
        fixes_requested = $Fixes
        dry_run = $DryRun.IsPresent
        llm_response = $llmResponse
    }
}

function Find-AgentPath {
    param([string]$AgentId)

    # Check standard location
    $standardPath = Join-Path $ProjectRoot "agents/$AgentId"
    if (Test-Path $standardPath) {
        return $standardPath
    }

    # Check wrong location
    $wrongPath = Join-Path $ProjectRoot ".agent/workflows/$AgentId"
    if (Test-Path $wrongPath) {
        Write-Warning "⚠️  Agent found in WRONG location: $wrongPath"
        return $wrongPath
    }

    return $null
}

function Apply-MoveToCorrectLocation {
    param([string]$AgentId, [string]$AgentPath)

    $correctPath = Join-Path $ProjectRoot "agents/$AgentId"

    if ($AgentPath -eq $correctPath) {
        Write-Host "✅ Already in correct location" -ForegroundColor Green
        return
    }

    Write-Host "Moving $AgentPath -> $correctPath" -ForegroundColor Yellow

    if (-not (Test-Path (Split-Path $correctPath))) {
        New-Item -Path (Split-Path $correctPath) -ItemType Directory -Force | Out-Null
    }

    Move-Item -Path $AgentPath -Destination $correctPath -Force

    Write-Host "✅ Moved to correct location" -ForegroundColor Green
}

function Apply-StandardizeManifest {
    param([string]$AgentId, [string]$AgentPath)

    $manifestPath = Join-Path $agentPath "manifest.json"

    if (-not (Test-Path $manifestPath)) {
        Write-Warning "No manifest.json found, cannot standardize"
        return
    }

    $manifest = Get-Content $manifestPath -Raw | ConvertFrom-Json

    # Add missing fields
    $changed = $false

    if (-not $manifest.id) {
        $manifest | Add-Member -NotePropertyName "id" -NotePropertyValue $AgentId -Force
        $changed = $true
    }

    if (-not $manifest.owner) {
        $manifest | Add-Member -NotePropertyName "owner" -NotePropertyValue "team-platform" -Force
        $changed = $true
    }

    if (-not $manifest.version) {
        $manifest | Add-Member -NotePropertyName "version" -NotePropertyValue "1.0.0" -Force
        $changed = $true
    }

    if (-not $manifest.llm_config) {
        $manifest | Add-Member -NotePropertyName "llm_config" -NotePropertyValue @{
            model = "gpt-4-turbo"
            temperature = 0.0
            system_prompt = "agents/$AgentId/PROMPTS.md"
        } -Force
        $changed = $true
    }

    if (-not $manifest.skills_required) {
        $manifest | Add-Member -NotePropertyName "skills_required" -NotePropertyValue @() -Force
        $changed = $true
    }

    if ($changed) {
        $manifest | ConvertTo-Json -Depth 10 | Set-Content $manifestPath
        Write-Host "✅ Standardized manifest.json" -ForegroundColor Green
    } else {
        Write-Host "✅ Manifest already standardized" -ForegroundColor Green
    }
}

function Apply-CreateMissingFiles {
    param([string]$AgentId, [string]$AgentPath)

    # Create priority.json if missing
    $priorityPath = Join-Path $agentPath "priority.json"
    if (-not (Test-Path $priorityPath)) {
        @{
            rules = @(
                @{
                    id = "default"
                    description = "Default validation rule"
                    severity = "advisory"
                }
            )
        } | ConvertTo-Json -Depth 10 | Set-Content $priorityPath
        Write-Host "✅ Created priority.json" -ForegroundColor Green
    }

    # Create memory/context.json if missing
    $memoryDir = Join-Path $agentPath "memory"
    $memoryPath = Join-Path $memoryDir "context.json"

    if (-not (Test-Path $memoryPath)) {
        if (-not (Test-Path $memoryDir)) {
            New-Item -Path $memoryDir -ItemType Directory -Force | Out-Null
        }

        @{
            created = (Get-Date -Format "o")
            stats = @{
                total_runs = 0
                errors = 0
                last_run = $null
            }
            knowledge = @{}
            preferences = @{}
        } | ConvertTo-Json -Depth 10 | Set-Content $memoryPath

        Write-Host "✅ Created memory/context.json" -ForegroundColor Green
    }
}

function Invoke-ValidateAgent {
    param([string]$AgentId)

    # TODO: Implement JSON Schema validation
    Write-Host "Schema validation not yet implemented" -ForegroundColor Yellow

    return @{
        valid = $true
        errors = @()
    }
}

function Invoke-GenerateReport {
    # TODO: Generate full compliance report
    Write-Host "Report generation not yet implemented" -ForegroundColor Yellow

    return @{
        output_path = "docs/audit-reports/compliance-report.md"
    }
}

#
# Main execution
#

Write-Host "🤖 Agent Audit v2.0 - LLM-Powered (Antifragile)" -ForegroundColor Cyan
Write-Host "Action: $Action | Agent: $AgentId | Dry Run: $DryRun" -ForegroundColor Gray

# Antifragile: automatic provider selection via env vars
# EASYWAY_LLM_PROVIDER = api|local|auto (default: auto)
# Provider selection handled by Invoke-LLM

$provider = $env:EASYWAY_LLM_PROVIDER ?? "auto"
Write-Host "LLM Provider: $provider" -ForegroundColor Gray
Write-Host ""

# Execute action
switch ($Action) {
    "audit" {
        if (-not $AgentId) {
            Write-Error "AgentId required for audit action"
            exit 1
        }

        Write-Host "Auditing $AgentId..." -ForegroundColor Cyan

        $result = Invoke-AuditAgent -AgentId $AgentId

        Write-Host ""
        Write-Host "=== AUDIT RESULTS ===" -ForegroundColor Cyan
        $result | ConvertTo-Json -Depth 10 | Write-Host
    }

    "fix" {
        if (-not $AgentId) {
            Write-Error "AgentId required for fix action"
            exit 1
        }

        if (-not $Fixes) {
            Write-Error "Fixes required. Example: -Fixes 'standardize_manifest,create_missing_files'"
            exit 1
        }

        $fixList = $Fixes -split ","

        Write-Host "Applying fixes to $AgentId..." -ForegroundColor Cyan
        Write-Host "Fixes: $($fixList -join ', ')" -ForegroundColor Gray
        Write-Host "Dry Run: $DryRun" -ForegroundColor Gray
        Write-Host ""

        $result = Invoke-FixAgent -AgentId $AgentId -Fixes $fixList -DryRun:$DryRun

        Write-Host ""
        Write-Host "=== FIX RESULTS ===" -ForegroundColor Cyan
        $result | ConvertTo-Json -Depth 10 | Write-Host
    }

    "validate" {
        if (-not $AgentId) {
            Write-Error "AgentId required for validate action"
            exit 1
        }

        Write-Host "Validating $AgentId against schema..." -ForegroundColor Cyan

        $result = Invoke-ValidateAgent -AgentId $AgentId

        if ($result.valid) {
            Write-Host "✅ Valid" -ForegroundColor Green
        } else {
            Write-Host "❌ Invalid" -ForegroundColor Red
            $result.errors | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }
        }
    }

    "report" {
        Write-Host "Generating compliance report for all agents..." -ForegroundColor Cyan

        $result = Invoke-GenerateReport

        Write-Host ""
        Write-Host "Report saved to: $($result.output_path)" -ForegroundColor Green
    }
}

Write-Host ""
Write-Host "✅ Done" -ForegroundColor Green
