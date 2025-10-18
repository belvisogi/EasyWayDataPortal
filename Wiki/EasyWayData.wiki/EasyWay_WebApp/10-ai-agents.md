---
id: ew-10-ai-agents
title: 10 ai agents
summary: Pagina top-level della documentazione.
status: draft
owner: team-docs
created: '2025-01-01'
updated: '2025-01-01'
tags:
  - layer/concept
  - privacy/internal
  - language/it
llm:
  include: true
  pii: none
  chunk_hint: 400-600
  redaction: [email, phone]
entities: []
id: ew-10-ai-agents
title: 10 ai agents
summary: 
owner: 
---
# EasyWay DataPortal – Conversational Intelligence & AMS

## Obiettivo
Integrare **AI Agents intelligenti e operativi** all'interno della piattaforma EasyWay DataPortal, per automatizzare attività di Application Management Services (AMS) e abilitare un'interazione naturale, efficace e contestualizzata con i servizi della piattaforma.

---

## Sommario

- [1. Introduzione](#1-introduzione)
- [2. Scenari di utilizzo](#2-scenari-di-utilizzo)
- [3. Architettura Conversazionale](#3-architettura-conversazionale)
- [4. Tecnologie Azure utilizzate](#4-tecnologie-azure-utilizzate)
- [5. Integrazione con EasyWay DataPortal](#5-integrazione-con-easyway-dataportal)
- [6. Multitenancy e Sicurezza](#6-multitenancy-e-sicurezza)
- [7. Costi stimati](#7-costi-stimati-per-1-ai-agent)
- [8. Roadmap evolutiva](#8-roadmap-evolutiva)
- [9. Naming convention AI Agents](#9-naming-convention-ai-agents)

---

## 1. Introduzione

L'obiettivo è sviluppare un'infrastruttura di **AI Agents** evoluti, in grado di:
- Rispondere in linguaggio naturale a domande sul portale.
- Eseguire azioni operative (es. avvio flussi, verifica ACL, apertura ticket).
- Automatizzare il supporto AMS con intelligenza e precisione.
- Garantire segmentazione multi-tenant e sicurezza by design.

---

## 2. Scenari di utilizzo

| AI Agent | Funzione principale | Canale previsto |
|--------|---------------------|-----------------|
| `agent.upload` | Guida al caricamento dati e gestione errori | Web, Teams |
| `agent.acl` | Supporto su permessi, profili e tenant | Web |
| `agent.dq` | Analisi Data Quality, righe scartate, motivi | Web |
| `agent.billing` | Verifica piani, licenze, costi | Web, Email |
| `agent.audit` | Accesso e consultazione audit logs | Interno (Admins) |

---

## 3. Architettura Conversazionale

- **Front-end Web**: AI Agent integrato nel portale via iframe/widget.
- **Canali secondari**: Microsoft Teams (AMS), App mobile futura.
- **Bot Service**: Azure Bot Framework o Power Virtual Agents.
- **AI Engine**: Azure OpenAI (GPT-4/3.5) con grounding su contenuti reali.
- **Dati di base**: Azure Cognitive Search su `.md`, log, PDF tecnici.
- **Speech Services**: opzionale per interazioni vocali.

---

## 4. Tecnologie Azure utilizzate

| Servizio | Funzione |
|---------|----------|
| Azure Bot Service | Orchestrazione agenti e canali |
| Azure OpenAI | Risposte intelligenti e contestualizzate |
| Azure Cognitive Search | Grounding su documentazione EasyWay |
| Azure Storage | Repository knowledge base & documenti |
| Azure Speech | Input/output vocale naturale |
| Azure App Service | Hosting container multi-tenant AI Agent |

---

## 5. Integrazione con EasyWay DataPortal

- Gli AI Agents operano nel contesto dell’utente autenticato.
- Rispettano completamente ACL, `tenant_id`, `profile_id`.
- Possono accedere a dati certificati `GOLD`, `PORTAL`, `AUDIT`.
- Ogni interazione può essere tracciata in `portal-audit/`.

---

## 6. Multitenancy e Sicurezza

- Gli AI Agents applicano filtraggio dei dati per tenant e profilo.
- Non accedono mai a dati di tenant terzi.
- Integrati con Entra ID, Audit SQL e Audit Datalake.
- Ogni azione può essere loggata per finalità legali, GDPR, SOC2.

---

## 7. Costi stimati (per 1 AI Agent)

| Voce | Tipo | Stima mensile |
|------|------|----------------|
| Azure OpenAI (GPT-4) | API usage | ~40–60€ |
| Azure Bot Service | Hosting | ~60€ |
| Azure Cognitive Search | 1 unità | ~100€ |
| Azure Speech (TTS/STT) | Opzionale | ~5–10€ |
| Azure Storage | ~10GB | ~2€ |

**Totale stimato: ~200–230€/mese** per AI Agent AMS in produzione limitata.

---

## 8. Roadmap evolutiva

| Fase | Azione |
|------|--------|
| 1 | Prototipo `agent.upload` su ambiente Dev |
| 2 | Integrazione ACL e multi-tenant |
| 3 | Grounding documentazione `.md` (analisi funzionale, ACL, pipeline) |
| 4 | Logging audit e feedback |
| 5 | Estensione vocale (Azure Speech) |
| 6 | Rilascio `agent.acl`, `agent.dq`, `agent.billing` |
| 7 | Dashboard analytics uso & efficienza AMS |

---

## 9. Naming convention AI Agents

Tutti gli agenti seguono il prefisso `agent.` e il dominio funzionale:

- `agent.upload`
- `agent.acl`
- `agent.dq`
- `agent.billing`
- `agent.audit`

I nomi sono chiari, coerenti, e riflettono la modularità microservizi EasyWay.

---



## Domande a cui risponde
- Cosa fa questa pagina?
- Quali sono i prerequisiti?
- Quali passi devo seguire?
- Quali sono gli errori comuni?
- Dove approfondire?


