# EasyWay Data Portal - Onboarding & Architettura

> **ℹ️**  
> Per automazioni export log, policy ACL e best-practice di accesso e governance dei dati in Datalake, vedi [Datalake Standard & Runbook](wiki/easyway-webapp/03_datalake_dev/index.md).

```mermaid
flowchart LR
    subgraph Portal_Core["DataPortal - Core Domains"]
      API([API REST/Agentica])
      DB([DB / Stored Procedure])
      LOGS([Audit/Business Logs])
      CONFIG([Config YAML/DB])
    end

    subgraph Datalake["Datalake (Azure Gen2 + IAM/ACL)"]
      LAKE_YAML([Branding YAML/Config])
      LAKE_LOGS([Log Export / Audit files])
      LAKE_DATA([ETL/ELT Stage/Raw])
      ACL([Policy, ACL, IAM])
    end

    API --push/pull branding, config--> LAKE_YAML
    LOGS --export pipeline--> LAKE_LOGS
    DB --Data workflows--> LAKE_DATA
    CONFIG --Read/Override--> LAKE_YAML
    API --Manage access--> ACL
    ACL --Apply policies--> Datalake
    LAKE_DATA -. Tracciabilità .-> LOGS
```
---
Start Here: [Wiki](wiki/EasyWayData.wiki/start-here.md)

KB veloci: [WHAT-first Lint](agents/kb/recipes.jsonl) · [Stubs E2E](agents/kb/recipes.jsonl) · [DQ Blueprint](agents/kb/recipes.jsonl) · [HOWTO WHAT-first](wiki/EasyWayData.wiki/howto-what-first-team.md)

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
   - Node.js 18+, npm install in `easyway-portal/easyway-portal-api/`
   - Variabili ambiente: vedi [deployment-decision-mvp.md](wiki/EasyWayData.wiki/deployment-decision-mvp.md)
   - DB: Azure SQL, provisioning via script in `database/provisioning/`
3. Avvio locale (dual‑mode)  
   - Sviluppo low‑cost: imposta `DB_MODE=mock` e usa `npm run dev:jwt` per generare token locali; dettagli in [Sviluppo Locale Dual‑Mode](wiki/EasyWayData.wiki/dev-dual-mode.md)
   - Avvio: `cd easyway-portal/easyway-portal-api/ && npm run dev`
   - Test API: vedi collezioni Postman in `tests/postman/`
4. Deploy cloud  
   - Pipeline Azure DevOps (vedi [roadmap.md](wiki/EasyWayData.wiki/roadmap.md) e [deployment-decision-mvp.md](wiki/EasyWayData.wiki/deployment-decision-mvp.md))
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

### Metodo di Lavoro (Agent-First)
- Intent-first, manifest per agente, orchestrazione `ewctl.ps1`, KB+Wiki aggiornate ad ogni change.
- Due rubinetti: locale low-cost (mock) e cloud pronto (sql/kv) via env.
- Definizione di Fatto: KB+Wiki aggiornate, gates verdi, eventi log.
- Best practice (doc navigation): `scripts/intents/doc-nav-improvement-001.json`
- Leggi: [Metodo Agent-First](wiki/EasyWayData.wiki/agent-first-method.md), [Contratto Intent](wiki/EasyWayData.wiki/intent-contract.md), [Output Contract](wiki/EasyWayData.wiki/output-contract.md)

Per dettagli:  
- [Architettura Azure](docs/infra/azure-architecture.md)  
- [Principi agentici](docs/agentic/AGENTIC_READINESS.md)  
- [Valutazione stato & gap](VALUTAZIONE_EasyWayDataPortal.md)  
- [Decisione deploy MVP](wiki/EasyWayData.wiki/deployment-decision-mvp.md)

---

## 4. Roadmap & TODO

- Roadmap evolutiva: [roadmap.md](wiki/EasyWayData.wiki/roadmap.md)
- Razionalizzazione e uniformamento: [TODO_CHECKLIST.md](wiki/EasyWayData.wiki/todo-checklist.md)

---

## 5. Contribuire

- Segui le convenzioni di naming e i template agentici (vedi wiki)
- Proponi PR incrementali, con test e documentazione aggiornata
- Consulta la [wiki](wiki/EasyWayData.wiki/index.md) per ogni dettaglio

---

## 6. Link utili

- [Orchestrazione n8n-db-ddl-inventory: workflow per allineamento automatizzato tra DDL DB, file inventario e wiki (agent_dba, n8n)](wiki/EasyWayData.wiki/orchestrations/n8n-db-ddl-inventory.md)
- [Orchestrazione n8n-db-table-create: workflow per creazione automatizzata di nuove tabelle DB con agent_dba, DDL, e aggiornamento Wiki (n8n, intent, CI/CD)](wiki/EasyWayData.wiki/orchestrations/n8n-db-table-create.md)
- [Wiki - Indice Globale](wiki/EasyWayData.wiki/index.md)
- [KB – WHAT-first Lint](agents/kb/recipes.jsonl) — ids: kb-whatfirst-lint-401, kb-howto-what-first-team-402
- [KB – Stubs Workflow E2E](agents/kb/recipes.jsonl) — id: kb-orch-intents-stubs-301
- [KB – DQ Blueprint Agent](agents/kb/recipes.jsonl) — id: kb-agent-dq-blueprint-201
- [HOWTO – WHAT‑first + Diario di Bordo](wiki/EasyWayData.wiki/howto-what-first-team.md)
- [Onboarding API](easyway-portal/easyway-portal-api/README.md)
- [Provisioning DB](database/provisioning/README.md)
- [Test & QA](tests/README.md)

---

**Per ogni dubbio, consulta la wiki o apri una issue!**

## Documenti di contesto
- [Materiale di riferimento (Legacy): documenti di architettura, onboarding, ADA ecc. non attivi ma utili a ricerca/confronto storico.](wiki/EasyWayData.wiki/blueprints/legacy-reference-material.md)
- `DEVELOPER_ONBOARDING.md`
- `Sintesi_EasyWayDataPortal.md`
- `VALUTAZIONE_EasyWayDataPortal.md`
- Asset UX: `wiki/EasyWayData.wiki/UX/branding-assets.md`
