---
type: guide
status: draft
---

---
title: Agent Security (IAM/KeyVault) - overview
tags: [security, iam, keyvault, agents, domain/control-plane, layer/reference, audience/dev, audience/ops, privacy/internal, language/it]
status: active
updated: 2026-01-16
redaction: [email, phone, token]
id: ew-security-agent-security-iam
chunk_hint: 200-300
entities: []
include: true
summary: Agente per provisioning sicuro di segreti/reference e supporto a provisioning accessi DB/Datalake (via n8n.dispatch).
llm: 
pii: none
owner: team-platform

llm:
  include: true
  chunk_hint: 5000---

[Home](./start-here.md) >  > 

# Agent Security (IAM/KeyVault)

## Contesto (repo)
- Registry agent: `control-plane/agents-registry.md`
- Segreti e accessi: `security/segreti-e-accessi.md`
- Runbook provisioning: `security/operativita-governance-provisioning-accessi.md`
- Entrypoint canonico: `orchestrator.n8n.dispatch` (n8n legge la knowledge vettoriale, non il repo)
- Script agente: `scripts/agent-security.ps1`
- Manifest: `agents/agent_security/manifest.json`

## Cosa fa
- Imposta/ruota secret in Key Vault senza mai stampare il valore (`kv-secret:set`).
- Genera reference per App Settings (`kv-secret:reference`).
- Propone entry per registry accessi (metadati, no secret) (`access-registry:propose`).

## Esempio (manuale)
```powershell
pwsh scripts/agent-security.ps1 -Action kv-secret:reference -IntentPath out/intent.kv-secret-ref.json -LogEvent
```sql

## Note di sicurezza
- Mai committare `.env*` o valori segreti.
- Log e audit: `agents/logs/events.jsonl` (non contiene secretValue).


## Vedi anche

- [Segregation Model (Dev vs Knowledge vs Runtime)](../control-plane/segregation-model-dev-knowledge-runtime.md)
- [07 iam naming utenti gruppi](../easyway-webapp/07-iam-naming-utenti-gruppi.md)
- [Agents Registry (owner, domini, intent)](../control-plane/agents-registry.md)
- [Segreti e accessi (DB + Datalake)](./segreti-e-accessi.md)
- [IAM Provision Access (WHAT)](../orchestrations/iam-provision-access.md)





