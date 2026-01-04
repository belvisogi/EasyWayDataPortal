---
title: Sviluppo Locale Dual-Mode (DB mock | SQL)
summary: Riduci i costi in locale con DB mock basato su file e passa a SQL senza refactor.
tags: [dev, db, costs, domain/control-plane, layer/howto, audience/dev, privacy/internal, language/it]
id: ew-dev-dual-mode
status: draft
owner: team-platform
llm:
  include: true
  pii: none
  chunk_hint: 250-400
  redaction: [email, phone]
entities: []
---

Obiettivo
- Permettere sviluppo economico in locale usando `DB_MODE=mock` con file JSON, mantenendo le stesse API.
- Passaggio zero‑rework a `DB_MODE=sql` con Azure SQL/App Service.

Uso rapido
- `.env.local` esempio:
  - `DB_MODE=mock`
  - `DEFAULT_TENANT_ID=tenant01`
  - `AUTH_ISSUER=https://test-issuer/`
  - `AUTH_AUDIENCE=api://test`
  - `TENANT_CLAIM=ew_tenant_id`
- Genera JWKS+token: `npm run dev:jwt` e imposta `AUTH_TEST_JWKS` in shell.
- Avvia API: `npm run dev` e prova `http://localhost:3000/portal/app`.

Dettagli implementativi
- Repository astratto per utenti/onboarding con due backend:
  - `mock`: `data/dev-users.json` (persistenza file), idempotente.
  - `sql`: query/Stored Procedure su Azure SQL.
- Switch via env `DB_MODE=mock|sql`.

Migrazione a cloud
- Cambia `.env` su App Service: `DB_MODE=sql`, parametri DB/AAD, `AUTH_ISSUER`/`AUTH_JWKS_URI`.
- Le stesse rotte funzionano senza modifiche client.



