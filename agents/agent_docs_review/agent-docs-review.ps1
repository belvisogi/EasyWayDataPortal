# agent-docs-review.ps1
<#
  Entrypoint per la review automatica/normalizzazione documentazione agentica EasyWay.
  Ora include anche check proattivo glossario/FAQ errori tipici, per ridurre knowledge gap.
#>

Write-Host "==> Avvio review/normalizzazione documentazione EasyWay..."

# Qui possono trovarsi altri step di lint/normalizzazione (future proof)
# ...

# Avvia il controllo glossario/FAQ errori tipici
Write-Host "==> Avvio check del glossario EasyWay e FAQ errori tipici..."
. "$PSScriptRoot\check_glossario_faq.ps1"
