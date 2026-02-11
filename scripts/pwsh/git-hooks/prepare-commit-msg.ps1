#!/usr/bin/env pwsh
#
# Prepare-Commit-Msg Hook
# Delegates to the main agent-git-commit.ps1 script
#

param(
    [string]$CommitMsgFile,
    [string]$Source,
    [string]$SHA
)

$ErrorActionPreference = 'Stop'

$scriptPath = Resolve-Path "$PSScriptRoot/../agent-git-commit.ps1"

if (Test-Path $scriptPath) {
    # Forward arguments to the agent script
    & $scriptPath -HookMode -CommitMsgFile $CommitMsgFile -Source $Source -SHA $SHA
}
else {
    Write-Warning "agent-git-commit.ps1 not found at $scriptPath"
}
