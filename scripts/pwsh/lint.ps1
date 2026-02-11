#
# Linting Script
# Runs PSScriptAnalyzer on the codebase or specific files
#

param(
    [string[]]$Paths = @("."),
    [switch]$FailOnError
)

$ErrorActionPreference = "Stop"

if (-not (Get-Module -ListAvailable PSScriptAnalyzer)) {
    Write-Warning "PSScriptAnalyzer module not found. Installing..."
    Install-Module -Name PSScriptAnalyzer -Scope CurrentUser -Force -AllowClobber
}

Write-Host "🔍 Running PSScriptAnalyzer on: $($Paths -join ', ')" -ForegroundColor Cyan

$results = Invoke-ScriptAnalyzer -Path $Paths -Recurse -Severity Error,Warning

if ($results) {
    echo $results | Format-Table -AutoSize
    
    $errors = $results | Where-Object { $_.Severity -eq 'Error' }
    if ($errors) {
        Write-Error "Found $($errors.Count) errors!"
        if ($FailOnError) { exit 1 }
    } else {
        Write-Host "✅ No errors found (some warnings present)." -ForegroundColor Yellow
    }
} else {
    Write-Host "✅ Code looks clean!" -ForegroundColor Green
}
