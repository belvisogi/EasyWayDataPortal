# upgrade-agents-v2.ps1
# Upgrades all non-Level-2 agents to manifest v2.0 structure
# Creates missing files: PROMPTS.md, priority.json, memory/context.json, templates/

param(
    [string]$AgentsDir = "$PSScriptRoot/../agents",
    [switch]$DryRun,
    [string[]]$SkipAgents = @("agent_security", "agent_dba", "agent_docs_sync", "agent_pr_manager", "agent_vulnerability_scanner", "agent_audit")
)

$timestamp = Get-Date -Format "o"
$upgraded = 0
$skipped = 0

# Get all agent directories
$agentDirs = Get-ChildItem -Path $AgentsDir -Directory -Filter "agent_*"

foreach ($dir in $agentDirs) {
    $agentId = $dir.Name

    if ($agentId -in $SkipAgents) {
        Write-Host "[SKIP] $agentId (Level 2 or excluded)" -ForegroundColor Yellow
        $skipped++
        continue
    }

    $manifestPath = Join-Path $dir.FullName "manifest.json"
    if (-not (Test-Path $manifestPath)) {
        Write-Warning "[WARN] $agentId - No manifest.json found"
        continue
    }

    Write-Host "[UPGRADE] $agentId" -ForegroundColor Cyan

    # Read manifest
    $manifest = Get-Content $manifestPath -Raw | ConvertFrom-Json

    # --- FIX 1: Convert allowed_paths from array to object ---
    if ($manifest.allowed_paths -is [System.Array]) {
        $readPaths = @($manifest.allowed_paths)
        $writePaths = @(
            "agents/$agentId/memory/",
            "agents/logs/"
        )
        $manifest.allowed_paths = @{
            read  = $readPaths
            write = $writePaths
        }
        Write-Host "  [FIX] allowed_paths: array -> object (read/write)" -ForegroundColor Green
    }

    # --- FIX 2: Add error_handling if missing ---
    if (-not $manifest.error_handling) {
        $manifest | Add-Member -NotePropertyName "error_handling" -NotePropertyValue @{
            retry_count         = 2
            retry_delay_seconds = 15
            fallback_mode       = "log_and_skip"
            alert_on_failure    = $false
        }
        Write-Host "  [FIX] Added error_handling" -ForegroundColor Green
    }

    # --- FIX 3: Add skills_optional if missing ---
    if (-not $manifest.skills_optional) {
        $manifest | Add-Member -NotePropertyName "skills_optional" -NotePropertyValue @(
            "utilities.json-validate",
            "utilities.retry-backoff"
        )
        Write-Host "  [FIX] Added skills_optional" -ForegroundColor Green
    }

    # --- FIX 4: Add classification if missing ---
    if (-not $manifest.classification) {
        $manifest | Add-Member -NotePropertyName "classification" -NotePropertyValue "arm"
        Write-Host "  [FIX] Added classification: arm" -ForegroundColor Green
    }

    # --- FIX 5: Ensure knowledge_sources use object format ---
    if ($manifest.knowledge_sources -and $manifest.knowledge_sources.Count -gt 0) {
        $newKS = @()
        foreach ($ks in $manifest.knowledge_sources) {
            if ($ks -is [string]) {
                $newKS += @{
                    priority = "medium"
                    path     = $ks
                    type     = if ($ks -match "\.jsonl?$") { "data" } elseif ($ks -match "\.(ps1|js|ts)$") { "code" } else { "document" }
                }
            }
            else {
                $newKS += $ks
            }
        }
        $manifest.knowledge_sources = $newKS
        Write-Host "  [FIX] Normalized knowledge_sources to object format" -ForegroundColor Green
    }

    # Save manifest
    if (-not $DryRun) {
        $manifest | ConvertTo-Json -Depth 10 | Set-Content $manifestPath -Encoding utf8
    }

    # --- CREATE MISSING FILES ---

    # PROMPTS.md
    $promptsPath = Join-Path $dir.FullName "PROMPTS.md"
    if (-not (Test-Path $promptsPath)) {
        $role = $manifest.role -replace "_", " "
        $desc = $manifest.description
        $promptContent = @"
# System Prompt: $($manifest.name)

You are **$role**, an EasyWay platform agent.
$desc

## Operating Principles

1. Follow the EasyWay Agent Framework 2.0 standards
2. Always validate inputs before processing
3. Log all actions for auditability
4. Use WhatIf mode when available for preview
5. Respect allowed_paths and required_gates

## Output Format

Respond in Italian. Structure output as:

``````
## Risultato

### Azione: [action_name]
### Stato: [OK/WARNING/ERROR]

### Dettagli
- ...

### Prossimi Passi
1. ...
``````
"@
        if (-not $DryRun) {
            Set-Content $promptsPath -Value $promptContent -Encoding utf8
        }
        Write-Host "  [CREATE] PROMPTS.md" -ForegroundColor Green
    }

    # priority.json
    $priorityPath = Join-Path $dir.FullName "priority.json"
    if (-not (Test-Path $priorityPath)) {
        $actions = @()
        if ($manifest.actions) {
            $weight = 1.0
            foreach ($action in $manifest.actions) {
                $actions += @{
                    action = $action.name
                    weight = [math]::Round($weight, 1)
                }
                $weight -= 0.1
                if ($weight -lt 0.3) { $weight = 0.3 }
            }
        }
        $priorityContent = @{
            id       = $agentId
            priority = $actions
            rules    = @()
        } | ConvertTo-Json -Depth 5

        if (-not $DryRun) {
            Set-Content $priorityPath -Value $priorityContent -Encoding utf8
        }
        Write-Host "  [CREATE] priority.json" -ForegroundColor Green
    }

    # memory/context.json
    $memoryDir = Join-Path $dir.FullName "memory"
    $contextPath = Join-Path $memoryDir "context.json"
    if (-not (Test-Path $contextPath)) {
        if (-not (Test-Path $memoryDir)) {
            if (-not $DryRun) { New-Item -Path $memoryDir -ItemType Directory -Force | Out-Null }
        }
        $contextContent = @{
            created     = $timestamp
            updated     = $timestamp
            stats       = @{
                total_runs            = 0
                successful            = 0
                errors                = 0
                last_run              = $null
                avg_duration_seconds  = 0
                success_rate          = 0
            }
            knowledge   = @{}
            preferences = @{}
            last_errors = @()
            first_run   = $false
        } | ConvertTo-Json -Depth 5

        if (-not $DryRun) {
            Set-Content $contextPath -Value $contextContent -Encoding utf8
        }
        Write-Host "  [CREATE] memory/context.json" -ForegroundColor Green
    }

    # templates/ directory with sample intent
    $templatesDir = Join-Path $dir.FullName "templates"
    if (-not (Test-Path $templatesDir)) {
        if (-not $DryRun) { New-Item -Path $templatesDir -ItemType Directory -Force | Out-Null }

        # Create sample intent for first action
        if ($manifest.actions -and $manifest.actions.Count -gt 0) {
            $firstAction = $manifest.actions[0]
            $actionSlug = $firstAction.name -replace ":", "-"
            $samplePath = Join-Path $templatesDir "intent.$actionSlug.sample.json"

            $sampleParams = @{}
            if ($firstAction.params) {
                $firstAction.params.PSObject.Properties | ForEach-Object {
                    $paramName = $_.Name
                    $paramDef = $_.Value
                    $sampleParams[$paramName] = switch ($paramDef.type) {
                        "string"  { "<$paramName>" }
                        "boolean" { $true }
                        "number"  { 1 }
                        "array"   { @("<item1>") }
                        "object"  { @{} }
                        default   { "<$paramName>" }
                    }
                }
            }

            $sampleContent = @{
                action        = $firstAction.name
                params        = $sampleParams
                whatIf        = $true
                nonInteractive = $true
                correlationId = "$actionSlug-001"
            } | ConvertTo-Json -Depth 5

            if (-not $DryRun) {
                Set-Content $samplePath -Value $sampleContent -Encoding utf8
            }
            Write-Host "  [CREATE] templates/intent.$actionSlug.sample.json" -ForegroundColor Green
        }
    }

    $upgraded++
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host " Upgrade Complete" -ForegroundColor Cyan
Write-Host " Upgraded: $upgraded" -ForegroundColor Green
Write-Host " Skipped:  $skipped" -ForegroundColor Yellow
Write-Host " Mode:     $(if ($DryRun) { 'DRY RUN' } else { 'APPLIED' })" -ForegroundColor White
Write-Host "========================================" -ForegroundColor Cyan
