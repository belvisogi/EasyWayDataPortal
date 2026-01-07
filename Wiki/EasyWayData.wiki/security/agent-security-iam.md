---
id: ew-security-agent-security-iam
title: Agent Security (IAM/KeyVault) - overview
summary: Agente per provisioning sicuro di segreti/reference e supporto a provisioning accessi DB/Datalake (via n8n.dispatch).
status: active
owner: team-platform
tags: [security, iam, keyvault, agents, domain/control-plane, layer/reference, audience/dev, audience/ops, privacy/internal, language/it]
llm:
  include: true
  pii: none
  chunk_hint: 200-300
  redaction: [email, phone, token]
entities: []
---

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
```

## Note di sicurezza
- Mai committare `.env*` o valori segreti.
- Log e audit: `agents/logs/events.jsonl` (non contiene secretValue).
