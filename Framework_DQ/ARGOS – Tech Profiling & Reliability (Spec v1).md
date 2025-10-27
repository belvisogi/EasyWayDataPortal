
# ARGOS – Tech Profiling & Reliability (Spec v1)

> **Scopo:** definire la terza «anima» di ARGOS – il **Tech Loop** – focalizzata su **profiling tecnico**, **drift** e **affidabilità IT** (file/table/job). Il loop fornisce segnali oggettivi che alimentano sia il **Fast Loop Operativo** (gating) sia lo **Slow Loop Learning** (miglioramento continuo). Documento agnostico, senza codice.

---

## 1) Perimetro del Tech Loop
- **Profiling dei campi**: distribuzioni, null rate, cardinalità, pattern, outlier, lunghezze.
- **Drift & cambiamento**: schema drift (add/remove/rename/type), distribution drift (PSI/KS/Z), pattern drift.
- **File/Table Health**: size, record count, compression, encoding/delimiter, small‑files, partition completeness/late/skew, dup tra partizioni.
- **Process/Job Health**: durata, throughput (rows/sec), retry, bytes read/written, success rate.

**Output**: profili baseline, eventi di drift, indicatori di salute, **suggerimenti di contratto** e **soglie dinamiche** per policy DQ.

---

## 2) Estensioni LDM (entità e attributi)
### 2.1 RUN_PROFILE_RESULT (per run/field)
`RUN_ID (PK part) · INSTANCE_ID · ELEMENT_ID · PROFILE_TS · EVAL_COUNT · NULL_RATE · DISTINCT_COUNT · DISTINCT_RATE · MIN · MAX · MEAN · STDDEV · P01 · P50 · P95 · P99 · LENGTH_MIN · LENGTH_MAX · TOPK_PATTERNS(JSON) · TOPK_VALUES_HASHED(JSON) · ENTROPY · OUTLIER_RATE · PROFILE_HASH · NOTES`

### 2.2 PROFILE_BASELINE (per instance/field)
`INSTANCE_ID · ELEMENT_ID · BASELINE_WINDOW_START/END · TARGET_P01 · TARGET_P99 · TARGET_NULL_RATE_MAX · DISTINCT_RATE_RANGE · PATTERN_SET(JSON) · DRIFT_TEST(ENUM: PSI|KS|Z|IQR) · UPDATED_AT · OWNER`

### 2.3 PROFILE_DRIFT_EVENT
`EVENT_ID (PK) · RUN_ID · INSTANCE_ID · ELEMENT_ID · DRIFT_TYPE(ENUM: SCHEMA|DISTRIBUTION|PATTERN|VOLUME|SPARSITY) · SEVERITY(LOW|MED|HIGH) · STATISTIC(PSI|KS|Z|IQR|KL) · STAT_VALUE · THRESHOLD · DECISION(INFO|WARN|CRITICAL) · ACTION(OPEN_RCA|NUDGE|PATCH_CONTRACT) · TRACE_REF`

### 2.4 FILE_HEALTH (per file)
`RUN_ID · FLOW_ID · INSTANCE_ID · FILE_PATH · FILE_SIZE_BYTES · RECORD_COUNT · AVG_ROW_SIZE · COMPRESSION_RATIO · ENCODING · DELIMITER · SMALL_FILE_FLAG · HASH_INPUT`

### 2.5 PARTITION_HEALTH (per partizione)
`INSTANCE_ID · PARTITION_KEY · PARTITION_VALUE · EXPECTED(BOOL) · ARRIVED_AT · LATE_FLAG · SKEW_INDEX · DUP_RATE · MISSING_FLAG · SIZE_BYTES · RECORD_COUNT`

### 2.6 PROCESS_METRICS (estensione RUN_TASK_RESULT)
`RUN_ID · TASK_ID · CPU_MS · BYTES_READ · BYTES_WRITTEN · DURATION_MS · ROWS_READ · ROWS_WRITTEN · RETRY_COUNT · STATUS`

> **Privacy:** TOPK_VALUES sono **hash**; nessun PII in chiaro nei profili.

---

## 3) Viste consigliate
- **VW_PROFILE_SUMMARY**: ultimo profilo vs baseline (semaforo e scostamenti).
- **VW_PROFILE_DRIFT**: trend drift per campo/dominio con severità e statistica.
- **VW_FILE_HEALTH**: elenco file per run con small‑files, encoding, compressione e anomalie.
- **VW_PARTITION_HEALTH**: completezza partizioni, lateness, skew e duplicazioni.
- **VW_PROCESS_EFFICIENCY**: rows/sec, retry, success rate, bytes/row.

---

## 4) Quality Gate «Profiling» (soft)
- **Esito**: non blocca di default; genera **WARN** o **DEFER** su drift severo in **campi critici** o su **small‑files rate** elevato. 
- **Integrazione con DQ Gate**: i segnali del Profiling pesano nella **severity dinamica** (➜ `severity_after_weighting`) e nelle decisioni PASS/DEFER/FAIL.
- **Routing**: eventi **CRITICAL** aprono **RCA_CASE** e informano il **Coach/Policy Agent** per patch/tuning.

---

## 5) Suggerimenti automatici (contratti & soglie)
- **Contract Patch**: proposta tipi/domìni/pattern dai **TARGET_P01/P99**, `PATTERN_SET`, `DISTINCT_RATE_RANGE`.
- **Soglie dinamiche**: bound auto‑proposti per regole di formato/valore (es. range numerici, lunghezze, whitelist pattern).
- **Ottimizzazioni tecniche**: compaction small‑files, re‑clustering, partizionamento, indici/bloom, gestione skew.

---

## 6) KPI & SLO IT
- **Schema Stability Index** = eventi drift SCHEMA / periodo.  
- **Profile Drift Rate** = eventi drift DISTRIBUTION/PATTERN / periodo.  
- **Small Files Rate** = file < threshold / totale file (per run/dom.)  
- **Partition Completeness** e **Late Partition Rate**.  
- **Partition Skew Index** (p95/p50 size o records tra partizioni).  
- **Job Success Rate**, **Throughput (rows/sec)**, **Retry Rate**.  
- **Storage Growth** controllata, **Compute Efficiency** (bytes/row, CPU/row).  
- *(opz.)* **Cost per 1M rows** se disponibile.

**SLO indicativi**  
- Schema Stability ≥ 99,5%; Small Files Rate ≤ 5%; Late Partition Rate ≤ 1%; Job Success ≥ 99,9%; Throughput p95 sopra baseline −10%.

---

## 7) Processi
1) **Baseline iniziale** (30 gg di storico) per PROFILE_BASELINE.  
2) **Profiling continuo** ad ogni RUN → RUN_PROFILE_RESULT.  
3) **Drift detection** → PROFILE_DRIFT_EVENT + routing (Alert/Coach/Policy).  
4) **Aggiornamento baseline** mensile con attestation (four‑eyes) e *freeze window* prima dei picchi.  
5) **Feedback loop**: generazione suggerimenti (Contract/Soglie/Playbook) e misurazione impatti.

---

## 8) Alerting & privacy
- **Alert** su drift HIGH, small‑files esplosivi, lateness partizioni, throughput in degrado.  
- **Digest** IT giornaliero (top drift, file/partition health, job health).  
- **Sanitizzazione** obbligatoria per sample/attachments; RBAC su viste IT.

---

## 9) Roadmap di adozione
- **W0/W1**: backfill baseline (30 gg) + attivare VW_PROFILE_SUMMARY/VW_FILE_HEALTH.  
- **W2**: abilitare PROFILE_DRIFT_EVENT + Gate «Profiling» soft su domini pilota.  
- **W3**: collegare Policy/Coach Agent per suggerimenti automatici; compaction small‑files.  
- **W4**: introdurre SLO IT; attivare digest IT; review impatti e promozione in **v1.2**.

---

## 10) Collegamenti
- **Blueprint v1.1 (Dual‑Loop)** — terzo loop **Tech**  
- **Innovation Addendum (v1)** — severity dinamica & decision trace  
- **Policy DSL & Registry** — contract patch & soglie dinamiche  
- **Monitoring & Scorecard** — viste e navigazione  
- **KPI & SLO Handbook / SLO Catalog** — SLO IT

---

## 11) Definition of Done (v1)
- Entità **RUN_PROFILE_RESULT, PROFILE_BASELINE, PROFILE_DRIFT_EVENT, FILE_HEALTH, PARTITION_HEALTH** definite.  
- Viste **PROFILE_SUMMARY, PROFILE_DRIFT, FILE_HEALTH, PARTITION_HEALTH, PROCESS_EFFICIENCY** disponibili.  
- Gate «Profiling» attivo (soft) con routing e privacy OK.  
- KPI/SLO IT minimi misurati su 2 domini pilota; digest IT operativo.
