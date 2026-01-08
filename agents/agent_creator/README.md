# Agent Creator

Obiettivo
- Creare nuovi agenti in modo **governato** (WHAT-first, WhatIf-by-default), riusando template canonici e aggiornando automaticamente Wiki/KB.

Come si usa
- Via orchestrazione: `orchestrator.n8n.dispatch` (entrypoint unico) con `action=agent.scaffold`.
- Esecuzione locale (demo):
  - `pwsh scripts/agent-creator.ps1 -Action agent:scaffold -IntentPath agents/agent_creator/templates/intent.agent-scaffold.sample.json -WhatIf -NonInteractive`

Riferimenti canonici
- Orchestratore n8n (policy + contratto): `Wiki/EasyWayData.wiki/orchestrations/orchestrator-n8n.md`
- Spec vettorializzazione (include/exclude): `ai/vettorializza.yaml`
- Knowledge base vettoriale: `Wiki/EasyWayData.wiki/ai/knowledge-vettoriale-easyway.md`
- Intent WHAT: `docs/agentic/templates/intents/agent.scaffold.intent.json`
- Manifest orchestrazione: `docs/agentic/templates/orchestrations/agent-scaffold.manifest.json`

Note RAG / Azure AI Search
- Il retrieval viene eseguito da n8n (HTTP node verso Azure AI Search) e passato come `rag_context_bundle` all'agente.
- Nessuna credenziale nel repo: usare Key Vault/App Config.
