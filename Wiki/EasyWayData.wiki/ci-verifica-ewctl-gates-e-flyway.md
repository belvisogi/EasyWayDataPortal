---
title: Verifica CI – ewctl gates e Flyway (branch non-main)
tags: [ci, gates, ewctl, flyway, domain/control-plane, layer/gate, audience/dev, audience/ops, privacy/internal, language/it]
status: active
id: ew-ci-verifica-ewctl-gates-e-flyway
summary: Runbook per verificare su branch non-main che i governance gates via ewctl e gli stage Flyway producano gli artifact attesi e logghino correttamente.
owner: team-platform
llm:
  include: true
  pii: none
  chunk_hint: 250-400
  redaction: [email, phone]
entities: []
updated: '2026-01-05'
next: TODO - definire next step.
---

[[start-here|Home]] > [[Domain - Control-Plane|Control-Plane]] > [[Layer - Gate|Gate]]

Obiettivo
- Verificare che i governance gates via `ewctl` e lo stage DB/Flyway funzionino su una branch non-main, con logging e artifact attesi.

Prerequisiti
- Pipeline aggiornata con `USE_EWCTL_GATES=true` e `FLYWAY_ENABLED=true` (vedi `azure-pipelines.yml`).
- Variable Group collegato (es. `EasyWay-Secrets`) con `FLYWAY_URL`, `FLYWAY_USER`, `FLYWAY_PASSWORD`.
- Job `NodeBuild` abilitato per tool Node richiesti dai gates.

Procedura
1) Crea una branch, ad es. `ci-verify-ewctl`, e fai push.
2) Avvia manualmente la pipeline su questa branch in Azure DevOps.
3) Attendi i job:
   - `GovernanceGatesEWCTL` (Checklist/DB Drift/KB Consistency via `ewctl --logevent`).
   - `FlywayValidateAny` (validate) su tutte le branch; `FlywayMigrateDevelop` (migrate) solo su `develop`.
4) Verifica artifact pubblicati:
   - `activity-log`: contiene `agents/logs/events.jsonl` aggiornato.
   - `gates-report`: contiene `gates-report.json` con stato dei gates.
   - (se generati) `db-drift` con `drift.json` e `checklist.json` in `workingDirectory`.

Esito atteso
- `GovernanceGatesEWCTL` completa con esito OK o fornisce diagnostica chiara.
- `FlywayValidateAny` esegue `validate` senza errori su tutte le branch.
- `FlywayMigrateDevelop` esegue `migrate` senza errori su `develop`.
- Artifact `activity-log` e `gates-report` pubblicati e coerenti.

Main con approvazioni (opzionale)
- Su branch `main`, la migrazione prod avviene nello stage `DBProd` (deployment job `FlywayMigrateMain`) legato all'environment `prod` con approvazioni.
- Condizioni: `FLYWAY_ENABLED=true` e `GOV_APPROVED=true`. Configurare le approvazioni nell'Environment `prod` in Azure DevOps.

Troubleshooting
- Variabili mancanti per Flyway: assicurarsi che `FLYWAY_URL`, `FLYWAY_USER`, `FLYWAY_PASSWORD` siano nel Variable Group collegato alla pipeline.
- Job `GovernanceGatesEWCTL` non avviato: verificare `USE_EWCTL_GATES=true` e dipendenza da `NodeBuild`.
- Drift/Checklist falliscono: controllare `.env.local` in locale e la configurazione di connessione DB per l’API.

Riferimenti
- `azure-pipelines.yml`
- `docs/ci/ewctl-gates.md`
- `agents/kb/recipes.jsonl` (ricetta `ci-verify-ewctl-flyway`)






## Vedi anche

- [ADO – Segnare un job come Required nelle PR](./checklist-ado-required-job.md)
- [Validazione Output Agenti in CI](./agent-output-validation-ci.md)
- [Multi‑Agent & Governance – EasyWay](./agents-governance.md)
- [Doc Alignment Gate](./doc-alignment-gate.md)
- [EnforcerCheck – Guardrail allowed_paths in CI](./enforcer-guardrail.md)


