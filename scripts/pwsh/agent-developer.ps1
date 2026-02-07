<#
.SYNOPSIS
    Agent Developer (The Contributor) 👷
    Automates Standard Git Flow: Branch -> Commit -> Push

.DESCRIPTION
    Wraps standard git commands with policy enforcement (e.g. branch naming).
    Simplifies the "Mechanical" part of coding.

.PARAMETER Action
    start-task | commit-work | open-pr
.PARAMETER PBI
    Ticket ID (e.g., PBI-123)
.PARAMETER Desc
    Short description (e.g., new-login)
.PARAMETER Type
    Commit type (feat, fix, docs)
.PARAMETER Message
    Commit message
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("start-task", "commit-work", "open-pr")]
    [string]$Action,

    [string]$PBI,
    [string]$Desc,
    [string]$Type,
    [string]$Message
)

$ErrorActionPreference = "Stop"

function Run-Git {
    param([string]$Command)
    Write-Host "🐙 git $Command" -ForegroundColor DarkGray
    Invoke-Expression "git $Command"
}

switch ($Action) {
    "start-task" {
        if (-not $PBI -or -not $Desc) { Throw "PBI and Desc required for start-task" }
        
        # 1. Update & Checkout Develop
        Run-Git "checkout develop"
        Run-Git "pull origin develop"

        # 2. Derive Branch Name (Standard)
        $branchName = "feature/$PBI-$Desc"
        Write-Host "👷 Starting work on: $branchName" -ForegroundColor Cyan

        # 3. Create Branch
        Run-Git "checkout -b $branchName"
    }

    "commit-work" {
        if (-not $Type -or -not $Message) { Throw "Type and Message required for commit-work" }
        
        # 1. Stage All
        Run-Git "add ."
        
        # 2. Semantic Commit
        $fullMsg = "$Type`: $Message"
        Run-Git "commit -m `"$fullMsg`""
        
        # 3. Push
        $current = git branch --show-current
        Run-Git "push --set-upstream origin $current"
        Write-Host "✅ Work pushed to $current" -ForegroundColor Green
    }

    "open-pr" {
        # Mock PR creation (In real world: call GitLab API)
        $current = git branch --show-current
        Write-Host "🔗 PR Created: $current -> develop" -ForegroundColor Magenta
        Write-Host "   (Simulated: https://gitlab.local/mr/new?source=$current)"
    }
}
