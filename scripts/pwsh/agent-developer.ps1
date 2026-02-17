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
    [ValidateSet("start-task", "commit-work", "open-pr", "dev:implement-fix")]
    [string]$Action,

    [string]$PBI,
    [string]$Desc,
    [string]$Domain = "devops",
    [string]$Type,
    [string]$Message,
    [string]$FixData
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
        $branchName = "feature/$Domain/$PBI-$Desc"
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

    "dev:implement-fix" {
        if (-not $FixData) { Throw "FixData required for dev:implement-fix" }
        
        # 1. Parse Fix Data
        try {
            if ($FixData -is [string]) {
                $fix = $FixData | ConvertFrom-Json
            }
            else {
                $fix = $FixData
            }
        }
        catch {
            Throw "Invalid FixData JSON: $_"
        }

        # 2. Start Task (Branching)
        $myPbi = if ($PBI) { $PBI } else { "AUTO" }
        $myDesc = if ($Desc) { $Desc } else { "fix-detected-error" }
         
        Run-Git "checkout develop"
        Run-Git "pull origin develop"
        $branchName = "feature/$Domain/$myPbi-$myDesc"
        
        if (git branch --list $branchName) {
            $branchName += "-" + (Get-Date -Format "yyyyMMddHHmmss")
        }
        
        Write-Host "👷 Starting Auto-Fix on: $branchName" -ForegroundColor Cyan
        Run-Git "checkout -b $branchName"

        # 3. Apply Fix with Security Check
        Write-Host "🔧 Applying Fix to $($fix.filePath)..." -ForegroundColor Yellow
        
        # Security: Prevent Path Traversal
        $repoRoot = (git rev-parse --show-toplevel)
        $fullPath = $null
        try {
            $potentialPath = Join-Path $repoRoot $fix.filePath
            $fullPath = [System.IO.Path]::GetFullPath($potentialPath)
        }
        catch {
            Throw "Invalid path: $($fix.filePath)"
        }
        
        if (-not $fullPath.StartsWith($repoRoot)) {
            Throw "SECURITY ERROR: Path Traversal detected! Cannot write outside repo root: $fullPath"
        }
        
        $targetPath = $fullPath

        if ($fix.newContent) {
            $fix.newContent | Set-Content -Path $targetPath -Encoding UTF8
        }
        elseif ($fix.search -and $fix.replace) {
            if (-not (Test-Path $targetPath)) { Throw "File not found for replacement: $targetPath" }
            $content = Get-Content -Path $targetPath -Raw
            $newContent = $content.Replace($fix.search, $fix.replace)
            $newContent | Set-Content -Path $targetPath -Encoding UTF8
        }
        else {
            Throw "FixData must contain 'newContent' OR 'search'/'replace'."
        }

        # 4. Commit & Push
        Run-Git "add ."
        $commitMsg = if ($Message) { $Message } else { "fix: auto-repair $($fix.filePath)" }
        Run-Git "commit -m `"$commitMsg`""
        
        Run-Git "push --set-upstream origin $branchName"
        Write-Host "✅ Fix pushed to $branchName" -ForegroundColor Green

        # 5. Open PR
        Write-Host "🔗 PR Created: $branchName -> develop" -ForegroundColor Magenta
        Write-Host "   (Simulated: https://gitlab.local/mr/new?source=$branchName)"
    }
}
