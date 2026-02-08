<#
.SYNOPSIS
    Convert structured data to formatted Markdown report

.DESCRIPTION
    Takes PSCustomObject or hashtable data and generates a formatted Markdown document.
    Supports tables, lists, headers, and severity badges.

.PARAMETER Data
    Data object to convert

.PARAMETER Title
    Report title

.PARAMETER Format
    Output format: "markdown", "console", "json"

.PARAMETER IncludeTimestamp
    Add generation timestamp to footer

.EXAMPLE
    ConvertTo-MarkdownReport -Data $scanResults -Title "Security Scan Report"

.EXAMPLE
    $checks | ConvertTo-MarkdownReport -Title "Health Report" -Format "console"
#>
function ConvertTo-MarkdownReport {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [object]$Data,

        [Parameter(Mandatory = $false)]
        [string]$Title = "Report",

        [Parameter(Mandatory = $false)]
        [ValidateSet("markdown", "console", "json")]
        [string]$Format = "markdown",

        [Parameter(Mandatory = $false)]
        [switch]$IncludeTimestamp = $true
    )

    try {
        if ($Format -eq "json") {
            return $Data | ConvertTo-Json -Depth 10
        }

        $sb = [System.Text.StringBuilder]::new()

        [void]$sb.AppendLine("# $Title")
        [void]$sb.AppendLine()

        if ($Data -is [array]) {
            # Array of objects -> table
            if ($Data.Count -gt 0) {
                $props = $Data[0].PSObject.Properties.Name

                # Header
                [void]$sb.AppendLine("| $($props -join ' | ') |")
                [void]$sb.AppendLine("| $(($props | ForEach-Object { '---' }) -join ' | ') |")

                # Rows
                foreach ($item in $Data) {
                    $values = $props | ForEach-Object { "$($item.$_)" }
                    [void]$sb.AppendLine("| $($values -join ' | ') |")
                }
            }
        } elseif ($Data -is [PSCustomObject] -or $Data -is [hashtable]) {
            $properties = if ($Data -is [hashtable]) { $Data.GetEnumerator() } else { $Data.PSObject.Properties }

            foreach ($prop in $properties) {
                $name = if ($prop.Name) { $prop.Name } else { $prop.Key }
                $value = if ($prop.Value) { $prop.Value } else { "" }

                if ($value -is [array]) {
                    [void]$sb.AppendLine("## $name")
                    foreach ($item in $value) {
                        if ($item -is [PSCustomObject]) {
                            $item.PSObject.Properties | ForEach-Object {
                                [void]$sb.AppendLine("- **$($_.Name)**: $($_.Value)")
                            }
                            [void]$sb.AppendLine()
                        } else {
                            [void]$sb.AppendLine("- $item")
                        }
                    }
                } elseif ($value -is [PSCustomObject]) {
                    [void]$sb.AppendLine("## $name")
                    $value.PSObject.Properties | ForEach-Object {
                        [void]$sb.AppendLine("- **$($_.Name)**: $($_.Value)")
                    }
                } else {
                    [void]$sb.AppendLine("- **$name**: $value")
                }
            }
        }

        if ($IncludeTimestamp) {
            [void]$sb.AppendLine()
            [void]$sb.AppendLine("---")
            [void]$sb.AppendLine("*Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss UTC')*")
        }

        $output = $sb.ToString()

        if ($Format -eq "console") {
            Write-Host $output
        }

        return $output

    } catch {
        Write-Error "Failed to generate report: $_"
        throw
    }
}
