---
id: runbook-dual-server-bootstrap
title: Bootstrap Dual Server (Oracle Dev/Staging + Hetzner Prod)
summary: Processo operativo ad alto livello per gestire l'approccio "dual server" e sapere dove recuperare gli artefatti di bootstrap.
owner: team-platform
status: draft
tags: [runbook, ops, infra, language/it]
created: '2026-01-25'
updated: '2026-01-25'

llm:
  pii: none
  redaction: [email, phone]
  include: true
  chunk_hint: 5000
entities: []
---

# Bootstrap Dual Server (Oracle Dev/Staging + Hetzner Prod)

## Obiettivo
Eseguire e ripetere il bootstrap infrastrutturale in modo affidabile, mantenendo chiaro:
- qual e' l'ambiente attuale (Oracle Dev/Staging)
- qual e' il target di produzione (Hetzner Prod)
- dove sono i documenti e gli script di riferimento

## Prerequisiti
- Accesso SSH al server target (Oracle o Hetzner).
- Token Azure DevOps (PAT) disponibile (fuori repo).
- Per automazione da Windows: PowerShell 7+ e `ssh`.

## Processo (alto livello)
1. Identifica l'ambiente
   - Verifica la "server matrix" in `docs/SERVER_BOOTSTRAP_PROTOCOL.md`.
   - Oracle = Dev/Staging corrente; Hetzner = Production futura.
2. Recupera la fonte corretta
   - Oracle: snapshot e quick start in `docs/infra/ORACLE_ENV_DOC.md` e `docs/infra/ORACLE_QUICK_START.md`.
   - Hetzner: guida setup e hardening in `docs/HETZNER_SETUP_GUIDE.md` e `docs/SERVER_BOOTSTRAP_PROTOCOL.md`.
3. Scegli la modalita' di esecuzione
   - Manuale (seguendo i doc sopra).
   - Remota da Windows (ripetibile): usa `scripts/infra/remote/` (vedi sotto).
4. Esegui con safety-first
   - Lancia sempre prima con `-WhatIf` (dry-run) per verificare target/config.
   - Esegui senza `-WhatIf` solo quando la preflight e' verde.
5. Verifica e registra
   - Verifica lo stato dei container e dei symlink runtime.
   - Se Oracle: ruota le credenziali dopo validazione (vedi `docs/infra/ORACLE_ENV_DOC.md`).

## Dove recuperare tutto (single source of truth)

### Documenti
- Standard dual server: `docs/SERVER_BOOTSTRAP_PROTOCOL.md`
- Golden path (server nudo -> nodo EasyWay): `docs/infra/SERVER_BOOTSTRAP_PROTOCOL.md`
- Oracle (snapshot stato): `docs/infra/ORACLE_ENV_DOC.md`
- Oracle (quick start accesso): `docs/infra/ORACLE_QUICK_START.md`
- Hetzner (provisioning): `docs/HETZNER_SETUP_GUIDE.md`

### Automazione remota (Windows)
- Script: `scripts/infra/remote/`
- Guida: `scripts/infra/remote/README.md`
- Config utente (gitignored): copia `scripts/infra/remote/remote.config.example.ps1` in `scripts/infra/remote/remote.config.ps1` e compila IP/Key/PatPath.

## Verifica
- `scripts/infra/remote/monitor_deployment.ps1` (prima con `-WhatIf`, poi reale).
- Conferma che lo stack Docker sia up e che `/opt/easyway/current` punti alla release attesa.

## Rollback
- Se deploy atomico: ripunta il symlink `/opt/easyway/current` alla release precedente e riavvia `docker compose`.
- Se hardening: ripristina configurazioni (SSH/UFW) solo tramite change controllato e tracciato.

## Riferimenti
- `docs/SERVER_BOOTSTRAP_PROTOCOL.md`
- `docs/infra/SERVER_BOOTSTRAP_PROTOCOL.md`
- `scripts/infra/remote/README.md`


