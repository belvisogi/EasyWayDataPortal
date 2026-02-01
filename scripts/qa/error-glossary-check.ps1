<#
.SYNOPSIS
    EasyWay Core - Error Glossary Coverage Check
    Ensures console error/warn messages are documented in docs/errors-glossary.md
#>

$ErrorActionPreference = "Continue"

$RootPath = Resolve-Path "$PSScriptRoot\..\.."
$FrontendSrc = "$RootPath\apps\portal-frontend\src"
$GlossaryPath = "$RootPath\docs\errors-glossary.md"

if (-not (Test-Path $GlossaryPath)) {
    Write-Host "❌ Missing glossary: $GlossaryPath" -ForegroundColor Red
    exit 1
}

$Glossary = Get-Content $GlossaryPath -Raw

$Messages = New-Object System.Collections.Generic.HashSet[string]

$TsFiles = Get-ChildItem $FrontendSrc -Recurse -Filter "*.ts"
foreach ($file in $TsFiles) {
    $Content = Get-Content $file.FullName -Raw
    $matches = [regex]::Matches($Content, "console\.(warn|error)\s*\(\s*([`'\""])(.*?)\2", [System.Text.RegularExpressions.RegexOptions]::Singleline)
    foreach ($m in $matches) {
        $msg = $m.Groups[3].Value.Trim()
        if ($msg.Length -lt 6) { continue }
        if ($msg -notmatch "(Missing|Failed|Invalid|Error|Fallback|warn|error|\[)") { continue }
        $null = $Messages.Add($msg)
    }
}

$Failures = 0
foreach ($msg in $Messages) {
    if ($Glossary -notmatch [regex]::Escape($msg)) {
        Write-Host "❌ Glossary missing entry for: $msg" -ForegroundColor Red
        $Failures++
    }
}

if ($Failures -eq 0) {
    Write-Host "✅ Error glossary coverage OK" -ForegroundColor Green
} else {
    Write-Host "🛑 Error glossary missing $Failures entries" -ForegroundColor Red
    exit 1
}
