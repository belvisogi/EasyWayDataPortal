---
id: ew-scripts
title: Scripts - One-shot e routine frequenti
summary: Comandi ricorrenti per rigenerare indici, manifest, ancore e chunk, eseguire lint e review, e loggare le attività.
status: active
owner: team-docs
created: '2025-10-18'
updated: '2025-10-18'
tags: [automation, domain/control-plane, layer/reference, audience/dev, audience/ops, privacy/internal, language/it, scripts]
entities: []
llm:
  include: true
  pii: none
  chunk_hint: 250-400
  redaction: [email, phone]
next: TODO - definire next step.
---

[[start-here|Home]] > [[Domain - Control-Plane|Control-Plane]] > [[Layer - Reference|Reference]]

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
```sql

## Multi-root: aggrega più progetti
```powershell
# Pre-requisito: genera gli artefatti per ogni root
. EasyWayData.wiki/scripts/generate-master-index.ps1 -Root EasyWayData.wiki
. EasyWayData.wiki/scripts/generate-master-index.ps1 -Root OtherWiki

# Aggregazione in file *_all (nella workspace root)
. EasyWayData.wiki/scripts/generate-master-index-aggregate.ps1 -Roots @('EasyWayData.wiki','OtherWiki')
```sql

## Multi-root: normalizzazione (scan/apply) e report
```powershell
# Scansione senza modifiche (report per-root + sommario)
. EasyWayData.wiki/scripts/normalize-project-multi.ps1 -Roots @('EasyWayData.wiki','OtherWiki') -Mode scan

# Applicazione con front matter minimo dove manca
. EasyWayData.wiki/scripts/normalize-project-multi.ps1 -Roots @('EasyWayData.wiki','OtherWiki') -Mode apply -EnsureFrontMatter
```sql

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
```sql

## Utility: aggiungi front matter mancante
```powershell
. EasyWayData.wiki/scripts/bulk-frontmatter.ps1 -Root EasyWayData.wiki -DefaultTag 'layer/reference'

## Utility: bulk fix frontmatter (owner/status/tags)
```powershell
. EasyWayData.wiki/scripts/fix-frontmatter-bulk.ps1 -WikiPath Wiki/EasyWayData.wiki -Apply
```sql
```sql

## Log attività (esempio)
```powershell
. EasyWayData.wiki/scripts/add-log.ps1 -Type DOC -Scope wiki -Status success -Owner team-docs -Message "Aggiornata guida scripts"
```sql

## Link-check + anchor-check (CI-friendly)

Check mirato per evitare link rotti e anchor mancanti, con output **machine-readable** (JSON) e senza generare indici/artefatti.

Nota: nei report JSON il campo `file` è un path **relativo** (stabile e CI-friendly). Per includere anche il path assoluto per debug, usa `-IncludeFullPath`.

```powershell
pwsh scripts/wiki-links-anchors-lint.ps1 -Path "Wiki/EasyWayData.wiki" -ExcludePaths logs/reports,old,.attachments -FailOnError -SummaryOut "wiki-links-anchors-lint.json"
```sql

## Summary lint (no placeholder) - phased

Enforce che `summary:` non sia vuoto e non sia un placeholder, iniziando da uno scope alla volta.

```powershell
pwsh scripts/wiki-summary-lint.ps1 -Path "Wiki/EasyWayData.wiki" -ExcludePaths logs/reports,old,.attachments -ScopesPath "docs/agentic/templates/docs/tag-taxonomy.scopes.json" -ScopeName "portal-api-frontend-20" -FailOnError -SummaryOut "wiki-summary-lint.portal-api-frontend-20.json"
```sql

## Index lint (`index.md`) - phased

Enforce che le pagine `index.md` non siano ambigue: `title` specifico (kebab-case) e `summary` non placeholder.

```powershell
pwsh scripts/wiki-index-lint.ps1 -Path "Wiki/EasyWayData.wiki" -ExcludePaths logs/reports,old,.attachments -ScopesPath "docs/agentic/templates/docs/tag-taxonomy.scopes.json" -ScopeName "portal-api-frontend-20" -FailOnError -SummaryOut "wiki-index-lint.portal-api-frontend-20.json"
```sql

## Domande a cui risponde
- Quali script usare per normalizzare e ricostruire la wiki?
- Come eseguire le routine multi-root e generare report?
- Dove trovare esempi one-shot e job completi?
- Come tracciare i risultati nei log?









