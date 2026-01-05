---
title: Datalake - Ensure Structure (Stub)
summary: Verifica e applica (in WhatIf di default) la struttura del Datalake per tenant/ambienti, con anteprima cambi.
tags: [datalake, governance, whatif, domain/datalake, layer/howto, audience/ops, audience/dev, privacy/internal, language/it]
id: ew-datalake-ensure-structure
status: draft
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

# Datalake - Ensure Structure (Agent Datalake)
Breadcrumb: Home / Datalake / Ensure Structure
Badge: WhatIf‑Ready ✅ (stub)

Scopo
- Validare in anticipo e poi applicare naming/strutture minime (container, path, policy) secondo standard.

Stato (WhatIf)
- L’azione deve mostrare anteprima: oggetti mancanti/da creare, ACL suggerite, differenze di naming.
 - Supporta provider locale: `params.currentPaths` inline oppure `params.currentPathsFile` (JSON con `paths[]` o `currentPaths[]`, o file di testo con un path per riga).

Esecuzione (orchestratore, quando disponibile)
- `pwsh scripts/ewctl.ps1 --engine ps --intent dlk-ensure-structure`

Intent sample
- `agents/agent_datalake/templates/intent.dlk-ensure-structure.sample.json`
 - Esempio provider file: `agents/agent_datalake/templates/currentPaths.sample.json`

Quick Test
- Modifica l’intent sample aggiungendo `"currentPathsFile": "agents/agent_datalake/templates/currentPaths.sample.json"` nei `params`.
- Esegui: `pwsh scripts/ewctl.ps1 --engine ps --intent dlk-ensure-structure`
- Atteso: output JSON con `expectedPaths` e `changesPreview` (in WhatIf, nessuna azione su Azure).

## Parsing Output (JSON)
- Chiavi `output`:
  - `filesystem` (string), `tenantId` (string)
  - `expectedPaths`: array di path attesi per il tenant
  - `changesPreview`: array di oggetti differenze, es. `{ "type":"create-path", "path":"landing/tenant01/" }`
- In WhatIf non viene applicata alcuna modifica; `changesPreview` rappresenta l’anteprima.

## Parse Cheatsheet
- jq
  - Riepilogo: `jq -r '.output.summary' out.json`
  - Conteggio attesi/mancanti: `jq '{expected: (.output.expectedPaths|length), missing: (.output.changesPreview|length)}' out.json`
  - Elenco cambi: `jq -r '.output.changesPreview[] | "\(.type): \(.path)"' out.json`
- PowerShell
  - `$o = Get-Content out.json | ConvertFrom-Json`
  - `$o.output.summary`
  - `@{ expected = $o.output.expectedPaths.Count; missing = $o.output.changesPreview.Count }`

KB ricette correlate
- Ricetta example_output: `agents/kb/recipes.jsonl` (id: `kb-agent-dlk-ensure-structure-080`)

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

