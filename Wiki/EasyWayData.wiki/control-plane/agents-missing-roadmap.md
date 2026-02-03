---
title: Roadmap agent (retrieval, observability, infra, backend, release)
tags: [domain/control-plane, layer/spec, audience/dev, audience/ops, privacy/internal, language/it, agents, rag, observability, infra]
status: active
updated: 2026-01-16
redaction: [email, phone, token]
id: ew-control-plane-agents-missing-roadmap
chunk_hint: 200-300
entities: []
include: true
summary: Pagina canonica: perche' servono questi agenti e quali intent minimi devono coprire.
llm: 
  pii: none
  redaction: [email, phone]
pii: none
owner: team-platform

llm:
  redaction: [email, phone]
  include: true
  chunk_hint: 5000
---

[[../start-here.md|Home]] > [[index.md|Control-Plane]] > Roadmap

# Roadmap agent (retrieval, observability, infra, backend, release)

## Contesto (repo)
- Registry agent: `control-plane/agents-registry.md`
- Segregation model: `control-plane/segregation-model-dev-knowledge-runtime.md`
- Policy RAG: `Wiki/EasyWayData.wiki/ai/knowledge-vettoriale-easyway.md` + `ai/vettorializza.yaml`
- Entrypoint: `scripts/ewctl.ps1` e `orchestrator.n8n.dispatch`

## Stato
Abbiamo creato gli agenti skeleton minimi per:
- retrieval (RAG)
- observability
- infra (terraform plan)
- backend (openapi validate)
- release (runtime bundle)

## Intent minimi (WHAT-first)
- `rag.export-wiki-chunks`
- `obs.healthcheck`
- `infra.terraform.plan`
- `api.openapi.validate`
- `runtime.bundle`

## Next (implementazione iterativa)
- Agganciare questi intent a `orchestrator.n8n.dispatch` con workflow n8n dedicati.
- Aggiungere upload/publish runtime (artifact) come step separato con `agent_datalake`.
- Rendere i controlli piu' robusti (es. openapi-cli, terraform plan artifact, health endpoint).


## Vedi anche

- [Agents Registry (owner, domini, intent)](./agents-registry.md)
- [Agents Manifest Audit (gap list)](./agents-manifest-audit.md)
- [Segregation Model (Dev vs Knowledge vs Runtime)](./segregation-model-dev-knowledge-runtime.md)
- [Control Plane - Panoramica](./index.md)
- [Multi‑Agent & Governance – EasyWay](../agents-governance.md)








