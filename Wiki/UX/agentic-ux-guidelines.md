---
title: Linee guida UX per agenti e LLM — formato leggibile dalle macchine
summary: Documentazione esplicita pensata per permettere ad agenti/LLM di capire rapidamente cosa fare, con esempi di intent, schema minimo e template di prompt.
owner: team-platform
status: draft
tags: [ux, agents, llm, guidelines, language/it]
---

Scopo
- Fornire una guida breve, precisa e strutturata che permetta a un agente (LLM/tooling) di leggere il repository EasyWayDataPortal e capire esattamente quali azioni proporre o eseguire.
- Rendere la documentazione adatta anche all'allenamento di LLM: messaggi chiari, esempi, schema minimo e template di prompt che riducono i parametri necessari.

Principi chiave (per gli autori di doc)
- Esplicito > implicito: un agente non deve "intuire" contesto mancante. Fornisci esempi e schema.
- Minimizzare il contesto: un intent ben formato con pochi campi deve essere sufficiente per generare un plan.
- Machine-readable first: includere JSON/metadata dove utile (mini‑DSL, tags, recipeMetadata).
- Versionare i prompt e i template usati per LLM (KB + manifest).

1) Cosa deve trovare un agente quando legge il progetto
- Visione sintetica: file agentic-portal-vision.md (contesto business + principi).
- Regole operative: AGENTS.md + AGENTIC_READINESS.md (idempotenza, guardrail).
- Goals machine-readable: agents/goals.json.
- Manifest agenti: agents/*/manifest.json (allowed_paths, actions).
- Template operativi: docs/agentic/templates/*.sql e agents/core/templates/*.
- Priority/checklist: agents/*/priority.json (regole quando mostrare checklist).
- Esempi: Wiki/UX/agentic-ux.md, Wiki/START_HOW_TO_START.md, mock plan in frontend.

2) Schema minimo di intent (JSON) — il primo oggetto che un agente dovrebbe produrre
- Campo minimo richiesto: intent, payload, tags?, metadata?
Esempio:
{
  "intent": "create_table",
  "entity": "USERS",
  "schema": "PORTAL",
  "columns": [
    {"name":"user_id","type":"NVARCHAR(50)","constraints":["NOT NULL","UNIQUE"]},
    {"name":"tenant_id","type":"NVARCHAR(50)","constraints":["NOT NULL"]},
    {"name":"email","type":"NVARCHAR(255)","constraints":["NOT NULL"]}
  ],
  "ndg": {"sequence":"SEQ_USER_ID","prefix":"CDI","width":9},
  "tags": ["onboarding","demo"],
  "metadata": {"env":"staging","owner":"team-a"}
}

3) ChecklistSuggestions: come presentare le raccomandazioni
- Struttura restituita dal plan: plan.checklistSuggestions = { "<agent>": { "mandatory": [...], "advisory": [...] } }
- Ogni voce include prefisso [rule-id] e testo esplicito.
- Gli agenti devono mostrare per default solo le "mandatory" all'utente non tecnico; le "advisory" sono espandibili.

4) Template prompt LLM (ridurre i parametri)
- Mantieni il prompt breve. Fornisci:
  1) Intestazione con vision + goal ID (agents/goals.json)
  2) Intent JSON (schema minimo)
  3) Richiesta esplicita di output (es. "Restituisci: { plan: {...}, preview: {...} } in JSON puro")
Esempio (testo da passare all’LLM):
```
Vision: Portale agentico EasyWay (see agents/goals.json id: <goal-id>).
Input: {intent JSON here}
Task: Genera un plan JSON con:
  - suggestion (agent, action, args)
  - checklistSuggestions per agent (mandatory/advisory)
  - preview.sql (DDL/SP) e simulatedDiff
Output format: JSON only, no prose.
```
- Versiona il template e archiviarlo in agents/kb o agents/core/templates/prompt-templates.

5) Regole pratiche per rendere la doc "allenabile"
- Esempi concreti: per ogni intent includere almeno 2-3 esempi (payload + expected plan).
- Metadata consistente: usare sempre gli stessi nomi di campo (intent, tags, metadata).
- Risultati strutturati: le risposte degli agenti devono essere JSON validi e validabili tramite schema (aggiungere schema JSON in agents/core/schemas).
- Prompt templates versionati e semplici: meno parametri, più esempi.

6) Check-list per gli autori di nuove pagine/doc che vogliano essere LLM-friendly
- [ ] Fornire un esempio JSON di intent per il caso d'uso.
- [ ] Indicare quali agenti dovrebbero intervenire e perché (role/manifest link).
- [ ] Specificare tags e metadata consigliati.
- [ ] Fornire expected checklist/rules in formato priority.json (esempi).
- [ ] Inserire snippet di output JSON atteso (plan preview).

7) Esempi rapidi (uso reale)
- Creare una nuova ricetta KB: aggiungi agents/kb/recipes.jsonl con id, intent, payload esempio, tags.
- Aggiungere priority.json in agents/<agent>/ con regole 'when' chiare (intentContains, tags, recipeMetadata).
- Salvare prompt template in agents/core/templates/prompt_template.txt e referenziarlo nel manifest dell'agente.

8) Dove inserire questa guida
- Link in AGENTS.md e in Wiki/UX/agentic-ux.md: aggiungere una sezione "Machine-readable guidelines" che rimanda a questo file.
- Consiglio operativo: i bot/agent starter devono leggere prima questo file per capire il formato atteso.

9) Next steps consigliati (operativo)
- Versionare e fissare 3 prompt-template minimi per gli use-case iniziali (create_table, update_docs, terraform_plan).
- Aggiungere 2–3 esempi intent+expected plan nel KB (agents/kb/).
- Integrare una routine di validazione (schema JSON) nelle pipeline CI per ogni PR che modifica docs/agentic o agents/*/priority.json.

Fine
- Se vuoi, procedo a:
  - 1) Aggiungere riferimenti diretti ad AGENTS.md e START_HOW_TO_START.md;
  - 2) Creare i prompt-template in agents/core/templates/ e 3 esempi intent in agents/kb/;
  - 3) Aggiungere uno schema JSON minimal per il plan in agents/core/schemas/plan.schema.json.
Indica quale di queste azioni vuoi che esegua per prima.
