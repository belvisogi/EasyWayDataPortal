# Agent Knowledge Base (KB)

Scopo
- Raccogliere, in formato machine‑readable, ricette di comandi e procedure operative che un agente può eseguire senza ambiguità.
- Aggiornare la KB man mano che eseguiamo test/prove, così da non farlo più “alla fine”.
  - Best practice: per QUALSIASI nuova funzionalità/procedura introdotta nel progetto, aggiungere o aggiornare SEMPRE una ricetta KB (con precondizioni, passi, verifica, riferimenti). Questo rende l’agente eseguibile e la governance ripetibile.

Formato
- File: `agents/kb/recipes.jsonl` (JSON Lines)
- Ogni riga è un oggetto con i campi principali:
```
{
  "id": "kb-setup-env-001",
  "intent": "setup-local-env",
  "question": "Come imposto l'ambiente locale (.env.local)?",
  "tags": ["env","local","powershell"],
  "preconditions": ["PowerShell 7+", "repo clonato"],
  "steps": ["pwsh scripts/setup-env.ps1 -TenantId <TENANT> -AuthClientId <CLIENT_ID> -DbConnString '<CONN>' -DefaultBusinessTenant tenant01"],
  "verify": ["File .env.local creato", "Checklist OK"],
  "rollback": ["Eliminare .env.local o rigenerare"],
  "outputs": ["EasyWay-DataPortal/easyway-portal-api/.env.local"],
  "references": ["EasyWay-DataPortal/easyway-portal-api/README.md", "scripts/setup-env.ps1"],
  "updated": "2025-10-19T00:00:00Z"
}
```

Come contribuire
- Aggiungi una riga JSON per ogni task/ricetta che vuoi rendere eseguibile dall’agente.
- Mantieni gli step idempotenti; usa percorsi e comandi completi.

Script helper
- `scripts/agent-kb-add.ps1` per aggiungere rapidamente una ricetta.

Pubblicazione
- La pipeline pubblica `agents/kb` come artifact `agent-kb`.
- L’endpoint API `/api/docs/kb.json` restituisce la KB in JSON (un array di ricette) per consumo programmatico.
