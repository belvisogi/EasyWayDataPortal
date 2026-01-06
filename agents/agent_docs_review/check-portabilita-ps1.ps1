# check-portabilita-ps1.ps1
<#
    Scansiona tutti gli script .ps1 per best practice cross-platform
    - Warning per uso di cmdlet solo-Windows (WMI, reg, COM, ecc)
    - Segnala path hardcode/backslash `\`
    - Verifica presenza shebang cross-platform
    - Warning se si usa sqlcmd.exe o tool tipici Windows-only
    - Suggerimenti correggi/PR stub

    Esegui come step di agent_docs_review, oppure in CI/CD/manuale.
#>

$ps1Files = Get-ChildItem -Path . -Recurse -Include *.ps1

$windowsCmdlets = @(
    "Get-WmiObject",
    "New-Object -ComObject",
    "Set-ItemProperty -Path 'HKLM:",
    "Set-ItemProperty -Path 'HKCU:",
    "Get-ChildItem -Path 'HKLM:",
    "Get-ChildItem -Path 'HKCU:",
    "sqlcmd.exe"
)

foreach ($file in $ps1Files) {
    $lines = Get-Content $file.FullName
    $hasShebang = $false
    $hasBackslash = $false
    $windowsMatch = @()
    # Check shebang & windows pattern
    foreach ($ln in $lines) {
        if ($ln -match "^#!.*pwsh") { $hasShebang = $true }
        if ($ln -match "\\") { $hasBackslash = $true }
        foreach ($wcmd in $windowsCmdlets) {
            if ($ln -like "*$wcmd*") { $windowsMatch += $wcmd }
        }
    }
    if (-not $hasShebang) {
        Write-Host "⚠️  [$($file.Name)]: manca shebang cross-platform (#\!/usr/bin/env pwsh) in testa file."
    }
    if ($hasBackslash) {
        Write-Host "⚠️  [$($file.Name)] contiene path con backslash (`\`). Usa Join-Path o /."
    }
    if ($windowsMatch.Count -gt 0) {
        Write-Host "🚫 [$($file.Name)] usa cmdlet/tool Windows-only: $($windowsMatch -join ', ')"
        Write-Host "     --> Sostituisci con alternativa cross-platform o documenta uso alternativo per Linux/macOS."
    }
}
