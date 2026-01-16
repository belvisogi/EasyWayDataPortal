---
title: Tag Taxonomy (Controllata)
tags: [domain/docs, layer/spec, audience/dev, privacy/internal, language/it, taxonomy]
status: active
updated: 2026-01-16
redaction: [email, phone]
id: ew-docs-tag-taxonomy
chunk_hint: 300-450
entities: []
include: true
summary: Vocabolario controllato per tag (domain/layer/audience/privacy/language) per migliorare ricerca, ridurre token e ridurre allucinazioni.
llm: 
pii: none
owner: team-platform
---

# Tag Taxonomy (Controllata)

Scopo: usare tag **coerenti e machine-readable** per migliorare retrieval e clustering, riducendo token e ambiguità.

Fonte machine-readable (source of truth):
- `docs/agentic/templates/docs/tag-taxonomy.json`

## Formato
- Tag di facet: `<facet>/<value>` (es: `domain/docs`)
- Tag liberi: `kebab-case` (es: `n8n`, `ewctl`, `flyway`, `data-quality`)

## Facet obbligatorie
Ogni pagina canonica dovrebbe avere:
- `domain/<...>`
- `layer/<...>`
- `audience/<...>` (una o più)
- `privacy/<...>`
- `language/<it|en>`

## Valori ammessi (v1.1)
### domain
- `domain/db`, `domain/datalake`, `domain/frontend`, `domain/api` ✨, `domain/security` ✨, `domain/analytics` ✨, `domain/docs`, `domain/control-plane`, `domain/ux`

### layer
- `layer/howto`, `layer/reference`, `layer/runbook`, `layer/spec`, `layer/orchestration`, `layer/intent`, `layer/gate`, `layer/index`, `layer/blueprint`

### audience
- `audience/non-expert`, `audience/dev`, `audience/dba`, `audience/ops`, `audience/architect` ✨

### privacy
- `privacy/internal`, `privacy/public`, `privacy/restricted`

### language
- `language/it`, `language/en`

## Free Tags Canonici ✨
Lista preferita (anti-sinonimi):
- `agents` (non ~~agentic~~)
- `dq` (non ~~data-quality~~)
- `n8n`, `ewctl`, `flyway`, `rag`, `keyvault` (non ~~key-vault~~), `rbac`, `otel`, `terraform`
- `argos`, `wiki`, `kb`, `manifest`
- `orchestration`, `intents`, `governance`, `compliance`, `audit`
- `automation`, `roadmap`, `onboarding`, `use-case`, `quest`, `kanban`, `checklist`

**Regola**: Usare SOLO la forma canonica. I sinonimi deprecati vengono segnalati dal lint.

## Regole anti-ambiguità
- Evitare sinonimi duplicati: scegliere una forma (`data-quality` oppure `dq`).
- Evitare tag troppo generici se non necessari (es. `misc`).
- Preferire i tag facet ai tag liberi quando servono filtri affidabili.

## Lint
- Dry-run (non blocca per facet mancanti):
  - `pwsh scripts/wiki-tags-lint.ps1 -Path "Wiki/EasyWayData.wiki" -ExcludePaths logs/reports`
- Strict (core first):
  - `pwsh scripts/wiki-tags-lint.ps1 -Path "Wiki/EasyWayData.wiki" -ExcludePaths logs/reports -RequireFacets -RequireFacetsScope core -FailOnError`
- Strict (all):
  - `pwsh scripts/wiki-tags-lint.ps1 -Path "Wiki/EasyWayData.wiki" -ExcludePaths logs/reports -RequireFacets -RequireFacetsScope all -FailOnError`


### Scope (enforcement a fasi)
Gli scope sono definiti in `docs/agentic/templates/docs/tag-taxonomy.scopes.json`.
Esempio: enforcement su 20 pagine DB+Datalake:
- `pwsh scripts/wiki-tags-lint.ps1 -Path "Wiki/EasyWayData.wiki" -ExcludePaths logs/reports -RequireFacets -RequireFacetsScope core -ScopeName db-datalake-20 -FailOnError`

### Scope (retrieval stabile per agenti)
Per retrieval (es. n8n) conviene usare scope `*-all` basati su directory/prefix: sono più stabili e riducono manutenzione rispetto a liste enumerate.


Esempi scope disponibili (casistiche):
- `db-datalake-20`
- `db-programmability-rest-20`
- `onboarding-runbook-20`
- `iam-security-20`
- `ops-runbooks-20`
- `argos-dq-20`
- `portal-api-frontend-20`
- `controlplane-governance-20`
- `frontend-ui-20`
- `governance-all`
- `portal-all`
- `data-all`
- `security-all`




## Vedi anche

- [Documentazione Agentica - Audit & Policy (Canonico)](./docs-agentic-audit.md)
- [Tag Scopes & Retrieval Bundles (Gerarchia)](./docs-tag-scopes.md) 📍 **NUOVO**
- [Start Here - Link Essenziali](./start-here.md)
- [Best Practices & Roadmap – Token Tuning e AI-Readiness Universale](./best-practices-token-tuning-roadmap.md)
- [Visione Portale Agentico](./agentic-portal-vision.md)
- [EasyWayData Portal - Regole Semplici (La Nostra Bibbia)](./docs-conventions.md)


