# check_glossario_faq.ps1
<#
    Script modulare da richiamare da agent-docs-review.ps1
    Scansiona Wiki/EasyWayData.wiki/ per termini chiave ("Intent", "Agent", "Orchestrazione", ecc) 
    e raccoglie error signature comunemente usate (regex es  "[Ee]rrore", "failed", "gate ", ecc).
    Verifica se tali termini sono già nel glossario (wiki/EasyWayData.wiki/glossario-errori-faq.md).
    Stampa TODO oppure prepara blocco patch Markdown da aggiungere.
#>

param (
    [string]$GlossarioPath = "wiki/EasyWayData.wiki/glossario-errori-faq.md"
)

$keywords_regex = @(
    "intent\.[a-zA-Z0-9\-_]+",
    "agent_[a-zA-Z0-9\-_]+",
    "gate [a-zA-Z0-9\-_]+",
    "orchestrazione [a-zA-Z0-9\-_]+"
)
$error_regex = @(
    "[Ee]rrore[^\n]*",
    "failed[^\n]*",
    "error[^\n]*"
)

$all_md = Get-ChildItem -Path "Wiki/EasyWayData.wiki" -Recurse -Include *.md
$found_terms = @{}
# Scansiona termini chiave nei markdown
foreach ($file in $all_md) {
    $content = Get-Content $file.FullName -Raw
    foreach ($rx in $keywords_regex) {
        $matches = [regex]::Matches($content, $rx)
        foreach ($m in $matches) {
            $found_terms[$m.Value] = $true
        }
    }
}
# Scansiona errori tipici in markdown
$found_errors = @{}
foreach ($file in $all_md) {
    $content = Get-Content $file.FullName -Raw
    foreach ($rx in $error_regex) {
        $matches = [regex]::Matches($content, $rx)
        foreach ($m in $matches) {
            $found_errors[$m.Value] = $true
        }
    }
}

# Parsing del glossario esistente
$gloss = Get-Content $GlossarioPath -Raw
$found_def = @{}
if ($gloss -match "\| \*\*(\w+)") {
    $rows = $gloss -split "\n"
    foreach ($row in $rows) {
        if ($row -match "\| \*\*(\w+)") {
            $found_def[$matches[1]] = $true
        }
    }
}

# Termini mancanti
$missing_terms = @()
foreach ($k in $found_terms.Keys) {
    $is_in_gloss = $false
    foreach ($g in $found_def.Keys) {
        if ($k -like "*$g*") { $is_in_gloss = $true; break }
    }
    if (-not $is_in_gloss) {
        $missing_terms += $k
    }
}

Write-Host "=== Termini chiave non ancora documentati in glossario ==="
$missing_terms | Sort-Object | ForEach-Object { Write-Host "- $_" }

# Errori tipici: TODO (se serve)
# Per ogni errore non comune/non generico, proporre una FAQ stub (output per revisione manuale)
Write-Host "`n=== Errori tipici estratti da markdown ==="
$found_errors.Keys | Sort-Object | ForEach-Object { Write-Host "- $_" }

Write-Host "`nAggiungi queste voci in: $GlossarioPath se rilevanti."
