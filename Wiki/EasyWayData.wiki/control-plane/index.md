---
title: Control Plane - Panoramica
tags: [domain/control-plane, layer/index, audience/dev, audience/ops, privacy/internal, language/it, control-plane, orchestration, governance, n8n]
status: active
updated: 2026-01-16
redaction: []
id: ew-control-plane-index
chunk_hint: 250-350
entities: []
include: true
summary: Punto di ingresso canonico per orchestrazione agentica (n8n + ewctl), gates, logging e Human-in-the-loop.
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

[[../start-here.md|Home]] > [[index.md|Control-Plane]] > Index

# Control Plane - Panoramica

- Nota per autori: per nuove pagine usare `./_template.md`.


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
- Registry agent: `control-plane/agents-registry.md`
- Audit manifest agent: `control-plane/agents-manifest-audit.md`
- Segregation model: `control-plane/segregation-model-dev-knowledge-runtime.md`
- Roadmap agent: `control-plane/agents-missing-roadmap.md`
- Release flow alignment: `control-plane/release-flow-alignment-2026-02-12.md`
- PRD wishlist MVP (multi-provider): `control-plane/prd-agentic-release-multivcs-mvp.md`
- Orchestrazioni: `orchestrations/wf-excel-csv-upload.md`





## Domande a cui risponde
- Che cosa raccoglie questo indice?
- Dove sono i documenti principali collegati?
- Come verificare naming e ancore per questa cartella?
- Dove trovare entità e guide correlate?









