---
id: ew-ado-operating-model
title: Azure DevOps Operating Model (Hybrid)
summary: Modello operativo ibrido (Kanban per AMS/Infra, Sprint per Business) + regole minime per backlog, board e automazione agentica.
status: draft
owner: team-platform
tags: [domain/ado, layer/policy, audience/dev, audience/ops, privacy/internal, language/it, governance, kanban, sprint]
llm:
  include: true
  pii: none
  chunk_hint: 250-400
  redaction: []
entities: []
updated: '2026-01-09'
next: Allineare con struttura reale Area/Iteration e team ADO.
type: guide
---

[Home](../../scripts/docs/project-root/DEVELOPER_START_HERE.md) > [[Domain - Ado|Ado]] > [[Layer - Policy|Policy]]

# Azure DevOps Operating Model (Hybrid)

## Obiettivo

Usiamo un modello ibrido per mantenere velocità sul prodotto e stabilità operativa:
- **Kanban** per **AMS** e **Infrastruttura** (run/support/change piccoli, flusso continuo).
- **Sprint** per **Business** (Reportistica, Logiche business, Frontend business) con delivery timeboxed.

## Struttura backlog (consigliata)

Gerarchia:
- `Epic → Feature → User Story/PBI → Task`

Nota sul tipo di work item:
- Se il progetto ADO usa process **Agile**: il work item di backlog è **User Story**.
- Se usa process **Scrum**: il work item di backlog è **Product Backlog Item (PBI)**.

## Aree (Area Path)

Separiamo i flussi con Area Path per poter avere board/policy diverse:
- `EasyWay\AMS`
- `EasyWay\Infra`
- `EasyWay\Business\Frontend`
- `EasyWay\Business\Logic`
- `EasyWay\Business\Reporting`

## Iterazioni (Iteration Path)

Business lavora “a sprint” su Iteration Path (es. 2 settimane):
- `EasyWay\Sprints\2026\Sprint 01`
- `EasyWay\Sprints\2026\Sprint 02`

AMS/Infra possono usare:
- Iteration di “triage” continuo (opzionale) oppure lavorare senza sprint, mantenendo comunque board Kanban.

## Kanban (AMS + Infra)

Policy minime:
- Classi di servizio: `Expedite`, `Standard`, `FixedDate` (o equivalenti).
- WIP limit per colonna.
- Swimlane dedicate (es. `Run`, `Support`, `Change`).
- SLA espliciti per `Expedite` (es. presa in carico entro N ore).

Work item tipici:
- `Bug`, `Task`, (opz.) `Incident/Change` se disponibili.

## Sprint (Business)

Policy minime:
- Definizione di Ready (DoR) e Done (DoD) per Story/PBI.
- Sprint goal + planning + review.
- Tagging coerente per tracciabilità (es. `domain:frontend`, `domain:reporting`, `governance`).

## Integrazione agentica (automazione)

Automazioni consigliate:
- **Bootstrap ADO**: creazione Area/Iteration + seed iniziale di backlog (Epic/Feature/Story/PBI).
- **Creazione User Story/PBI governata**: prefetch best practices + output strutturato + no-secrets.

Riferimenti:
- Orchestrazione: `Wiki/EasyWayData.wiki/orchestrations/ado-userstory-create.md`
- Intent/manifest: `docs/agentic/templates/intents/ado-userstory-create.intent.json`, `docs/agentic/templates/orchestrations/ado-userstory-create.manifest.json`
- Agente: `scripts/agent-ado-userstory.ps1`





