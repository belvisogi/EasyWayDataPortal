---
id: ew-etl-inspirations
title: ETL/ELT Inspirations (ADA Framework)
summary: Sintesi fonti esterne (PDF) e mapping verso Playbook, DQ e Logging di EasyWayDataPortal.
status: active
owner: team-data
tags: [domain/datalake, layer/reference, audience/dev, audience/ops, privacy/internal, language/it, etl, dq, logging, inspirations]
llm:
  include: true
  pii: none
  chunk_hint: 400-600
  redaction: [email, phone]
entities: []
updated: '2026-01-05'
next: TODO - definire next step.
---

[Home](../../docs/project-root/DEVELOPER_START_HERE.md) > [[domains/datalake|datalake]] > [[Layer - Reference|Reference]]

# ETL/ELT – Inspirations
Breadcrumb: Home / Datalake / ETL Inspirations

Fonti (cartella locale)
- Framework DQ ADA - Informatica - Overview.pdf
- Framework DQ ADA - Synapse - Overview.pdf
- Table Log ADA - Overview.pdf

Obiettivo
- Estrarre il “meglio” e armonizzarlo con il modello EasyWay (Playbook, DQ, Logging, Agentico).

Da estrarre (punti chiave)
- DQ Framework (classi di regole, severità, applicazione in catena landing→staging→official).
- Governance DQ (ownership, eccezioni, audit di regole).
- Logging ETL (schema tabellare/logfile, campi minimi, correlazioni, retention).

Mapping verso EasyWay
- DQ → “Regole di Data Quality (DQ)” nel Playbook + pagina “ETL – DQ Framework”.
- Logging → “Audit & Logging” nel Playbook + pagina “ETL – Table Log Model”.
- Operatività → Intent agentici (dry-run/apply) e Output Contract per audit uniforme.

Prossimi passi
- Compilare le pagine “ETL – DQ Framework” e “ETL – Table Log Model” con le decisioni derivate.
- Allineare ricette KB per bootstrap DQ e logging.







