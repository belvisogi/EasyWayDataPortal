---
id: ew-param-best-practices
title: Parametrizzazione – Best Practices
summary: Evitare hardcoded; usare env/variabili YAML e gates condizionati
status: active
owner: team-platform
tags: [best-practice, config, domain/control-plane, layer/reference, audience/dev, audience/ops, privacy/internal, language/it]
llm:
  include: true
  pii: none
  chunk_hint: 250-400
  redaction: [email, phone]
entities: []
updated: '2026-01-05'
next: TODO - definire next step.
---

[Home](../../docs/project-root/DEVELOPER_START_HERE.md) > [[Domain - Control-Plane|Control-Plane]] > [[Layer - Reference|Reference]]

Principi
- Niente valori hardcoded: tutto parametrizzabile via env, YAML o Variable Group.
- Config separata dal codice; default sensati in dev; sicurezza in prod (Key Vault/Variable Group).

API (env)
- Sicurezza: `RATE_LIMIT_WINDOW_MS`, `RATE_LIMIT_MAX`, `BODY_LIMIT`, `ALLOWED_ORIGINS`, `TRUST_PROXY`
- Auth: `AUTH_ISSUER`, `AUTH_JWKS_URI`, `AUTH_AUDIENCE`, `TENANT_CLAIM`, `AUTH_CLIENT_ID`, `AUTH_TENANT_ID`, `AUTH_SCOPES`
- Storage: `AZURE_STORAGE_CONNECTION_STRING` o `AZURE_STORAGE_ACCOUNT` (MI)
- Branding: `BRANDING_CONTAINER`, `BRANDING_PREFIX`, `DEFAULT_TENANT_ID`
- RLS: `RLS_CONTEXT_ENABLED` (true/false)
- Log: `LOG_LEVEL`, `LOG_DIR`
- Portal: `PORTAL_BASE_PATH` (default `/portal`)

Pipeline (YAML/vars)
- Versioni esterne: `ci/versions.yml` → `node_version`, `flyway_version`, `terraform_version`
- Gates condizionati: `ENABLE_CHECKLIST`, `ENABLE_DB_DRIFT`, `ENABLE_KB_CONSISTENCY`, `FLYWAY_ENABLED`
  - Disattiva/attiva i job senza modificare la pipeline.
- Segreti/connessioni: Variable Group/Key Vault.

Flyway & Terraform
- Parametri/credenziali passati come variabili (mai hardcoded).
- Config file (flyway.conf) minimale; URL/USER/PASSWORD da env.

Esempi
- Pipeline: `- template: ci/versions.yml` per versioni; `condition: eq(variables['ENABLE_*'],'true')` per gates.
- API: `app.use(process.env.PORTAL_BASE_PATH || '/portal', portalRoutes)`; `withTenantContext` usa `RLS_CONTEXT_ENABLED`.










