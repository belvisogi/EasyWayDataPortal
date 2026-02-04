# Blueprint Agente LLM – Riassunto Completo

## Obiettivo

Costruire un **agente intelligente davanti a un LLM** (es. DeepSeek via Ollama) capace di:

* capire l’intento dell’utente
* riformulare correttamente l’input
* scegliere cosa fare (chat, RAG, tool, workflow)
* mantenere memoria e coerenza
* migliorare l’interlocuzione senza retraining del modello

> Principio chiave: **l’intelligenza percepita non è nel modello, ma nel sistema attorno al modello**.

---

## Concetti fondamentali

### LLM (Large Language Model)

* Motore statistico di generazione testo
* Non ha memoria propria
* Non conosce il contesto se non gli viene passato

### Agente

Un **agente** =

```
LLM
+ Prompt strutturati
+ Memoria esterna
+ Router / Planner
+ Tool
+ Log & feedback
```

È l’agente che:

* pulisce e interpreta l’input
* decide la strategia
* orchestra le chiamate al modello

---

## Flusso generale (sempre valido)

```
Utente
  ↓
Gateway (CLI / Web / API)
  ↓
Agent Orchestrator
  ├─ Interpreter (pulizia + intento)
  ├─ Memory Manager (short / long)
  ├─ Router (decide cosa fare)
  ├─ LLM Adapter (Ollama, OpenAI…)
  ├─ Tool / RAG / Workflow
  ↓
Post-processing risposta
  ↓
Salvataggio: memoria + log + feedback
```

---

## Prompting corretto (fondamentale)

Separare sempre:

* **System Prompt**: identità, lingua, tono, regole
* **Policy / Developer Prompt**: guardrail (no invenzioni, chiedi chiarimenti se serve)
* **User Prompt**: input pulito + intento

Il testo che arriva al modello **non è mai solo quello scritto dall’utente**.

---

## Memoria (non magica, ma ingegnerizzata)

### Tipi di memoria

1. **Short-term memory**

   * ultime N interazioni
   * serve per coerenza del dialogo

2. **Long-term memory**

   * preferenze utente
   * fatti utili e stabili
   * es. lingua, tono, livello tecnico

3. **Event log**

   * tutto grezzo (debug, audit, tuning)

### Storage consigliato

* Inizio: **SQLite**
* Crescita: **PostgreSQL**
* RAG: **Vector DB** (Chroma / Qdrant)

---

## Interpreter (riformulazione intelligente)

Modulo che:

* corregge typo
* espande frasi ambigue
* rileva lingua e registro
* costruisce un oggetto di intento

Esempio:

```json
{
  "intent": "framework_agente",
  "language": "it",
  "constraints": ["locale", "ollama"],
  "clean_user_message": "Quale framework usare per costruire un agente davanti a un LLM?"
}
```

---

## Router (cuore decisionale)

Decide **come** rispondere:

* **CHAT** → conversazione pura
* **RAG** → risposta basata su documenti
* **TOOL** → azioni (DB, file, API)
* **WORKFLOW** → task multi-step

Regole tipiche:

* “secondo i miei documenti” → RAG
* “fai / esegui / aggiorna” → TOOL
* “procedura / pipeline / più step” → WORKFLOW
* altrimenti → CHAT

---

## Blueprint per casi d’uso

### 1️⃣ Chat Agent

* memoria
* stile coerente
* nessun tool

### 2️⃣ RAG Agent

* ingestion documenti
* retrieval + context composer
* risposta *grounded*
* se info non trovata → lo dice

### 3️⃣ Tool Agent

* registry tool con schema
* plan → execute → summarize
* policy di sicurezza

### 4️⃣ Workflow Agent

* state machine
* step, retry, checkpoint
* sotto-agenti con ruoli

### 5️⃣ Hybrid Agent (finale)

* un unico orchestrator
* router centrale
* governa tutto

---

## Ciclo di miglioramento (senza retraining)

1. log input/output
2. feedback (👍 / 👎)
3. analisi errori
4. tuning di:

   * prompt
   * router
   * memoria

> L’agente **migliora** anche se il modello resta identico.

---

## Framework consigliati

* **LangChain (Python/JS)** – rapido, completo
* **LlamaIndex (Python)** – eccellente per RAG
* **Semantic Kernel** – enterprise / plugin-based
* **AutoGen / CrewAI** – multi-agente
* **Custom Agent (consigliato)** – massimo controllo

Con Ollama + DeepSeek: **LangChain o custom loop**.

---

## Struttura progetto consigliata

```
agent/
  app.py
  orchestrator.py
  router.py
  interpreter.py
  llm/
    ollama_adapter.py
  memory/
    short_term.py
    long_term.py
    store.sqlite
  rag/
    ingest.py
    retriever.py
  tools/
    registry.py
    runner.py
  workflows/
    engine.py
  observability/
    logger.py
    feedback.py
```

---

## Loop centrale (pseudo-codice)

```python
def handle_message(user_text):
    parsed = interpreter(user_text)
    ctx = memory.load_short_term()
    profile = memory.load_long_term()

    route = router.decide(parsed, ctx, profile)

    if route == "rag":
        evidence = rag.retrieve(parsed)
        answer = llm.answer(ctx, profile, parsed, evidence)

    elif route == "tool":
        plan = llm.plan_tools(ctx, profile, parsed)
        results = tools.execute(plan)
        answer = llm.summarize(results)

    elif route == "workflow":
        answer = workflows.run(parsed)

    else:
        answer = llm.chat(ctx, profile, parsed)

    memory.save_turn(user_text, answer)
    observability.log(parsed, route, answer)
    return answer
```

---

## Roadmap consigliata

1. Chat agent stabile
2. Router
3. RAG
4. Tool agent
5. Workflow agent

---

## Frase finale da ricordare

> **Il modello genera testo. L’agente genera intelligenza.**

Questo documento è la base per costruire un agente LLM serio, locale, estendibile e governabile.
