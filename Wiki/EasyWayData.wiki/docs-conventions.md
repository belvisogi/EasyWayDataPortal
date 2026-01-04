---
id: docs-conventions
title: EasyWayData Portal - Regole Semplici (La Nostra Bibbia)
summary: Regole per mantenere la Wiki chiara e machine-readable (naming, struttura, link, esempi).
status: draft
owner: team-docs
tags: [docs, conventions, governance, domain/docs, layer/reference, audience/dev, privacy/internal, language/it]
llm:
  include: true
  pii: none
  chunk_hint: 300-500
  redaction: [email, phone]
entities: []
---

# EasyWayData Portal - Regole Semplici (La Nostra Bibbia)

Scopo: rendere la Wiki chiara per persone e AI. Regole brevi, esempi chiari, sempre uguali.

## 1) Nomi di file e cartelle
- Solo minuscole ASCII, numeri e trattini `-`.
- Niente spazi, niente caratteri speciali, niente accenti.
- Convenzione: `kebab-case` (es: `easyway-webapp/02_logiche_easyway/login-flussi-onboarding.md`).

## 2) kebab-case vs snake_case
Regola: il canonico lato doc/UI è `kebab-case`; i derivati sono meccanici per il dominio tecnico.

- Canonico (slug/tag): `kebab-case` es. `user-profile-settings`
- DB/payload: `snake_case` es. `user_profile_settings`
- Classi/DTO: `PascalCase` es. `UserProfileSettings`
- Variabili JS: `camelCase` es. `userProfileSettings`

### 2.1) Quando usare kebab-case
- URL / routing web: `/dashboard/data-quality-report`
- Cartelle e file frontend: `user-dashboard/summary-view.tsx`
- Tag semantici / ontologie AI: `ai-data-quality`

### 2.2) Quando usare snake_case
- Database (SQL Server): `user_profile_id`, `created_at`
- JSON/CSV (payload e file): `{ "user_id": 1001 }`
- Chiavi configurazione/metadati: `portal_schema_name`

## 3) Quick check (regex)
```text
# Slug (senza estensione)
kebab-case: ^[a-z0-9]+(?:-[a-z0-9]+)*$
snake_case: ^[a-z0-9]+(?:_[a-z0-9]+)*$

# File .md
kebab-case file .md: ^[a-z0-9]+(?:-[a-z0-9]+)*\.md$
snake_case file .md: ^[a-z0-9]+(?:_[a-z0-9]+)*\.md$

# File con estensioni permesse
kebab-case: ^[a-z0-9]+(?:-[a-z0-9]+)*\.(?:md|yml|yaml|json|sql|ps1)$
snake_case: ^[a-z0-9]+(?:_[a-z0-9]+)*\.(?:md|yml|yaml|json|sql|ps1)$
```

## 4) Link e percorsi
- Nei documenti usare backtick per i path reali del repo.
- Per file generati/artifact, dichiarare chiaramente dove vengono prodotti (CI, `out/`, `logs/`).

## 5) Regola di coerenza (DoD)
Ogni modifica significativa deve aggiornare:
- una ricetta KB in `agents/kb/recipes.jsonl`
- almeno una pagina Wiki pertinente
- (se cambia un workflow) manifest + intents in `docs/agentic/templates/`







