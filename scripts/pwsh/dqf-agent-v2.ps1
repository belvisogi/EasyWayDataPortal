# DQF AGENT V2 - PowerShell Wrapper
# ===================================
# Wraps the TypeScript CLI for easy PowerShell usage

param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$Command,
    
    [string]$SessionId = $null
)

$ErrorActionPreference = "Stop"

# Set session ID if provided
if ($SessionId) {
    $env:DQF_SESSION_ID = $SessionId
}

# Navigate to package directory
$packageDir = Join-Path $PSScriptRoot "..\..\packages\dqf-agent"
Push-Location $packageDir

try {
    # Run the TypeScript CLI
    Write-Host "🚀 Launching DQF Agent V2..." -ForegroundColor Cyan
    Write-Host ""
    
    npx ts-node --project tsconfig.json src/cli-v2.ts $Command
    
    Write-Host ""
    Write-Host "✨ Done!" -ForegroundColor Green
}
finally {
    Pop-Location
}
