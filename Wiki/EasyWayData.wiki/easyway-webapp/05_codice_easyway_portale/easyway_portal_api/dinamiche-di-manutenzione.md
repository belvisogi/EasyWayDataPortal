---
id: ew-dinamiche-di-manutenzione
title: dinamiche di manutenzione
tags: [domain/control-plane, layer/reference, audience/dev, audience/ops, privacy/internal, language/it, maintenance]
owner: team-platform
summary: 'Documento su dinamiche di manutenzione.'
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

[[start-here|Home]] > [[Domain - Control-Plane|Control-Plane]] > [[Layer - Reference|Reference]]

# Capitolo - Dinamiche di Manutenzione

## Architettura delle Cartelle — Dinamiche di Manutenzione

In EasyWay Data Portal, la struttura delle cartelle segue pattern enterprise  
per garantire chiarezza, scalabilità, facile manutenzione e onboarding immediato di nuovi sviluppatori e agenti automatici.

### Quali cartelle “si muovono” di più?

| Cartella      | Modifica frequente? | Perché cambia |
|---------------|:-------------------:|--------------|
| `/controllers`|   ✅ (spesso)       | Qui vive la logica degli endpoint. Cambia ogni volta che si aggiorna una funzione, una regola, una validazione, ecc. |
| `/routes`     |   ✅ (spesso)       | Qui mappi tutti gli endpoint REST. Cambia quando aggiungi, togli o rinomini API. |
| `/config`     |   ✅ (spesso)       | Gestisce le modalità di caricamento delle configurazioni (YAML, DB, blob). Cambia quando aggiungi nuove opzioni parametriche. |
| `/models`     |   ❌ (raramente)    | Fotografia della struttura dati (DB). Cambia solo se cambia il database o la business entity. |
| `/middleware` |   ❌ (raramente)    | Blocchi di logica riusabile (es: security, logging, multi-tenant, conversational hooks). Cambia solo per nuove policy di sicurezza, logging o agent-awareness. |
| `/utils`      |   ❌ (raramente)    | Utility generiche, funzioni di supporto. Cambia poco, solo con nuove necessità tecniche o evoluzioni conversational. |
| `/queries`    |   ❌ (raramente)    | Query SQL pronte all’uso, versionate e riusate. Cambiano solo per ottimizzazioni, evoluzioni del dato, nuove policy di accesso. |

---

### **Best Practice per la manutenzione**

- **Focus sui controller**: qui vive la business logic e la conversational logic. Documenta bene funzioni, parametri di input/output e motivazione (“intent”).
- **Routes sempre minimali**: nessuna logica nelle route, solo collegamento route → controller.
- **Config chiara e centralizzata**: ogni nuova configurazione/documentazione va aggiornata con fonte, formato, chi la usa e se è accessibile anche ad agenti automatici.
- **Aggiorna sempre la sezione “Architettura”** ogni volta che introduci una nuova funzionalità o evolvi una logica chiave.
- **Commenta ogni nuovo file e funzione**: specifica a cosa serve, chi la usa (umano, agent, servizio), esempio d’uso.
- **Rivedi e aggiorna la tabella delle dinamiche** ogni volta che la struttura o le policy si evolvono.

---

### **Esempio concreto**

- Un nuovo sviluppatore, QA o agente automatico che entra e vede `/controllers/usersController.ts`,  
  trova lì la logica per `/api/users` e sa che ogni modifica utenti passa da qui.
- Per sapere dove e come si carica la configurazione di un tenant o di una feature, va in `/config/` e trova documentazione aggiornata.
- Per tracciare una nuova azione conversational, aggiungi/migliora il logging e documenta subito la nuova entry-point in questa sezione.

---

**Questa sezione va sempre all’inizio della documentazione tecnica.  
Facilita onboarding di persone e AI, riduce errori, aumenta la trasparenza e rende il progetto self-maintainable nel tempo.**


## Domande a cui risponde
- Cosa fa questa pagina?
- Quali sono i prerequisiti?
- Quali passi devo seguire?
- Quali sono gli errori comuni?
- Dove approfondire?








