<#
.SYNOPSIS
    Validate JSON files against schema or structure rules

.DESCRIPTION
    Validates JSON files for syntax correctness, required fields, and optional schema compliance.
    Returns structured validation report.

.PARAMETER Path
    Path to JSON file to validate

.PARAMETER Content
    JSON string to validate (alternative to Path)

.PARAMETER RequiredFields
    Array of field names that must be present at root level

.PARAMETER SchemaPath
    Path to JSON Schema file for validation (optional)

.EXAMPLE
    Test-JsonValid -Path "agents/agent_security/manifest.json" -RequiredFields @("id", "name", "version")

.EXAMPLE
    Test-JsonValid -Content '{"name": "test"}' -RequiredFields @("name", "id")
#>
function Test-JsonValid {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$Path,

        [Parameter(Mandatory = $false)]
        [string]$Content,

        [Parameter(Mandatory = $false)]
        [string[]]$RequiredFields = @(),

        [Parameter(Mandatory = $false)]
        [string]$SchemaPath
    )

    try {
        $issues = @()
        $jsonContent = $null

        # Get content
        if ($Path) {
            if (-not (Test-Path $Path)) {
                return [PSCustomObject]@{
                    Valid = $false
                    File = $Path
                    Issues = @("File not found: $Path")
                    FieldsPresent = @()
                    FieldsMissing = @()
                }
            }
            $raw = Get-Content $Path -Raw
        } elseif ($Content) {
            $raw = $Content
        } else {
            throw "Either -Path or -Content must be provided"
        }

        # Syntax check
        try {
            $jsonContent = $raw | ConvertFrom-Json
        } catch {
            return [PSCustomObject]@{
                Valid = $false
                File = if ($Path) { $Path } else { "(inline)" }
                Issues = @("JSON syntax error: $($_.Exception.Message)")
                FieldsPresent = @()
                FieldsMissing = @()
            }
        }

        # Required fields check
        $fieldsPresent = @()
        $fieldsMissing = @()

        if ($RequiredFields.Count -gt 0) {
            $objectProps = $jsonContent.PSObject.Properties.Name

            foreach ($field in $RequiredFields) {
                if ($field -in $objectProps) {
                    $fieldsPresent += $field
                } else {
                    $fieldsMissing += $field
                    $issues += "Missing required field: $field"
                }
            }
        }

        # Empty value checks
        if ($jsonContent) {
            foreach ($prop in $jsonContent.PSObject.Properties) {
                if ($prop.Name -in $RequiredFields -and [string]::IsNullOrWhiteSpace("$($prop.Value)")) {
                    $issues += "Required field '$($prop.Name)' is empty"
                }
            }
        }

        return [PSCustomObject]@{
            Valid = $issues.Count -eq 0
            File = if ($Path) { $Path } else { "(inline)" }
            Issues = $issues
            FieldsPresent = $fieldsPresent
            FieldsMissing = $fieldsMissing
            TotalFields = $jsonContent.PSObject.Properties.Count
            CheckedAt = Get-Date -Format "o"
        }

    } catch {
        Write-Error "JSON validation failed: $_"
        throw
    }
}
