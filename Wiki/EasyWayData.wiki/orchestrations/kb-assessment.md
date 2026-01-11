---
id: ew-orch-kb-assessment
title: KB Assessment (WHAT)
summary: Verifica allineamento della KB (JSONL valido, references, campi minimi) e produce report.
status: draft
owner: team-platform
tags: [domain/docs, layer/orchestration, audience/dev, privacy/internal, language/it, kb, governance]
llm:
  include: true
  pii: none
  chunk_hint: 250-400
  redaction: []
entities: []
updated: '2026-01-08'
next: Collegare a un gate CI opzionale.
---

# KB Assessment (WHAT)

Contratto
- Intent: `docs/agentic/templates/intents/kb.assessment.intent.json`
- Manifest: `docs/agentic/templates/orchestrations/kb-assessment.manifest.json`
- KB recipe: `agents/kb/recipes.jsonl` -> `kb.assessment`

Entrypoint (n8n.dispatch)
```json
{
  "action": "orchestrator.n8n.dispatch",
  "params": {
    "action": "kb.assessment",
    "params": {
      "path": "agents/kb/recipes.jsonl",
      "out": "out/kb-assessment.json",
      "failOnError": true
    },
    "whatIf": true,
    "nonInteractive": true,
    "correlationId": "op-2026-01-08-113"
  }
}
```



## Vedi anche

- [WHAT-first Lint (WHAT)](./whatfirst-lint.md)
- [Predeploy Checklist (WHAT)](./predeploy-checklist.md)
- [Docs Related Links Apply (WHAT)](./docs-related-links-apply.md)
- [DB Drift Check (WHAT)](./db-drift-check.md)
- [DB Generate Docs (WHAT)](./db-generate-docs.md)

