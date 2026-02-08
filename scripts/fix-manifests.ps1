
# scripts/fix-manifests.ps1
# Standardizes all agent manifests to Framework 2.0 (adding missing fields)
# Usage: pwsh scripts/fix-manifests.ps1 [-DryRun]

param (
    [switch]$DryRun
)

$AgentsDir = Join-Path $PSScriptRoot "../agents"
$StandardVersion = "1.0.0" # Default version for updated agents
$Owner = "team-platform"

Write-Host "🔍 Starting Agent Manifest Standardization..." -ForegroundColor Cyan

# 1. Get all agent directories
$Agents = Get-ChildItem -Path $AgentsDir -Directory

foreach ($Agent in $Agents) {
    $AgentName = $Agent.Name
    $ManifestPath = Join-Path $Agent.FullName "manifest.json"

    if (-not (Test-Path $ManifestPath)) {
        Write-Warning "⚠️  Skipping $AgentName (No manifest.json found)"
        continue
    }

    Write-Host "Processing $AgentName..." -NoNewline

    # 2. Read existing manifest
    try {
        $ManifestJson = Get-Content -Path $ManifestPath -Raw -ErrorAction Stop
        $Manifest = $ManifestJson | ConvertFrom-Json
    }
    catch {
        Write-Error "`n❌ Failed to parse JSON for $AgentName"
        continue
    }

    $OriginalJson = $Manifest | ConvertTo-Json -Depth 10 -Compress
    $Modified = $false

    # 3. Apply Standard Fields (if missing)

    # ID
    if (-not $Manifest.id) {
        $Manifest | Add-Member -NotePropertyName "id" -NotePropertyValue $AgentName
        $Modified = $true
    }

    # Owner
    if (-not $Manifest.owner) {
        $Manifest | Add-Member -NotePropertyName "owner" -NotePropertyValue $Owner
        $Modified = $true
    }

    # Version
    if (-not $Manifest.version) {
        if ($AgentName -eq "agent_security") {
            $Manifest | Add-Member -NotePropertyName "version" -NotePropertyValue "2.0.0"
        }
        else {
            $Manifest | Add-Member -NotePropertyName "version" -NotePropertyValue $StandardVersion
        }
        $Modified = $true
    }

    # Evolution Level
    if (-not $Manifest.evolution_level) {
        $Level = if ($AgentName -eq "agent_security") { 2 } else { 1 }
        $Manifest | Add-Member -NotePropertyName "evolution_level" -NotePropertyValue $Level
        $Modified = $true
    }

    # Context Config (Memory)
    if (-not $Manifest.context_config) {
        $ContextConfig = [ordered]@{
            memory_files         = @("agents/kb/recipes.jsonl")
            context_limit_tokens = 128000
            enable_memory        = $true
        }
        $Manifest | Add-Member -NotePropertyName "context_config" -NotePropertyValue $ContextConfig
        $Modified = $true
    }

    # Skills Required
    if (-not $Manifest.skills_required) {
        $Manifest | Add-Member -NotePropertyName "skills_required" -NotePropertyValue @()
        $Modified = $true
    }

    # LLM Config (The big missing piece)
    if (-not $Manifest.llm_config) {
        if ($AgentName -eq "agent_security") {
            # Special case: DeepSeek for security agent (as per README)
            $LlmConfig = [ordered]@{
                provider      = "deepseek"
                model         = "deepseek-chat"
                temperature   = 0.1
                system_prompt = "agents/$AgentName/PROMPTS.md"
                tools         = @("function_calling")
            }
        }
        else {
            # Default case: GPT-4o
            $LlmConfig = [ordered]@{
                provider      = "openai"
                model         = "gpt-4o"
                temperature   = 0.0
                system_prompt = "agents/$AgentName/PROMPTS.md"
                tools         = @("function_calling")
            }
        }
        $Manifest | Add-Member -NotePropertyName "llm_config" -NotePropertyValue $LlmConfig
        $Modified = $true
    }

    # 4. Save if modified
    if ($Modified) {
        $NewJson = $Manifest | ConvertTo-Json -Depth 10
        
        if ($DryRun) {
            Write-Host " [WOULD UPDATE]" -ForegroundColor Yellow
            # Write-Host $NewJson
        }
        else {
            $NewJson | Set-Content -Path $ManifestPath
            Write-Host " ✅ UPDATED" -ForegroundColor Green
        }
    }
    else {
        Write-Host " (No changes needed)" -ForegroundColor Gray
    }
}

Write-Host "`n✨ Standardization Complete." -ForegroundColor Cyan
