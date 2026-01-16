---
id: ado-bootstrap
title: Orchestration - ADO Bootstrap
summary: Orchestrazione per il bootstrap di Azure DevOps (Area, Iteration, Seed Backlog).
status: active
owner: team-platform
tags: [orchestration, domain/ado, layer/orchestration]
llm:
  include: true
  chunk_hint: 500
---

# ADO Bootstrap

Questa orchestrazione automatizza il setup iniziale di un progetto Azure DevOps per EasyWay.

## Responsabilità
- Creazione di **Area Paths** (es. `EasyWay\AMS`, `EasyWay\Business`).
- Creazione di **Iteration Paths** (es. Sprint 01, 02...).
- Popolamento iniziale ("seed") del backlog con Epic/Feature standard se richiesto.

## Riferimenti
- Modello Operativo: [[ew-ado-operating-model|Azure DevOps Operating Model]]
- Manifest: `ado-bootstrap.manifest.json`
