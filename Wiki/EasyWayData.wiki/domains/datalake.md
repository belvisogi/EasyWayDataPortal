---
id: ew-domain-datalake
title: Dominio Datalake
summary: Scheletro del dominio Datalake: struttura, ACL, retention, runbook e output idempotenti.
status: draft
owner: team-data
tags: [domain/datalake, agents, language/it]
llm:
  include: true
  pii: none
  chunk_hint: 250-350
  redaction: []
entities: []
---

# Dominio Datalake

Cosa fa
- Preparazione struttura tenant, applicazione ACL, policy retention.

Agenti
- `agents/agent_datalake/manifest.json`

Pagine
- `datalake-ensure-structure.md`
- `datalake-apply-acl.md`
- `datalake-set-retention.md`

Gates
- Checklist + policy (quando applicabile)

KB
- Ricette Datalake in `agents/kb/recipes.jsonl` (da completare).




