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
- Autorizzazione: RBAC/Scopes su endpoint sensibili (docs/db/notifications).
- Error handling coerente con payload standard e code unificati.

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
  - `requireAccessFromEnv` applica RBAC per route sensibili (docs/db/notifications)
  - rate limit per-tenant + burst su `/api/*` (chiave: tenantId)
  - `errorHandler` centralizzato con payload standard `{ error: { code, message, details }, requestId, correlationId }`
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
- `BODY_LIMIT`: default `1mb`.
- `PORTAL_BASE_PATH`: default `/portal`.
- `TENANT_RATE_LIMIT_WINDOW_MS`: finestra rate limit per-tenant (ms). Default: `60000`.
- `TENANT_RATE_LIMIT_MAX`: max richieste per-tenant nella finestra. Default: `600`.
- `TENANT_BURST_WINDOW_MS`: finestra burst per-tenant (ms). Default: `10000`.
- `TENANT_BURST_MAX`: max richieste burst per-tenant. Default: `120`.
- `AUTH_ROLE_CLAIM`: claim ruoli (default `roles`).
- `AUTH_SCOPE_CLAIM`: claim scope (default `scp`).
- `DOCS_ROLES`, `DOCS_SCOPES`: ruoli/scopes ammessi per `/api/docs/*`.
- `DB_ROLES`, `DB_SCOPES`: ruoli/scopes ammessi per `/api/db/*`.
- `NOTIFY_ROLES`, `NOTIFY_SCOPES`: ruoli/scopes ammessi per `/api/notifications/*`.

Note
- Per ambienti dietro LB, impostare `TRUST_PROXY=true` per X-Forwarded-*.
- Validazione input già gestita via Zod nei middleware.
- Rimuovere `X-Tenant-Id` dai client: il tenant è determinato dal token.
- Se i ruoli/scopes non sono presenti nel token, l'API restituisce 403.

Uso consigliato (GOLD/REPORTING)
- Per rotte GOLD/REPORTING e query sensibili, usa una di queste forme:
  - `await runTenantQuery(req.tenantId, (reqDb) => reqDb.query('...'))`
  - `await withTenantContext(req.tenantId, async (tx) => new sql.Request(tx).query('...'))`
- Per debug locale senza RLS: imposta `RLS_CONTEXT_ENABLED=false` in `.env.local`.
- `AUTH_ISSUER`, `AUTH_JWKS_URI`, `AUTH_AUDIENCE` (opzionale), `TENANT_CLAIM` (default `ew_tenant_id`)
- `RLS_CONTEXT_ENABLED` (default `true`): se `false`, non imposta il contesto RLS a DB (debug)

Approfondimenti
- Parametrizzazione completa: vedi `Wiki/EasyWayData.wiki/parametrization-best-practices.md`

## Security testing & pen test (piano)
- In sviluppo: ogni feature nuova deve considerare vulnerabilita' note (OWASP Top 10, injection, authz).
- SAST/SCA in CI: scanning continuo su dipendenze e codice (ogni PR).
- DAST in pre-prod: smoke di sicurezza su endpoint critici prima di release.
- Pen test periodico: almeno 1/anno (o semestrale se rischio alto) e dopo cambi major.
- Threat model leggero per workflow nuovi o dati sensibili.

## Punti di attenzione (backlog)
- Secrets hygiene: nessun segreto in repo/log; migrare valori sensibili a Key Vault/Variable Group e applicare redaction nei log.
- Logging/PII: definire campi vietati (token, password, PII) e redazione automatica nei log applicativi e `events.jsonl`.
- CI security gates: introdurre SCA/SAST (minimo `npm audit` + lint) su ogni PR; aggiungere DAST smoke in pre-prod.
- Token handling: in prod rimuovere fallback dev (token manuale) e dipendenze CDN non necessarie; applicare CSP/headers robusti.
- RBAC scopes: validare ruoli/scopes reali dei token Entra e allineare mapping/policy (403 atteso senza claim).

## Go-Live preflight (Security/Compliance/Audit)
Usa questa checklist prima di andare in produzione (umana + agent).

- Segreti: nessun segreto in repo (`.env*`), variabili sensibili solo in Key Vault/Variable Group, rotazione definita.
- AuthN/AuthZ: `AUTH_ISSUER/JWKS/AUDIENCE` corretti, tenant claim valido, RBAC per endpoint sensibili abilitato e testato (403 senza claim).
- Audit: log strutturati con `requestId/correlationId/tenantId/actor`, retention definita, redaction PII/token attiva.
- Rate limit: per-tenant + burst configurati e verificati (429 con payload standard).
- Gates sicurezza: SCA/SAST su PR, DAST smoke in pre-prod, pen test pianificato (almeno annuale) e dopo cambi major.
- Docs: policy e QnA errori aggiornate; KB recipe presente per la preflight.





