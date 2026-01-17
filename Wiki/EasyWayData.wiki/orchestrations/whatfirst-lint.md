---
id: ew-orch-whatfirst-lint
title: WHAT-first Lint (WHAT)
summary: Lint dei requisiti WHAT-first (manifest/intents/ux_prompts) con report machine-readable.
status: draft
owner: team-platform
tags: [domain/docs, layer/orchestration, audience/dev, privacy/internal, language/it, governance, lint]
llm:
  include: true
  pii: none
  chunk_hint: 250-400
  redaction: []
entities: []
updated: '2026-01-08'
next: Collegare a un gate CI opzionale.
---

[[start-here|Home]] > [[domains/docs-governance|Docs]] > [[Layer - Orchestration|Orchestration]]

# WHAT-first Lint (WHAT)

Contratto
- Intent: `docs/agentic/templates/intents/whatfirst-lint.intent.json`
- Manifest: `docs/agentic/templates/orchestrations/whatfirst-lint.manifest.json`
- KB: `agents/kb/recipes.jsonl` (intent `whatfirst-lint`)

Entrypoint (n8n.dispatch)
```json
{
  "action": "orchestrator.n8n.dispatch",
  "params": {
    "action": "whatfirst-lint",
    "params": { "failOnError": true, "summaryOut": "whatfirst-lint.json" },
    "whatIf": true,
    "nonInteractive": true,
    "correlationId": "op-2026-01-08-114"
  }
}
```sql



## Vedi anche

- [KB Assessment (WHAT)](./kb-assessment.md)
- [Dominio Docs & Governance](../domains/docs-governance.md)
- [Docs Related Links Apply (WHAT)](./docs-related-links-apply.md)
- [Predeploy Checklist (WHAT)](./predeploy-checklist.md)
- [Documentazione Agentica - Audit & Policy (Canonico)](../docs-agentic-audit.md)


