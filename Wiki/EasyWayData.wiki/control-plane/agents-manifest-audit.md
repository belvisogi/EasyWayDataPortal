---
id: ew-control-plane-agents-manifest-audit
title: Agents Manifest Audit (gap list)
summary: Operativita' per generare automaticamente una lista di gap per agente (manifest/readme/actions/gates/knowledge sources).
status: active
owner: team-platform
tags: [domain/control-plane, layer/howto, audience/dev, audience/ops, privacy/internal, language/it, agents, docs-governance, rag]
llm:
  include: true
  pii: none
  chunk_hint: 200-300
  redaction: [email, phone, token]
entities: []
---

# Agents Manifest Audit (gap list)

## Contesto (repo)
- Scopo: ridurre ambiguita' (RAG) e rendere gli agenti consumabili da `orchestrator.n8n.dispatch`.
- Source of truth operativa: `agents/<agent>/manifest.json`
- Registry canonico: `control-plane/agents-registry.md`
- Log: `agents/logs/events.jsonl`
- KB: `agents/kb/recipes.jsonl`

## Come eseguire (manuale)
```powershell
pwsh scripts/agents-manifest-audit.ps1
```

Output:
- JSON: `out/docs/agents-manifest-audit.json`
- Markdown: `out/docs/agents-manifest-audit.md`

## Come eseguire (agentico)
```powershell
pwsh scripts/agent-docs-review.ps1 -AgentsManifestAudit
```

## Cosa controlla (minimo)
- `description/role/name` nel manifest
- `allowed_paths` e `allowed_tools`
- `required_gates` e `knowledge_sources`
- `actions[]` dichiarate (per routing/validazione)
- presenza `README.md` e `templates/` (advisory)

## Uso consigliato
- In locale: audit + fix guidati (human-in-the-loop).
- In CI: usalo come advisory (non blocca) finche' non avete standardizzato tutti i manifest.


## Vedi anche

- [Agents Registry (owner, domini, intent)](./agents-registry.md)
- [Roadmap agent (retrieval, observability, infra, backend, release)](./agents-missing-roadmap.md)
- [Segregation Model (Dev vs Knowledge vs Runtime)](./segregation-model-dev-knowledge-runtime.md)
- [Validazione Output Agenti in CI](../agent-output-validation-ci.md)
- [Agent Security (IAM/KeyVault) - overview](../security/agent-security-iam.md)

