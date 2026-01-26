---
title: Quest Board – Excel/CSV Upload (L1→L5)
tags: [domain/ux, layer/spec, audience/non-expert, audience/dev, privacy/internal, language/it, quest, roadmap, use-case, argos, agents]
status: active
updated: 2026-01-16
redaction: [email, phone]
id: ew-questboard-excel-csv
chunk_hint: 250-400
entities: []
include: true
summary: Roadmap a livelli per portare l’utente da un file Excel/CSV a una dashboard con diario di bordo e agenti ARGOS, in modalità One‑Button.
llm: 
pii: none
owner: team-platform
---

[Home](../../docs/project-root/DEVELOPER_START_HERE.md) > [[Domain - Ux|Ux]] > [[Layer - Spec|Spec]]

# Quest Board – Excel/CSV Upload (L1→L5)

Principi
- WHAT‑first: definire cosa fare (manifest, intents, UX) prima del come.
- One‑Button UX: semplicità per tutti; percorso Base sempre disponibile.
- Diario di bordo: ogni step lascia messaggi chiari, esiti e prossime azioni.

Mappa a livelli (L1→L5)
- L1 – One‑Button MVP
  - Quest: caricare un file, superare DQ base, vedere la dashboard standard.
  - Deliverable: manifest wf, intents JSON, mapping template, UX mock, stub CLI end‑to‑end, diario JSON.
  - Gate: Wiki LLM front‑matter lint; Events JSON Schema Validation; GovernanceGates (ewctl) se applicabile.
  - SLO/KPI: file→dashboard ≤ 2 min; first‑try success ≥ 85%.
  - DoR: manifest wf + intents + UX prompts presenti; KB di prova pronta.
  - DoD: stub CLI eseguibili in sequenza; diario prodotto; Wiki/KB aggiornate.
- L2 – Mapping & Dedup
  - Quest: suggerire/applicare mapping salvabile; dedup controllato su chiave candidata.
  - Deliverable: mapping persistente (template id), opzioni dedup (safe), copy UX.
  - Gate: Governance review mapping; privacy (no PII in sample/anteprime).
  - KPI: riduzione dei retry; minor rumore DQ.
- L3 – Conversational Analytics
  - Quest: agent Q&A su viste/materializzazioni; salva widget.
  - Deliverable: set di viste stabili; copy UX per domande comuni; log query.
  - Gate: performance base; explainability (mostra come calcoliamo).
- L4 – Arricchimenti Tecnici
  - Quest: outlier avanzati, multi‑conto, cambio valuta.
  - Deliverable: policy/viste aggiuntive; template opzioni avanzate.
- L5 – Connettori & Scheduling
  - Quest: template multipli, schedulazione, connettori esterni (banche/API).
  - Deliverable: manifest con nuovi trigger; checklist sicurezza.

Riferimenti essenziali
- Orchestrazione (WHAT): orchestrations/wf-excel-csv-upload.md
- Manifest JSON: docs/agentic/templates/orchestrations/wf.excel-csv-upload.manifest.json
- Intents Catalog: orchestrations/intents-catalog.md
- Mapping Template: docs/agentic/templates/mapping.entrate-uscite.template.yaml
- UX Diario (mock): UX/diary-mock-wf-excel-csv-upload.md
- UX Prompts (IT/EN): docs/agentic/templates/orchestrations/ux_prompts.it.json, ux_prompts.en.json
- KB – Prova stubs: agents/kb/recipes.jsonl (id=kb-orch-intents-stubs-301)
- KB – DQ Blueprint (facoltativo): agents/kb/recipes.jsonl (id=kb-agent-dq-blueprint-201)

Backlog mirato (L1)
- Implementare ingest reale (landing + anteprima robusta) mantenendo il contratto dell’intent.
- DQ base reale (ARGOS) con Decision Trace minimale.
- Materializzazioni KPI base (viste semplici) con tempi di risposta adeguati.
- Diario JSON/HTML consolidato con i messaggi da ux_prompts.

Misurazione (L1)
- time_to_dashboard_ms, first_try_success, warnings_count, gpr (se applicabile).
- Artifact: out/diary/diary.json (timeline), log eventi argos.* (se emessi).

Note
- I livelli successivi (L2..L5) si innestano senza rompere il contratto UX/WHAT definito a L1.







