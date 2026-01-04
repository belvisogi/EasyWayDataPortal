# Governance Gates via ewctl (ibrido)

Obiettivo
- Uniformare esecuzione dei gate (Checklist/DB Drift/KB Consistency) tra locale e CI usando `ewctl`, mantenendo un fallback agli step espliciti.

Toggle pipeline
- Variabile: `USE_EWCTL_GATES=true|false` (default `false`)
  - `true`: esegue job `GovernanceGatesEWCTL` che lancia `ewctl` con PS engine e `--logevent`.
  - `false`: usa i job esistenti `PreDeployChecklist`, `KBConsistency`, `DBDriftCheck` e il job `ActivityLog` per il logging.

Comandi usati da ewctl (PS engine)
- `pwsh scripts/ewctl.ps1 --engine ps --checklist --dbdrift --kbconsistency --noninteractive --logevent`
  - Esegue: Checklist (API), DB Drift, KB Consistency
  - Registra evento strutturato (JSONL) e aggiorna `Wiki/EasyWayData.wiki/activity-log.md`

Altre variabili utili
- `ENABLE_CHECKLIST`, `ENABLE_DB_DRIFT`, `ENABLE_KB_CONSISTENCY` (continuano a valere per i job legacy)
- `ENABLE_ORCHESTRATOR`, `ORCHESTRATOR_INTENT` per il job di pianificazione TS

Uso locale
- Stessi gate: `pwsh scripts/ewctl.ps1 --engine ps --checklist --dbdrift --kbconsistency --noninteractive --logevent`
- Solo piano: `pwsh scripts/ewctl.ps1 --engine ts --intent governance-predeploy`

Guardrail: EnforcerCheck (PR required)
- Perché: Serve a bloccare azioni fuori scope in modo automatico e precoce. Verifica che i file toccati rientrino negli `allowed_paths` dell’agente responsabile.
- Cosa fa: esegue `scripts/enforcer.ps1` su `git diff` per gli agenti chiave (`agent_governance`, `agent_docs_review`, `agent_pr_manager`). Fallisce il job su violazioni.
- Posizione in pipeline: stage iniziale `PreChecks` → job `EnforcerCheck` (prima di build/test/gates).
- Come renderlo obbligatorio: in Branch Policies di Azure Repos, aggiungere il job `EnforcerCheck` come `required` per PR verso `develop`/`main`.
- Benefici: fail early in PR, coerenza con manifest, riduce rischio operativo, audit chiaro su violazioni.

Verifica in branch non-main
- Prerequisiti: `USE_EWCTL_GATES=true`, Variable Group collegato (EasyWay-Secrets), Node installato via job `NodeBuild`.
- Passi:
  - Crea una branch (es. `ci-verify-ewctl`), push e avvia la pipeline.
  - Attendi il job `GovernanceGatesEWCTL` e verifica che esegua `ewctl` con `--logevent`.
  - Controlla gli artifact pubblicati: `activity-log` (contenente `agents/logs/*.jsonl`), eventuali `checklist.json`/`drift.json`, e `gates-report`.
- Esito atteso:
  - Log evento aggiunto a `agents/logs/events.jsonl` e, se configurato, aggiornamento Wiki/EasyWayData.wiki/activity-log.md.
  - Gate checklist/drift OK o diagnostica chiara in caso di KO.
- Troubleshooting:
  - Se mancano variabili DB, il drift/checklist può fallire: verificare Variable Group e `.env.local` in locale.
  - Se il job non parte, confermare `USE_EWCTL_GATES=true` e dipendenze da `NodeBuild` soddisfatte.

Strategia Flyway consigliata
- `FlywayValidateAny` (sempre): esegue `flyway validate` su tutte le branch quando `FLYWAY_ENABLED=true`.
- `FlywayMigrateDevelop` (solo develop): esegue `flyway migrate` sulla branch `develop`.
- `DBProd` stage (solo main, con approvazioni): deployment job `FlywayMigrateMain` su environment `prod` con `validate + migrate`. Condizioni: branch `main`, `FLYWAY_ENABLED=true`, `GOV_APPROVED=true`. Configurare le approvazioni nell'Environment `prod` in Azure DevOps.

Note
- Il job `GovernanceGatesEWCTL` dipende da `NodeBuild` per garantire `node_modules` disponibili (ts-node usato nei tool TypeScript).
- Se necessario, disabilita completamente i gate impostando i rispettivi `ENABLE_*` a `false`.


