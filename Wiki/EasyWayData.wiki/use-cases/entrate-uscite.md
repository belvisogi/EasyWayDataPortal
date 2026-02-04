---
title: Use Case – Entrate/Uscite (One‑Button UX)
tags: [domain/ux, layer/spec, audience/non-expert, audience/dev, privacy/internal, language/it, use-case, ux, argos, agents]
status: active
updated: 2026-01-16
redaction: [email, phone]
id: ew-uc-entrate-uscite
chunk_hint: 250-400
entities: []
include: true
summary: Carica un file Excel/CSV con movimenti e ottieni subito una dashboard, con un percorso “un bottone = luce accesa”.
llm: 
  include: true
  pii: none
  chunk_hint: 250-400
  redaction: [email, phone]
pii: none
owner: team-platform
type: guide
---

[Home](./start-here.md) >  > 

# Use Case – Entrate/Uscite (One‑Button UX)

Principio guida (per tutti)
- Come accendere la luce: premi un bottone e funziona. L’utente non deve capire contratti, transistor o DSL: l’interfaccia lo guida con parole semplici, scelte sicure e risultati immediati.

Percorso “Un Bottone” (Base)
- Carica file → Verifica automatica → Mappatura smart → Caricamento → Dashboard pronta → Chat per domande.
- Il sistema sceglie i default migliori, spiega in italiano chiaro cosa succede e come rimediare se serve.

Percorso “Pro” (Opzionale)
- Per utenti esperti: rivedi mapping, vedi regole DQ applicate, abilita dedup condizionale, salva template.

Flusso (alto livello)
```mermaid
flowchart TD
    U[Utente: Carica file] --> P[Parsing & Anteprima]
    P --> DQ[Controlli DQ (ARGOS)]
    DQ -->|PASS/DEFER| M[Schema Mapping (auto)]
    M --> S[Staging]
    S --> T[Target]
    T --> V[Viste & Dashboard]
    V --> C[Chat: domande e calcoli]
    DQ -->|FAIL| H[Messaggio chiaro + correzione guidata]
```sql

Regole DQ Minime (in parole semplici)
- Formato accettato: Excel o CSV.
- Campi indispensabili: Data, Descrizione, Categoria, Importo, Tipo (Entrata/Spesa), Valuta, Conto.
- Tipi corretti: Data nel formato riconosciuto; Importo è un numero; Tipo è Entrata o Spesa.
- Campi mancanti: non ammessi sugli indispensabili.
- Duplicati: se trovati, te lo diciamo e possiamo aiutarti a sistemarli.
- Importi strani: segnaliamo valori anomali (non blocca).

UX: Semplicità prima di tutto
- Un bottone: “Carica e analizza” → il resto lo facciamo noi.
- Linguaggio umano: niente gergo tecnico; esempi e suggerimenti brevi.
- Zero sorprese: scelte di default sicure, sempre reversibili.
- Errori spiegati: “Cosa non va” + “Come risolvere” + “Provalo ora”.
- Privacy: i tuoi dati sono tuoi; niente dati sensibili in chiaro dove non serve.

Messaggi tipo (stilistica)
- OK: “Fatto! Dashboard pronta. Vuoi fare una domanda?”
- Warn: “Alcune categorie non sono riconosciute. Usiamo ‘Altro’. Vuoi impostarle ora?”
- Errore: “Manca la colonna ‘Importo’. Scarica il modello o scegli la colonna corretta.”

Cosa ottieni (MVP)
- Dashboard pronta: trend mensile, spesa per categoria, top voci, saldo.
- Chat: “Qual è la spesa media per ristorante nel Q3?” (risposta + come l’abbiamo calcolata).
- Diario di bordo: cronologia del caricamento con esiti e suggerimenti.

Perché è per tutti
- Nessuna configurazione iniziale obbligatoria.
- Template di mapping riutilizzabile (lo proponiamo noi al prossimo upload).
- Percorso base sempre disponibile; quello avanzato non intralcia.

SLO/KPI (esperienza)
- Tempo file→dashboard: ≤ 2 minuti (MVP).
- Caricamenti “al primo colpo”: ≥ 85%.
- Domande in chat per sessione: ≥ 3; soddisfazione ≥ 4/5.

Note per implementazione (aggancio ad agenti & ARGOS)
- Intent orchestratore: `wf.excel-csv-upload` (stati, esiti, Decision Trace).
- Eventi: `argos.run.completed` (upload/parsing), `argos.gate.decision` (DQ), `argos.ticket.opened` se errore critico.
- Mapping smart: suggeriamo noi l’allineamento colonne→schema target; puoi accettare e salvare.

Roadmap “a livelli” (caccia al tesoro)
- L1: One‑Button MVP (carica→dashboard) con DQ base e mapping auto.
- L2: Salvataggio template mapping, dedup controllato, categorie suggerite.
- L3: Chat Q&A e widget salvabili.
- L4: Outlier avanzati, multi‑conto, valuta.
- L5: Template multipli, scheduler, connettori.








