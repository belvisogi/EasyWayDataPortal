---
id: wiki-uniformamento-roadmap
title: Roadmap Uniformamento Wiki secondo docs-conventions
summary: Piano pratico e incrementale per riscrivere e uniformare l'intera wiki secondo le convenzioni, con fasi, strumenti, responsabilità e criteri di accettazione.
status: active
owner: team-docs
created: '2025-10-18'
updated: '2025-10-18'
tags: [domain/docs, layer/reference, audience/dev, audience/non-expert, privacy/internal, language/it, roadmap, quality, documentation, governance, ai-readiness]
entities: []
llm:
  include: true
  pii: none
  chunk_hint: 250-400
  redaction: [email, phone]
next: TODO - definire next step.
---

[[start-here|Home]] > [[domains/docs-governance|Docs]] > [[Layer - Reference|Reference]]

# Roadmap Uniformamento Wiki secondo docs-conventions

## Obiettivi

- Uniformare naming, front matter, struttura contenuti, linking e indici.
- Rendere ogni pagina LLM‑friendly e bambino‑friendly.
- Automatizzare check e report per iterazioni rapide.

## Fasi e Sequenza

### Fase 0 — Baseline e strumenti
- Confermare regole in `docs-conventions.md` e `llm-readiness-checklist.md`.
- Usare `scripts/review-run.ps1` e `scripts/review-examples.ps1`; tenere aggiornati `entities.yaml` e `entities-index.md`.

### Fase 1 — Naming e indici
- Applicare batch di rinomine per kebab-case; generare `index.md` in sottocartelle e `index.md` globale.
- Aggiornare link interni; rigenerare `entities-index.md`.

### Fase 2 — Front Matter
- Aggiungere front matter minimo a tutti i `.md` (id, title, summary, owner, tags, llm, entities).
- Assegnare owner/tag per area (es. team-docs, team-api, team-data, team-ops).

### Fase 3 — Struttura Pagine
- Uniformare sezioni: Scopo, Prerequisiti, Passi, Esempi, Errori comuni, Q&A, Collegamenti.
- Obbligatoria “Questions Answered” (3–7) e blocchi di codice con linguaggio.

### Fase 4 — Entità e Tagging
- Aggiornare `entities.yaml` con entità da DB, API, policy, flussi, standard.
- Aggiungere `entities: [...]` nel front matter; rigenerare `entities-index.md`.

### Fase 5 — Link e Ancore
- Link checker + anchor checker (`-CheckAnchors`); correggere link rotti/ancore mancanti.

### Fase 6 — Privacy e PII
- Classificare privacy (`privacy/*`) e PII (`llm.pii`) nelle pagine sensibili; attivare redaction se necessario.

### Fase 7 — QA Finale
- Eseguire review-run completo (naming=0, anchors=0, indici creati).
- Allineare `docs-conventions.md` se emergono nuovi pattern.

## Per‑Cartella (linee guida)

### 01_database_architecture
- `programmability/` (function.md, sequence.md, stored-procedure/*.md): front matter con `artifact/*`, check esempi DDL idempotenti; `index.md` a livello cartella e sottocartella.
- `easyway-webapp/01_database_architecture/01a-db-setup.md`, `easyway-webapp/01_database_architecture/01b-schema-structure.md`: sezioni standard, Q&A, collegamenti a entità DB.

### 02_logiche_easyway
- Sotto‑cartelle (`api-esterne-integrazione`, `logging-and-audit`, `login-flussi-onboarding`, `notifiche-gestione`): front matter completo, esempi CURL/JSON, schemi input/output, Q&A.
- Aggiornare `entities.yaml` con standard (`rest-naming`, `best-practice-naming`) e guide.

### 03_datalake_dev
- Standard IAM/naming: front matter (policy/security), esempi e tabelle schemi.

### 05_codice_easyway_portale
- `easyway_portal_api`: endpoint con schema `endp-00n-*.md` + front matter ricco; policy e step con naming pulito; index cartella; anchor check.
- I log/policy e standard devono linkare entità e pagine correlate.

### 06_frontend_architecture, 07_iam_naming_utenti_gruppi, 10_ai_agents
- Front matter + sezioni standard; esempi path e mapping, Q&A, collegamenti.

## Template Autoriali (snippet)

### Endpoint (API)
- Purpose, Inputs/Validations, Responses (200/4xx/5xx), Examples (curl/JSON), Error handling, Related.

### Stored Procedure
- Purpose, Signature, Inputs/Outputs, Idempotenza, Indici/FK/Check, Esempi invocazione, Rollback, Related.

### Flow/Guide/Standard
- Scope, Prereqs, Steps, Examples, Pitfalls, Q&A, Related, Entities.

## Automazioni (da usare sempre)

### Naming + indici
- `EasyWayData.wiki/scripts/review-run.ps1 -Root EasyWayData.wiki -Mode kebab`

### Anchor check
- `EasyWayData.wiki/scripts/review-run.ps1 -Root EasyWayData.wiki -Mode kebab -CheckAnchors`

### Index globale
- `. EasyWayData.wiki/scripts/review-examples.ps1; New-RootIndex -Root 'EasyWayData.wiki'`

### Log attività
- `EasyWayData.wiki/scripts/add-log.ps1 -Type DOC -Scope wiki -Status success -Owner team-docs -Message "Aggiornata roadmap uniformamento" -Split monthly`

### Manifest per agenti (JSONL/CSV) + ancore
- `EasyWayData.wiki/scripts/generate-master-index.ps1 -Root EasyWayData.wiki`
- Output: `index_master.csv`, `index_master.jsonl`, `anchors_master.csv`

## Criteri di Accettazione

- Naming: 0 warning (runner naming=0) o warning solo whitelistati (meta/legacy).
- Front matter: presente in tutti i `.md` (id, title, summary, owner, tags, llm, entities).
- Struttura: sezioni standard + Q&A in ogni pagina.
- Link: 0 link file mancanti, 0 anchor mancanti (report anchors=0).
- Indici: `index.md` in cartelle chiave + `index.md` globale aggiornato.
- Entities: `entities.yaml` aggiornato + `entities-index.md` rigenerato.
- Privacy: `llm.include/pii` coerenti; redaction indicata dove serve.

## Assegnazione Owner e Tag (esempio)

- team-docs: root, convenzioni, checklist, indici.
- team-api: easyway_portal_api, endpoint, policy api.
- team-data: 01_database_architecture, 03_datalake_dev.
- team-ops: logging, runbook, iac.

Tag base:
- `layer/architecture`, `layer/reference`, `layer/how-to`, `policy/security/logging`, `artifact/endpoint/function/sequence/stored-procedure`, `audience/dev/ops/data/product`.

## Roadmap Operativa

### Sprint 1 (2–3 giorni)
- Conferma tassonomia tag/owner; passata completa naming (runner); indici cartelle; front matter top-level; baseline `entities.yaml`.

### Sprint 2 (3–5 giorni)
- Front matter completo per 01/02/05; struttura sezioni standard + Q&A; `entities-index.md` aggiornato.

### Sprint 3 (3–5 giorni)
- Link + anchor checker; fix rotture; privacy/PII; index globale.

### Sprint 4 (2–3 giorni)
- Rifiniture, report finale “LLM readiness”; aggiornamento `docs-conventions.md` con lessons learned.

## Rischi e Mitigazioni

- Link rotti post‑rinomina: correre sempre update link + anchor check prima del merge.
- Legacy path rumorosi: whitelist documentata; migrazione pianificata a valle.
- Double source/duplicati: eliminare file legacy appena la versione kebab-case è valida (loggare CLEAN).

## Output e Report

- `logs/reports/naming-*.txt` (naming issues)
- `logs/reports/anchors-*.md` (anchor issues)
- `entities-index.md` rigenerato
- `activity-log.md` aggiornato per ogni step (CSV-friendly)
- `index_master.csv` e `index_master.jsonl` per agenti e filtri rapidi
- `anchors_master.csv` per richiami di sezione H2/H3

## Domande a cui risponde
- Qual è il piano pratico per uniformare la wiki secondo le convenzioni?
- Quali strumenti/script usare e quando?
- Quali sono i criteri di accettazione misurabili?
- Come assegnare owner/tag e tracciare l’avanzamento?









