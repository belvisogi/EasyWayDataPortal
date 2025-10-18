# tests/agentic

Obiettivo: validare che artefatti generati da agenti rispettino le linee guida agentiche.

Checklist minima:
- Idempotenza: riesecuzione DDL/SP senza errori.
- Logging: scrittura su `PORTAL.STATS_EXECUTION_LOG` con campi obbligatori.
- Convenzioni: nomi conformi, presenza variante `_DEBUG` ove richiesto.
- Sicurezza: nessun segreto in chiaro nei file.

Suggerito:
- Integrare un validatore (script) che, dato un JSON (mini‑DSL), verifichi i file SQL generati prima della PR.

