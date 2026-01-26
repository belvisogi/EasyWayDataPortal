---
id: ew-docs-contesto-standard
title: Documentazione - Contesto standard (obbligatorio)
tags: [onboarding, devx, docs, governance, agentic, audience/dev, language/it]
summary: Pattern minimo per rendere ogni pagina auto-consistente e usabile da umani e agenti (source-of-truth, comandi, artefatti, gate, osservabilità).
status: draft
owner: team-platform
updated: '2026-01-06'
---

[Home](../../../docs/project-root/DEVELOPER_START_HERE.md)

# Documentazione: Contesto standard (obbligatorio)

## Obiettivo
Ogni pagina deve essere auto-consistente: chi legge (umano o agente) deve capire subito **scopo, fonti canoniche, comandi di rigenerazione, artefatti e gate**.

## Template consigliato (da incollare)

### Contesto (repo)
- Obiettivi e principi: `agents/goals.json`
- Orchestrazione/gates (entrypoint): `scripts/ewctl.ps1`
- Ricette operative (KB): `agents/kb/recipes.jsonl`
- Osservabilità (eventi): `agents/logs/events.jsonl`
- Wiki indicizzabile (chunks): `Wiki/EasyWayData.wiki/chunks_master.jsonl` (generato da `Wiki/EasyWayData.wiki/scripts/export-chunks-jsonl.ps1`)

### Come rigenerare (idempotente)
- Indica 1 comando “happy path” e 1 comando “diagnostica/verbose”.
- Se esistono varianti “legacy/export”, esplicita che sono **solo audit/delta**.

### Artefatti e output
- Elenca file generati/aggiornati (path cliccabili) e cosa contengono.

### Gate e conferme (human-in-the-loop)
- Elenca i gate che devono passare prima del merge (Checklist/DB Drift/KB Consistency/WhatFirstLint).
- Indica cosa richiede conferma umana e perché.

## Checklist rapida (prima del merge)
- La pagina cita almeno una fonte canonica (SoT) e un comando idempotente.
- I cross-link puntano a file/pagine esistenti.
- Se la pagina è “runtime-facing”, include confini di sicurezza (Zero Trust/sandbox).



## Vedi anche

- [Documentazione Agentica - Audit & Policy (Canonico)](../docs-agentic-audit.md)
- [Developer & Agent Experience Upgrades](./developer-agent-experience-upgrades.md)
- [Storyboard evolutivo - Da knowledge base classica a continuous improvement agentico (EasyWay)](./storyboard-easyway-agentic.md)
- [HOWTO — Tagging e metadati in EasyWay DataPortal](./howto-tagging.md)
- [Setup ambiente di test/Sandbox e Zero Trust](./setup-playground-zero-trust.md)



