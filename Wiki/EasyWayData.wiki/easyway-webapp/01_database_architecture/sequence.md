---
tags:
  - artifact/sequence
id: ew-db-sequence
title: Sequence – NDG e convenzioni
summary: Numeratori per codici business (TEN…, CDI…) e debug
status: draft
owner: team-data
tags: [domain/db, layer/reference, audience/dev, privacy/internal, language/it]
llm:
  include: true
  pii: none
  chunk_hint: 250-400
  redaction: [email, phone]
entities: []
updated: '2026-01-05'
next: TODO - definire next step.
---

Sequence principali (PORTAL)
- SEQ_TENANT_ID → genera parte numerica di TENxxxxx (start 1000)
- SEQ_USER_ID → genera parte numerica di CDIxxxxx (start 1000)
- SEQ_TENANT_ID_DEBUG / SEQ_USER_ID_DEBUG → sequenze per inserimenti di test

Regola
- Le SP di insert formattano il codice finale (prefisso + padding) se non fornito in input.







