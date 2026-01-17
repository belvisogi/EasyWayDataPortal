---
title: Datalake - Apply ACL (Stub)
summary: Calcola e applica (in WhatIf di default) ACL suggerite su container/cartelle, con anteprima differenze.
tags: [datalake, security, whatif, domain/datalake, layer/howto, audience/ops, audience/dev, privacy/internal, language/it]
id: ew-datalake-apply-acl
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

[[start-here|Home]] > [[domains/datalake|datalake]] > [[Layer - Howto|Howto]]

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


