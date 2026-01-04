---
title: Metodo di Lavoro Agent‑First
summary: Regole operative chiare per umani e agenti. Come si lavora in EasyWayDataPortal (intenti, manifest, ewctl, KB/Wiki, gates).
tags: [agents, governance, onboarding, domain/control-plane, layer/spec, audience/dev, privacy/internal, language/it]
id: ew-agent-first-method
status: draft
owner: team-platform
llm:
  include: true
  pii: none
  chunk_hint: 250-400
  redaction: [email, phone]
entities: []
---

# Metodo di Lavoro (Agent‑First)
Breadcrumb: Home / Metodo Agent‑First

Obiettivo
- Rendere il progetto comprensibile e azionabile da subito per stagisti, contributor e agenti (es. Cursor), senza spiegazioni esterne.

Principi
- Intent‑first: ogni attività nasce da un input JSON (mini‑DSL). Vedi “Contratto Intent”.
- Manifest per agenti: ogni agente dichiara azioni e `allowed_paths` in `agents/<agent>/manifest.json`.
- Convergenza codice ↔ KB ↔ Wiki: ogni modifica aggiorna ricetta KB e pagina Wiki.
- Gates CI/CD: Checklist, DB Drift, KB Consistency. Eventi loggati.
- Dual‑mode: locale a costo zero (mock), cloud pronto (sql/kv) via env.
- WhatIf-by-default: le azioni pericolose eseguono pre‑check e stato "a secco" prima di applicare; l’esecuzione reale richiede rimuovere esplicitamente WhatIf.

Strumenti
- Orchestrazione: `scripts/ewctl.ps1 --engine ps|ts` (entrypoint unico)
- Obiettivi/vision: `agents/goals.json`
- Ricette KB: `agents/kb/recipes.jsonl`
- Log eventi: `agents/logs/events.jsonl`

Definizione di Fatto (DoD, agent‑aware)
- KB aggiornata (almeno una ricetta) + Wiki aggiornata (pagina pertinente)
- Gates verdi (Checklist/DB Drift/KB Consistency) in pipeline
- Evento log con esito e metadati

Dual‑Mode (due rubinetti)
- Locale: `DB_MODE=mock`, token dev con `npm run dev:jwt` (AUTH_TEST_JWKS), branding da file
- Cloud: `DB_MODE=sql`, Auth Entra ID, Key Vault, Storage Blob per branding/queries
  - Dettagli: `dev-dual-mode.md`

Come creare/estendere una sezione
1) Aggiungi/aggiorna codice e template (SQL/YAML)
2) Aggiungi manifest dell’agente di sezione con azioni idempotenti
3) Scrivi la ricetta KB (intent, passi, verify)
4) Aggiorna/crea pagina Wiki pertinente
5) Verifica gates (ewctl o pipeline)

Per nuovi tool/agent (es. Cursor)
- Leggi `AGENTS.md`, questa pagina e la “Contratto Intent”
- Usa `scripts/ewctl.ps1` come front‑door
- Rispetta `allowed_paths` dei manifest
- Scrivi output strutturato (JSON) e aggiorna KB/Wiki insieme al codice

Riferimenti
- `AGENTS.md` (root)
- `dev-dual-mode.md` (locale vs cloud)
- `intent-contract.md` (schema input azioni)
 - `output-contract.md` (struttura JSON degli output)

## Best practice per le Ricette KB
- Ogni ricetta includa un campo `example_output` con lo stato atteso (almeno `stateBefore` in WhatIf), così agenti e umani vedono subito l’esito tipico.
- Indicare chiaramente prerequisiti, passi, verify, e link alla pagina Wiki di approfondimento.

## Badges & Guardrail
- WhatIf‑Ready: l’azione implementa pre‑check a secco e mostra `stateBefore` (e `stateAfter` dopo l’applicazione). È la modalità predefinita consigliata.
- Guardrail: gli agenti devono anticipare gli errori (validazioni, limiti, anteprime), riducendo i rischi prima di eseguire modifiche.






