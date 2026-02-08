<#
.SYNOPSIS
Auto-generates skills registry from PowerShell skill files

.DESCRIPTION
Scans agents/skills/ directory for .ps1 files, extracts metadata from comments,
and generates/updates registry.json with skill definitions.

.EXAMPLE
pwsh scripts/pwsh/generate-skills-registry.ps1
#>

param(
    [string]$SkillsDir = "agents/skills",
    [string]$OutputFile = "agents/skills/registry.json",
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"

Write-Host "🔍 Scanning skills directory: $SkillsDir" -ForegroundColor Cyan

# Find all PowerShell skill files
$skillFiles = Get-ChildItem -Path $SkillsDir -Filter "*.ps1" -Recurse -File | 
Where-Object { $_.Name -ne "Load-Skills.ps1" }

Write-Host "Found $($skillFiles.Count) skill files" -ForegroundColor Green

$skills = @()

foreach ($file in $skillFiles) {
    Write-Host "  Processing: $($file.Name)" -ForegroundColor Gray
    
    # Extract metadata from file content
    $content = Get-Content $file.FullName -Raw
    
    # Parse function name
    if ($content -match 'function\s+([\w-]+)') {
        $functionName = $Matches[1]
    }
    else {
        Write-Warning "  ⚠️  No function found in $($file.Name), skipping"
        continue
    }
    
    # Parse SYNOPSIS
    $description = ""
    if ($content -match '\.SYNOPSIS\s+([^\r\n]+)') {
        $description = $Matches[1].Trim()
    }
    
    # Determine domain from directory structure
    $relativePath = $file.FullName.Replace((Get-Location).Path, "").TrimStart('\', '/')
    $domain = if ($relativePath -match 'skills[/\\](\w+)[/\\]') { $Matches[1] } else { "utilities" }
    
    # Generate skill ID (domain.kebab-case-name)
    $skillId = "$domain.$($functionName -replace '^(Invoke-|Test-|ConvertTo-|Send-)', '' -replace '([A-Z])', '-$1' -replace '^-', '' -replace '--', '-')".ToLower()
    
    # Parse parameters
    $parameters = @()
    if ($content -match 'param\s*\(([\s\S]*?)\)') {
        $paramBlock = $Matches[1]
        $paramMatches = [regex]::Matches($paramBlock, '\[(\w+)\]\s*\$(\w+)')
        foreach ($match in $paramMatches) {
            $parameters += @{
                name     = $match.Groups[2].Value
                type     = $match.Groups[1].Value.ToLower()
                required = $paramBlock -match "\[\w+\]\s*\`$$($match.Groups[2].Value)[^\[]"
            }
        }
    }
    
    # Determine dependencies
    $dependencies = @()
    if ($content -match 'docker') { $dependencies += "docker" }
    if ($content -match 'az\s') { $dependencies += "az" }
    if ($content -match 'python') { $dependencies += "python3" }
    if ($content -match 'qdrant') { $dependencies += "qdrant-client" }
    
    # Generate tags
    $tags = @($domain)
    if ($functionName -match 'RAG') { $tags += "rag" }
    if ($functionName -match 'Search') { $tags += "search" }
    if ($functionName -match 'Security|Secret|CVE') { $tags += "security" }
    if ($functionName -match 'Validate|Test') { $tags += "validation" }
    
    $skill = [PSCustomObject]@{
        id           = $skillId
        name         = $functionName
        domain       = $domain
        file         = $relativePath.Replace('\', '/')
        version      = "1.0.0"
        description  = $description
        parameters   = $parameters
        dependencies = $dependencies
        tags         = $tags
    }
    
    $skills += $skill
}

# Sort skills by domain, then by name
$skills = $skills | Sort-Object domain, name

# Create registry object
$registry = [PSCustomObject]@{
    version      = "2.1.0"
    last_updated = (Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ")
    skills       = $skills
}

if ($DryRun) {
    Write-Host "`n📋 DRY RUN - Would generate:" -ForegroundColor Yellow
    $registry | ConvertTo-Json -Depth 10 | Write-Host
}
else {
    # Write to file
    $registry | ConvertTo-Json -Depth 10 | Set-Content $OutputFile -Encoding UTF8
    Write-Host "`n✅ Registry generated: $OutputFile" -ForegroundColor Green
    Write-Host "   Skills: $($skills.Count)" -ForegroundColor Cyan
    Write-Host "   Domains: $($skills.domain | Select-Object -Unique | Measure-Object).Count" -ForegroundColor Cyan
}
