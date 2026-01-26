---
title: Gestione Accessi DB (Contained Users & Ruoli PORTAL)
summary: Creazione/rotazione/revoca utenti contained per Azure SQL e ruoli PORTAL_* con agente DBA.
tags: [dba, security, onboarding, domain/db, layer/howto, audience/dba, audience/dev, privacy/internal, language/it]
id: ew-db-user-access-management
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

[Home](../../docs/project-root/DEVELOPER_START_HERE.md) > [[domains/db|db]] > [[Layer - Howto|Howto]]

# Gestione Accessi DB (Agent DBA)
Breadcrumb: Home / Codice Portale / Database Access
Badge: WhatIf‑Ready ✅

Azioni (agente DBA)
- db-user:create — crea/aggiorna utente contained, assegna ruoli (auth: SQL o AAD)
- db-user:rotate — ruota password e aggiorna (opz.) Key Vault
- db-user:revoke — rimuove membership ruoli ed elimina utente (idempotente)

Prerequisiti
- Connessione admin: `DB_ADMIN_CONN_STRING` (oppure specifica in intent `adminConnString`)
- sqlcmd presente; (opz.) az CLI per Key Vault

Intent esempio
- `agents/agent_dba/templates/intent.db-user-create.sample.json`

Esecuzione (via orchestratore)
- Create: `pwsh scripts/ewctl.ps1 --engine ps --intent db-user-create`
- Rotate: `pwsh scripts/ewctl.ps1 --engine ps --intent db-user-rotate`
- Revoke: `pwsh scripts/ewctl.ps1 --engine ps --intent db-user-revoke`

Sicurezza
- Principle of Least Privilege: ruoli `portal_reader` (SELECT schema PORTAL), `portal_writer` (I/U/D schema PORTAL)
- Password non loggata in chiaro (solo masked); se richiesto, salva in Key Vault
- AAD: richiede `az login` o Managed Identity sul runner; lo script usa `sqlcmd -G`

## Parsing Output (JSON)
- Chiavi top‑level: `action`, `ok`, `whatIf`, `nonInteractive`, `correlationId`, `startedAt`, `finishedAt`, `output`, `error`.
- `output` (create/rotate/revoke):
  - `server`, `database`, `username`, `auth` (`sql|aad`)
  - `roles` (solo create): array es. `["portal_reader","portal_writer"]`
  - `executed` (bool), `keyVaultSet` (bool, se abilitato)
  - `passwordMasked` (string), `tsqlPreview` (string)
  - `stateBefore`/`stateAfter` (oggetto con bool: `readerExists`, `writerExists`, `userExists`, `memberReader`, `memberWriter`)
  - `preCheck` (WhatIf): output di `scripts/db-verify-connect.ps1` con `ok`, `roles`, `userExists`, `lint[]`
- Convenzione: in WhatIf `executed=false` e `stateAfter=null`. In esecuzione reale `executed=true` e `stateAfter` valorizzato.

## Parse Cheatsheet
- jq
  - Estrarre riepilogo: `jq -r '.output.summary' out.json`
  - Stato iniziale: `jq '.output.stateBefore' out.json`
  - Lint preCheck: `jq '.output.preCheck.lint' out.json`
  - Esecuzione reale? `jq -r '.output.executed' out.json`
- PowerShell
  - `$o = Get-Content out.json | ConvertFrom-Json`
  - `$o.output.summary`
  - `$o.output.stateBefore | ConvertTo-Json -Depth 6`
  - `($o.output.executed) -and ($o.ok)`


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



