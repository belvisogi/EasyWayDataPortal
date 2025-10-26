---
title: Datalake - Set Retention (Stub)
summary: Imposta/verifica policy di retention per filesystem/path. WhatIf di default con anteprima.
tags: [datalake, retention, whatif]
---

# Datalake - Set Retention (Agent Datalake)
Breadcrumb: Home / Datalake / Set Retention
Badge: WhatIf‑Ready ✅ (stub)

Scopo
- Applicare e verificare policy di retention coerenti per le aree: landing, staging, official, invalidrows, portal-audit.

Stato (WhatIf)
- Mostrare anteprima delle policy che verrebbero create/aggiornate.

Esecuzione (orchestratore, quando disponibile)
- `pwsh scripts/ewctl.ps1 --engine ps --intent dlk-set-retention`

Intent sample
- `agents/agent_datalake/templates/intent.dlk-set-retention.sample.json`

Quick Test
- Usa l’intent sample così com’è (stub WhatIf).
- Esegui: `pwsh scripts/ewctl.ps1 --engine ps --intent dlk-set-retention`
- Atteso: output JSON con `policies` (anteprima delle regole) senza modifiche.

## Parsing Output (JSON)
- Chiavi `output`:
  - `policies`: array di oggetti `{ "path": string, "days": number|null, "change": "create_or_update|noop|remove" }`
- In WhatIf nessuna modifica viene effettuata; `change` è una stima dell’azione eventuale.

## Parse Cheatsheet
- jq
  - Riepilogo: `jq -r '.output.summary' out.json`
  - Policy da applicare (non noop): `jq -r '.output.policies[] | select(.change != "noop") | "\(.path): \(.days)"' out.json`
- PowerShell
  - `$o = Get-Content out.json | ConvertFrom-Json`
  - `$o.output.summary`
  - `$o.output.policies | ? { $_.change -ne 'noop' } | % { "$($_.path): $($_.days)" }`
