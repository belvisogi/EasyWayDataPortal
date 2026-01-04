---
title: Datalake - Apply ACL (Stub)
summary: Calcola e applica (in WhatIf di default) ACL suggerite su container/cartelle, con anteprima differenze.
tags: [datalake, security, whatif, domain/datalake, layer/howto, audience/ops, audience/dev, privacy/internal, language/it]
id: ew-datalake-apply-acl
status: draft
owner: team-platform
llm:
  include: true
  pii: none
  chunk_hint: 250-400
  redaction: [email, phone]
entities: []
---

# Datalake - Apply ACL (Agent Datalake)
Breadcrumb: Home / Datalake / Apply ACL
Badge: WhatIf‑Ready ✅ (stub)

Scopo
- Validare e poi applicare ACL coerenti con i ruoli e i principi del progetto.

Stato (WhatIf)
- L’azione deve mostrare anteprima: ACL correnti vs proposte, impatti attesi, eventuali conflitti.

Esecuzione (orchestratore, quando disponibile)
- `pwsh scripts/ewctl.ps1 --engine ps --intent dlk-apply-acl`

Intent sample
- `agents/agent_datalake/templates/intent.dlk-apply-acl.sample.json`

KB ricette correlate
- Ricetta example_output: `agents/kb/recipes.jsonl` (id: `kb-agent-dlk-apply-acl-081`)

Quick Test
- Usa l’intent sample così com’è (stub WhatIf).
- Esegui: `pwsh scripts/ewctl.ps1 --engine ps --intent dlk-apply-acl`
- Atteso: output JSON con `proposedAcl` e `diff` (nessuna modifica applicata).

## Parsing Output (JSON)
- Chiavi `output`:
  - `path` (string)
  - `proposedAcl`: array di oggetti `{ "principal": string, "permissions": string }`
  - `diff`: array di oggetti differenze, es. `{ "path":"raw/tenant01", "current":"r-x", "proposed":"rwx", "principal":"svc_tenant01_writer" }`
- In WhatIf non viene applicata alcuna modifica; `diff` è solo un’anteprima.

## Parse Cheatsheet
- jq
  - Riepilogo: `jq -r '.output.summary' out.json`
  - Principals coinvolti: `jq -r '.output.proposedAcl[].principal' out.json | sort -u`
  - Diff sintetico: `jq -r '.output.diff[] | "\(.path): \(.current) -> \(.proposed) (\(.principal))"' out.json`
- PowerShell
  - `$o = Get-Content out.json | ConvertFrom-Json`
  - `$o.output.summary`
  - `$o.output.proposedAcl | % principal | Sort-Object -Unique`

Note
- Questa pagina definisce il modus operandi; l’implementazione dell’agente seguirà gli stessi guardrail (WhatIf-by-default).


