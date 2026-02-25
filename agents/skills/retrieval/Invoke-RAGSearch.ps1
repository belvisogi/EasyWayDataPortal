
<#
.SYNOPSIS
    Searches the EasyWay Wiki using RAG (Qdrant).

.DESCRIPTION
    Uses a python bridge to query the Qdrant vector database.
    Returns relevant documentation chunks.

.PARAMETER Query
    The question or keywords to search for.

.PARAMETER Limit
    Max number of results to return (default 3).

.EXAMPLE
    Invoke-RAGSearch -Query "How to deploy"
#>
function Invoke-RAGSearch {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Query,

        [Parameter(Mandatory = $false)]
        [int]$Limit = 3
    )

    try {
        $scriptPath = "$PSScriptRoot/rag_search.py"
        
        # Ensure python calls the script
        # Pass env vars if needed, though they should be inherited from the container env
        Write-Verbose "Executing: python3 $scriptPath [query length=$($Query.Length)]"

        # Use & operator to pass $Query as a proper argument (avoids Invoke-Expression
        # parsing errors when $Query contains JSON braces, colons, or quotes).
        $jsonOutput = & python3 $scriptPath $Query
        
        if (-not $jsonOutput) {
            throw "No output from RAG search script."
        }
        
        $result = $jsonOutput | ConvertFrom-Json
        
        if ($result.PSObject.Properties['error'] -and $result.error) {
            throw "RAG Search Error: $($result.error)"
        }
        
        return $result.results

    }
    catch {
        Write-Error "Failed to invoke RAG search: $_"
        throw
    }
}
