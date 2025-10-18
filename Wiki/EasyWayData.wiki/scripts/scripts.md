---
id: ew-scripts
title: Scripts - One-shot e routine frequenti
summary: Comandi ricorrenti per rigenerare indici, manifest, ancore e chunk, eseguire lint e review, e loggare le attività.
status: draft
owner: team-docs
created: '2025-10-18'
updated: '2025-10-18'
tags:
  - layer/how-to
  - automation
  - language/it
llm:
  include: true
  pii: none
  chunk_hint: 300-500
entities: []
---

# Scripts - One-shot e routine frequenti

## One-shot: rigenera tutto (root corrente)
```powershell
# 1) Naming + indici + anchor check
EasyWayData.wiki/scripts/review-run.ps1 -Root EasyWayData.wiki -Mode kebab -CheckAnchors

# 2) Entities index
. EasyWayData.wiki/scripts/generate-entities-index.ps1 -Root EasyWayData.wiki

# 3) Manifest (CSV/JSONL) + Anchors
. EasyWayData.wiki/scripts/generate-master-index.ps1 -Root EasyWayData.wiki

# 4) Export chunk atomici (H2/H3)
. EasyWayData.wiki/scripts/export-chunks-jsonl.ps1 -Root EasyWayData.wiki

# 5) Lint atomicità
. EasyWayData.wiki/scripts/lint-atomicity.ps1 -Root EasyWayData.wiki

# 6) Log
. EasyWayData.wiki/scripts/add-log.ps1 -Type REVIEW -Scope full-rebuild -Status success -Owner team-docs -Message "Rigenerazione completa indici/manifest/chunk/lint" -Split monthly
```

## Multi-root: aggrega più progetti
```powershell
# Pre-requisito: genera gli artefatti per ogni root
. EasyWayData.wiki/scripts/generate-master-index.ps1 -Root EasyWayData.wiki
. EasyWayData.wiki/scripts/generate-master-index.ps1 -Root OtherWiki

# Aggregazione in file *_all (nella workspace root)
. EasyWayData.wiki/scripts/generate-master-index-aggregate.ps1 -Roots @('EasyWayData.wiki','OtherWiki')
```

## Multi-root: normalizzazione (scan/apply) e report
```powershell
# Scansione senza modifiche (report per-root + sommario)
. EasyWayData.wiki/scripts/normalize-project-multi.ps1 -Roots @('EasyWayData.wiki','OtherWiki') -Mode scan

# Applicazione con front matter minimo dove manca
. EasyWayData.wiki/scripts/normalize-project-multi.ps1 -Roots @('EasyWayData.wiki','OtherWiki') -Mode apply -EnsureFrontMatter
```

## Job: Full‑pass multi‑root (normalize → rebuild → lint)
```powershell
$roots = @('EasyWayData.wiki','OtherWiki')

# 1) Normalizza tutte le radici
. EasyWayData.wiki/scripts/normalize-project-multi.ps1 -Roots $roots -Mode apply -EnsureFrontMatter

# 2) Rebuild artefatti e lint per ogni root
foreach($r in $roots){
  $rootPath = Resolve-Path $r
  EasyWayData.wiki/scripts/review-run.ps1 -Root $rootPath -Mode kebab -CheckAnchors | Out-Host
  . EasyWayData.wiki/scripts/generate-entities-index.ps1 -Root $rootPath | Out-Host
  . EasyWayData.wiki/scripts/generate-master-index.ps1 -Root $rootPath | Out-Host
  . EasyWayData.wiki/scripts/export-chunks-jsonl.ps1 -Root $rootPath | Out-Host
  . EasyWayData.wiki/scripts/lint-atomicity.ps1 -Root $rootPath | Out-Host
}

# 3) Log finale
. EasyWayData.wiki/scripts/add-log.ps1 -Type REVIEW -Scope full-pass-multi -Status success -Owner team-docs -Message "Full pass multi-root: normalize+rebuild+lint" -Split monthly
```

## Utility: aggiungi front matter mancante
```powershell
. EasyWayData.wiki/scripts/bulk-frontmatter.ps1 -Root EasyWayData.wiki -DefaultTag 'layer/reference'
```

## Log attività (esempio)
```powershell
. EasyWayData.wiki/scripts/add-log.ps1 -Type DOC -Scope wiki -Status success -Owner team-docs -Message "Aggiornata guida scripts"
```

## Domande a cui risponde
- Quali script usare per normalizzare e ricostruire la wiki?
- Come eseguire le routine multi-root e generare report?
- Dove trovare esempi one-shot e job completi?
- Come tracciare i risultati nei log?
