# out/ (local artifacts)

Questa cartella contiene **artefatti generati localmente** (o in CI) dagli agent/script: intent generati, summary JSON, report, blueprint, runlog.

Regola: il **canonico** resta nel repo (es. `db/flyway/sql/`, `Wiki/EasyWayData.wiki/`); `out/` serve solo per esecuzioni e debug.

Esempi:
- Intent generato da sheet: `out/intents/intent.db-table-create.generated.json`
- Summary generazione tabella: `out/db/db-table-create.<schema>.<table>.json`
