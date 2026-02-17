function Invoke-AgentTool {
    <#
    .SYNOPSIS
        Main entry point for EasyWay Hybrid Agent capabilities.
    
    .DESCRIPTION
        Orchestrates the execution of agent tools (Review, Describe, etc.).
        It prefers Native PowerShell implementations for speed and reliability ('Antifragile'),
        but can be configured to bridge to Python for advanced features.
        
        IMPORTANT: Always use the pipeline ('|') to pass large text content like git diffs 
        to avoid shell parsing errors.

    .EXAMPLE
        git diff | Invoke-AgentTool -Task Review
        
        Description
        -----------
        Reviews the changes in the current working directory using the pipeline.

    .EXAMPLE
        git diff --cached | Invoke-AgentTool -Task Describe
        
        Description
        -----------
        Generates a PR description from staged changes.
    
    .PARAMETER Task
        The task to perform: 'Review', 'Describe', 'SmartDiff'
    
    .PARAMETER Target
        The target content (e.g. diff content) or path. 
        RECOMMENDED: Pass this via Pipeline value.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('Review', 'Describe', 'SmartDiff')]
        [string]$Task,

        [Parameter(ValueFromPipeline = $true)]
        [string]$Target
    )

    $CorePath = "$PSScriptRoot\powershell"
    $PromptsPath = "$PSScriptRoot\prompts"

    switch ($Task) {
        'SmartDiff' {
            # Pure PowerShell implementation
            . "$CorePath\Get-SmartDiff.ps1"
            Get-SmartDiff -PatchContent $Target
        }
        'Review' {
            Write-Host " [HybridAgent] Starting Review Task..." -ForegroundColor Cyan
            
            # 1. Get Smart Diff
            $diff = Invoke-AgentTool -Task SmartDiff -Target $Target
            
            # 2. Load System Prompt
            $systemPrompt = Get-Content "$PromptsPath\system_review.md" -Raw
            
            # 3. (Mock) Call LLM
            # In a real scenario, this would call Invoke-LLM or similar.
            # For MVP, we output the "Package" designed for the LLM.
            
            return @{
                SystemPrompt = $systemPrompt
                UserMessage  = $diff
            }
        }
        'Describe' {
            Write-Host " [HybridAgent] Starting Description Task..." -ForegroundColor Cyan
            # 1. Get Smart Diff
            $diff = Invoke-AgentTool -Task SmartDiff -Target $Target
            
            # 2. Load System Prompt
            $systemPrompt = Get-Content "$PromptsPath\system_describe.md" -Raw
            
            return @{
                SystemPrompt = $systemPrompt
                UserMessage  = $diff
            }
        }
    }
}
