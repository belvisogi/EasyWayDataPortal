---
id: ew-questboard-docs-dq
title: Quest Board - Documentazione (DQ + Kanban)
summary: Kanban per la revisitazione della documentazione usando metriche DQ (frontmatter/tags/links/WHAT-first + connettivita' grafo) e remediation guidata.
status: draft
owner: team-platform
tags: [domain/docs, layer/spec, audience/dev, privacy/internal, language/it, quest, kanban, dq, governance]
llm:
  redaction: [email, phone]
  include: true
  pii: none
  chunk_hint: 250-400
entities: []
updated: '2026-01-09'
next: Eseguire docs-dq-scorecard e triage del backlog.
type: guide
---

[Home](../../scripts/docs/project-root/DEVELOPER_START_HERE.md) > [[domains/docs-governance|Docs]] > 

# Quest Board - Documentazione (DQ + Kanban)

Obiettivo
- Trattare la documentazione come un dataset: misure ripetibili + backlog + Definition of Done.

Regole Kanban (minime)
- WIP limit: max 3 card in "Doing" per team.
- DoR (Ready): card con file target + check da eseguire + output atteso.
- DoD (Done): link/anchor ok, frontmatter ok, tag ok, WHAT-first ok (se coinvolto), KB aggiornata se serve.

Comandi
- Audit + backlog preview: `pwsh scripts/docs-dq-scorecard.ps1`
- Tool di remediation link: `pwsh scripts/wiki-related-links.ps1` (HITL)
- Indice orfani: `pwsh scripts/wiki-orphan-index.ps1`

<!-- AUTO:START -->
## Snapshot DQ (auto) - TBD

- Eseguire: `pwsh scripts/docs-dq-scorecard.ps1 -UpdateQuestBoard -WhatIf:$false`
<!-- AUTO:END -->





