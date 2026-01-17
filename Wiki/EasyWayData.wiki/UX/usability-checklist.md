---
title: UX – Usability Checklist (One‑Button)
tags: [domain/ux, layer/howto, audience/dev, audience/non-expert, privacy/internal, language/it, ux, checklist]
status: active
updated: 2026-01-16
redaction: [email, phone]
id: ew-ux-usability-checklist
chunk_hint: 200-300
entities: []
include: true
summary: Checklist rapida per validare semplicità ed efficacia delle schermate (3‑click rule, leggibilità, zero dead‑ends, CTA chiare, default sicuri).
llm: 
pii: none
owner: team-platform
---

[[start-here|Home]] > [[Domain - Ux|Ux]] > [[Layer - Howto|Howto]]

# UX – Usability Checklist (One‑Button)

Obiettivo
- Garantire che ogni schermata del diario sia semplice “come accendere la luce”: un’azione chiara, linguaggio semplice, nessun vicolo cieco.

Checklist (rapida)
- 3‑Click Rule: l’utente arriva alla dashboard in ≤ 3 azioni dal caricamento (MVP).
- CTA primaria evidente: un solo pulsante principale (es. “Continua”, “Apri Dashboard”).
- Zero dead‑ends: sempre presente un’azione per uscire/continuare (Retry, Scarica modello, Vedi dettagli).
- Linguaggio semplice: messaggi brevi, senza gergo tecnico, con “Cosa non va” e “Come risolvere”.
- Default sicuri: scelte precompilate non distruttive e reversibili.
- Consistenza: etichette e messaggi coerenti tra stati (copioni IT/EN).
- Accessibilità: contrasto, dimensione font minima, focus visibile, testi alternativi per immagini.
- Feedback immediato: spinner/progresso + conferme esplicite su azioni.
- Error budget UX: evitare troppi warning consecutivi (digestare e semplificare).
- Privacy: non mostrare PII non necessarie; sanificare anteprime.

Come usarla
- Applicare la checklist ad ogni PR che modifica UI/UX e allegare evidenze (screenshot/wireframe) nel diario.


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



