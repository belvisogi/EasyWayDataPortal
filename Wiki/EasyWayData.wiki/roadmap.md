---
id: ew-roadmap
title: Roadmap & Qualità Documentazione
summary: Sezione operativa per mantenere la documentazione conforme alle best practice e pronta per agenti/LLM, con comandi locali e pipeline CI.
status: active
owner: team-docs
created: '2025-10-18'
updated: '2025-10-18'
tags: [roadmap, quality, automation, domain/docs, layer/reference, audience/non-expert, audience/dev, privacy/internal, language/it]
entities: []
llm:
  include: true
  pii: none
  chunk_hint: 250-400
  redaction: [email, phone]
next: TODO - definire next step.
---

[[start-here|Home]] > [[domains/docs-governance|Docs]] > [[Layer - Reference|Reference]]

# Roadmap & Qualità Documentazione

## Obiettivi
- Garantire naming/ancore=0, front matter completo, Q&A minime e code fence con linguaggio.
- Generare manifest JSONL/CSV, anchors e chunk per agenti.
- Automatizzare scan/apply multi‑root e pubblicare report in CI.

## Comandi locali (riassunto)
```powershell
# 1) Scansione normalizzazione (multi-root)
. scripts/normalize-project-multi.ps1 -Roots @('.') -Mode scan

# 2) Applicazione normalizzazione (front matter, fence, tag, Q&A index)
. scripts/normalize-project-multi.ps1 -Roots @('.') -Mode apply -EnsureFrontMatter

# 3) Rebuild + lint
./scripts/review-run.ps1 -Root . -Mode kebab -CheckAnchors
. ./scripts/generate-entities-index.ps1 -Root .
. ./scripts/generate-master-index.ps1 -Root .
. ./scripts/export-chunks-jsonl.ps1 -Root .
. ./scripts/lint-atomicity.ps1 -Root .
```sql

## Pipeline CI (Azure DevOps)
- La pipeline `azure-pipelines.yml` lancia la scansione normalizzatrice in modalità `scan` ad ogni PR e pubblica i report `logs/reports/*` come artifact.
- Estendibile per includere rebuild e linter se richiesto.

## Criteri di accettazione
- Lint atomicità: nessun file con Q&A < 3 (fuori whitelist) e nessun code fence senza linguaggio.
- Naming/Anchor check: 0 issue.
- Manifest/Anchors/Chunks aggiornati.








