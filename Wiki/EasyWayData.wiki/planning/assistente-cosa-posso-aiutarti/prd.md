---
prd_id: PRD-20260301-assistente-cosa-posso-aiutarti
domain: Frontend
epic_id: AB#2
generated: 2026-03-01T06:57:17
initiative_id: INIT-20260301-assistente-cosa-posso-aiutarti
---

## Executive Summary  
**Problema**: Gli utenti EasyWay spesso non sfruttano appieno le funzionalità della piattaforma, perdendo efficienza.  
**Soluzione**: Integrare un chatbot proattivo che suggerisce azioni contestuali in base al ruolo e alla sezione corrente.  
**Business Value**: Miglioramento dell’esperienza utente, aumento della produttività e ottimizzazione dell’uso delle funzionalità esistenti.  
**Metriche principali**:  
1. Aumento dell’uso delle funzionalità suggerite: target 40%.  
2. Riduzione del tempo di navigazione: target 2 minuti.  
3. Soddisfazione utente (survey): target 4/5.  

---

## Evidence & Confidence  

| Area | Evidence | Confidence | Note |  
|------|----------|------------|------|  
| **Data Model** | N/A | Low | ⚠️ Richiede validazione umana per integrazione con dati di ruolo/sezione |  
| **Security** | N/A | Medium | ⚠️ Necessaria verifica dei permessi per accesso ai dati utente |  
| **Integration/API** | API di gestione ruoli e sezioni esistenti | High | Integrazione con API già disponibili |  

---

## Requisiti Funzionali  

### FR-001: Rilevamento contestuale della sezione e del ruolo [MUST]  
**Descrizione**: Il chatbot deve identificare la sezione corrente e il ruolo dell’utente per fornire suggerimenti pertinenti.  
**Acceptance Criteria**:  
- Dato che un utente è loggato, quando naviga in una sezione, allora il chatbot rileva la sezione corrente.  
- Dato che un utente ha un ruolo specifico, quando interagisce con il chatbot, allora i suggerimenti sono basati sul suo ruolo.  
**Priorità**: MUST  

### FR-002: Suggerimenti proattivi basati su funzionalità disponibili [MUST]  
**Descrizione**: Il chatbot deve suggerire azioni pertinenti in base alle funzionalità disponibili nella sezione corrente.  
**Acceptance Criteria**:  
- Dato che un utente è in una sezione specifica, quando il chatbot è attivo, allora vengono mostrati fino a 3 suggerimenti pertinenti.  
- Dato che un utente ignora un suggerimento, quando torna nella stessa sezione, allora il suggerimento non viene ripetuto.  
**Priorità**: MUST  

### FR-003: Personalizzazione dei messaggi in base al profilo utente [SHOULD]  
**Descrizione**: Il chatbot deve adattare i messaggi in base al profilo e alle preferenze dell’utente.  
**Acceptance Criteria**:  
- Dato che un utente ha preferenze specifiche, quando interagisce con il chatbot, allora i messaggi sono personalizzati.  
**Priorità**: SHOULD  

---

## Requisiti Non-Funzionali  

### NFR-001: Performance del chatbot [MUST]  
**Descrizione**: Il chatbot deve rispondere entro 200ms al p95 per garantire un’esperienza fluida.  
**AC**: Tempo di risposta < 200ms al p95.  

### NFR-002: Sicurezza dei dati [MUST]  
**Descrizione**: Il chatbot deve accedere solo ai dati autorizzati in base al ruolo dell’utente.  
**AC**: Verifica dei permessi di accesso ai dati utente.  

### NFR-003: Usabilità [SHOULD]  
**Descrizione**: L’interfaccia del chatbot deve essere intuitiva e non invasiva.  
**AC**: Feedback utente positivo nella survey di usabilità (≥ 4/5).  

---

## User Stories (formato ADO)  

1. Come operatore dati, voglio che il chatbot mi suggerisca azioni pertinenti così da completare i task più rapidamente.  
2. Come manager, voglio che il chatbot mi indichi strumenti utili per analizzare i dati così da ottimizzare il mio flusso di lavoro.  
3. Come nuovo utente, voglio che il chatbot mi guidi attraverso le funzionalità della piattaforma così da imparare a usarla efficacemente.  

---

## ADO Mapping  

| Campo | Valore |  
|-------|--------|  
| **Epic ID** | AB#2 |  
| **Domain** | Frontend |  
| **Area Path** | EasyWay\Frontend |  
| **PBI suggeriti** |  
- Implementazione rilevamento contestuale  
- Integrazione suggerimenti proattivi  
- Personalizzazione messaggi chatbot  

---

## Out of Scope  
- Integrazione con AI avanzata per suggerimenti predittivi – motivo: complessità tecnica, rimandato a future iterazioni.  
- Supporto multilingua – motivo: priorità bassa rispetto al core functionality.  

---

## Dipendenze e Rischi  
**Dipendenza tecnica principale**: API di gestione ruoli e sezioni esistenti.  
**Rischi**:  
- Suggerimenti non pertinenti – mitigazione: test utente iterativi.  
- Sovraccarico di informazioni – mitigazione: limitare i suggerimenti a 2-3 per sessione.
