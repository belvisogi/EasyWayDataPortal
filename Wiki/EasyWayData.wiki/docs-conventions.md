---
id: docs-conventions
title: EasyWayData Portal - Regole Semplici (La Nostra Bibbia)
summary: Regole per mantenere la Wiki chiara e machine-readable (naming, struttura, link, esempi).
status: active
owner: team-docs
tags: [docs, conventions, governance, domain/docs, layer/reference, audience/dev, privacy/internal, language/it]
llm:
  include: true
  pii: none
  chunk_hint: 300-500
  redaction: [email, phone]
entities: []
updated: '2026-01-05'
next: Aggiornare quando cambiano taxonomy/lint o regole di naming.
---

# EasyWayData Portal - Regole Semplici (La Nostra Bibbia)

Scopo: rendere la Wiki chiara per persone e AI. Regole brevi, esempi chiari, sempre uguali.

## 1) Nomi di file e cartelle
- Per nuovi file/cartelle: solo minuscole ASCII, numeri e trattini `-` (kebab-case).
- Niente spazi, niente caratteri speciali, niente accenti.
- Non mescolare separatori nello stesso path (es. evitare `foo_bar-baz.md`).
- Eccezioni: `_` è ammesso solo in alberi legacy già esistenti o in artefatti tecnici (DB/payload/config), non nei nuovi path Wiki.
- Esempio: `easyway-webapp/02_logiche_easyway/login-flussi-onboarding.md`.

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

### 4.1) Regola per `index.md` (pagine indice)
`index.md` va bene come “indice di cartella”, ma deve essere leggibile e non ambiguo per un agente.

- Tenere il filename `index.md` quando serve un entrypoint standard nella cartella.
- Nel frontmatter:
  - `title` deve essere specifico (kebab-case), non `index`/`Indice`.
  - `summary` deve dire cosa contiene l’indice e per chi è (non “Documento su …”).
  - `tags` deve includere `layer/index` e il `domain/*` corretto.
- Nel contenuto:
  - aggiungere `Breadcrumb:` e una lista link “canonici” (niente auto-link a `./index.md`).
  - se la pagina è operativa (runbook/howto/orchestration/intent), includere `## Domande a cui risponde`.

## 5) Compatibilità Obsidian (lettura)
- Usare YAML frontmatter sempre con terminatore su riga separata: `---` (inizio) e `---` (fine) + una riga vuota prima del contenuto.
- Evitare fence Markdown “rotte”: ogni blocco ``` deve essere chiuso (Obsidian altrimenti evidenzia male e aumenta il rumore).
- Preferire UTF-8; evitare caratteri di controllo/encoding legacy quando si tocca un file.

## 6) Regola di coerenza (DoD)
Ogni modifica significativa deve aggiornare:
- una ricetta KB in `agents/kb/recipes.jsonl`
- almeno una pagina Wiki pertinente
- (se cambia un workflow) manifest + intents in `docs/agentic/templates/`
