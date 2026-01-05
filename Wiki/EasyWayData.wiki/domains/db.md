---
id: ew-domain-db
title: Dominio DB
summary: Scheletro del dominio DB: migrazioni, stored procedure, generatori, drift e logging.
status: draft
owner: team-data
tags: [domain/db, layer/reference, audience/dev, audience/dba, privacy/internal, language/it, agents, flyway]
llm:
  include: true
  pii: none
  chunk_hint: 250-350
  redaction: []
entities: []
---

# Dominio DB

Cosa fa
- Evoluzione schema via migrazioni (`db/flyway/`).
- DDL/SP idempotenti, logging su `PORTAL.STATS_EXECUTION_LOG`.

Agenti
- `agents/agent_dba/manifest.json`

Contratti/Template
- Readiness: `docs/agentic/AGENTIC_READINESS.md`
- Template SQL: `docs/agentic/templates/ddl/`, `docs/agentic/templates/sp/`

Esempi
- DSL generator: `db-generate-artifacts-dsl.md` + input sample `dsl/user.json`

Gates
- DB Drift (CI/ewctl)

KB
- `agents/kb/recipes.jsonl` (es. `db-migrate`, `predeploy-checklist`)




