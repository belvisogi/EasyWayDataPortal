#Requires -Version 5.1
<#
.SYNOPSIS
Genera registry macro-skill consumabile da console/UI a partire da docs/skills/catalog.json.

.DESCRIPTION
Mantiene separato il layer macro-use-case dal registry runtime agents/skills/registry.json.
Produce docs/skills/catalog.generated.json con metadati normalizzati per UI.

.EXAMPLE
pwsh scripts/pwsh/generate-macro-skills-registry.ps1

.EXAMPLE
pwsh scripts/pwsh/generate-macro-skills-registry.ps1 -ValidateOnly
#>
[CmdletBinding()]
param(
    [string]$CatalogPath = "docs/skills/catalog.json",
    [string]$SchemaPath = "docs/skills/catalog.schema.json",
    [string]$OutputPath = "docs/skills/catalog.generated.json",
    [switch]$ValidateOnly
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Assert-Path {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$Label
    )
    if (-not (Test-Path $Path)) {
        throw "$Label not found: $Path"
    }
}

Assert-Path -Path $CatalogPath -Label "Catalog"
Assert-Path -Path $SchemaPath -Label "Schema"

$catalog = Get-Content $CatalogPath -Raw -Encoding UTF8 | ConvertFrom-Json
$schema = Get-Content $SchemaPath -Raw -Encoding UTF8 | ConvertFrom-Json

if (-not $catalog.version -or -not $catalog.skills) {
    throw "Invalid catalog: missing version or skills."
}

foreach ($skill in @($catalog.skills)) {
    if ($skill.type -ne "macro-use-case") {
        throw "Invalid skill type for '$($skill.id)': $($skill.type)"
    }
    if ($skill.id -notmatch '^[a-z0-9]+(?:-[a-z0-9]+)*$') {
        throw "Invalid skill id format: $($skill.id)"
    }
    if (-not $skill.entrypoint) {
        throw "Missing entrypoint for skill: $($skill.id)"
    }
    if (@($skill.references).Count -eq 0) {
        throw "Missing references for skill: $($skill.id)"
    }
    if (@($skill.success_criteria).Count -eq 0) {
        throw "Missing success_criteria for skill: $($skill.id)"
    }
}

Write-Host "Catalog validation OK: $(@($catalog.skills).Count) macro skill(s)." -ForegroundColor Green

if ($ValidateOnly) {
    return
}

$generated = [ordered]@{
    version = $catalog.version
    generated_at = (Get-Date).ToUniversalTime().ToString("o")
    source_catalog = $CatalogPath
    skills = @()
}

foreach ($skill in @($catalog.skills)) {
    $generated.skills += [ordered]@{
        id = $skill.id
        name = $skill.name
        type = $skill.type
        domain = "macro-use-case"
        description = $skill.summary
        entrypoint = $skill.entrypoint
        agents = @($skill.agents)
        orchestrations = @($skill.orchestrations)
        references = @($skill.references)
        success_criteria = @($skill.success_criteria)
    }
}

$generated | ConvertTo-Json -Depth 10 | Set-Content $OutputPath -Encoding UTF8
Write-Host "Generated: $OutputPath" -ForegroundColor Green
