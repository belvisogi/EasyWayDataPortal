---
id: ew-agent-scrummaster
title: Agent ScrumMaster – Single Owner, Multi‑Agent
summary: Coordinamento backlog/roadmap (Azure Boards), DoD/gates, sincronizzazione KB/Wiki in modello single‑owner.
status: draft
owner: team-platform
tags: [domain/control-plane, layer/reference, audience/dev, privacy/internal, language/it, agents, governance, scrummaster]
llm:
  include: true
  pii: none
  chunk_hint: 250-400
  redaction: [email, phone]
entities: []
updated: '2026-01-05'
next: TODO - definire next step.
---

Modello Operativo
- Single‑owner + multi‑agent: un unico owner umano approva; gli agenti eseguono e tracciano.
- Azioni su Boards/Prod richiedono approvazioni esplicite e sono loggate in activity-log.md.

Responsabilità
- Backlog su Azure Boards (Epics/Features) con Definition of Done e gates.
- Sincronizzazione KB/Wiki (ricette, snippet, indici/chunk) e generazione TODO (da linter/report).
- Coordinamento con Agent_Governance per policy/gates; con Agent_AMS per esecuzione ricette.

Approvals
- Boards: Human_ProductOwner_Approval
- Prod: Human_Governance_Approval

Strumenti
- Script seed: scripts/ado/boards-seed.ps1
- Review/indici: Wiki/EasyWayData.wiki/scripts/*

Note
- Questo documento integra agents-governance.md con il focus ScrumMaster.







