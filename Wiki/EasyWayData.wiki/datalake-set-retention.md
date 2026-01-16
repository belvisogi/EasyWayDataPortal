---
title: Datalake - Set Retention (Stub)
summary: Imposta/verifica policy di retention per filesystem/path. WhatIf di default con anteprima.
tags: [datalake, retention, whatif, domain/datalake, layer/howto, audience/ops, audience/dev, privacy/internal, language/it]
id: ew-datalake-set-retention
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


## Domande a cui risponde
- Qual e' l'obiettivo di questa procedura e quando va usata?
- Quali prerequisiti servono (accessi, strumenti, permessi)?
- Quali sono i passi minimi e quali sono i punti di fallimento piu comuni?
- Come verifico l'esito e dove guardo log/artifact in caso di problemi?

## Prerequisiti
- Accesso al repository e al contesto target (subscription/tenant/ambiente) se applicabile.
- Strumenti necessari installati (es. pwsh, az, sqlcmd, ecc.) in base ai comandi presenti nella pagina.
- Permessi coerenti con il dominio (almeno read per verifiche; write solo se whatIf=false/approvato).

## Passi
1. Raccogli gli input richiesti (parametri, file, variabili) e verifica i prerequisiti.
2. Esegui i comandi/azioni descritti nella pagina in modalita non distruttiva (whatIf=true) quando disponibile.
3. Se l'anteprima e' corretta, riesegui in modalita applicativa (solo con approvazione) e salva gli artifact prodotti.

## Verify
- Controlla che l'output atteso (file generati, risorse create/aggiornate, response API) sia presente e coerente.
- Verifica log/artifact e, se previsto, che i gate (Checklist/Drift/KB) risultino verdi.
- Se qualcosa fallisce, raccogli errori e contesto minimo (command line, parametri, correlationId) prima di riprovare.

