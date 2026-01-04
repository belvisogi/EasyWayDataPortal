---
id: ew-control-plane-index
title: Control Plane - Panoramica
summary: Punto di ingresso canonico per orchestrazione agentica (n8n + ewctl), gates, logging e Human-in-the-loop.
status: active
owner: team-platform
tags: [control-plane, orchestration, governance, n8n, language/it]
llm:
  include: true
  pii: none
  chunk_hint: 250-350
  redaction: []
entities: []
---

# Control Plane - Panoramica

Scopo
- Rendere l'esecuzione dei workflow agentici governabile da non esperti.
- Fornire un'unica "porta d'ingresso" per: validazione intent, gate precheck, dispatch esecuzione, log e audit.

Entry points
- CLI/CI: `scripts/ewctl.ps1`
- Orchestratore n8n (dispatch): `orchestrations/orchestrator-n8n.md`

Contratti
- Input: `intent-contract.md`
- Output: `output-contract.md`
- Manifest WHAT-first: `docs/agentic/templates/orchestrations/*.manifest.json`
- Intents WHAT-first: `docs/agentic/templates/intents/*.intent.json`

Gates (minimi)
- Doc Alignment / WHAT-first Lint / Wiki frontmatter lint
- Checklist / DB Drift / KB Consistency (via `ewctl` oppure pipeline)

Osservabilità
- Log eventi: `agents/logs/events.jsonl`
- Diario di bordo: `UX/diary-mock-wf-excel-csv-upload.md` (mock) + campi canonici in manifest.

Riferimenti
- Start here: `start-here.md`
- Metodo: `agent-first-method.md`
- Orchestrazioni: `orchestrations/wf-excel-csv-upload.md`




