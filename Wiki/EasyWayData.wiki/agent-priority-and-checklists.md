---
title: Agent Priority Rules e Checklists (human-in-the-loop)
tags: [agents, governance, docs, domain/control-plane, layer/reference, audience/dev, privacy/internal, language/it]
status: active
id: ew-agent-priority-and-checklists
summary: Regole per decidere quando un agente deve proporre una checklist (mandatory/advisory) e come applicare human-in-the-loop senza alert fatigue.
owner: team-platform
llm:
  include: true
  pii: none
  chunk_hint: 250-400
  redaction: [email, phone]
entities: []
---

Obiettivo
- Rendere la proposta di checklist una metodologia comune a TUTTI gli agenti, ridurre “alert fatigue” e proporre checklists solo quando serve, con regole per‑agente parametriche.

Come funziona
- Ogni agente DEVE definire `agents/<agent>/priority.json` con regole (schema: `agents/core/schemas/agent-priority.schema.json`).
- Le regole valutano: branch, env, intent, file cambiati (git diff), variabili (es. `USE_EWCTL_GATES`).
- Se una regola matcha, l’agente propone una checklist (severity: `mandatory` o `advisory`) e l’utente approva.

Template
- Copia da `agents/core/templates/priority.template.json` e adatta a ciascun agente.

Esempi
- Governance (`agents/agent_governance/priority.json`):
  - Mandatory su `main/develop` o quando cambiano `db/**` o `azure-pipelines.yml`.
  - Advisory se in CI `USE_EWCTL_GATES=false`.
- Docs (`agents/agent_docs_review/priority.json`):
  - Advisory quando cambiano `Wiki/**` o `agents/kb/recipes.jsonl`.

Integrazione negli agent
- Script: `scripts/agent-priority.ps1` valuta le regole e restituisce una decisione JSON.
- `scripts/agent-governance.ps1` e `scripts/agent-docs-review.ps1` includono checklists condizionali basate sulla decisione.

Estensione
- Aggiungi altre regole per agenti o condizioni personalizzate (intent-based, path filter specifici, ecc.).
- Mantieni le checklists concise e orientate all’approvazione umana.

Best Practice
- Ogni nuovo agente nel repo deve includere: `agents/<agent>/manifest.json`, `agents/<agent>/priority.json` e riferimenti alla pagina presente in `knowledge_sources` del manifest.
- Gli script agent devono invocare `scripts/agent-priority.ps1` e mostrare la checklist solo quando le regole lo richiedono.

Riferimenti
- `agents/core/schemas/agent-priority.schema.json`
- `scripts/agent-priority.ps1`
- `agents/agent_governance/priority.json`
- `agents/agent_docs_review/priority.json`



