# Agent Template (Skeleton)

Obiettivo
- Fornire uno scheletro minimale per creare nuovi agenti agent‑first: accettano Intent JSON, sono idempotenti, producono output strutturato e rispettano `allowed_paths`.

File
- `manifest.json` — metadati, azioni, allowed_paths
- `priority.json` — peso/ordinamento azioni
- `templates/intent.sample.json` — esempio di Intent
- `scripts/agent-template.ps1` — eseguibile PowerShell con output JSON

Esecuzione (esempio)
```
pwsh scripts/agent-template.ps1 -Action sample:echo -IntentPath agents/agent_template/templates/intent.sample.json -NonInteractive -LogEvent
```

Output
- JSON con esito, timestamps, action, params, e (se richiesto) evento in `agents/logs/events.jsonl`.

Linee Guida
- Aggiungi nuove azioni aggiornando `manifest.json` e lo script.
- Implementa `-WhatIf` per azioni con effetti.
- Mantieni idempotenza: ripetere l’azione non deve produrre effetti collaterali inattesi.

