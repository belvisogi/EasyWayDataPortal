---
title: Release Flow Alignment 2026-02-12 (Agent Release)
tags: [domain/control-plane, layer/spec, audience/dev, audience/ops, privacy/internal, language/it, release, git, workflow, agents]
status: active
updated: 2026-02-12
redaction: [email, phone]
id: ew-control-plane-release-flow-alignment-2026-02-12
chunk_hint: 220-360
entities: []
include: true
summary: Allineamento end-to-end del workflow release (branch policy, naming, script, skill, manifest, roster, RAG) con guida pratica e Q&A anti-pattern.
llm:
  pii: none
  redaction: [email, phone]
pii: none
owner: team-platform

llm:
  redaction: [email, phone]
  include: true
  chunk_hint: 5000
type: guide
---

[[../start-here.md|Home]] > [[index.md|Control-Plane]] > Release

# Release Flow Alignment 2026-02-12 (Agent Release)

## Cosa e' stato fatto
- Evoluzione di `agent_release` da focus "runtime bundle" a focus "release promotion" (`release:promote`).
- Introduzione skill git dedicate:
  - `git.checkout`
  - `git.merge`
  - `git.push`
- Hardening dello script `scripts/pwsh/agent-release.ps1` con:
  - preflight checks (repo, working tree, sync con origin),
  - policy enforcement su source/target branch,
  - warning su flussi rischiosi (es. `develop -> main`),
  - draft release notes automatiche in `agents/logs/`,
  - ritorno garantito al branch iniziale.
- Allineamento manifest/prompt/roster/documentazione su standard canonico:
  - `Wiki/EasyWayData.wiki/standards/gitlab-workflow.md`.

## Perche' e' stato fatto
- Ridurre errori operativi durante merge e push.
- Applicare in modo deterministico il branching workflow ufficiale.
- Rendere tracciabile il rilascio (analisi commit + release notes).
- Migliorare la qualita' del contesto RAG per agenti e operatori.

## Come e' stato fatto
1. Definizione skill git riusabili e registrazione in `agents/skills/registry.json`.
2. Refactor di `scripts/pwsh/agent-release.ps1`:
   - enforcement naming/target policy,
   - merge/push safety,
   - supporto `merge|squash`,
   - fallback graceful se skill opzionali non disponibili.
3. Aggiornamento metadata agente:
   - `agents/agent_release/manifest.json`
   - `agents/agent_release/PROMPTS.md`
   - `agents/agent_release/priority.json`
4. Sincronizzazione della documentazione:
   - Control-plane registry/roadmap
   - Roster Wiki e roster JSON frontend
5. Rigenerazione indice RAG:
   - `Wiki/EasyWayData.wiki/scripts/export-chunks-jsonl.ps1`

## Quando e' stato fatto
- Data allineamento: **12 febbraio 2026**.
- Scope: release workflow, policy branch, docs sync, indicizzazione RAG.

## Policy operativa (sintesi)
- `feature/PBI-XXX-*` e `bugfix/PBI-XXX-*` -> target consentito: `develop`.
- `hotfix/INC-XXX-*` -> target consentito: `main` (poi back-merge su `develop`).
- `baseline` aggiornabile solo da `develop` o `main`.
- Vietato merge diretto feature/bugfix su `main`.

## Q&A (cosa NON va fatto)
Q1. Posso promuovere `feature/*` direttamente su `main`?
- No. E' una violazione della policy.

Q2. Posso usare branch senza naming convention?
- Sconsigliato. Lo script segnala branch non standard e applica blocchi sui target non ammessi.

Q3. Posso bypassare working tree sporco?
- Solo con override esplicito (`-AllowDirty`) e responsabilita' operativa.

Q4. Posso forzare push su branch protetti?
- No come default operativo. L'obiettivo e' preservare la sicurezza della history.

Q5. Posso saltare la documentazione dopo un cambiamento di flow?
- No. Manifest, prompt, roster e wiki devono restare coerenti.

Q6. Posso cambiare target MR se ho sbagliato PR?
- No. Chiudere e riaprire su target corretto (come da standard).

Q7. Posso trattare `agent_release` come builder di artifact runtime?
- Non come funzione primaria. Il runtime packaging resta separabile come capability dedicata.

## Dove trovare la source of truth
- Standard workflow: `Wiki/EasyWayData.wiki/standards/gitlab-workflow.md`
- Registry agent: `Wiki/EasyWayData.wiki/control-plane/agents-registry.md`
- Manifest agente: `agents/agent_release/manifest.json`
- Script operativo: `scripts/pwsh/agent-release.ps1`
- Roster wiki: `Wiki/EasyWayData.wiki/agents/agent-roster.md`
- Roster frontend: `agents/agent_frontend/data/roster.json`
- Indice RAG: `Wiki/EasyWayData.wiki/chunks_master.jsonl`

## Vedi anche
- [[agents-registry.md|Agents Registry]]
- [[agents-missing-roadmap.md|Roadmap agent]]
- [[index.md|Control Plane - Panoramica]]
- [[../standards/gitlab-workflow.md|GitLab Workflow Standard]]
