#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Agent Git Commit - AI Powered Commit Messages
    Generates commit messages based on staged changes using an LLM.

.DESCRIPTION
    Analyzes staged changes via `git diff --cached`, sends the context to an LLM,
    and generates a Conventional Commit message.
    Can also be run via Git Hook interaction.

.PARAMETER Type
    Force a specific commit type (feat, fix, etc.)

.PARAMETER Scope
    Force a specific scope (auth, api, etc.)

.PARAMETER HookMode
    Indicates the script is running from a Git Hook (prepare-commit-msg).

.PARAMETER CommitMsgFile
    Path to the commit message file (passed by Git Hook).

.PARAMETER Source
    Source of the commit message (message, template, merge, squash, commit).
    
.PARAMETER SHA
    SHA of the commit (if any).
    
.EXAMPLE
    ./agent-git-commit.ps1 -Type feat -Scope auth
#>

[CmdletBinding()]
param(
    [string]$Type,
    [string]$Scope,
    [switch]$HookMode,
    [string]$CommitMsgFile,
    [string]$Source,
    [string]$SHA,
    [switch]$SkipLLM
)

$ErrorActionPreference = 'Stop'

function Get-StagedDiff {
    $diff = git diff --cached
    if (-not $diff) {
        return $null
    }
    return $diff
}

function Generate-CommitMessage {
    param($Diff, $Type, $Scope)
    
    # Simple heuristic fallback if LLM is skipped or fails
    $prefix = if ($Type) { $Type } else { "chore" }
    $scopeStr = if ($Scope) { "($Scope)" } else { "" }
    
    # analyze diff for hints
    $files = git diff --cached --name-only
    $fileList = $files -join ", "
    
    return "$prefix$scopeStr`: update $fileList"
}

# --- Main Logic ---

if ($HookMode) {
    # If run as a hook, check if we should intervene
    # If Source is message, merge, squash, or commit, we usually skip unless empty
    if ($Source -in "message", "merge", "squash", "commit") {
        # Keep existing message
        exit 0
    }
    
    $diff = Get-StagedDiff
    if (-not $diff) { exit 0 }
    
    # TODO: Here we would call the LLM Agent
    # For now, using the generator function
    $msg = Generate-CommitMessage -Diff $diff -Type $Type -Scope $Scope
    
    if ($CommitMsgFile) {
        $msg | Set-Content $CommitMsgFile -Encoding UTF8
    }
}
else {
    # Interactive Mode
    $diff = Get-StagedDiff
    if (-not $diff) {
        Write-Warning "No staged changes to commit."
        exit 0
    }
    
    $msg = Generate-CommitMessage -Diff $diff -Type $Type -Scope $Scope
    
    Write-Host "Proposed Commit Message:" -ForegroundColor Cyan
    Write-Host $msg -ForegroundColor White
    
    $choice = Read-Host "Commit with this message? (Y/n)"
    if ($choice -eq 'Y' -or $choice -eq '') {
        git commit -m $msg
    }
}
