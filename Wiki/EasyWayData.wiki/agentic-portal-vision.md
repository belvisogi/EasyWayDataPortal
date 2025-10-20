---
id: ew-agentic-portal-vision
title: Visione Portale Agentico
summary: Obiettivi e principi per un portale totalmente agentico, usabile anche da non esperti.
status: active
owner: team-platform
tags: [agents, vision, language/it]
---

## Visione
Portale governabile da agenti e da umani non esperti, con piani chiari e scelte confermabili.

## Principi
- Human-in-the-loop
- Trasparenza (piani, esiti, log)
- Idempotenza
- Documentazione viva (KB + Wiki)
- Policy & gates comprensibili
- Parametrizzazione
- Osservabilità

## Implementazione
- Wrapper: `scripts/ewctl.ps1` (engine `ps|ts`)
- Orchestratore: `agents/core/orchestrator.js` (carica manifest, KB, `agents/goals.json`)
- Agenti: `scripts/agent-docs-review.ps1`, `scripts/agent-governance.ps1`
- Memoria obiettivi: `agents/goals.json`

## Flusso Consigliato
1) Pianifica (TS): `pwsh scripts/ewctl.ps1 --engine ts --intent <intent>`
2) Esegui (PS): `pwsh scripts/ewctl.ps1 --engine ps --intent <intent> --noninteractive`
3) Verifica gates (Checklist/DB Drift/KB Consistency)
4) Aggiorna KB + Wiki

