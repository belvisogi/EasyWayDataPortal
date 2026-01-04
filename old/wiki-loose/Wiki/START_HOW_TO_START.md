---
title: Da dove iniziare — Piano operativo per l'MVP agentico
summary: Passi concreti, priorità e deliverable per partire con un MVP di EasyWayDataPortal focalizzato su Plan Viewer, checklist e wizard.
---

Obiettivo rapido
- Ottenere un MVP funzionante che dimostri la vision agentica: Plan API + Plan Viewer + Wizard minimale + WhatIf preview + checklistSuggestions (priority.json).

Principi guida per l'avvio
- Iterare velocemente: prototipo funzionante → test pilota → hardening.
- Minimizzare il perimetro: solo 3 intent/flow iniziali (es. create table, modifica schema, update docs).
- Safety-first: preview/WhatIf e guardrail per evitare DML diretto.

Attività immediate (sprint 0 — 1–2 settimane)
1) Spec Plan API
   - Cosa: definire GET /api/plan?intent=..., POST /api/intent, GET /api/agents/{agent}/priority, POST /api/simulate.
   - Owner: backend dev (1)
   - Stima: 2 giorni
   - Criteri: risposta JSON contiene plan.checklistSuggestions come da orchestratore.

2) Abilitare evaluation priority.json nell'orchestratore
   - Cosa: completare valutazione delle condizioni "when" (branch, changedPaths) e rendere opzionale la logica se mancano file.
   - Owner: backend dev (1)
   - Stima: 2–3 giorni
   - Criteri: orchestratore restituisce checklistSuggestions per agent se priority.json presente.

3) Template priority.json e ejemplos
   - Cosa: creare agents/core/templates/priority.template.json e un esempio per agent_docs_review e agent_governance.
   - Owner: platform/tech writer
   - Stima: 1 giorno
   - Criteri: esempi commitati e referenziati in manifest.

4) Plan Viewer — prototype frontend
   - Cosa: pagina che consuma /api/plan e mostra intent, passi, agenti, checklistSuggestions (mandatory/advisory).
   - Owner: frontend dev (1)
   - Stima: 4–6 giorni
   - Criteri: mostra plan JSON traducendo checklistSuggestions in badge severity e lista per agente.

5) Wizard minimale (Create table)
   - Cosa: wizard multi-step che genera JSON mini-DSL e invia intent a /api/intent; include preview SQL (WhatIf stub).
   - Owner: frontend dev + backend dev (coordinati)
   - Stima: 1–2 settimane (prototipo)
   - Criteri: wizard produce intent JSON valido, Plan Viewer mostra il plan risultante.

Deliverable MVP (8–12 settimane target)
- API: /api/plan, /api/intent, /api/simulate
- Orchestratore: reading priority.json + evaluation skeleton
- Frontend: Plan Viewer + Wizard base + Preview SQL
- Templates: priority.json examples, mini-DSL examples
- Docs: Wiki con how-to per wizard e piano di test, un dataset demo per simulator

Roadmap consigliata (tre fasi)
- Fase A (MVP): come sopra — dimostrazione interna + 1 cliente pilota.
- Fase B (Pilot → Hardening, 3 mesi): WhatIf engine completo, conversational assistant MVP, checklist conditional rules complete, tests.
- Fase C (Productize, 3–6 mesi): multi-tenant, sandbox simulator per PMI, packaging commerciale, security & compliance.

Ruoli raccomandati per primo ciclo
- Product / UX (0.5 FTE)
- Backend dev (1‑2 FTE)
- Frontend dev (1 FTE)
- DevOps/QA (0.5‑1 FTE)
- Tech writer / KB maintainer (0.5 FTE)

Metriche di successo per il pilot
- Time-to-plan < 5 min per intent
- Gate pass rate > 80% per PR generate dagli agenti (dopo tuning)
- Numero di interventi manuali richiesti < 30% dei piani
- Feedback utenti non tecnici: task completion rate > 80% sul wizard

Quick wins (da fare subito)
- Aggiungere priority.template.json per agenti e inserirne 2 esempi reali.
- Aggiornare orchestratore (già fatto parzialmente) per includere checklistSuggestions.
- Prototipare Plan Viewer con dati mock (veloce: HTML + JS che carica JSON statico).

Prossimi passi consigliati (operativi)
1. Kickoff meeting 1h: definire 3 intent iniziali, assegnare owners.
2. Sprint 0 (2 settimane): completare Spec Plan API + template priority.json + orchestratore checklist.
3. Sprint 1 (2 settimane): Plan Viewer prototype + wizard skeleton.
4. Sprint 2 (2 settimane): integrare preview WhatIf e test interno + demo al pilota.

Note finali
- Posso generare ora: bozza pagina wiki dettagliata (wireframes + API spec), template priority.json per tutti gli agenti e backlog issue list.  
- Se vuoi, procedo subito a creare questi artefatti nel repository.
