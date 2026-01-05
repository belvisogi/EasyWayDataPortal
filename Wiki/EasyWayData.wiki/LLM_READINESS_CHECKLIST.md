---
title: LLM Readiness Checklist (shim)
summary: Redirect compat per vecchi link; usare llm-readiness-checklist.md.
id: ew-llm-readiness-checklist
status: deprecated
owner: team-platform
canonical: llm-readiness-checklist.md
tags: [domain/docs, layer/howto, audience/non-expert, audience/dev, privacy/internal, language/it, llm, checklist, docs, deprecated]
llm:
  include: false
  pii: none
  chunk_hint: 250-400
  redaction: [email, phone]
entities: []
---

Questa pagina è un alias per compatibilità.

Usa: `llm-readiness-checklist.md`


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

