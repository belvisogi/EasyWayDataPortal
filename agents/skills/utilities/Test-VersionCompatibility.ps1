<#
.SYNOPSIS
    Test version compatibility against compatibility matrix

.DESCRIPTION
    Checks if a component version is compatible with its dependencies
    based on rules defined in compatibility-matrix.json

.PARAMETER Component
    Component name (e.g., "n8n", "postgres", "traefik")

.PARAMETER Version
    Version to check (e.g., "1.123.20", "15.10", "v2.10")

.PARAMETER MatrixFile
    Path to compatibility-matrix.json

.PARAMETER CurrentVersions
    Hashtable of current versions of other components (for dependency checking)

.EXAMPLE
    Test-VersionCompatibility -Component "n8n" -Version "1.123.20"

.EXAMPLE
    $versions = @{ postgres = "15.10"; qdrant = "v1.12.4" }
    Test-VersionCompatibility -Component "n8n" -Version "1.123.20" -CurrentVersions $versions

.OUTPUTS
    PSCustomObject with:
    - Component: string
    - Version: string
    - IsCompatible: boolean
    - Issues: array of compatibility issues
    - Recommendations: array of recommendations
    - CheckedAt: datetime
#>
function Test-VersionCompatibility {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Component,

        [Parameter(Mandatory = $true)]
        [string]$Version,

        [Parameter(Mandatory = $false)]
        [string]$MatrixFile = "./compatibility-matrix.json",

        [Parameter(Mandatory = $false)]
        [hashtable]$CurrentVersions = @{}
    )

    try {
        # Load compatibility matrix
        if (-not (Test-Path $MatrixFile)) {
            throw "Compatibility matrix not found: $MatrixFile"
        }

        $matrix = Get-Content $MatrixFile -Raw | ConvertFrom-Json

        # Find component in matrix
        $componentRules = $matrix.compatibility_rules.$Component

        if (-not $componentRules) {
            Write-Warning "No compatibility rules found for component: $Component"
            return [PSCustomObject]@{
                Component = $Component
                Version = $Version
                IsCompatible = $null
                Issues = @("No compatibility rules defined for $Component")
                Recommendations = @("Add $Component to compatibility-matrix.json")
                CheckedAt = Get-Date -Format "o"
            }
        }

        # Find version-specific rules (exact match or use latest if not found)
        $versionRules = $componentRules.$Version

        if (-not $versionRules) {
            # Try to find closest version or use general rules
            $availableVersions = $componentRules.PSObject.Properties.Name
            Write-Verbose "Version $Version not found in matrix. Available: $($availableVersions -join ', ')"

            # Use first available version as fallback (should be improved with semver comparison)
            $versionRules = $componentRules.($availableVersions[0])
            Write-Warning "Using rules for version $($availableVersions[0]) as fallback"
        }

        $issues = @()
        $recommendations = @()

        # Check required dependencies
        if ($versionRules.requires) {
            foreach ($dep in $versionRules.requires.PSObject.Properties) {
                $depName = $dep.Name
                $depRequirements = $dep.Value

                if ($CurrentVersions.ContainsKey($depName)) {
                    $currentDepVersion = $CurrentVersions[$depName]

                    # Check minimum version
                    if ($depRequirements.min) {
                        if (-not (Test-VersionMeetsRequirement -Version $currentDepVersion -Requirement $depRequirements.min -Operator ">=")) {
                            $issues += "[$Component] requires $depName >= $($depRequirements.min), but found $currentDepVersion"
                        }
                    }

                    # Check recommended version
                    if ($depRequirements.recommended -and $currentDepVersion -ne $depRequirements.recommended) {
                        $recommendations += "[$Component] recommends $depName $($depRequirements.recommended) for best compatibility"
                    }

                    # Check for known issues
                    if ($depRequirements.issue) {
                        $issues += "[$Component → $depName] $($depRequirements.issue)"
                        if ($depRequirements.reason) {
                            $issues[-1] += " (Reason: $($depRequirements.reason))"
                        }
                    }
                } else {
                    # Dependency version not provided
                    $recommendations += "Provide current version of $depName to check compatibility"
                }
            }
        }

        # Check compatible_with relationships
        if ($versionRules.compatible_with) {
            foreach ($compat in $versionRules.compatible_with.PSObject.Properties) {
                $compatName = $compat.Name
                $compatRequirements = $compat.Value

                if ($CurrentVersions.ContainsKey($compatName)) {
                    $currentCompatVersion = $CurrentVersions[$compatName]

                    # Check minimum version
                    if ($compatRequirements.min) {
                        if (-not (Test-VersionMeetsRequirement -Version $currentCompatVersion -Requirement $compatRequirements.min -Operator ">=")) {
                            $issues += "[$Component] is compatible with $compatName >= $($compatRequirements.min), but found $currentCompatVersion"
                        }
                    }

                    # Check if in tested versions
                    if ($compatRequirements.tested -and $currentCompatVersion -notin $compatRequirements.tested) {
                        $recommendations += "[$Component] has been tested with $compatName versions: $($compatRequirements.tested -join ', '). Current: $currentCompatVersion (untested)"
                    }
                }
            }
        }

        # Check for breaking changes
        if ($versionRules.breaking_changes) {
            foreach ($change in $versionRules.breaking_changes) {
                $issues += "⚠️ BREAKING CHANGE in $Component $Version: $change"
            }
        }

        # Check for known issues
        if ($versionRules.known_issues) {
            foreach ($issue in $versionRules.known_issues.PSObject.Properties) {
                $issueKey = $issue.Name
                $issueDesc = $issue.Value
                $issues += "❌ KNOWN ISSUE ($issueKey): $issueDesc"
            }
        }

        $isCompatible = $issues.Count -eq 0

        return [PSCustomObject]@{
            Component = $Component
            Version = $Version
            IsCompatible = $isCompatible
            Issues = $issues
            Recommendations = $recommendations
            CheckedAt = Get-Date -Format "o"
            MatrixFile = $MatrixFile
        }

    } catch {
        Write-Error "Version compatibility check failed for ${Component}:${Version}: $_"
        throw
    }
}

function Test-VersionMeetsRequirement {
    <#
    .SYNOPSIS
        Helper function to compare versions
    #>
    param(
        [string]$Version,
        [string]$Requirement,
        [string]$Operator = ">="
    )

    # Remove 'v' prefix if present
    $Version = $Version -replace '^v', ''
    $Requirement = $Requirement -replace '^v', ''

    try {
        $v1 = [version]$Version
        $v2 = [version]$Requirement

        switch ($Operator) {
            ">=" { return $v1 -ge $v2 }
            ">" { return $v1 -gt $v2 }
            "<=" { return $v1 -le $v2 }
            "<" { return $v1 -lt $v2 }
            "==" { return $v1 -eq $v2 }
            default { throw "Unknown operator: $Operator" }
        }
    } catch {
        # Fallback to string comparison if not valid version format
        Write-Verbose "Failed to parse as version, using string comparison: $Version vs $Requirement"

        switch ($Operator) {
            ">=" { return $Version -ge $Requirement }
            ">" { return $Version -gt $Requirement }
            "<=" { return $Version -le $Requirement }
            "<" { return $Version -lt $Requirement }
            "==" { return $Version -eq $Requirement }
            default { throw "Unknown operator: $Operator" }
        }
    }
}
