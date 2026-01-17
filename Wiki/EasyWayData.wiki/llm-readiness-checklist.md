---
id: ew-llm_readiness_checklist
title: LLM READINESS CHECKLIST
tags: [domain/docs, layer/howto, audience/non-expert, audience/dev, privacy/internal, language/it, llm, checklist]
owner: team-platform
summary: 'Documento su LLM READINESS CHECKLIST.'
status: active
llm:
  include: true
  pii: none
  chunk_hint: 250-400
  redaction: [email, phone]
entities: []
updated: '2026-01-05'
next: TODO - definire next step.
---
[[start-here|Home]] > [[domains/docs-governance|Docs]] > [[Layer - Howto|Howto]]

# LLM Readiness – Lista Semplice (Per Persone e AI)

Scopo: controllare che ogni pagina sia pronta per essere letta da un’AI Conversational Intelligence (Q&A, RAG) e da persone.

## Checklist per OGNI pagina (.md)
- [ ] Ha il front matter YAML completo (id, title, summary, status, owner, tags, llm, entities)?
- [ ] Titolo chiaro (H1) e sezioni in ordine: Scopo, Prerequisiti, Passi, Esempi, Errori comuni, Domande, Collegamenti.
- [ ] Frasi brevi, niente “vedi sopra/sotto”, sigle spiegate la prima volta.
- [ ] Esempi di codice/payload in blocchi ``` ben formattati.
- [ ] Niente dati sensibili (PII). Se presenti: `llm.pii: contains-pii` e indicare redazione.
- [ ] Link relativi funzionanti a 2–5 pagine correlate.
- [ ] Domande a cui risponde (3–7) presenti.
- [ ] `tags` e `entities` valorizzati (minimo: dominio, layer, audience, privacy, lingua).

## Checklist NOMI (file e cartelle)
- [ ] Solo minuscole, `-`, numeri (kebab-case). Nessuno `%2D`, quote/backtick, spazi.
- [ ] Niente caratteri strani (�). Niente & (usa `and`). Niente accenti.
- [ ] Nomi corti e chiari. Se serve ordine locale: prefissi `01-`, `02-`.

## Checklist CONTENUTI (per tipo)
DBA (tabelle, procedure):
- [ ] DDL idempotente (crea solo se non esiste) + rollback.
- [ ] PK `<table>_id`, indici e FK nominati, default UTC per `created_at`.
- [ ] Esempi query base e note di performance.

API (endpoint):
- [ ] Metodo, path, input/validazioni, output, errori (codici e messaggi).
- [ ] Esempi `curl`/JSON e schema degli oggetti (se serve).

ETL (pipeline):
- [ ] Sorgente → destinazione, mapping colonne, qualità dati, schedule.
- [ ] Monitoraggio e fallback (cosa fare in caso di errore).

AMS/Operazioni (runbook):
- [ ] Avvio/stop, health-check, log e dashboard utili.
- [ ] Allarmi: causa, destinazione, come si risolve.

Analista/BI (metriche, dashboard):
- [ ] Definizione metrica (nome, formula, fonte, filtro).
- [ ] Scopo dashboard, utenti target, viste chiave.

## Repository: controlli periodici
- [ ] Indice auto (per cartella) con titoli e link (`index.md`).
- [ ] Link checker (nessun link rotto, nessuna anchor duplicata). Anchor checker: i link con #ancora puntano a H1/H2/H3 esistenti (slug coerente).
- [ ] Report nomi (niente `%2D`, backtick, maiuscole dove non servono).
- [ ] Stima pezzi per AI (chunk 400–600 token): pagine molto lunghe → sezioni più piccole.
- [ ] Privacy e `llm.include`: file sensibili esclusi o ridatti.

## Suggerimenti pratici
- Pagine corte vincono. Molte pagine piccole > una enorme.
- Ogni pagina risponde a poche domande specifiche.
- Usa esempi reali (funzionanti). Evita immagini con testo.


Esecuzione rapida (con anchor check)
`
EasyWayData.wiki/scripts/review-run.ps1 -Root EasyWayData.wiki -Mode kebab -CheckAnchors
`
Il report ancore è in EasyWayData.wiki/logs/reports/anchors-*.md.


## Domande a cui risponde
- Cosa fa questa pagina?
- Quali sono i prerequisiti?
- Quali passi devo seguire?
- Quali sono gli errori comuni?
- Dove approfondire?


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


