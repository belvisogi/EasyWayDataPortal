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
        $results = Invoke-ScriptAnalyzer -Path $psFiles -Severity Error
        
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

exit 0
