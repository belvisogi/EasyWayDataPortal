# validate-cross-refs.ps1
# Validate cross-references between docs and scripts

. "$PSScriptRoot\parse-metadata.ps1"

function Test-DocScriptAlignment {
    <#
    .SYNOPSIS
        Check if doc and script metadata are aligned
    #>
    param(
        [string]$DocPath,
        [string]$ScriptPath
    )
    
    $docMeta = Get-MarkdownMetadata $DocPath
    $scriptMeta = Get-ScriptMetadata $ScriptPath
    
    $issues = @()
    $aligned = $true
    
    # Check category match
    if ($docMeta.category -and $scriptMeta.category) {
        if ($docMeta.category -ne $scriptMeta.category) {
            $issues += "Category mismatch: doc=$($docMeta.category) vs script=$($scriptMeta.category)"
            $aligned = $false
        }
    }
    
    # Check domain match
    if ($docMeta.domain -and $scriptMeta.domain) {
        if ($docMeta.domain -ne $scriptMeta.domain) {
            $issues += "Domain mismatch: doc=$($docMeta.domain) vs script=$($scriptMeta.domain)"
            $aligned = $false
        }
    }
    
    # Check bidirectional references
    $scriptName = Split-Path $ScriptPath -Leaf
    if ($docMeta.'script-refs' -and $scriptName -notin $docMeta.'script-refs') {
        $issues += "Doc doesn't reference script: $scriptName"
        $aligned = $false
    }
    
    $docName = Split-Path $DocPath -Leaf
    if ($scriptMeta.'related-docs') {
        $docReferenced = $scriptMeta.'related-docs' | Where-Object { $_ -like "*$docName*" }
        if (-not $docReferenced) {
            $issues += "Script doesn't reference doc: $docName"
            $aligned = $false
        }
    }
    
    return [PSCustomObject]@{
        Aligned        = $aligned
        Issues         = $issues
        DocMetadata    = $docMeta
        ScriptMetadata = $scriptMeta
    }
}
