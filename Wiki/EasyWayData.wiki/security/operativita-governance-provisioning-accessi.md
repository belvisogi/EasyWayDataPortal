---
id: ew-security-operativita-governance-provisioning-accessi
title: Operativita governance-driven - provisioning accessi (DB/Datalake)
summary: Runbook operativo per simulazione governance-driven e replica tramite agent (db/datalake).
status: active
owner: team-platform
tags: [domain/security, layer/runbook, audience/ops, audience/dba, privacy/internal, language/it, governance, agents, db, datalake]
llm:
  include: true
  pii: none
  chunk_hint: 200-300
  redaction: [email, phone, token]
entities: []
---

# Operativita governance-driven - provisioning accessi (DB/Datalake)

## Contesto (repo)
- Source of truth segreti: `Wiki/EasyWayData.wiki/security/segreti-e-accessi.md`
- Goals agentici: `agents/goals.json`
- KB: `agents/kb/recipes.jsonl`
- Log eventi: `agents/logs/events.jsonl`
- Entrypoint orchestrazione: `scripts/ewctl.ps1`

## Obiettivo
Simulare un flusso governance-driven per creare accessi tecnici e poi replicarlo con l'agente corretto, garantendo audit e reversibilita'.

## Input minimo (da compilare)
- target: `db` | `datalake`
- environment: `dev` | `ci` | `prod`
- identity_type: `managed_identity` | `service_principal` | `user`
- identity_name: `<nome>`
- permissions: `read` | `write` | `read/write` | `admin`
- secret_ref: `<nome secret in Key Vault>`
- owner: `<team>`
- justification: `<motivazione>`

## Step 1 - Governance (simulazione)
Checklist rapida:
- privilegi minimi
- secret_ref definito (Key Vault)
- policy log e audit attive
- rotazione definita (rotation_days)

Output atteso:
- decisione governance (approve/deny)
- note audit

## Step 2 - Esecuzione con agente

### DB (agent_dba)
Esempio comando (manuale):
```powershell
pwsh scripts/agent-dba.ps1 -Action db-user:create -IntentPath <intent.json> -WhatIf -LogEvent
```

### Datalake (agent_datalake)
Esempio comando (manuale):
```powershell
pwsh scripts/agent-datalake.ps1 -Action dlk-apply-acl -IntentPath <intent.json> -WhatIf -LogEvent
```

## Step 3 - Registrazione e audit
- Aggiorna il censimento accessi in `Wiki/EasyWayData.wiki/security/segreti-e-accessi.md`.
- Logga l'evento in `agents/logs/events.jsonl` (gia' fatto se `-LogEvent`).

## Come replicare per altri agenti
Per ogni agente, creare una pagina operativa equivalente:
- stessa struttura (input minimo, governance, esecuzione, audit)
- link al manifest dell'agente
- ricetta KB corrispondente

## Verify
- Output agente ok=true
- Secret salvato in Key Vault (solo riferimento nel repo)
- Censimento accessi aggiornato


## Vedi anche

- [Segreti e accessi (DB + Datalake)](./segreti-e-accessi.md)
- [Agent Security (IAM/KeyVault) - overview](./agent-security-iam.md)
- [IAM Provision Access (WHAT)](../orchestrations/iam-provision-access.md)
- [Datalake - Ensure Structure (Stub)](../datalake-ensure-structure.md)
- [Dominio Datalake](../domains/datalake.md)

