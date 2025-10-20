# Agent Docs Review – Assistente documentazione

Scopo
- Rende guidata la revisione della documentazione: normalizza la Wiki, rigenera indici/chunk, verifica la coerenza con la KB e aiuta ad aggiungere ricette operative.

Uso
- Interattivo (consigliato):
  - `pwsh scripts/agent-docs-review.ps1`
- Selezione esplicita:
  - `pwsh scripts/agent-docs-review.ps1 -Wiki -KbConsistency`
- Tutto (se abilitato):
  - `pwsh scripts/agent-docs-review.ps1 -All`
- Dry‑run:
  - `pwsh scripts/agent-docs-review.ps1 -WhatIf`

Attività
- Wiki Normalize & Review: naming/front‑matter/ancore + rebuild indici/chunk.
- KB Consistency (advisory): suggerisce update KB/Wiki quando cambiano DB/API/agents docs.
- Aggiungi Ricetta KB (guidata): popola `agents/kb/recipes.jsonl` usando `scripts/agent-kb-add.ps1`.

Note
- Richiede PowerShell 7+. Per il controllo “KB Consistency” è consigliato git in PATH.

