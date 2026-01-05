---
id: ew-security-observability
title: Security Middleware & Observability
summary: Best practice di sicurezza, request id e correlazione
status: draft
owner: team-api
tags: [domain/control-plane, layer/spec, audience/dev, audience/ops, privacy/internal, language/it]
llm:
  include: true
  pii: none
  chunk_hint: 300-500
  redaction: [email]
entities: []
updated: '2026-01-05'
next: TODO - definire next step.
---

Obiettivi
- Hardening API: helmet, CORS ristretto, rate limiting, body limit, compression.
- Correlazione e tracciamento: `X-Request-Id`, `X-Correlation-Id`, log coerenti.
- Autenticazione: JWT (Entra ID), estrazione tenant da claim applicativo (no header client).

Implementazione (backend)
- `src/app.ts`:
  - `helmet()`
  - `cors()` con allowlist da `ALLOWED_ORIGINS` (CSV)
  - `compression()`
  - `express-rate-limit` (env: `RATE_LIMIT_WINDOW_MS`, `RATE_LIMIT_MAX`)
  - `express.json({ limit: BODY_LIMIT })`
  - generazione di `X-Request-Id` e `X-Correlation-Id` (uuid v4), riutilizzando header in ingresso se presenti
  - `authenticateJwt` prima di tutte le rotte (verifica token via JWKS)
  - `extractTenantId` usa il claim dal token (default `ew_tenant_id` configurabile via `TENANT_CLAIM`)
  - `withTenantContext(tenantId, fn)` imposta `SESSION_CONTEXT('tenant_id')` su SQL (RLS); flag `RLS_CONTEXT_ENABLED=false` per disattivare in debug
  - helper `runTenantQuery(tenantId, fn)` per route GOLD/REPORTING future

Osservabilità (OTel + App Insights)
- Imposta in `.env.local`:
  - `APPLICATIONINSIGHTS_CONNECTION_STRING` (da Azure Portal)
  - `OTEL_ENABLED=true`
  - (Opzionale) `OTEL_RESOURCE_ATTRIBUTES=service.name=easyway-portal-api,service.namespace=easyway,deployment.environment=dev`
- Avvio: l’SDK OTel viene attivato automaticamente (auto‑instrumentations HTTP/SQL/Blob)
- Verifica in App Insights:
  - `requests | order by timestamp desc`
  - `dependencies | where type in ('SQL','http') | order by timestamp desc`

Propagazione
- Logger allega implicitamente gli ID (tramite middleware di logging); gli handler possono accedere a `req.requestId` e `req.correlationId`.
- In futuro: OpenTelemetry per tracing distribuito (span DB/Blob) e Application Insights.

Configurazione
- `ALLOWED_ORIGINS`: domini abilitati (CSV). Default: `http://localhost:3000`.
- `RATE_LIMIT_WINDOW_MS`: finestra (ms). Default: `60000`.
- `RATE_LIMIT_MAX`: richieste per finestra. Default: `600`.
- `BODY_LIMIT`: default `1mb`.
- `PORTAL_BASE_PATH`: default `/portal`.

Note
- Per ambienti dietro LB, impostare `TRUST_PROXY=true` per X-Forwarded-*.
- Validazione input già gestita via Zod nei middleware.
- Rimuovere `X-Tenant-Id` dai client: il tenant è determinato dal token.

Uso consigliato (GOLD/REPORTING)
- Per rotte GOLD/REPORTING e query sensibili, usa una di queste forme:
  - `await runTenantQuery(req.tenantId, (reqDb) => reqDb.query('...'))`
  - `await withTenantContext(req.tenantId, async (tx) => new sql.Request(tx).query('...'))`
- Per debug locale senza RLS: imposta `RLS_CONTEXT_ENABLED=false` in `.env.local`.
- `AUTH_ISSUER`, `AUTH_JWKS_URI`, `AUTH_AUDIENCE` (opzionale), `TENANT_CLAIM` (default `ew_tenant_id`)
- `RLS_CONTEXT_ENABLED` (default `true`): se `false`, non imposta il contesto RLS a DB (debug)

Approfondimenti
- Parametrizzazione completa: vedi `Wiki/EasyWayData.wiki/parametrization-best-practices.md`





