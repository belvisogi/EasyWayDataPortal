#!/usr/bin/env pwsh
# Wrapper root per Developer Experience
# Inoltra tutto al Kernel in scripts/pwsh/ewctl.ps1

$ScriptPath = Join-Path $PSScriptRoot "scripts/pwsh/ewctl.ps1"
if (-not (Test-Path $ScriptPath)) {
    Write-Error "Kernel not found at $ScriptPath"
    exit 1
}

& $ScriptPath @args
exit $LASTEXITCODE
