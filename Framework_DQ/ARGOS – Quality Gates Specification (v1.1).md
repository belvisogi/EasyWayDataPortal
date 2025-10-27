
# ARGOS – Quality Gates Specification (v1.1)

> **Scopo:** definire in modo completo e agnostico i **Quality Gates** di ARGOS (esiti, input, matrici decisionali, hysteresis/cool-down, budget mapping, explainability e gestione eccezioni), allineati con Blueprint Dual/Triple-Loop, Policy DSL v1.1 e Event Schema Addendum.

---

## 0) Principi
1) **Outcome standard**: `PASS | DEFER | FAIL` (quarantine è **zona**, non outcome).  
2) **Explainability**: ogni decisione produce una **Decision Trace** (segnali, budget, regole coinvolte, rationale).  
3) **Severity dinamica**: la severità runtime è **pesata** da `IMPACT_SCORE` e consumo di **Error/Noise Budget**.  
4) **Anti-flapping**: *hysteresis/cool-down* per evitare oscillazioni (WARN↔OK, DEFER↔PASS).  
5) **Safe-ops**: **DEFER** preferito a **FAIL** quando l’impatto è basso o esistono **safe-actions**.  
6) **Compatibilità**: i Gates sono **modulari** (M1 Fast-Ops), ma **consumano** segnali di M2/M3 quando disponibili.

---

## 1) Tipi di Gate
- **INGRESS GATE** — *Deterministico*: conformità al **Data Contract** (header, tipi, encoding, delimiter, colonne obbligatorie).  
- **DQ GATE** — *Contenuto*: esiti delle policy (Blocking/Alert) e stato dei **budget** (Error/Noise).  
- **ROLLOUT GATE** — *Change Management*: promozione di nuove `RULE_VERSION` (shadow/canary/A-B) e backout.  
- *(opz.)* **PROFILING GATE (soft)** — segnali di M3 (drift, small files, partition lateness/skew) che influenzano severità o producono DEFER/WARN.

---

## 2) Input minimi (per tutti i Gate)
- **Correlation**: `RUN_ID, INSTANCE_ID, FLOW_ID, DOMAIN_ID, REFERENCE_DATE, RUN_DATE`.  
- **Policy**: elenco `RULE_VERSION` attive e loro **severità base**.  
- **Esiti**: `RUN_RULE_RESULT` con contatori OK/WARN/KO (distinti e deduplicati row-level).  
- **Budget**: `SLO_TARGET`, **Error Budget** residuo, **Noise Budget** residuo.  
- **Impatto**: `IMPACT_SCORE` (0..1) per elemento/istanza/flow.  
- **Profiling (M3)**: `PROFILE_DRIFT_EVENT`, `FILE/PARTITION/PROCESS health` (se attivo).  
- **Esperimenti (M2)**: stato **canary/A-B** (percent, min_runs, success criteria) se attivi.  
- **Override**: deroghe attive (scadenza, approvatore, rischio accettato).

---

## 3) Esiti & semantica
- **PASS**: promozione verso `reference`; notifiche **INFO**.  
- **DEFER**: promozione **differita** in **QUARANTINE** (ri-valutazione programmata); notifiche **WARN**; possibili **safe-actions**.  
- **FAIL**: promozione **bloccata**; notifiche **CRITICAL**; ticket e playbook obbligatori.

---

## 4) Matrici decisionali (logica)
### 4.1 INGRESS GATE (deterministico)
| Condizione | Esito | Note |
|---|---|---|
| Contract **OK** (header/tipi/encoding) | **PASS** | Continue |
| Contract **KO** su **colonne obbligatorie/tipo** | **FAIL** | Blocco diretto |
| Contract **KO** minori (ordine colonne/non-critical, delimiter ambigui) | **DEFER** | Se disponibile **safe-action** (re-parse, normalizza) |
| **Maintenance window** dichiarata | **DEFER** | Quarantine fino a fine finestra |

**Hysteresis Ingress**: se una stessa violazione *minore* persiste per ≥ N run → escalation a **FAIL**.

### 4.2 DQ GATE (contenuto)
**Step di valutazione (ordine):**  
1) **Blocking KO presente?**  
   - Se sì **e** `IMPACT_SCORE ≥ 0.7` → **FAIL**.  
   - Se sì **ma** `IMPACT_SCORE < 0.7` **e** `Error Budget > 0` → **DEFER** (preferire safe-action).  
2) **Noise Budget**: se `Noise Budget ≤ 0` **e** share WARN↑ → irrigidire severità (ALERT→BLOCKING *per elementi ad alto IMPACT*).  
3) **Conformity (Without Warnings)** sotto soglia **critica** (es. < target−Δ)? → **DEFER/FAIL** in base a IMPACT & Error Budget.  
4) **Profiling Gate** (se attivo): `drift HIGH` su campo critico → almeno **DEFER**.  
5) **Hysteresis**: per rientrare da **DEFER/FAIL** richiede 2 run consecutivi **PASS** oppure un **canary** riuscito.

**Tabella di indirizzo (semplificata)**
| Condizioni principali | Outcome |
|---|---|
| ≥1 **BLOCKING KO** su elemento ad **alto IMPACT** | **FAIL** |
| Solo **ALERT** ma **Noise Budget** esaurito | **DEFER** |
| Conformity\_Wo < *critico* (es. −5 p.p. dal target) | **FAIL** |
| Conformity\_Wo < *warning* (es. −2 p.p.) | **DEFER** |
| Profiling drift **HIGH** su campo chiave | **DEFER** |
| Nessuna condizione di cui sopra | **PASS** |

### 4.3 ROLLOUT GATE (change)
| Fase | Condizioni | Outcome |
|---|---|---|
| **Shadow** | nessun effetto su gate | **PASS** (monitor only) |
| **Canary** | `min_runs` raggiunto **e** `success_criteria` (Noise↓, Conformity\_Wo≥baseline, GPR≥baseline) | **PROMOTE→%↑** |
| **A/B** | criterio (p-value o delta KPI) soddisfatto | **PROMOTE** variante vincente |
| **Early stop** | peggioramento netto dei KPI | **BACKOUT** |

---

## 5) Severity dinamica (funzione concettuale)
`severity_at_runtime = f(base_severity, IMPACT_SCORE, error_budget_residuo, noise_budget_residuo, profiling_flags)`

**Esempi di regola**  
- `IMPACT_SCORE ≥ 0.7` **e** `error_budget_residuo ≤ 20%` ⇒ **escalate** severità (ALERT → BLOCKING).  
- `IMPACT_SCORE ≤ 0.3` **e** `noise_budget_residuo ≤ 0%` ⇒ **de-escalate** (ALERT_WITHOUT_DISCARD; DEFER invece di FAIL).  
- `profiling.drift = HIGH` su *field critico* ⇒ minimo **DEFER** anche senza KO.

---

## 6) Hysteresis & Cool-down
- **Hysteresis WARN**: una regola torna a `OK` solo se `WARN` sotto soglia per **K run** consecutivi (default K=2).  
- **Gate state**: transizione `DEFER → PASS` richiede **2 PASS** di fila o canary riuscito; `FAIL → PASS` richiede **1 PASS** + **ticket chiuso**.  
- **Cool-down tuning**: dopo un **tuning** (soglia/mostly) bloccare nuovi tuning per **X giorni** (default 7).  
- **Quiet hours**: canali di alert compressi/differiti in finestre definite.

---

## 7) Override & Backout
- **Override**: eccezione temporale con *risk acceptance* (owner, scadenza, ambito). Mostrata in scorecard, rinnovabile solo con approvazione **four-eyes**.  
- **Backout**: piano pre-scritto per ripristinare policy/gate precedenti (obbligatorio per **MAJOR**).  
- **Audit**: override/backout sono **eventi** nel Registry + nota in **Decision Trace**.

---

## 8) Decision Trace (contenuto minimo)
- `DECISION_TRACE_ID`, `gate_type`, `outcome`, `reason_code`, `signals_json` (estratti linter/kpi/drift), `policy_version_set`, `budget_before/after`, `severity_after_weighting`, `override_ref?`, `experiment_ref?`, `created_at`, `actor` (agent/human).  
- Emissione evento: **`argos.gate.decision`** (vedi Addendum Eventi).

---

## 9) Quarantine & re-processing
- **Quarantine**: area logica con **TTL** (default 72h) e **policy di retention**; dataset **non** visibile ai consumer.  
- **Re-processing**: trigger manuale/programmato; correlare `PARENT_RUN_ID`.  
- **Safe-actions**: abilitate solo se `AUTO_SAFE` nel playbook e **IMPACT basso** + budget ok.

---

## 10) Edge cases
- **Backfill massivo**: sospendere SLO e applicare modalità *relaxed*; KPI separati.  
- **Late partitions**: marcate in **PARTITION_HEALTH**; possono causare **DEFER**.  
- **Re-run idempotente**: riconosciuto via `HASH_INPUT` + `PARENT_RUN_ID`; non duplica conteggi.

---

## 11) KPI dei Gates
- **GPR (Gate Pass Rate)** per tipo di gate.  
- **Blocking Rate** e **False PASS sample rate** (campionamento manuale).  
- **Quarantine Dwell Time**.  
- **Decision Trace coverage** (≥ 99%).  
- **Override/backout rate**.  
- **Time-to-decision p95**.

---

## 12) Collegamenti
- **Policy DSL & Registry v1.1** — severità base, IMPACT/Noise, probabilistic rules.  
- **Event Schema Addendum v1** — `argos.gate.decision`.  
- **KPI Book (Logiche)** — Conformity, GPR, Noise.  
- **Tech Profiling & Reliability (Spec v1)** — segnali M3.  
- **Operating Guide** — runbook e template notifiche.

---

## 13) Definition of Done (v1.1)
- Matrici decisionali definite per **Ingress/DQ/Rollout** (+ Profiling soft).  
- **Hysteresis/cool-down** introdotti e parametrizzati.  
- **Severity dinamica** formalizzata.  
- **Decision Trace** attivo e inviato come evento.  
- Procedure di **override/backout** documentate.  
- KPI e edge cases elencati, con collegamenti ai documenti correlati.
