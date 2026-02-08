<#
.SYNOPSIS
    Skills System loader for EasyWay Agents

.DESCRIPTION
    Provides functions to discover, load, and use skills dynamically.

.EXAMPLE
    # Load the Skills System
    . "$PSScriptRoot/Load-Skills.ps1"

    # Import specific skill
    Import-Skill -SkillId "security.cve-scan"

    # Use the skill
    $result = Invoke-CVEScan -ImageName "n8nio/n8n:1.123.20"

.NOTES
    Version: 2.0.0
    Created: 2026-02-08
#>

$script:SkillsRegistry = $null
$script:LoadedSkills = @{}
$script:SkillMetrics = @()

function Get-SkillsRegistry {
    <#
    .SYNOPSIS
        Get the skills registry (lazy loaded)
    #>
    if (-not $script:SkillsRegistry) {
        $registryPath = Join-Path $PSScriptRoot "registry.json"

        if (-not (Test-Path $registryPath)) {
            throw "Skills registry not found: $registryPath. Run Initialize-SkillsRegistry first."
        }

        $script:SkillsRegistry = Get-Content $registryPath -Raw | ConvertFrom-Json
        Write-Verbose "Loaded skills registry: $($script:SkillsRegistry.skills.Count) skills available"
    }
    return $script:SkillsRegistry
}

function Import-Skill {
    <#
    .SYNOPSIS
        Load a skill into the current session

    .PARAMETER SkillId
        Skill identifier (e.g., "security.cve-scan")

    .PARAMETER Force
        Reload skill even if already loaded

    .EXAMPLE
        Import-Skill -SkillId "security.cve-scan"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$SkillId,

        [Parameter(Mandatory = $false)]
        [switch]$Force
    )

    # Check if already loaded
    if ($script:LoadedSkills.ContainsKey($SkillId) -and -not $Force) {
        Write-Verbose "Skill $SkillId already loaded (use -Force to reload)"
        return $script:LoadedSkills[$SkillId].Metadata
    }

    # Find skill in registry
    $registry = Get-SkillsRegistry
    $skill = $registry.skills | Where-Object { $_.id -eq $SkillId }

    if (-not $skill) {
        throw "Skill not found in registry: $SkillId. Available skills: $($registry.skills.id -join ', ')"
    }

    # Check if deprecated
    if ($skill.deprecated) {
        Write-Warning "Skill $SkillId is DEPRECATED. $($skill.deprecation_message)"
    }

    # Resolve file path (relative to agents/ directory)
    $skillPath = Join-Path $PSScriptRoot ".." $skill.file
    $skillPath = $skillPath -replace "agents[\\/]agents[\\/]", "agents/"

    if (-not (Test-Path $skillPath)) {
        throw "Skill file not found: $skillPath (defined in registry as: $($skill.file))"
    }

    # Check dependencies
    $depCheck = Test-SkillDependencies -SkillId $SkillId
    if (-not $depCheck.AllDependenciesAvailable) {
        Write-Warning "Skill $SkillId has missing dependencies: $($depCheck.MissingDependencies -join ', ')"
        Write-Warning "The skill may not work correctly without these dependencies."
    }

    # Dot-source the skill at global scope so functions are available to callers
    try {
        # Get functions before loading
        $beforeFunctions = Get-ChildItem function: | Select-Object -ExpandProperty Name

        . $skillPath

        # Register new functions at global scope
        $afterFunctions = Get-ChildItem function: | Select-Object -ExpandProperty Name
        $newFunctions = $afterFunctions | Where-Object { $_ -notin $beforeFunctions }
        foreach ($fn in $newFunctions) {
            $fnBody = (Get-Item "function:$fn").ScriptBlock
            Set-Item -Path "function:global:$fn" -Value $fnBody
        }

        $script:LoadedSkills[$SkillId] = @{
            Metadata = $skill
            LoadedAt = Get-Date
            LoadedFrom = $skillPath
        }

        Write-Verbose "✅ Loaded skill: $($skill.name) ($SkillId) from $skillPath"

        # Log skill usage
        if ($env:AGENT_NAME) {
            $usageLog = @{
                SkillId = $SkillId
                Agent = $env:AGENT_NAME
                LoadedAt = Get-Date -Format "o"
                LoadedBy = $env:USERNAME
            } | ConvertTo-Json -Compress

            $logPath = Join-Path $PSScriptRoot ".." "logs" "skill-usage.jsonl"
            if (-not (Test-Path (Split-Path $logPath))) {
                New-Item -Path (Split-Path $logPath) -ItemType Directory -Force | Out-Null
            }
            Add-Content -Path $logPath -Value $usageLog
        }

        return $skill

    } catch {
        Write-Error "Failed to load skill ${SkillId}: $_"
        throw
    }
}

function Get-LoadedSkills {
    <#
    .SYNOPSIS
        Get list of currently loaded skills

    .EXAMPLE
        Get-LoadedSkills | Format-Table
    #>
    return $script:LoadedSkills.GetEnumerator() | ForEach-Object {
        [PSCustomObject]@{
            SkillId = $_.Key
            Name = $_.Value.Metadata.name
            Domain = $_.Value.Metadata.domain
            Version = $_.Value.Metadata.version
            LoadedAt = $_.Value.LoadedAt
            LoadedFrom = $_.Value.LoadedFrom
        }
    }
}

function Get-AvailableSkills {
    <#
    .SYNOPSIS
        Get list of available skills from registry

    .PARAMETER Domain
        Filter by domain (e.g., "security", "database")

    .PARAMETER Tags
        Filter by tags (e.g., "cve", "docker")

    .EXAMPLE
        Get-AvailableSkills -Domain "security"

    .EXAMPLE
        Get-AvailableSkills -Tags "docker", "vulnerability"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$Domain,

        [Parameter(Mandatory = $false)]
        [string[]]$Tags
    )

    $registry = Get-SkillsRegistry
    $skills = $registry.skills

    if ($Domain) {
        $skills = $skills | Where-Object { $_.domain -eq $Domain }
    }

    if ($Tags) {
        $skills = $skills | Where-Object {
            $skillTags = $_.tags
            $matchCount = ($Tags | Where-Object { $skillTags -contains $_ }).Count
            $matchCount -gt 0
        }
    }

    return $skills | ForEach-Object {
        [PSCustomObject]@{
            SkillId = $_.id
            Name = $_.name
            Domain = $_.domain
            Version = $_.version
            Description = $_.description
            Tags = ($_.tags -join ', ')
            Deprecated = if ($_.deprecated) { "⚠️ YES" } else { "" }
        }
    }
}

function Test-SkillDependencies {
    <#
    .SYNOPSIS
        Check if all dependencies for a skill are available

    .PARAMETER SkillId
        Skill identifier to check

    .EXAMPLE
        Test-SkillDependencies -SkillId "security.cve-scan"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$SkillId
    )

    $registry = Get-SkillsRegistry
    $skill = $registry.skills | Where-Object { $_.id -eq $SkillId }

    if (-not $skill) {
        throw "Skill not found: $SkillId"
    }

    $missingDeps = @()

    if ($skill.dependencies) {
        foreach ($dep in $skill.dependencies) {
            # Handle OR dependencies (e.g., "docker-scout OR snyk OR trivy")
            if ($dep -match " OR ") {
                $orDeps = $dep -split " OR " | ForEach-Object { $_.Trim() }
                $anyAvailable = $false

                foreach ($orDep in $orDeps) {
                    $cmd = Get-Command $orDep -ErrorAction SilentlyContinue
                    if ($cmd) {
                        $anyAvailable = $true
                        break
                    }
                }

                if (-not $anyAvailable) {
                    $missingDeps += $dep
                }
            } else {
                # Single dependency
                $cmd = Get-Command $dep -ErrorAction SilentlyContinue
                if (-not $cmd) {
                    $missingDeps += $dep
                }
            }
        }
    }

    return [PSCustomObject]@{
        SkillId = $SkillId
        AllDependenciesAvailable = $missingDeps.Count -eq 0
        MissingDependencies = $missingDeps
        RequiredDependencies = $skill.dependencies
    }
}

function Import-SkillsFromManifest {
    <#
    .SYNOPSIS
        Load all skills required by an agent manifest

    .PARAMETER ManifestPath
        Path to agent manifest.json

    .PARAMETER IncludeOptional
        Also load optional skills

    .EXAMPLE
        Import-SkillsFromManifest -ManifestPath "agents/agent_vulnerability_scanner/manifest.json"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ManifestPath,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeOptional
    )

    if (-not (Test-Path $ManifestPath)) {
        throw "Manifest not found: $ManifestPath"
    }

    $manifest = Get-Content $ManifestPath -Raw | ConvertFrom-Json

    # Load required skills
    if ($manifest.skills_required) {
        Write-Verbose "Loading $($manifest.skills_required.Count) required skills..."
        foreach ($skillId in $manifest.skills_required) {
            Import-Skill -SkillId $skillId
        }
    }

    # Load optional skills if requested
    if ($IncludeOptional -and $manifest.skills_optional) {
        Write-Verbose "Loading $($manifest.skills_optional.Count) optional skills..."
        foreach ($skillId in $manifest.skills_optional) {
            try {
                Import-Skill -SkillId $skillId
            } catch {
                Write-Warning "Failed to load optional skill ${skillId}: $_"
            }
        }
    }

    Write-Host "✅ Skills loaded from $ManifestPath" -ForegroundColor Green
    Get-LoadedSkills | Format-Table -AutoSize
}

function Initialize-SkillsRegistry {
    <#
    .SYNOPSIS
        Create/update skills registry by scanning skills directory

    .DESCRIPTION
        Scans agents/skills/ directory and generates registry.json

    .EXAMPLE
        Initialize-SkillsRegistry
    #>
    [CmdletBinding()]
    param()

    $skillsPath = Join-Path $PSScriptRoot "."
    $registryPath = Join-Path $skillsPath "registry.json"

    Write-Host "Scanning skills directory: $skillsPath" -ForegroundColor Cyan

    $skills = @()
    $domains = Get-ChildItem -Path $skillsPath -Directory | Where-Object { $_.Name -ne "tests" }

    foreach ($domain in $domains) {
        Write-Verbose "Scanning domain: $($domain.Name)"

        $skillFiles = Get-ChildItem -Path $domain.FullName -Filter "*.ps1" -Exclude "*.Tests.ps1"

        foreach ($file in $skillFiles) {
            Write-Verbose "  Found skill: $($file.Name)"

            # Extract function name from file (assumes Verb-Noun.ps1 format)
            $functionName = $file.BaseName

            # Basic skill metadata (can be enhanced by parsing file content)
            $skillId = "$($domain.Name).$($functionName.ToLower() -replace '-', '-')"

            $skill = @{
                id = $skillId
                name = $functionName
                domain = $domain.Name
                file = "skills/$($domain.Name)/$($file.Name)"
                version = "1.0.0"
                description = "Skill: $functionName"
                parameters = @()
                dependencies = @()
                tags = @($domain.Name)
            }

            $skills += $skill
        }
    }

    $registry = @{
        version = "2.0.0"
        last_updated = (Get-Date -Format "o")
        skills = $skills
    }

    $registry | ConvertTo-Json -Depth 10 | Set-Content -Path $registryPath

    Write-Host "✅ Skills registry created: $registryPath ($($skills.Count) skills)" -ForegroundColor Green

    return $registry
}

# Auto-initialize if registry doesn't exist
$registryPath = Join-Path $PSScriptRoot "registry.json"
if (-not (Test-Path $registryPath)) {
    Write-Warning "Skills registry not found. Run Initialize-SkillsRegistry to create it."
}

# Export functions (only when loaded as module, not dot-sourced)
if ($MyInvocation.ScriptName -and (Get-Module -Name (Split-Path $MyInvocation.ScriptName -LeafBase) -ErrorAction SilentlyContinue)) {
    Export-ModuleMember -Function @(
        'Get-SkillsRegistry',
        'Import-Skill',
        'Get-LoadedSkills',
        'Get-AvailableSkills',
        'Test-SkillDependencies',
        'Import-SkillsFromManifest',
        'Initialize-SkillsRegistry'
    )
}
