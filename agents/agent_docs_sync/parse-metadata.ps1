# parse-metadata.ps1
# Helper functions for parsing metadata from .md and .ps1 files

function Get-MarkdownMetadata {
    <#
    .SYNOPSIS
        Extract YAML frontmatter from markdown file
    #>
    param([string]$FilePath)
    
    if (-not (Test-Path $FilePath)) {
        return @{}
    }
    
    $content = Get-Content $FilePath -Raw
    $metadata = @{}
    
    # Match YAML frontmatter (--- ... ---)
    if ($content -match '(?s)^---\s*\n(.*?)\n---') {
        $yamlBlock = $matches[1]
        
        # Simple YAML parsing
        $lines = $yamlBlock -split "`n"
        $currentKey = $null
        $inArray = $false
        
        foreach ($line in $lines) {
            # Key: value
            if ($line -match '^\s*(\w[\w-]*)\s*:\s*(.*)$') {
                $key = $matches[1]
                $value = $matches[2].Trim()
                $currentKey = $key
                
                # Handle inline arrays [item1, item2]
                if ($value -match '^\[(.*)\]$') {
                    $metadata.$key = $matches[1] -split ',' | ForEach-Object { $_.Trim() }
                    $inArray = $false
                }
                # Empty value = multi-line array starts
                elseif ($value -eq '') {
                    $metadata.$key = @()
                    $inArray = $true
                }
                # Single value
                else {
                    $metadata.$key = $value
                    $inArray = $false
                }
            }
            # Array item (starts with -)
            elseif ($line -match '^\s*-\s*(.+)$' -and $inArray -and $currentKey) {
                $metadata.$currentKey += $matches[1].Trim()
            }
        }
    }
    
    return $metadata
}

function Get-ScriptMetadata {
    <#
    .SYNOPSIS
        Extract .METADATA block from PowerShell script
    #>
    param([string]$FilePath)
    
    if (-not (Test-Path $FilePath)) {
        return @{}
    }
    
    $content = Get-Content $FilePath -Raw
    $metadata = @{}
    
    # Match .METADATA block in comment
    if ($content -match '(?s)\.METADATA\s+([\s\S]+?)(?=\.DESCRIPTION|\.EXAMPLE|\.PARAMETER|#>)') {
        $metaBlock = $matches[1]
        
        # Parse key: value pairs
        $lines = $metaBlock -split "`n"
        foreach ($line in $lines) {
            if ($line -match '^\s*(\w[\w-]*)\s*:\s*(.+)$') {
                $key = $matches[1]
                $value = $matches[2].Trim()
                
                # Handle arrays
                if ($value -match ',') {
                    $metadata.$key = $value -split ',' | ForEach-Object { $_.Trim() }
                }
                else {
                    $metadata.$key = $value
                }
            }
            # Handle multi-line arrays (related-docs)
            elseif ($line -match '^\s*-\s*(.+)$') {
                $item = $matches[1].Trim()
                if (-not $metadata.'related-docs') {
                    $metadata.'related-docs' = @()
                }
                $metadata.'related-docs' += $item
            }
        }
    }
    
    return $metadata
}
