#!/usr/bin/env pwsh
#
# Pre-Commit Hook
# Validates Staged Files before commit
#

$ErrorActionPreference = 'Stop'

Write-Host "🛡️  Iron Dome: Pre-Commit Checks Initiated..." -ForegroundColor Cyan

# 1. Get Staged Files
$stagedFiles = git diff --cached --name-only --diff-filter=ACM
if (-not $stagedFiles) {
    Write-Host "✅ No files staged to check." -ForegroundColor Green
    exit 0
}

# Filter for PowerShell files
$psFiles = $stagedFiles | Where-Object { $_ -match '\.(ps1|psm1|psd1)$' }

if ($psFiles) {
    Write-Host "🔍 Analyzing $($psFiles.Count) PowerShell files..." -ForegroundColor Cyan
    
    # Check for PSScriptAnalyzer
    if (-not (Get-Module -ListAvailable PSScriptAnalyzer)) {
        Write-Warning "PSScriptAnalyzer not found. Skipping linting (Please install it: Install-Module PSScriptAnalyzer)"
    }
    else {
        # 1. Check for Syntax Errors (Parse Errors)
        # Use the AST Parser which detects missing braces, etc.
        $hasSyntaxErrors = $false
        foreach ($file in $psFiles) {
            if (-not (Test-Path $file)) { continue } # Skip deleted files
            $content = Get-Content $file -Raw
            $tokens = $null
            $errors = $null
            [void][System.Management.Automation.Language.Parser]::ParseInput($content, [ref]$tokens, [ref]$errors)
            
            if ($errors) {
                Write-Host "❌ Syntax Error in $file" -ForegroundColor Red
                foreach ($err in $errors) {
                    Write-Host "   Line $($err.Extent.StartLineNumber): $($err.Message)" -ForegroundColor Red
                }
                $hasSyntaxErrors = $true
            }
        }
        
        if ($hasSyntaxErrors) {
            Write-Host "ABORTING COMMIT: Syntax errors found." -ForegroundColor Red
            exit 1
        }

        # 2. Run Analyzer
        # Ensure correct type casting for Invoke-ScriptAnalyzer
        $results = $psFiles | Invoke-ScriptAnalyzer -Severity Error
        
        # Filter out "ParseError" if we handled it above, but keeping it is fine.
        
        if ($results) {
            Write-Host "❌ Linting Errors Found:" -ForegroundColor Red
            $results | Format-Table -AutoSize
            Write-Host "ABORTING COMMIT: Please fix the errors above." -ForegroundColor Red
            exit 1
        }
        else {
            Write-Host "✅ PSScriptAnalyzer passed." -ForegroundColor Green
        }
    }
}

# ---------------------------------------------------------------------------
# Auto-sync: regenerate .cursorrules platform section if wiki source changed
# ---------------------------------------------------------------------------
$wikiSource = 'Wiki/EasyWayData.wiki/agents/platform-operational-memory.md'
$wikiStaged = $stagedFiles | Where-Object { $_ -eq $wikiSource }
if ($wikiStaged) {
    Write-Host "[SYNC] Platform wiki changed - syncing .cursorrules..." -ForegroundColor Cyan
    $syncScript = Join-Path $PSScriptRoot '..\Sync-PlatformMemory.ps1'
    if (Test-Path $syncScript) {
        & $syncScript
        if ($LASTEXITCODE -ne 0) {
            Write-Warning "Sync-PlatformMemory.ps1 failed (exit $LASTEXITCODE). .cursorrules may be stale."
        } else {
            git add .cursorrules
            Write-Host "  ✅ .cursorrules auto-updated and staged." -ForegroundColor Green
        }
    } else {
        Write-Warning "Sync script not found at: $syncScript (skipping auto-sync)"
    }
}

exit 0
