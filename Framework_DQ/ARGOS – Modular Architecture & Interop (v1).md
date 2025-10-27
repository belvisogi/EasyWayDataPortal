
# ARGOS – Modular Architecture & Interop (v1)

> **Scopo:** definire ARGOS come **3 moduli autonomi** ma **correlabili**:  
> **M1 Fast‑Ops (Gating)** · **M2 Biz‑Learning (Producer & Coaching)** · **M3 Tech‑Profiling (IT Health)**.  
> Ogni modulo può vivere **di vita propria** e attivarsi **a gradini**, ma condivide un **strato di correlazione** comune.

---

## 0) Principi di modularità
1. **Indipendenza**: ciascun modulo ha storage, SLO, RACI e release cycle propri.  
2. **Interoperabilità by‑design**: scambio tramite **eventi** e **chiavi canoniche**, non tramite coupling diretto.  
3. **Opt‑in progressivo**: si può adottare M1→M3→M2 (o altri ordini) senza refactoring.  
4. **Explainability & audit**: ogni decisione/gate/nudge lascia una **trace** correlabile.  
5. **Privacy‑first**: PII solo dove strettamente necessario; nei profili valori **hash** o sanificati.

---

## 1) I tre moduli
### M1 – Fast‑Ops (Gating)
**Scopo**: enforcement immediato di contratti/policy con esiti `PASS/DEFER/FAIL`.  
**Input**: Linter, Rule results, SLO/Noise Budget, Impact.  
**Output**: `QUALITY_GATE_DECISION`, invalid rows ZIP, ticket/playbook, **DECISION_TRACE**.  
**SLO**: *DQ Gate decision latency p95* ≤ 5m; *False PASS* ≤ X%; *Alert Dedup Ratio* ≥ Y%.

### M2 – Biz‑Learning (Producer & Coaching)
**Scopo**: analisi post‑run, attribuzione errori a **PRODUCER**, nudges, tuning policy/contratti.  
**Input**: Producer League, Error Concentration, Noise Usage, RCA backlog.  
**Output**: **NUDGE**, `POLICY_CHANGE (proposal)`, `CONTRACT_CHANGE (proposal)`, watchlist.  
**SLO**: *Time‑to‑Nudge p95* ≤ 24h; *Δ Noise (30d)* ≤ −20%; *Adoption rate* ≥ 60%.

### M3 – Tech‑Profiling (IT Health)
**Scopo**: profilare dati e job (distribuzioni, drift, file/partition/process health).  
**Input**: RUN_PROFILE_RESULT, FILE/PARTITION/PROCESS metrics.  
**Output**: PROFILE_BASELINE, PROFILE_DRIFT_EVENT, suggerimenti **contract/soglie**, digest IT.  
**SLO**: *Schema Stability* ≥ 99,5%; *Small Files Rate* ≤ 5%; *Job Success* ≥ 99,9%.

---

## 2) Strato di correlazione comune (**Correlation Fabric**)
**Entità/chiavi canoniche**  
- `RUN_ID`, `INSTANCE_ID`, `FLOW_ID`, `DOMAIN_ID`, `RULE_VERSION_ID`, `PRODUCER_ID`, `DECISION_TRACE_ID`.

**Temporali (role dates)**  
- `RUN_DATE`, `REFERENCE_DATE`, `LOAD_DATE` (tutti i moduli le usano in modo consistente).

**Eventi canonici (pub/sub)**  
- `argos.run.completed` (M1 emette) – payload: run & counters.  
- `argos.gate.decision` (M1 emette) – esito + `DECISION_TRACE_ID`.  
- `argos.profile.drift` (M3 emette) – tipo/severità/element.  
- `argos.coach.nudge.sent` (M2 emette) – destinatario/causa/trace.  
- `argos.policy.proposal` (M2 emette) – tuning/canary.  
- `argos.contract.proposal` (M2 emette) – patch additive.  
- `argos.ticket.opened` (M1/M2 emettono) – link a evidenze.  
> Ogni evento include: **correlation keys**, **role date**, **security scope**, **retention hint**.

**Tabelle/viste condivise**  
- **Run Hub** (read‑only per M2/M3) – fonte di verità dei run/esiti.  
- **Registry** (read‑only per M2/M3) – stato policy/soglie, SLO/Noise Budget.

---

## 3) Boundary & contratti
**Storage**  
- M1: Run Hub + Gate Decisions + Invalid Artifacts.  
- M2: NUDGE/RCA/Proposals + viste analitiche.  
- M3: Profile/Baseline/Drift + File/Partition/Process Health.

**Interfacce**  
- **Read contracts**: M2 legge M1 (Run Hub/Decisions); M1 legge M3 (drift) solo via eventi o viste.  
- **Write isolation**: ogni modulo scrive *solo* nel proprio storage.  
- **Versioning**: semver per schema eventi e viste; **compatibilità forward** prioritaria.

---

## 4) Packaging & deployment
**Modalità**  
- **Solo M1**: enforcement minimale → adotta Run Hub + Gates.  
- **M1+M3**: enforcement + profili/drift senza coaching.  
- **M1+M2**: enforcement + miglioramento produttori (senza profili IT).  
- **Full (M1+M2+M3)**: massima efficacia.

**Feature flags**  
- `enable_dynamic_severity`, `enable_decision_trace`, `enable_coach_autopilot`, `enable_profiling_gate_soft`.

**NFR**  
- **Latency budget**: M1 online; M2/M3 asincroni (eventual consistency ≤ 24h).  
- **Backpressure**: coda eventi con retry e DLQ.  
- **RBAC & privacy**: PII segregate; profili sanificati (hash/sampling sicuro).

---

## 5) Correlabilità «senza lock‑in»
- **TRACE propagation**: `DECISION_TRACE_ID` collega gate→nudges→RCA.  
- **Impact map**: `IMPACT_SCORE` disponibile a tutti i moduli come metadato.  
- **Role dates** allineate per confronti coerenti.  
- **Audit immutabile** per eventi chiave (gate, drift, nudge).

---

## 6) RACI sintetico per modulo
- **M1**: A/R Gatekeeper & Ops; C Product/Steward; I Governance.  
- **M2**: A/R Coach & Steward; C DQ Engineer; I Product/Governance.  
- **M3**: A/R Platform/IT Ops; C Data Architect; I Governance.

---

## 7) Roadmap di attivazione modulare
1) **Baseline**: attiva M1 (Run Hub + Gates).  
2) **Profiling**: aggiungi M3 (profile & drift) per generare soglie dinamiche e IT health.  
3) **Coaching**: innesta M2 (nudges/proposals) con eventi M1/M3.  
4) **Full**: abilita feature flags (severity dinamica, decision trace, coach autopilot) → promozione **v1.2**.

---

## 8) Definition of Done (v1)
- Eventi canonici definiti e documentati.  
- Correlation keys standard adottate in tutti i moduli.  
- RBAC & privacy policy per ogni modulo.  
- Demo end‑to‑end: M3 emette drift → M1 irrigidisce gate → M2 invia nudge con trace unico.

---

## 9) Perché i moduli sono **validi** (Razionale & ROI)
**Sintesi**: l’architettura modulare (M1 Fast‑Ops · M2 Biz‑Learning · M3 Tech‑Profiling) riduce il *time‑to‑value*, isola i rischi e massimizza l’efficacia quando i moduli sono attivi insieme.

### 9.1 Valore per area
- **Ops (M1)**: protezione immediata della *data pipeline* (PASS/DEFER/FAIL), MTTR↓, incident avoidance.  
- **Business (M2)**: calo **recidive** e **rumore** via nudges mirati; roadmap di remediation e ROI tracciabile.  
- **IT/Platform (M3)**: stabilità tecnica (profiling, drift, file/partition/process health), cost & performance tuning.

### 9.2 Ragioni architetturali
- **Indipendenza & fault‑isolation**: un modulo in degrado non blocca gli altri; *circuit breaker* e feature flags.  
- **Separazione delle responsabilità**: enforcement vs analisi vs profilo tecnico → team dedicati, SLO chiari.  
- **Interop by‑design**: eventi canonici + correlation keys + role dates evitano *tight coupling* e semplificano l’evoluzione.  
- **Testabilità & versioning**: rollout e canary per modulo; compatibilità forward sugli eventi.

### 9.3 Ragioni economiche
- **Adozione a gradini** → valore rapido con M1, poi estensioni M2/M3 quando conviene.  
- **Cost control**: M2 e M3 sono asincroni/periodici; si scalano per domini critici.  
- **ROI misurabile**: Noise↓, Pass Rate↑, MTTR↓, Throughput↑, Small Files↓, Storage Growth sotto controllo.

### 9.4 Ragioni di compliance & sicurezza
- **Data minimization**: M3 lavora su profili/hash, non su PII grezza.  
- **RBAC per modulo**: accessi separati (Ops/Business/IT) e audit per eventi chiave.  
- **Auditability**: **DECISION_TRACE_ID** collega gate→nudges→RCA.

### 9.5 Sinergia (perché insieme “cambiano il volto”)
- **M3→M1**: profiling & drift riducono falsi positivi → gating più preciso.  
- **M2→M1**: coaching riduce gli errori ricorrenti → meno DEFER/FAIL nel tempo.  
- **M1→M2/M3**: Run Hub ed eventi *run/gate* alimentano analisi e baseline.

### 9.6 Quando **non** serve tutta la modularità
- Team piccolo, poche sorgenti stabili → M1 può bastare.  
- Profiling complesso senza ownership IT → partire da M1+M2 e introdurre M3 solo quando ci sono benefici chiari.

### 9.7 Prova di valore (PoV consigliata)
- Disegno a 3 bracci su 1 dominio: **(A) M1**, **(B) M1+M3**, **(C) Full M1+M2+M3**.  
- **KPI outcome**: Gate Pass Rate, Warning Noise, MTTR, Freshness p95 degradations, Small Files Rate, Recidiva 30d.  
- **Criteri di successo**: Noise −20%, Pass Rate +5 p.p., MTTR −30%, Small Files −50% entro 8 settimane.

> **Conclusione**: i moduli sono **validi** perché uniscono indipendenza operativa, interop semplice e *compounding effects* misurabili su qualità, costi e velocità di risposta.
