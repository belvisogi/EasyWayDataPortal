param(
    [string]$AgentsDir = "Rules/agents",
    [switch]$Fix
)

$agents = Get-ChildItem -Path $AgentsDir -Directory

foreach ($agentDir in $agents) {
    $manifestPath = Join-Path $agentDir.FullName "manifest.json"
    if (-not (Test-Path $manifestPath)) {
        Write-Host "Skipping $($agentDir.Name) (no manifest.json)" -ForegroundColor Yellow
        continue
    }

    $manifestJson = Get-Content -Raw $manifestPath | ConvertFrom-Json
    $modified = $false

    # 1. Standardize required_gates
    if (-not $manifestJson.PSObject.Properties['required_gates']) {
        Write-Host "[$($agentDir.Name)] Adding required_gates..." -ForegroundColor Cyan
        $manifestJson | Add-Member -MemberType NoteProperty -Name "required_gates" -Value @("KB_Consistency")
        $modified = $true
    } elseif ($manifestJson.required_gates.Count -eq 0) {
        Write-Host "[$($agentDir.Name)] Populating required_gates..." -ForegroundColor Cyan
        $manifestJson.required_gates = @("KB_Consistency")
        $modified = $true
    }

    # 2. Standardize allowed_tools
    if (-not $manifestJson.PSObject.Properties['allowed_tools']) {
        Write-Host "[$($agentDir.Name)] Adding allowed_tools..." -ForegroundColor Cyan
        $manifestJson | Add-Member -MemberType NoteProperty -Name "allowed_tools" -Value @("pwsh")
        $modified = $true
    }

    # 3. Standardize knowledge_sources
    if (-not $manifestJson.PSObject.Properties['knowledge_sources']) {
        Write-Host "[$($agentDir.Name)] Adding knowledge_sources..." -ForegroundColor Cyan
        $manifestJson | Add-Member -MemberType NoteProperty -Name "knowledge_sources" -Value @("Wiki/AdaDataProject.wiki/agents-governance.md")
        $modified = $true
    }
    
    # 4. Standardize actions (if missing, ensure empty array)
    if (-not $manifestJson.PSObject.Properties['actions']) {
        Write-Host "[$($agentDir.Name)] Adding actions..." -ForegroundColor Cyan
        $manifestJson | Add-Member -MemberType NoteProperty -Name "actions" -Value @()
        $modified = $true
    }


    # 5. Ensure README
    $readmePath = Join-Path $agentDir.FullName "README.md"
    if (-not (Test-Path $readmePath)) {
        Write-Host "[$($agentDir.Name)] Creating README.md..." -ForegroundColor Cyan
        $role = if ($manifestJson.role) { $manifestJson.role } else { $agentDir.Name }
        $desc = if ($manifestJson.description) { $manifestJson.description } else { "Agent logic for $($agentDir.Name)" }
        
        $readmeContent = @"
# $role

$desc

## Overview
This agent is part of the Axet automation fleet.

## Capabilities
- **Role**: $role
- **Tools**: $(($manifestJson.allowed_tools) -join ', ')

## Usage
Refer to \`axctl\` documentation for invoking this agent via intents.
"@
        if ($Fix) {
            Set-Content -Path $readmePath -Value $readmeContent -Encoding utf8
        }
    }
    
    # Update manifest reference to README if missing
    if (-not $manifestJson.PSObject.Properties['readme']) {
         $manifestJson | Add-Member -MemberType NoteProperty -Name "readme" -Value "agents/$($agentDir.Name)/README.md"
         $modified = $true
    }

    if ($modified -and $Fix) {
        Write-Host "[$($agentDir.Name)] Saving manifest updates..." -ForegroundColor Green
        $manifestJson | ConvertTo-Json -Depth 5 | Set-Content -Path $manifestPath -Encoding utf8
    } elseif ($modified) {
        Write-Host "[$($agentDir.Name)] DRY RUN: Would update manifest." -ForegroundColor Gray
    }
}

