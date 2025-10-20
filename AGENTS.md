---
id: ew-agents-root
title: Agent Operating Guide (Root)
summary: Regole e obiettivi per agenti e umani. Tenere sempre allineato il portale all'obiettivo di essere totalmente agentico e usabile da non esperti.
owner: team-platform
status: active
tags: [agents, governance, language/it]
---

Principio guida
- Il progetto EasyWay deve evolvere verso un portale totalmente agentico e governabile anche da persone non esperte.

Memoria degli obiettivi
- Fonte unica: `agents/goals.json` (machine‑readable). Gli agenti devono leggerla all’avvio e rispettarne i principi.
- Aggiornare `agents/goals.json` quando l’obiettivo si raffina e riflettere il cambiamento nella Wiki.

Convergenza documentazione ↔ agenti
- Per ogni cambiamento in DB/API/Wiki/CI, aggiornare anche:
  - una ricetta KB (`agents/kb/recipes.jsonl`)
  - almeno una pagina Wiki pertinente

Orchestrazione
- Usare `scripts/ewctl.ps1` come entrypoint. Engine: `--engine ps|ts`.
- Gli agenti figli (docs/governance/DB/frontend) devono esporre script idempotenti e con esiti strutturati.

Gates in pipeline (ibrido)
- Variabile `USE_EWCTL_GATES=true|false` controlla se usare `ewctl` per Checklist/DB Drift/KB Consistency.
- `true` → job `GovernanceGatesEWCTL` esegue `pwsh scripts/ewctl.ps1 --engine ps --checklist --dbdrift --kbconsistency --noninteractive --logevent`.
- `false` → job legacy `PreDeployChecklist`, `KBConsistency`, `DBDriftCheck` + `ActivityLog`.

Definizione di Fatto (agent‑aware)
- KB aggiornata, Wiki aggiornata, gate verdi (Checklist/DB Drift/KB Consistency), eventi loggati in `agents/logs/events.jsonl`.

Sicurezza
- Rispettare `allowed_paths` nei manifest degli agent.
- Usare `WhatIf` per azioni potenzialmente distruttive.
