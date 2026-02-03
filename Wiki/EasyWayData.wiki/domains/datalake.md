---
id: ew-domain-datalake
title: Dominio Datalake
summary: Definizione del dominio Datalake: struttura dei tenant, applicazione ACL, policy di retention e agenti correlati.
status: active
owner: team-data
tags: [domain/datalake, layer/reference, audience/dev, audience/ops, privacy/internal, language/it, agents]
llm:
  include: true
  pii: none
  chunk_hint: 250-350
  redaction: []
entities: []
updated: '2026-01-16'
next: Completare le ricette KB.
---

[[../start-here.md|Home]] > [[datalake.md|datalake]] > Reference

# Dominio Datalake

## Domande a cui risponde
1. Quali sono le responsabilità del dominio Datalake?
2. Dove sono definiti gli agenti per il Datalake?
3. Come vengono gestite le ACL e la retention?

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







## Vedi anche

- [Dominio DB](./db.md)
- [datalake-dev-index](../easyway-webapp/03_datalake_dev/index.md)
- [Dominio Frontend](./frontend.md)
- [Datalake - Set Retention (Stub)](../datalake-set-retention.md)
- [ETL/ELT Playbook](../etl-elt-playbook.md)





