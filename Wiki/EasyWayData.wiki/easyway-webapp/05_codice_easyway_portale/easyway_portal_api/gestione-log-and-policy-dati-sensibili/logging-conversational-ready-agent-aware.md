---
id: ew-logging-conversational-ready-agent-aware
title: logging conversational ready agent aware
tags: [domain/control-plane, layer/spec, audience/dev, audience/ops, privacy/internal, language/it]
owner: team-platform
summary: Logging conversational/agent-aware: header, campi obbligatori, correlazione e risposta standard.
status: draft
llm:
  include: true
  pii: none
  chunk_hint: 250-400
  redaction: [email, phone]
entities: []
---

#### Logging conversational-ready (agent-aware)
Questa sezione integra e amplia le policy dati sensibili:  
- ogni log non è solo tracciato per sicurezza/compliance,  
ma è anche progettato per essere interpretabile e utilizzabile da agenti AI, chatbot, workflow AMS.

- Ogni endpoint core include nei log: `intent`, `origin`, `agent_id`/`user_id`, `conversation_id`, `esito`, `context`
- Tutti i log sono export-ready per BI, AMS, NLP, auditing

#### Risposta standardizzata
Ogni endpoint risponde sempre con:
```json
{
  "status": "success"|"error",
  "message": "...",
  "data": { ... },
  "intent": "...",
  "esito": "success"|"error"|"fallback"|"escalation",
  "conversation_id": "...",
  "origin": "user"|"agent"|"ams"|"api"
}
```sql

---

### **C. Cosa fare lato chiamanti (frontend, agent, chatbot, orchestratori):**
- Passa sempre header:
  - `X-Origin`: chi sta chiamando ("user", "agent", "ams", "api", "job"…)
  - `X-Agent-Id`: identificativo agente, se chiamata da agent/app
  - `X-Conversation-Id`: se la chiamata fa parte di un workflow o conversazione bot

---

### **D. Dove integrare nel progetto**
- File modificati:
  - `/src/controllers/onboardingController.ts`
  - `/src/utils/logger.ts` (deve supportare campi aggiuntivi)
  - `/README.md` e/o Wiki (sezione Logging agent-aware e Risposta standardizzata)

---


## Domande a cui risponde
- Cosa fa questa pagina?
- Quali sono i prerequisiti?
- Quali passi devo seguire?
- Quali sono gli errori comuni?
- Dove approfondire?







