---
id: ew-agents-governance
title: Multi‑Agent & Governance – EasyWay
summary: Struttura di agenti specializzati + control plane (gates/policy) con ADO
status: draft
owner: team-platform
tags: [agents, governance, domain/control-plane, layer/reference, audience/non-expert, audience/dev, audience/ops, privacy/internal, language/it]
llm:
  include: true
  pii: none
  chunk_hint: 250-400
  redaction: [email, phone]
entities: []
updated: '2026-01-05'
next: TODO - definire next step.
---

Visione
- Agenti specializzati (DBA, Frontend, AMS, Governance) coordinati da un control plane (Azure DevOps) con policy, gates e audit.

Ruoli
- Agent_DBA: migrazioni Flyway, drift, ERD/SP docs, RLS rollout
- Agent_Frontend: mini‑portal, branding, MSAL wiring
- Agent_AMS: esecuzione ricette KB, setup env, checklist, variable group
- Agent_Governance: policy, qualità, gates (Checklist/Drift/KB), approvazioni

Policy & Manifests
- `agents/<role>/manifest.json`: scope path, tools ammessi, gates richiesti, approvazioni
- KB operativa: `agents/kb/recipes.jsonl` (JSONL) consumabile via `/api/docs/kb.json`

Gates in pipeline (ADO)
- Pre‑Deploy Checklist: verifica env/connessioni e OpenAPI
- DB Drift Check: oggetti richiesti presenti
- KB Consistency: se cambiano `db/**` o `src/**`, obbligo aggiornamento KB + Wiki
- (Opz.) Flyway Migrate Dev/Test: esegue validate/migrate con variabili Flyway

ChatOps (opzionali)
- Teams/Logic Apps per comandi semplici; l’agente usa la KB e pubblica artifact (checklist.json/drift.json)

Audit & Osservabilità
- `PORTAL.LOG_AUDIT` per eventi agent; Application Insights/OTel per tracing e KPI (in roadmap)







