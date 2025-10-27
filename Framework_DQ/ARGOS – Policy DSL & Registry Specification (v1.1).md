
# ARGOS – Policy DSL & Registry Specification (v1.1)

> **Scopo:** definire un **linguaggio di policy** agnostico (DSL) e il **Registry** che governa ciclo di vita, versioning e promozione delle regole di data quality di ARGOS. Allineato a: **Quality Gates v1.1**, **Event Schema Addendum v1**, **KPI & SLO Handbook**, **Tech Profiling** e **Modular Interop**.

---

## 0) Principi
1) **Chiarezza vs potenza**: la DSL copre l’80% dei casi reali (completezza, formato, dominio, referenziale, freschezza, unicità, consistenza, probabilistiche) con costrutti semplici.  
2) **Deterministico + Probabilistico**: accanto alle regole “hard” esistono controlli *soft* (drift, densità, co‑occorrenze) con **MOSTLY** e finestre temporali.  
3) **Severity base** distinta dalla **severity dinamica** (calcolata a runtime dai Gates, pesata da IMPACT & Budget).  
4) **Explainability** by‑design: ogni policy supporta `EXPLAIN_TRACE_REQUIRED` e campioni sanificati.  
5) **Compatibilità & versioning**: semver coerente con **Change & Versioning**; MAJOR richiede dual‑read/dual‑write e viste di compatibilità.  
6) **Privacy‑first**: nessuna PII in definizione; esempi/valori in chiaro proibiti nel Registry; solo pattern/hash.

---

## 1) Oggetto *Policy* (schema logico)
**Chiavi e meta**  
- `RULE_ID` (snake_case; namespace dominio), `RULE_VERSION` (semver), `TITLE`, `DESCRIPTION`, `CATEGORY (FORMAT|DOMAIN|COMPLETENESS|FRESHNESS|UNIQUENESS|REFERENTIAL|CONSISTENCY|PROBABILISTIC)`, `OWNER`, `RISK_LEVEL (LOW|MED|HIGH)`, `TAGS[]`.

**Scope & grana**  
- `SCOPE` = `DOMAIN|FLOW|INSTANCE|ELEMENT` (minimo **INSTANCE**, opzionale **ELEMENT**).  
- `ELEMENT_REF` (lista) quando `SCOPE=ELEMENT`.  
- `ROW_KEY` (per dedup a riga; opzionale).  
- `WHERE` (filtro logico su condizioni/partizioni, p.es. `country in ['IT','ES']`).

**Valutazione**  
- `POLICY_TYPE` = `DETERMINISTIC | PROBABILISTIC`.  
- `CHECK` (dichiarativo; vedi §2).  
- `MOSTLY` ∈ [0..1] (quota minima accettata; default 1.0 per deterministic).  
- `WINDOW` (rolling es. `7d|30d`) per probabilistiche.  
- `SEVERITY_BASE` = `BLOCKING | ALERT_WITH_DISCARD | ALERT_WITHOUT_DISCARD`.  
- `DISCARD_MODE` = `ROW|FILE|NONE` (solo se ALERT/Blocking richiede scarto).  
- `IMPACT_SCORE` ∈ [0..1] (peso business);  `NOISE_BUDGET_HINT` (soglia WARN suggerita).  
- `EXPLAIN_TRACE_REQUIRED` (BOOL).

**Esecuzione & output**  
- `SAMPLE_SIZE_MAX` (righe invalid da allegare; sanificate).  
- `INVALID_ROWS_PATH` (template percorso; gestito da Run Hub).  
- `METRICS_HINT` (KPI attesi: p.es. `Conformity_Wo target`).

**Governance**  
- `STATE` = `DRAFT|PROPOSED|APPROVED|DEPRECATED|RETIRED`.  
- `CHANGE_TYPE` all’ultima modifica = `PATCH|MINOR|MAJOR` (coerente con semver).  
- `ADR_REF`, `SECURITY_REVIEW_REF` (link).  
- `EXPERIMENT` (se attivo): `type (CANARY|AB)`, `min_runs`, `success_criteria`, `backout_plan_ref`.

---

## 2) Sezione `CHECK` (costrutti DSL)
### 2.1 Deterministiche (esempi concettuali)
- **FORMAT**: `element matches /regex/` · `type is DECIMAL(10,2)` · `length between 8..20`  
- **DOMAIN**: `element in {allowed_values}` · `element not in {blacklist}`  
- **COMPLETENESS**: `element is not null` · `at least {k} of {e1,e2,e3} not null`  
- **FRESHNESS**: `load_timestamp - reference_timestamp <= 24h`  
- **UNIQUENESS**: `unique key (customer_id, reference_date)`  
- **REFERENTIAL**: `element fk -> master.customer(customer_id)` (join condizione + filtro validità)  
- **CONSISTENCY**: `if channel='B2B' then customer_type in {'ORG','ENT'}`.

### 2.2 Probabilistiche (soft)
- **DISTRIBUTION DRIFT**: `psi(element) <= 0.25 over WINDOW=30d`  
- **SHAPE/VOLUME**: `row_count within [p01..p99] over WINDOW=30d`  
- **PATTERN DRIFT**: `share(pattern=/^IT[0-9]{2}.+/) >= 0.98 over 14d`  
- **CO‑OCCURRENCE**: `confidence( feature_A ⇒ feature_B ) >= 0.995 over 30d`.

> Le probabilistiche usano **MOSTLY** (tasso di run in finestra compliant) oltre a test statistici; severità base tipicamente `ALERT_*`.

---

## 3) Esempi di definizione (formato descrittivo)
### 3.1 Deterministica – Dominio valori
```
RULE_ID: R_DOM_CUSTOMER
RULE_VERSION: 2.1.0
TITLE: Customer ID must belong to allowed domain
CATEGORY: DOMAIN
SCOPE: ELEMENT
ELEMENT_REF: [customer_id]
POLICY_TYPE: DETERMINISTIC
CHECK: element in {ALLOWED_CUSTOMER_IDS}
MOSTLY: 1.0
SEVERITY_BASE: ALERT_WITH_DISCARD
DISCARD_MODE: ROW
IMPACT_SCORE: 0.8
NOISE_BUDGET_HINT: 0.02
EXPLAIN_TRACE_REQUIRED: true
WHERE: country in ['IT','ES']
STATE: APPROVED
```

### 3.2 Probabilistica – Drift distribuzionale
```
RULE_ID: R_DRIFT_AMOUNT
RULE_VERSION: 1.0.0
TITLE: Amount distribution PSI <= 0.25 on 30d
CATEGORY: PROBABILISTIC
SCOPE: ELEMENT
ELEMENT_REF: [amount]
POLICY_TYPE: PROBABILISTIC
CHECK: psi(element) <= 0.25 over WINDOW=30d
MOSTLY: 0.9
SEVERITY_BASE: ALERT_WITHOUT_DISCARD
IMPACT_SCORE: 0.6
EXPLAIN_TRACE_REQUIRED: false
STATE: PROPOSED
EXPERIMENT:
  type: CANARY
  min_runs: 6
  success_criteria:
    noise_reduction_pct: ">=10"
    conformity_wo_delta: ">=0"
  backout_plan_ref: ADR-042-rollback
```

---

## 4) Linter & pre‑check
- Naming/stile; Efficacy/Noise/Flapping; Performance/costi; Privacy (no PII nei valori).  
- `LINTER_RESULT` consumato dal Gate **INGRESS** e pubblicazione nel Registry.

---

## 5) Registry (stati, workflow, versioning)
- **Stati**: `DRAFT→PROPOSED→APPROVED→DEPRECATED→RETIRED`; four‑eyes & ADR.  
- **Versioning**: PATCH (meta), MINOR (tuning/additivo), MAJOR (semantica/severità).  
- **Policy Set**: gruppo coerente di `RULE_VERSION` per ambito (dominio/flow/istanza).

---

## 6) Integrazioni
- **Gates**: consumano meta per **severity dinamica** e **Decision Trace**.  
- **Tech Profiling**: suggerisce probabilistiche & soglie dinamiche.  
- **Biz‑Learning**: genera `argos.policy.proposal` (canary/A‑B).

---

## 7) Eventi & audit
- Emit su proposta/promozione; changelog Registry; link nelle **Decision Trace**.

---

## 8) Enum
`CATEGORY, POLICY_TYPE, SEVERITY_BASE, DISCARD_MODE, STATE` come definiti.

---

## 9) DoD (v1.1)
- Schema Policy completo + linter; workflow & semver documentati; integrazioni; esempi; privacy ok.
