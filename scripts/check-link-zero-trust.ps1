<#
    Script: check-link-zero-trust.ps1
    Scansiona i principali entrypoint (README.md, onboarding, doc agent, sicurezza)
    e segnala se manca il link/mention/see-also alla guida "setup-playground-zero-trust.md"
    (path: wiki/EasyWayData.wiki/onboarding/setup-playground-zero-trust.md).

    Output: stampa OK se link presente, TODO patch se assente, suggerendo dove inserirlo.
#>

param (
    [string[]]$EntrypointFiles = @(
        "README.md",
        "DEVELOPER_ONBOARDING.md",
        "Wiki/EasyWayData.wiki/onboarding/README.md"
    ),
    [string]$GuidaTarget = "wiki/EasyWayData.wiki/onboarding/setup-playground-zero-trust.md"
)

foreach ($f in $EntrypointFiles) {
    if (Test-Path $f) {
        $content = Get-Content $f -Raw
        if ($content -match [regex]::Escape($GuidaTarget)) {
            Write-Host "✅ [OK] $f contiene già link a setup-playground-zero-trust.md"
        } elseif ([regex]::IsMatch($content, "zero.?trust|sandbox.{0,30}setup|playground", "IgnoreCase")) {
            Write-Host "🟡 [Parziale] $f menziona zero trust/sandbox, ma senza link guida. Consigliato inserire:"
            Write-Host "`n- [Setup ambiente Zero Trust/Sandbox](wiki/EasyWayData.wiki/onboarding/setup-playground-zero-trust.md)`n"
        } else {
            Write-Host "❌ [TODO] $f NON contiene riferimento/link a setup-playground-zero-trust.md. Consigliato patch:"
            Write-Host "`n## Sicurezza / Zero Trust / Sandbox"
            Write-Host "- [Setup ambiente Zero Trust/Sandbox](wiki/EasyWayData.wiki/onboarding/setup-playground-zero-trust.md)"
            Write-Host ""
        }
    } else {
        Write-Host "ℹ️ File $f non trovato."
    }
}
