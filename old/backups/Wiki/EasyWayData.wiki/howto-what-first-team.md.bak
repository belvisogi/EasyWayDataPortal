---
id: ew-howto-what-first-team
title: HOWTO – WHAT‑first + Diario di Bordo (Team)
summary: Guida pratica per team: definisci il WHAT (manifest, intents, UX), esegui i lint, poi implementa gli agent sostituendo gli stub, mantenendo il diario di bordo.
status: active
owner: team-platform
tags: [howto, process, agents, argos, language/it]
llm:
  include: true
  pii: none
  chunk_hint: 250-400
  redaction: [email, phone]
entities: []
---

# HOWTO – WHAT‑first + Diario di Bordo (Team)

Obiettivo
- Adottare un flusso di lavoro semplice e ripetibile: prima descriviamo cosa fare (WHAT), poi realizziamo il come (HOW), con un diario di bordo chiaro per utenti e sviluppatori.

Prerequisiti
- Manifesto orchestrazione + intents (cartella `docs/agentic/templates/`)
- Copioni UX localizzati (IT/EN)
- Stub CLI disponibili (opzionali) per provare il flusso end‑to‑end

Passi consigliati (Step‑by‑Step)
1) Definisci il WHAT dell’orchestrazione
   - Crea/aggiorna `docs/agentic/templates/orchestrations/<wf>.manifest.json` (scopo, stati, transizioni, contratti I/O, osservabilità, ux_prompts key)
   - Aggiungi pagina Wiki: `Wiki/EasyWayData.wiki/orchestrations/<wf>.md` (WHAT)
2) Definisci gli Intents (WHAT)
   - Per ogni step/agent: `docs/agentic/templates/intents/<name>.intent.json` con input/output e criteri di esito
   - Aggiorna il Catalogo: `Wiki/.../orchestrations/intents-catalog.md`
3) Scrivi i copioni UX (locale IT/EN)
   - `docs/agentic/templates/orchestrations/ux_prompts.it.json` e `ux_prompts.en.json`
   - Verifica coerenza con i messaggi del manifest e i mock
4) Esegui i lint (Docs + WHAT‑first)
   - Front‑matter Wiki: `pwsh scripts/wiki-frontmatter-lint.ps1 -FailOnError`
   - WHAT‑first: `pwsh scripts/whatfirst-lint.ps1 -FailOnError`
   - Eventi ARGOS: job “Events JSON Schema Validation” su CI
5) Prova gli stub (opzionale ma utile)
   - Usa la ricetta KB `kb-orch-intents-stubs-301` per generare artifact in `out/`
   - Condividi il diario preliminare con il team
6) Implementa il HOW per agent/step
   - Sostituisci uno stub alla volta rispettando i contratti WHAT
   - Mantieni l’output JSON atteso (per il diario) e gli eventi `argos.*`
7) Diario di Bordo
   - Aggrega le entry JSON ad ogni transizione (`timestamp, stage, outcome, reason, next, decision_trace_id, artifacts[]`)
   - Usa i copioni UX per i messaggi in UI (One‑Button UX)

Definition of Ready / Done
- DoR: manifest + intents + UX prompts presenti; lint verdi; Wiki aggiornata
- DoD: agent implementati con output strutturati; diario generato; pagina Wiki/Quest Board aggiornata; gates CI verdi

Checklist veloce
- [ ] Manifest orchestrazione (WHAT)
- [ ] Intents (WHAT) completi
- [ ] UX prompts IT/EN
- [ ] Lint (front‑matter, WHAT‑first, eventi) OK
- [ ] Stub provati (se usati)
- [ ] Agent HOW implementati (almeno 1 step)
- [ ] Diario generato e linkato in PR

Troubleshooting
- Lint fallisce → apri i report artifact: `wiki-frontmatter-lint.json`, `whatfirst-lint.json`, `event-schema-validate.log`
- UX incoerente → riallinea `ux_prompts.*.json` e i mock
- Output mismatch → confronta con gli schemi degli intents

Riferimenti
- AGENTS.md → Metodo WHAT‑first + Diario di Bordo
- Orchestrazione (Excel/CSV): `orchestrations/wf-excel-csv-upload.md`
- Intents Catalog: `orchestrations/intents-catalog.md`
- UX Mock (diario): `UX/diary-mock-wf-excel-csv-upload.md`
- UX Checklist: `UX/usability-checklist.md`
- Quest Board: `quest-board-excel-csv.md`

