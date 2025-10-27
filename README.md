# EasyWay Data Portal - Onboarding & Architettura

Start Here: [Wiki](Wiki/EasyWayData.wiki/start-here.md)

KB veloci: [WHAT-first Lint](agents/kb/recipes.jsonl) · [Stubs E2E](agents/kb/recipes.jsonl) · [DQ Blueprint](agents/kb/recipes.jsonl) · [HOWTO WHAT-first](Wiki/EasyWayData.wiki/howto-what-first-team.md)

Inclusività digitale: dar voce ai tuoi dati.

Benvenuto!
Questa repository contiene il portale EasyWay Data Portal, progettato per essere agentic‑ready, cloud‑native e facilmente estendibile.
**Questa pagina è la porta di ingresso: qui trovi tutto ciò che serve per capire, avviare e contribuire al progetto.**

## Perché e Cosa Fa

Perché EasyWay Data Portal
- Crediamo che la gestione dei dati debba essere semplice, accessibile e sicura per tutti: dalla piccola impresa al grande gruppo. Vogliamo abbattere le barriere tecniche e democratizzare l’accesso a strumenti avanzati, permettendo a chiunque di ottenere valore dai propri dati senza complessità, costi nascosti o dipendenza da specialisti.

Cosa fa EasyWay Data Portal
- Offre una piattaforma intuitiva dove anche chi non è tecnico può gestire, analizzare e valorizzare i propri dati in modo sicuro e automatizzato.
- Automatizza i processi ripetitivi e complessi con agenti, liberando tempo e risorse per il business.
- Garantisce sicurezza, compliance e tracciabilità by design.
- Si adatta alle esigenze: chi vuole “usare” trova servizi pronti; chi vuole “costruire” trova un framework modulare e estendibile.
- Cresce con te: dalla microimpresa al grande gruppo, senza rework.

> Stato: Preview in evoluzione — stiamo costruendo un portale per tutti. Le fondamenta sono già operative (agent‑first, dual‑mode, WhatIf, gates, Doc Alignment). La roadmap accompagna i prossimi mesi fino al rilascio pubblico.

---

## 1. Cos'è EasyWay Data Portal

- Portale dati multi‑tenant, API‑first, con architettura agentica e automazione avanzata.
- Basato su Azure (App Service, SQL, Blob, Key Vault, App Insights), Node.js/TypeScript, e best practice DevOps.
- Tutte le mutazioni dati passano da Stored Procedure con auditing/logging centralizzato.

---

## 2. Onboarding rapido

1. Clona la repo  
   `git clone ...`
2. Setup ambiente  
   - Node.js 18+, npm install in `EasyWay-DataPortal/easyway-portal-api/`
   - Variabili ambiente: vedi [deployment-decision-mvp.md](Wiki/EasyWayData.wiki/deployment-decision-mvp.md)
   - DB: Azure SQL, provisioning via script in `DataBase/provisioning/`
3. Avvio locale (dual‑mode)  
   - Sviluppo low‑cost: imposta `DB_MODE=mock` e usa `npm run dev:jwt` per generare token locali; dettagli in [Sviluppo Locale Dual‑Mode](Wiki/EasyWayData.wiki/dev-dual-mode.md)
   - Avvio: `cd EasyWay-DataPortal/easyway-portal-api/ && npm run dev`
   - Test API: vedi collezioni Postman in `tests/postman/`
4. Deploy cloud  
   - Pipeline Azure DevOps (vedi [roadmap.md](Wiki/EasyWayData.wiki/roadmap.md) e [deployment-decision-mvp.md](Wiki/EasyWayData.wiki/deployment-decision-mvp.md))
   - Segreti via Key Vault, slot di staging, smoke test post‑deploy

---

## 3. Architettura (sintesi)

- Cloud: Azure App Service, SQL, Blob, Key Vault, App Insights, Entra ID (roadmap)
- Principi agentici: orchestratore, manifest.json, goals.json, template SQL/SP, gates CI/CD, human‑in‑the‑loop
- Principali agent disponibili:
  - agent_datalake: gestione operativa e compliance del Datalake (naming, ACL, retention, export log, audit)
  - agent_dba: gestione migrazioni DB, drift check, documentazione ERD/SP, RLS rollout
  - agent_docs_review: normalizzazione Wiki, indici/chunk, coerenza KB, supporto ricette
  - agent_governance: quality gates, checklist pre‑deploy, DB drift, KB consistency, generazione appsettings
  - (vedi cartella `agents/` per l'elenco completo)
- Sicurezza: segreti solo in Key Vault, rate limiting, validazione input, audit log
- Documentazione: Wiki ricca, template, checklist, roadmap, TODO pubblici

### Metodo di Lavoro (Agent‑First)
- Intent‑first, manifest per agente, orchestrazione `ewctl.ps1`, KB+Wiki aggiornate ad ogni change.
- Due rubinetti: locale low‑cost (mock) e cloud pronto (sql/kv) via env.
- Definizione di Fatto: KB+Wiki aggiornate, gates verdi, eventi log.
- Leggi: [Metodo Agent‑First](Wiki/EasyWayData.wiki/agent-first-method.md), [Contratto Intent](Wiki/EasyWayData.wiki/intent-contract.md), [Output Contract](Wiki/EasyWayData.wiki/output-contract.md)

Per dettagli:  
- [Architettura Azure](docs/infra/azure-architecture.md)  
- [Principi agentici](docs/agentic/AGENTIC_READINESS.md)  
- [Valutazione stato & gap](VALUTAZIONE_EasyWayDataPortal.md)  
- [Decisione deploy MVP](Wiki/EasyWayData.wiki/deployment-decision-mvp.md)

---

## 4. Roadmap & TODO

- Roadmap evolutiva: [roadmap.md](Wiki/EasyWayData.wiki/roadmap.md)
- Razionalizzazione e uniformamento: [TODO_CHECKLIST.md](Wiki/EasyWayData.wiki/todo-checklist.md)

---

## 5. Contribuire

- Segui le convenzioni di naming e i template agentici (vedi Wiki)
- Proponi PR incrementali, con test e documentazione aggiornata
- Consulta la [Wiki](Wiki/EasyWayData.wiki/index.md) per ogni dettaglio

---

## 6. Link utili

- [Wiki - Indice Globale](Wiki/EasyWayData.wiki/index.md)
- [KB – WHAT-first Lint](agents/kb/recipes.jsonl) — ids: kb-whatfirst-lint-401, kb-howto-what-first-team-402
- [KB – Stubs Workflow E2E](agents/kb/recipes.jsonl) — id: kb-orch-intents-stubs-301
- [KB – DQ Blueprint Agent](agents/kb/recipes.jsonl) — id: kb-agent-dq-blueprint-201
- [HOWTO – WHAT‑first + Diario di Bordo](Wiki/EasyWayData.wiki/howto-what-first-team.md)
- [Onboarding API](EasyWay-DataPortal/easyway-portal-api/README.md)
- [Provisioning DB](DataBase/provisioning/README.md)
- [Test & QA](tests/README.md)

---

**Per ogni dubbio, consulta la Wiki o apri una issue!**
