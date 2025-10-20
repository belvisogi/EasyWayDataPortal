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
  - Registra evento strutturato (JSONL) e aggiorna `Wiki/EasyWayData.wiki/ACTIVITY_LOG.md`

Altre variabili utili
- `ENABLE_CHECKLIST`, `ENABLE_DB_DRIFT`, `ENABLE_KB_CONSISTENCY` (continuano a valere per i job legacy)
- `ENABLE_ORCHESTRATOR`, `ORCHESTRATOR_INTENT` per il job di pianificazione TS

Uso locale
- Stessi gate: `pwsh scripts/ewctl.ps1 --engine ps --checklist --dbdrift --kbconsistency --noninteractive --logevent`
- Solo piano: `pwsh scripts/ewctl.ps1 --engine ts --intent governance-predeploy`

Note
- Il job `GovernanceGatesEWCTL` dipende da `NodeBuild` per garantire `node_modules` disponibili (ts-node usato nei tool TypeScript).
- Se necessario, disabilita completamente i gate impostando i rispettivi `ENABLE_*` a `false`.
