---
title: Segregation Model (Dev vs Knowledge vs Runtime)
tags: [domain/control-plane, layer/reference, audience/dev, audience/ops, privacy/internal, language/it, rag, n8n, security, keyvault]
status: active
updated: 2026-01-16
redaction: [email, phone, token]
id: ew-control-plane-segregation-model
chunk_hint: 250-350
entities: []
include: true
summary: Linea guida canonica per segregare repo (evoluzione), knowledge vettoriale (lettura n8n/LLM) e runtime (esecuzione con segreti).
llm: 
pii: none
owner: team-platform
---

# Segregation Model (Dev vs Knowledge vs Runtime)

## Contesto (repo)
- Goals: `agents/goals.json`
- KB: `agents/kb/recipes.jsonl`
- Log eventi: `agents/logs/events.jsonl`
- Entrypoint: `scripts/ewctl.ps1`
- RAG policy: `Wiki/EasyWayData.wiki/ai/knowledge-vettoriale-easyway.md` + `ai/vettorializza.yaml`
- Dispatch policy: `orchestrations/orchestrator-n8n.md`
- Segreti: `security/segreti-e-accessi.md` (Key Vault come source-of-truth)

## Obiettivo
Separare chiaramente:
1) **Dev world** (repo): dove si evolve e si versiona
2) **Knowledge world** (vector DB): dove n8n/LLM leggono solo conoscenza ammessa
3) **Runtime world** (runner): dove si esegue con permessi e segreti (Key Vault/MI)

## Dev world (repo)
- Contiene: codice, scripts, manifest, Wiki, KB.
- Non contiene: valori segreti, output runtime persistenti.
- Output locali/artefatti: `out/**` (escluso da RAG e normalmente non versionato).

## Knowledge world (Vector DB)
- n8n/LLM **non leggono il repo**: interrogano solo il vector DB.
- Indicizzazione governata da `ai/vettorializza.yaml`:
  - Sempre: Wiki + KB + manifest agent
  - Scripts (`scripts/**/*.ps1`) indicizzati ma recuperati **solo on-demand** (bundle/filtro path) per evitare rumore
  - Sempre esclusi: `.env*`, `*secrets*`, `scripts/variables/**`, `out/**`

## Runtime world (Execution Runner)
- Una VM/container/CI runner con checkout del repo (o pacchetto versionato).
- Esegue `ewctl`/script e accede ai segreti tramite Key Vault (Managed Identity / Service Principal).
- Produce solo output sanitizzato + artifact.

## Come portare il codice al runner (copia parziale, segregata)
Obiettivo: il runner deve avere **solo** i file necessari all'azione, evitando accesso diretto al repo da parte di n8n.

Opzioni equivalenti (scegline una):

### 1) Sparse checkout (Git)
Il runner fa checkout solo delle cartelle necessarie (esempio tipico control-plane):
- `scripts/`
- `agents/`
- `docs/agentic/templates/`
- `Wiki/EasyWayData.wiki/` (solo se l'azione rigenera indici o verifica link)

### 2) Runtime bundle (artifact)
In CI si produce un artifact zip/versionato con:
- `scripts/` + `agents/` + `docs/agentic/templates/`
e il runner lo scarica/esegue senza accesso al repo.

### 3) Container image (versionata)
Build di un'immagine con dentro `ewctl` + scripts/agents (versionati), e runtime che legge segreti da Key Vault via MI/SP.

Nota
- Datalake/Storage va usato per **artifact** (report/log/blueprint), non come distribuzione del codice eseguibile.

## Flusso canonico (n8n -> runner -> artifacts)
```mermaid
flowchart LR
  A[n8n: intent] --> B[Vector DB: retrieval]
  B --> A
  A --> C[orchestrator.n8n.dispatch]
  C --> D[Runner: checkout repo + ewctl]
  D --> E[Artifacts: out/ + events.jsonl]
  E --> F[Datalake/Storage: publish artifacts]
  D --> G[Key Vault: secrets]
  D --> A
```sql

## Regole (linea guida)
- n8n non deve avere accesso diretto a repo e segreti.
- Il runner e' l'unico che puo' leggere Key Vault e applicare azioni.
- Il vector DB contiene solo contenuti “safe” e governati.
- Ogni operazione produce log strutturato e artifact (audit).

## Checklist operativa (prima di mettere in produzione)
- Key Vault configurato e policy di accesso (MI/SP) minime.
- `ai/vettorializza.yaml` aggiornato e applicato in pipeline embedding.
- Retrieval bundles per n8n definiti (scripts solo on-demand).
- Runner con `ewctl` e gate attivi.
- Datalake usato solo per artifact (no codice eseguibile).


## Vedi anche

- [Agents Registry (owner, domini, intent)](./agents-registry.md)
- [Agent Security (IAM/KeyVault) - overview](../security/agent-security-iam.md)
- [Roadmap agent (retrieval, observability, infra, backend, release)](./agents-missing-roadmap.md)
- [Control Plane - Panoramica](./index.md)
- [Agents Manifest Audit (gap list)](./agents-manifest-audit.md)


