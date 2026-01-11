# Agent ADO UserStory

Obiettivo
- Gestire User Story su Azure DevOps con flusso agent-first: prefetch best practices (Wiki locale + fonti esterne) e creazione work item con output strutturato.

File
- `manifest.json` - metadati, azioni, allowed_paths
- `priority.json` - checklist minime
- `templates/intent.ado-userstory-create.sample.json` - esempio di intent per creazione User Story
- `templates/intent.ado-bestpractice-prefetch.sample.json` - esempio di intent prefetch best practices
- `scripts/agent-ado-userstory.ps1` - eseguibile PowerShell con output JSON

Esecuzione (esempio)
```
pwsh scripts/agent-ado-userstory.ps1 -Action ado:userstory.create -IntentPath agents/agent_ado_userstory/templates/intent.ado-userstory-create.sample.json -NonInteractive -LogEvent
```

Note
- Usa `WhatIf` per evitare modifiche reali su Azure DevOps.
- Evita di mettere PAT in chiaro: usa `ADO_PAT` come variabile ambiente.
- Output e log eventi finiscono in `agents/logs/events.jsonl`.
