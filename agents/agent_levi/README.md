---
id: agent_levi
title: "Agent Levi — The Sovereign Cleaner"
status: active
owner: team-platform
tags: [agent, domain/docs, layer/arm, level/L2, role/cleaner]
---

# Agent Levi — The Sovereign Cleaner

> *"Il caos non e' un'opzione. La pulizia e' la legge."*

Levi e' il guardiano della documentazione. Aggiorna `HANDOFF_LATEST.md` a fine sessione e mantiene puliti i file Markdown della piattaforma.

## Azioni

| Action | Descrizione | Quando usarla |
|---|---|---|
| `handoff:update` | Aggiorna `docs/HANDOFF_LATEST.md` con stato sessione corrente + archivia | Fine di ogni sessione, dopo `server git pull` |
| `md:fix` | Scansiona `.md` e rileva frontmatter mancanti, link rotti, sezioni vuote | Prima di ogni release o ingest Qdrant |

## Uso

```powershell
# Fine sessione: aggiorna HANDOFF_LATEST
pwsh agents/agent_levi/Invoke-AgentLevi.ps1 -Action handoff:update -SessionNumber 20

# Dry run per vedere cosa cambierebbe
pwsh agents/agent_levi/Invoke-AgentLevi.ps1 -Action handoff:update -SessionNumber 20 -DryRun

# Scansione doc quality su docs/
pwsh agents/agent_levi/Invoke-AgentLevi.ps1 -Action md:fix -Scope docs/

# Scansione su Wiki
pwsh agents/agent_levi/Invoke-AgentLevi.ps1 -Action md:fix -Scope Wiki/EasyWayData.wiki/agents/
```

## Output

Entrambe le azioni restituiscono JSON:

```json
{
  "ok": true,
  "action": "handoff:update",
  "session": 20,
  "confidence": 0.92,
  "ragChunks": 5,
  "elapsedSec": 4.2,
  "dryRun": false
}
```

## Prerequisiti

- `DEEPSEEK_API_KEY` in `/opt/easyway/.env.secrets` (server) o `C:\old\.env.developer` (locale)
- `QDRANT_API_KEY` per il conteggio chunk (opzionale, solo su server)
- `agents/skills/retrieval/Invoke-LLMWithRAG.ps1` presente

## Integrazione workflow

Aggiungere a fine di ogni sessione (dopo `server git pull`):

```powershell
pwsh agents/agent_levi/Invoke-AgentLevi.ps1 -Action handoff:update -SessionNumber <N>
ewctl commit  # include HANDOFF_LATEST.md + HANDOFF_SESSION_N.md
```
