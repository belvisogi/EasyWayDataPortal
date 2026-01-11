---
id: ew-domain-docs-governance
title: Dominio Docs & Governance
summary: Scheletro: convenzioni doc, linter, gates, PR discipline, human-in-the-loop e activity log.
status: draft
owner: team-platform
tags: [domain/docs, layer/reference, audience/dev, audience/non-expert, privacy/internal, language/it, governance, agents]
llm:
  include: true
  pii: none
  chunk_hint: 250-350
  redaction: []
entities: []
updated: '2026-01-05'
next: TODO - definire next step.
---

# Dominio Docs & Governance

Cosa fa
- Mantiene coerenza tra codice, KB e Wiki.
- Applica gates (Checklist/DB Drift/KB Consistency + lint WHAT-first).

Agenti
- `agents/agent_docs_review/manifest.json`
- `agents/agent_governance/manifest.json`
- `agents/agent_scrummaster/manifest.json`

Pagine chiave
- Metodo: `agent-first-method.md`
- Contratti: `intent-contract.md`, `output-contract.md`
- Conventions: `docs-conventions.md`
- Gate: `doc-alignment-gate.md`

Strumenti
- `scripts/ewctl.ps1`
- Lint: `scripts/whatfirst-lint.ps1`, `scripts/wiki-frontmatter-lint.ps1`
- Docs drift: `scripts/agents-readme-sync.ps1` (check-only nei gate, fix locale se necessario)

Audit
- `agents/logs/events.jsonl`
- `activity-log.md`







## Vedi anche

- [Domini - Panoramica](./index.md)
- [Multi‑Agent & Governance – EasyWay](../agents-governance.md)
- [Dominio Frontend](./frontend.md)
- [Dominio DB](./db.md)
- [Dominio Datalake](./datalake.md)

