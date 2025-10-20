# Agent Governance – Helper interattivo

Scopo
- Proporre attività di quality/gates e lasciare all’utente la scelta di cosa eseguire, con verifiche simili alla pipeline ADO.

Uso rapido
- Interattivo (consigliato):
  - `pwsh scripts/agent-governance.ps1`
- Selezione esplicita:
  - `pwsh scripts/agent-governance.ps1 -Wiki -Checklist -DbDrift -GenAppSettings`
- Esegui tutto (se abilitato):
  - `pwsh scripts/agent-governance.ps1 -All`
- Dry‑run:
  - `pwsh scripts/agent-governance.ps1 -WhatIf`

Attività proposte
- Wiki Normalize & Review: normalizza e ricostruisce indici/chunk (\`Wiki/EasyWayData.wiki/scripts/*\`).
- Pre‑Deploy Checklist (API): controlli env/Auth/DB/Blob/OpenAPI (\`npm run check:predeploy\").
- DB Drift Check: verifica oggetti DB richiesti (\`npm run db:drift\").
- KB Consistency (advisory): coerenza tra cambi DB/API/agents docs e KB/Wiki.
- Genera App Settings da .env.local: produce \`out/appsettings*.json\` per deploy.
- Terraform Plan (facoltativo): init/validate/plan su \`infra/terraform\`.

Note
- Alcune attività richiedono prerequisiti (Node, DB, Terraform). Lo script segnala cosa è consigliato/abilitato.
- Lo script non modifica la pipeline; serve come aiutante locale o nel CI con step mirati.

