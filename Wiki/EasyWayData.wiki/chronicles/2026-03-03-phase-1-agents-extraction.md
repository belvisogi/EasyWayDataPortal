---
title: "Phase 1 — Agents Extraction"
date: 2026-03-03
category: milestone
session: "S56"
tags: [chronicle, milestone]
---

## Cronaca

### Evento: Phase 1 — Agents Extraction
### Data: 2026-03-03 16:19
**Session**: S56
### Categoria: milestone

### Cosa e' Successo
Phase 1 de La Fabbrica completata: git-filter-repo ha estratto 672 file e 236 commit dal monorepo EasyWayDataPortal al nuovo repository easyway-agents. Directory estratte: agents/, control-plane/, scripts/pwsh/, scripts/agents/, scripts/ai-agent/, scripts/gates/. PR #250 creata su ADO (initial-import to main). La Fabbrica ora ha 2 repo operativi: easyway-wiki (684 file) e easyway-agents (672 file).

### Perche' Conta
_(Da compilare — perche' questo momento e' significativo per il progetto)_

### Artefatti Correlati
- easyway-agents ADO repo: 236 commit, 672 file
- PR #250: initial-import to main
- C:\old\easyway\agents\ — clone locale
- C:\old\easyway\wiki\ — clone locale

### Lezione Appresa
git-filter-repo (non subtree split) per multi-path extraction. subtree split supporta solo 1 prefix, filter-repo ne supporta N.
