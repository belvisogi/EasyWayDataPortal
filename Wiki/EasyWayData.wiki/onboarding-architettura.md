---
id: ew-onboarding-architettura
title: EasyWay Data Portal — Onboarding & Architettura (Sintesi Unificata)
summary: 'Documento su EasyWay Data Portal — Onboarding & Architettura (Sintesi Unificata).'
status: active
owner: team-platform
tags: [domain/docs, layer/index, audience/non-expert, audience/dev, privacy/internal, language/it, onboarding, architecture, docs]
llm:
  include: true
  pii: none
  chunk_hint: 250-400
  redaction: [email, phone]
entities: []---
# EasyWay Data Portal — Onboarding & Architettura (Sintesi Unificata)

Questa pagina razionalizza e centralizza tutte le informazioni essenziali per capire, avviare e contribuire al progetto EasyWay Data Portal.  
**Per ogni dettaglio operativo, consulta i file canonici linkati in fondo.**
updated: '2026-01-05'
next: TODO - definire next step.
---

[[start-here|Home]] > [[domains/docs-governance|Docs]] > [[Layer - Index|Index]]

## 1. Stato attuale & gap principali

- Architettura agentica, cloud-native, multi-tenant, con automazione avanzata e sicurezza by design.
- Gap principali (vedi dettagli in [VALUTAZIONE_EasyWayDataPortal.md](../../VALUTAZIONE_EasyWayDataPortal.md)):
  - README root e onboarding: ora razionalizzati (vedi questa pagina e README.md)
  - Alcune API non usano solo SP e c’è mismatch tra nomi colonne e DDL standard (Users, Config)
  - Documentazione ricca ma dispersa: ora centralizzata qui e nella Wiki
  - Naming e struttura: attività di pulizia in corso (vedi [todo-checklist.md](todo-checklist.md))
  - Pipeline CI/CD e automazione documentale: da rafforzare
  - Sicurezza avanzata (Entra ID, RLS/masking, export log su Datalake): in roadmap

---

## 2. Architettura cloud (sintesi)

- **Compute**: Azure App Service (Linux), slot di staging, autoscaling
- **Database**: Azure SQL Database (backup/DR, AAD auth opzionale)
- **Storage**: Azure Blob Storage (override query SQL, asset branding, log export)
- **Sicurezza segreti**: Azure Key Vault (conn string DB, chiavi API, segreti)
- **Config**: Azure App Configuration (feature flags) o PORTAL.CONFIGURATION su DB
- **Observability**: Application Insights, Log Analytics
- **Identità**: Microsoft Entra ID / AD B2C (roadmap)
- **DevOps**: Azure Pipelines/GitHub Actions, smoke test post-deploy

Per dettagli: [docs/infra/azure-architecture.md](../../docs/infra/azure-architecture.md)

---

## 3. Principi agentici (sintesi)

- **Idempotenza**: ogni DDL/SP deve essere rieseguibile senza effetti collaterali
- **Solo Store Procedure per DML**: mutazioni dati solo via SP con auditing/logging centralizzato
- **Logging obbligatorio**: ogni SP aggiorna PORTAL.STATS_EXECUTION_LOG
- **Template e orchestrazione**: orchestratore, manifest.json, goals.json, template SQL/SP, gates CI/CD, human-in-the-loop
- **Sicurezza**: nessuna credenziale hard-coded, parametri via Key Vault/App Config, validazioni input lato API

Per dettagli: [docs/agentic/AGENTIC_READINESS.md](../../docs/agentic/AGENTIC_READINESS.md)

---

## 4. Roadmap & TODO

- Roadmap evolutiva: [roadmap.md](roadmap.md)
- Razionalizzazione e uniformamento: [todo-checklist.md](todo-checklist.md)
- Decisione deploy MVP: [deployment-decision-mvp.md](deployment-decision-mvp.md)

---

## 5. Azioni da fare (priorità)

1. Allineare tutte le API a usare solo SP e mapping colonne coerente con DDL
2. Completare la pulizia naming e struttura file/cartelle (kebab-case, no encoding, no maiuscole)
3. Rafforzare pipeline CI/CD (test automatici, validazione drift DB, gates agentici)
4. Implementare sicurezza avanzata (Entra ID, RLS/masking, export log su Datalake)
5. Completare automazione export AI (JSONL, tagging PII, dataset)
6. Aggiornare/creare guide rapide per DBA, AMS/Ops, ETL, Analisti/BI

---

## 6. File canonici (riferimento ufficiale)

- [README.md](../../README.md) — Entry point e onboarding rapido
- [VALUTAZIONE_EasyWayDataPortal.md](../../VALUTAZIONE_EasyWayDataPortal.md) — Stato, gap, azioni
- [docs/infra/azure-architecture.md](../../docs/infra/azure-architecture.md) — Architettura cloud
- [docs/agentic/AGENTIC_READINESS.md](../../docs/agentic/AGENTIC_READINESS.md) — Principi agentici
- [deployment-decision-mvp.md](deployment-decision-mvp.md) — Decisione deploy MVP
- [roadmap.md](roadmap.md) — Roadmap evolutiva
- [todo-checklist.md](todo-checklist.md) — Razionalizzazione e uniformamento

**Nota:**  
Questa pagina centralizza e razionalizza le informazioni chiave.  
Le informazioni ridondanti sono state eliminate o rimandate ai file canonici sopra elencati.  
Per ogni dettaglio operativo, consulta sempre questi riferimenti.







