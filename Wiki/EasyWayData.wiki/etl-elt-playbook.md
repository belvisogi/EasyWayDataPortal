---
id: ew-etl-elt-playbook
title: ETL/ELT Playbook
summary: Schema guida per pipeline dati (sorgenti, mapping, DQ, naming file, schedule, monitoraggio, audit) in EasyWayDataPortal.
status: draft
owner: team-data
tags:
  - domain/data
  - layer/how-to
  - artifact/pipeline
  - etl
  - datalake
  - language/it
llm:
  include: true
  pii: none
  chunk_hint: 400-600
  redaction: [email, phone]
entities: []
---

# ETL/ELT Playbook
Breadcrumb: Home / Datalake / ETL-ELT Playbook

Scopo
- Fornire uno scheletro chiaro e ripetibile per documentare ed eseguire pipeline ETL/ELT in EasyWayDataPortal.
- Allineare persone e agenti (agent-first) su standard, naming e controlli.

Principi (agent-first)
- Intent → azione agente → WhatIf → apply → audit (Output Contract JSON).
- Tutto as‑code (spec/template/codice) e versionato (GitOps).
- Guardrail: qualità, sicurezza (ACL/ruoli), audit, costi.

Prerequisiti
- ADLS Gen2 con filesystem e path tenant (vedi “Datalake – Ensure Structure”).
- Policy di retention (vedi “Datalake – Set Retention”).
- Ruoli/ACL configurati (vedi “Datalake – Apply ACL”).

Sorgenti Tipiche (compila)
- Sistema: … (API/CSV/Database)
- Connessione/Autenticazione: …
- Frequenza: … (oraria/giornaliera/settimanale)

Naming File & Partizionamento
- Nome file (kebab‑case): `dataset-<tenant>-<yyyyMMddHHmm>.csv`
- Partizioni: `landing/<tenant>/yyyy=YYYY/mm=MM/dd=DD/`
- Solo ASCII; no spazi/accenti/simboli.

Schema & Mapping Colonne
- Tabella (nome, tipo, null, default, note).
- Trasformazioni/derivazioni: …

Regole di Data Quality (DQ)
- Validazioni minime: chiavi obbligatorie, formati, range, domini.
- Esito: `OK/BLOCKED`; scarti in `invalidrows/` con motivazione.

Flusso ETL/ELT (sintesi)
- landing → staging (arricchimento, DQ) → invalidrows (se KO) / official (se OK) → SQL (BRONZE/SILVER/GOLD).

Schedule & Orchestrazione
- Finestra: … (cron/ADF/Databricks/Jobs)
- Dipendenze: …

Monitoraggio & Fallback
- Metriche: throughput, latenze, volume file, % scarti.
- Allarmi: soglie, canali, runbook.
- Fallback: retry/backoff, reprocess window, quarantena file.

Audit & Logging
- Esecuzioni in `portal-audit/etl-execution-logs/...`
- Correlazione: job id, tenant, dataset, finestra.

Output & Contratti a Valle
- Dataset/Tabella di arrivo: …
- Contratto (schema, SLAs): …

Quick Checklist
- [ ] Sorgente, credenziali e finestra definiti
- [ ] Naming file e partizioni conformi
- [ ] Mapping colonne e DQ documentati
- [ ] ACL/ruoli e retention allineati
- [ ] Schedule e allarmi configurati
- [ ] Audit/log attivi

Allineamento Agentico
- Intents d’appoggio: `dlk-ensure-structure`, `dlk-apply-acl`, `dlk-set-retention` (WhatIf di default).
- Output Contract: JSON con `action/ok/whatIf/output/summary`; validabile via script.
- Ricette KB con `example_output` per facilitare parsing da LLM.

Riferimenti
- Datalake – Ensure Structure
- Datalake – Apply ACL
- Datalake – Set Retention
- Docs: “5.3 ETL / Datalake” in docs-conventions.md
- Output Contract (JSON)

