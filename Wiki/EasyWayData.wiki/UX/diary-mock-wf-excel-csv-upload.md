---
title: UX Mock – Diario di Bordo (wf.excel-csv-upload)
tags: [domain/ux, layer/spec, audience/dev, audience/non-expert, privacy/internal, language/it, ux, diary, use-case, argos]
status: active
updated: 2026-01-16
redaction: [email, phone]
id: ew-ux-diary-wf-excel-csv-upload
chunk_hint: 250-400
entities: []
include: true
summary: Schermate mock (testuali) del diario di bordo per il workflow Excel/CSV→Dashboard, in modalità One‑Button (Base) e Pro.
llm: 
  pii: none
  redaction: [email, phone]
pii: none
owner: team-platform

llm:
  redaction: [email, phone]
  include: true
  chunk_hint: 5000
---

[[../start-here.md|Home]] > [[agentic-ux.md|Ux]] > Spec

# UX Mock – Diario di Bordo (wf.excel-csv-upload)

Principi UX
- One‑Button: un’azione principale sempre disponibile (“Carica e analizza”) e scelte sicure predefinite.
- Linguaggio semplice: messaggi brevi, chiari, senza gergo tecnico.
- Diario chiaro: timeline con stati, esiti, motivazioni (“Perché”) e passi successivi.
- Base vs Pro: interruttore che svela dettagli (mapping, regole DQ, trace) senza intralciare il percorso base.

Schema pagina (generale)
- Header: titolo processo + chip stato (In corso / Completato / Serve attenzione)
- Barra avanzamento: 7 step (Uploaded → Parsed → DQ → Mapping → Staging → Merge → Views)
- Timeline (card): per ogni stato, Mostra: “Cosa ho fatto”, “Perché”, “Esito”, “Prossimo passo”
- Azioni: pulsante primario (Continua / Riprova / Apri Dashboard) + link secondari (Scarica modello CSV, Vedi trace)
- Toggle Pro: mostra pannelli avanzati (regole DQ applicate, mapping dettagliato, Decision Trace, conteggi)

Asset & collegamenti (screenshot/wireframe)
- Cartella asset: `Wiki/EasyWayData.wiki/.attachments/ux/`
- Convenzioni nome: `wf-excel-step-<N>-<state>-<lang>.png` (es. `wf-excel-step-3-defer-it.png`)
- Quando disponibili, inserire link a ciascuna card con `! [alt] (../.attachments/ux/wf-excel-step-<N>-<state>-<lang>.png)`

Stato 1 – Uploaded (OK)
Mock (testo)
- Titolo: Carica e analizza
- Step 1/7 – File ricevuto ✓
- Cosa ho fatto: Ho salvato il file in modo sicuro.
- Perché: preparare l’analisi e la qualità.
- Esito: OK
- Prossimo passo: Leggo intestazioni e creo un’anteprima.
- Azioni: [Continua]  [Annulla]
- Link: [Scarica modello CSV]

Stato 2 – Parsed (OK / Errore)
Base – OK
- Step 2/7 – Anteprima pronta ✓
- Cosa ho fatto: Ho riconosciuto il formato e letto le intestazioni.
- Esito: OK
- Prossimo passo: Controlli di qualità.
- Azioni: [Continua]

Base – Errore
- Step 2/7 – Non riesco a leggere il file ✕
- Cosa non va: Il file sembra corrotto o il foglio non è presente.
- Come risolvere: Prova con il nostro modello o esporta in CSV.
- Azioni: [Riprova]  [Scarica modello CSV]

Stato 3 – DQ (PASS / DEFER / FAIL)
PASS
- Step 3/7 – Controlli qualità superati ✓
- Cosa ho fatto: Ho verificato campi indispensabili e formati.
- Esito: PASS
- Prossimo passo: Mappo le colonne automaticamente.
- Azioni: [Continua]
DEFER
- Step 3/7 – Qualche avviso (procedo in sicurezza) !
- Avvisi: Alcune categorie non sono riconosciute (userò “Altro”); trovati possibili duplicati.
- Esito: DEFER (non blocca)
- Prossimo passo: Applico la mappatura suggerita.
- Azioni: [Continua]  [Vedi dettagli]
FAIL
- Step 3/7 – Dati mancanti ✕
- Cosa non va: Manca la colonna “Importo”.
- Come risolvere: Scegli la colonna corretta o scarica il modello.
- Azioni: [Scegli colonna]  [Scarica modello CSV]  [Riprova]

Stato 4 – Mapping (Auto / Interattivo)
Auto (Base)
- Step 4/7 – Mappatura completata ✓
- Cosa ho fatto: Ho allineato intestazioni al nostro schema standard.
- Esito: OK (ho compilato i campi mancanti con valori sicuri)
- Prossimo passo: Carico in staging.
- Azioni: [Continua]
Interattivo (Pro)
- Step 4/7 – Serve conferma su alcuni campi
- Cosa fare: Abbina “Descrizione” → description, “Tipo” → income/expense, “Valuta” → iso_code
- Azioni: [Applica mapping]  [Salva come template]

Stato 5 – Staging (OK / Errore)
OK
- Step 5/7 – Caricamento in staging ✓
- Esito: OK (righe caricate: 3.241)
- Prossimo passo: Normalizzo e allineo ai target.
- Azioni: [Continua]
Errore
- Step 5/7 – Caricamento non riuscito ✕
- Cosa non va: Un valore non è numerico nella colonna Importo.
- Come risolvere: Sostituisci “—” con “0” o un numero valido.
- Azioni: [Riprova]

Stato 6 – Merge (OK / Warn)
OK
- Step 6/7 – Dati allineati ✓
- Esito: OK (dedup controllato applicato su possibili duplicati)
- Prossimo passo: Aggiorno le viste.
- Azioni: [Continua]
Warn
- Step 6/7 – Trovati duplicati (risolti) !
- Dettagli: 14 record consolidati secondo regole di scelta (timestamp più recente)
- Azioni: [Vedi dettagli]  [Continua]

Stato 7 – Views & Dashboard (OK / Errore)
OK
- Step 7/7 – Dashboard pronta ✓
- Cosa ho fatto: Ho aggiornato KPI e grafici.
- Esito: OK
- Azioni: [Apri Dashboard]  [Fai una domanda]
Errore
- Step 7/7 – Materializzazione non riuscita ✕
- Cosa non va: Vista KPI non disponibile.
- Azioni: [Riprova]  [Apri log]

Timeline (Base → Pro)
- Ogni card mostra: data/ora, stato, messaggio OK/Warn/Errore, azioni successive.
- Toggle Pro aggiunge: conteggi, regole DQ applicate, campi mappati, link Decision Trace.

Esempio entry (JSON)
```sql
{
  "timestamp": "2025-10-27T10:12:00Z",
  "stage": "dq_evaluated",
  "outcome": "DEFER",
  "reason": "Categorie ignote e duplicati potenziali",
  "next": "mapped",
  "decision_trace_id": "trace-abc-123",
  "artifacts": ["dq_summary.json", "invalid_sample.csv"],
  "ux": {
    "title": "Qualche avviso (procedo in sicurezza)",
    "actions": ["Continua", "Vedi dettagli"]
  }
}
```sql

Note
- Tutti i messaggi UX sono allineati ai `ux_prompts` del manifest (WHAT) e vanno localizzati.
- Il diario deve essere leggibile “a colpo d’occhio”, con pulsanti chiari e un aiuto contestuale semplice.
 - Copioni localizzati: vedere `docs/agentic/templates/orchestrations/ux_prompts.it.json` e `ux_prompts.en.json`.











