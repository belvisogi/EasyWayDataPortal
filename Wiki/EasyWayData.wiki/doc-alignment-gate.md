---
title: Doc Alignment Gate
summary: Gate leggero che verifica coerenza agenti ↔ intent template ↔ KB ↔ Wiki.
tags: [docs, gates, agents, domain/control-plane, layer/gate, audience/dev, privacy/internal, language/it]
id: ew-doc-alignment-gate
status: active
owner: team-platform
llm:
  include: true
  pii: none
  chunk_hint: 250-400
  redaction: [email, phone]
entities: []
updated: '2026-01-05'
next: TODO - definire next step.
---

# Doc Alignment Gate
Breadcrumb: Home / CI / Doc Alignment
Badge: WhatIf‑Ready ✅

Obiettivo
- Evitare drift tra azioni dichiarate dagli agenti e la documentazione ad essi associata (intent template, ricette KB, pagina Wiki).

Check eseguiti
- Intent template: per ogni `actions[].name` nel manifest, verifica esistenza `agents/<agent>/templates/intent.<action>.sample.json`.
- KB: verifica presenza di una riga in `agents/kb/recipes.jsonl` con `"intent":"<action>"`.
- Wiki: verifica presenza di pagina associata (mappatura semplice per domini noti: DBA/Datalake).

Esecuzione
- Orchestratore: `pwsh scripts/ewctl.ps1 --engine ps --intent doc-alignment`
- Script diretto: `pwsh scripts/doc-alignment-check.ps1 [-FailOnError]`

Output
- JSON con `ok` e gli elenchi `missingIntentTemplates`, `missingKbRecipes`, `missingWikiPages`.

Integrazione CI
- Aggiungi uno step che esegue lo script con `-FailOnError` se vuoi bloccare il merge fino al riallineamento.






## Vedi anche

- [Validazione Output Agenti in CI](./agent-output-validation-ci.md)
- [Metodo di Lavoro Agent‑First](./agent-first-method.md)
- [Orchestratore n8n (WHAT)](./orchestrations/orchestrator-n8n.md)
- [Verifica CI – ewctl gates e Flyway (branch non-main)](./ci-verifica-ewctl-gates-e-flyway.md)
- [Agent Priority Rules e Checklists (human-in-the-loop)](./agent-priority-and-checklists.md)

