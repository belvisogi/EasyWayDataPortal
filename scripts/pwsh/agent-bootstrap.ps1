<#
.SYNOPSIS
    Bootstraps a new agent from the standard factory template.

.DESCRIPTION
    Creates a new agent directory in `agents/<Name>`, populates it with
    standard files from `agents/templates/basic-agent`, and replaces
    placeholders {{AGENT_NAME}}, {{AGENT_ROLE}}, {{AGENT_DESCRIPTION}}.

.EXAMPLE
    .\agent-bootstrap.ps1 -Name "agent_pilot" -Role "Pilot Agent" -Description "First factory agent"
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$Name,

    [Parameter(Mandatory = $true)]
    [string]$Role,

    [Parameter(Mandatory = $true)]
    [string]$Description,

    [string]$TemplatePath = "..\..\agents\templates\basic-agent",
    [string]$AgentsRoot = "..\..\agents"
)

$ErrorActionPreference = "Stop"

# Resolve paths
$scriptDir = $PSScriptRoot
$absTemplate = Join-Path $scriptDir $TemplatePath
$absRoot = Join-Path $scriptDir $AgentsRoot
$targetDir = Join-Path $absRoot $Name

Write-Host "Bootstrap: Creating agent '$Name' ($Role)..." -ForegroundColor Cyan

# 1. Validation
if (Test-Path $targetDir) {
    throw "Agent '$Name' already exists at $targetDir"
}

if (-not (Test-Path $absTemplate)) {
    throw "Template not found at $absTemplate"
}

# 2. Copy Template
New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
Copy-Item -Path "$absTemplate\*" -Destination $targetDir -Recurse -Force

# Ensure empty dirs exist (git doesn't track them)
if (-not (Test-Path "$targetDir\memory")) { New-Item -ItemType Directory -Path "$targetDir\memory" | Out-Null }
if (-not (Test-Path "$targetDir\tools")) { New-Item -ItemType Directory -Path "$targetDir\tools" | Out-Null }

# 3. Customize Files
$files = Get-ChildItem -Path $targetDir -Recurse -File
foreach ($file in $files) {
    if ($file.Extension -in ".json", ".md", ".txt", ".ps1") {
        $content = Get-Content $file.FullName -Raw
        $newContent = $content -replace "\{\{AGENT_NAME\}\}", $Name `
            -replace "\{\{AGENT_ROLE\}\}", $Role `
            -replace "\{\{AGENT_DESCRIPTION\}\}", $Description
        
        if ($content -ne $newContent) {
            $newContent | Set-Content $file.FullName -Encoding utf8
            Write-Host "  > Customized $($file.Name)" -ForegroundColor Gray
        }
    }
}

# 4. Register Agent (Concept - usually updating a registry.json or just file existence)
# Current platform relies on folder existence + manifest.json, so implicit registration is done.

Write-Host "Agent '$Name' created successfully!" -ForegroundColor Green
Write-Host "Location: $targetDir"
Write-Host "Try it: pwsh scripts/pwsh/agent-llm-router.ps1 -Agent $Name -Prompt 'Hello'"
