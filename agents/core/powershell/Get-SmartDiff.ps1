function Get-SmartDiff {
    <#
    .SYNOPSIS
        Generates an LLM-friendly diff format with line numbers and hunk separation.
        Inspired by logic in pr-agent's git_patch_processing.py.
    
    .DESCRIPTION
        Takes a raw git diff and reformats it to be clearer for AI agents.
        It adds:
        - explicit file headers
        - line numbers for new code
        - separation of __new hunk__ and __old hunk__
    
    .PARAMETER PatchContent
        The raw string content of 'git diff'. If not provided, reads from pipeline.
    
    .LIST MAPPING
        Based on pattern:
        @@ -start1,len1 +start2,len2 @@ header
    #>
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline = $true)]
        [string]$PatchContent
    )

    process {
        if ([string]::IsNullOrWhiteSpace($PatchContent)) { return }

        $lines = $PatchContent -split "`r`n|`n"
        $formattedDiff = [System.Text.StringBuilder]::new()
        
        $currentFile = ""
        $inHunk = $false
        
        $newContentLines = [System.Collections.Generic.List[string]]::new()
        $oldContentLines = [System.Collections.Generic.List[string]]::new()
        
        # Hunk tracking
        $hunkHeader = ""
        $start2 = 0
        $currentLine2 = 0

        # Regex for standard git diff header
        # @@ -1,5 +1,6 @@
        $hunkRegex = [regex]"^@@ -(\d+)(?:,(\d+))? \+(\d+)(?:,(\d+))? @@(.*)"

        foreach ($line in $lines) {
            if ($line -match "^diff --git a/(.*) b/(.*)") {
                # New File section
                $currentFile = $matches[2]
                $formattedDiff.AppendLine() | Out-Null
                $formattedDiff.AppendLine("## File: '$currentFile'") | Out-Null
                $inHunk = $false
                continue
            }
            if ($line -match "^index" -or $line -match "^---" -or $line -match "^\+\+\+") {
                # Skip metadata lines
                continue
            }

            if ($line -match "^@@") {
                # Process previous hunk if exists
                if ($newContentLines.Count -gt 0 -or $oldContentLines.Count -gt 0) {
                    if ($oldContentLines.Count -gt 0) {
                        $formattedDiff.AppendLine("__old hunk__") | Out-Null
                        foreach ($l in $oldContentLines) { $formattedDiff.AppendLine($l) | Out-Null }
                    }
                    if ($newContentLines.Count -gt 0) {
                        $formattedDiff.AppendLine("__new hunk__") | Out-Null
                        foreach ($l in $newContentLines) { $formattedDiff.AppendLine($l) | Out-Null }
                    }
                    $formattedDiff.AppendLine() | Out-Null
                }

                # Reset for new hunk
                $newContentLines.Clear()
                $oldContentLines.Clear()
                
                $match = $hunkRegex.Match($line)
                if ($match.Success) {
                    $start2 = [int]$match.Groups[3].Value
                    $currentLine2 = $start2
                    $hunkHeader = $line
                    
                    # We don't output the raw @@ header, we structure it below
                }
                $inHunk = $true
                continue
            }

            if ($inHunk) {
                if ($line.StartsWith("-")) {
                    $oldContentLines.Add($line.Substring(1)) # Remove the - marker for cleaner read? Or keep it? pr-agent keeps symbols but splits hunks. 
                    # Actually pr-agent output exmaple: "-       line3"
                    # We will output just the content for old hunk, or maybe with '-'? 
                    # Let's keep it simple: Just the content for old hunk, they are context.
                    # Wait, pr-agent example shows: 
                    # __old hunk__
                    #  unchanged
                    # - removed
                    
                    # For simplicity in this MVP, we will just output the line as is for old hunk logic
                    # But wait, we want to separate New vs Old completely.
                    
                    # Logic:
                    # If it starts with -, add to old lines list (with -)
                    # If it starts with +, add to new lines list (with line number)
                    # If it starts with space, add to BOTH (context)
                    
                    # $oldContentLines.Add($line)
                }
                elseif ($line.StartsWith("+")) {
                    $newLineContent = "$currentLine2 $line" # Add line number reference
                    $newContentLines.Add($newLineContent)
                    $currentLine2++
                }
                else {
                    # Context line
                    $oldContentLines.Add($line)
                    
                    $newLineContent = "$currentLine2 $line"
                    $newContentLines.Add($newLineContent)
                    $currentLine2++
                }
            }
        }
        
        # Flush last hunk
        if ($newContentLines.Count -gt 0 -or $oldContentLines.Count -gt 0) {
            if ($oldContentLines.Count -gt 0) {
                $formattedDiff.AppendLine("__old hunk__") | Out-Null
                foreach ($l in $oldContentLines) { $formattedDiff.AppendLine($l) | Out-Null }
            }
            if ($newContentLines.Count -gt 0) {
                $formattedDiff.AppendLine("__new hunk__") | Out-Null
                foreach ($l in $newContentLines) { $formattedDiff.AppendLine($l) | Out-Null }
            }
        }

        return $formattedDiff.ToString()
    }
}
