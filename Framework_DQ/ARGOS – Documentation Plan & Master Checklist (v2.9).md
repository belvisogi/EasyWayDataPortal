# ARGOS – Documentation Plan & Master Checklist (v2.9)

> **Data:** 27/10/2025  
> **Scopo:** versione aggiornata che recepisce **Playbook Catalog (v1)** oltre a **Alerting & Notifications v1.1**, **Policy DSL v1.1**, **Quality Gates v1.1**, **Event Schema**, **Modular Interop**, **Tech Profiling** e **Coach Agent**.

Legenda stato: ✅ Completato · 🟡 Bozza (v1 pronta) · ⏳ Da creare · 🔁 Evolutivo

---

## 1) Mappa dei deliverable (per modulo)
### M1 – Fast‑Ops (Gating)
- ✅ **Quality Gates Spec v1.1** (Decision Trace, severity dinamica, **hysteresis/cool‑down**, Profiling Gate *soft*)  
- ✅ **Run Hub Spec**  
- ✅ **Alerting & Notifications Guide (v1.1)**  
- ✅ **Playbook Catalog (v1)**  

### M2 – Biz‑Learning (Producer & Coaching)
- ✅ **Monitoring & Scorecard Schema** (+4 viste: Producer League, Cause by Element, Noise Usage, RCA Backlog)  
- ✅ **Coach Agent – Spec v1**  
- 🟡 **KPI Book (Logiche) v1**  
- 🟡 **SLO Catalog (Pilot v1)**  

### M3 – Tech‑Profiling (IT Health)
- ✅ **Tech Profiling & Reliability – Spec v1**  
- 🟡 **Profiling Gate (soft)** – implementazione operativa  
- 🟡 **Process/Job Health (estensioni RUN_TASK_RESULT)**

### Common & Interop
- ✅ **Modular Architecture & Interop (v1)** *(+ sezione “Perché i moduli sono validi”)*  
- ✅ **Event Schema Addendum (v1)**  
- ✅ **Policy DSL & Registry v1.1** (Impact/Noise/Probabilistic, Explainability, Linter pre‑check)  
- 🟡 **Change & Versioning Guide v1**  
- 🟡 **Glossario Unificato v1**  

---

## 2) Interoperabilità (Correlation Fabric)
- **Eventi canonici**: `argos.run.completed`, `argos.gate.decision`, `argos.profile.drift`, `argos.coach.nudge.sent`, `argos.policy.proposal`, `argos.contract.proposal`, `argos.ticket.opened`.  
- **Chiavi**: `RUN_ID`, `INSTANCE_ID`, `FLOW_ID`, `DOMAIN_ID`, `RULE_VERSION_ID`, `PRODUCER_ID`, `DECISION_TRACE_ID`.  
- **Role dates**: `RUN_DATE`, `REFERENCE_DATE`, `LOAD_DATE`.

---

## 3) Master Checklist
- [x] Quality Gates – **v1.1** (Decision Trace, severity dinamica, **hysteresis/cool‑down**, Profiling Gate *soft*)  
- [x] Monitoring & Scorecard – **+4 viste Dual‑Loop**  
- [x] Coach Agent – **Spec v1**  
- [x] Tech Profiling & Reliability – **Spec v1**  
- [x] Event Schema Addendum – **v1**  
- [x] Modular Architecture & Interop – **v1**  
- [x] Policy DSL & Registry – **v1.1** (Impact/Noise/Probabilistic, Explainability, Linter pre‑check)  
- [x] **Alerting & Notifications Guide – v1.1**  
- [x] **Playbook Catalog – v1**  
- [ ] Profiling Gate (soft) – **spec & mapping operativi**  
- [ ] Change & Versioning Guide – **v1**  
- [ ] Glossario Unificato – **v1**  

---

## 4) Roadmap di attivazione (Q1)
- **Mese 1**: M1 operativo + **Quality Gates v1.1** con Decision Trace; **Alerting & Notifications v1.1** attivo; feature flag `enable_dynamic_severity` **OFF** su domini non pilota.  
- **Mese 2**: M3 profiling+drift, **Profiling Gate soft**; suggerimenti soglie/contratti; **Eventi** fully adopted.  
- **Mese 3**: M2 coaching, nudges e proposals; abilita `enable_dynamic_severity` su 1 dominio pilota; chiusura canary.  
- **Fine Q1**: pilot full‑stack su 2 domini; KPI outcome migliorati (Noise↓, MTTR↓, GPR↑); tag documenti **v1.2**.

---

## 5) Definition of Done (Q1)
- **Quality Gates v1.1** in produzione (Decision Trace ≥99%, hysteresis/cool‑down attivi).  
- **Alerting & Notifications v1.1** operativo (dedup, quiet hours, payload standard, digest).  
- **Playbook Catalog v1** pubblicato e referenziato nei ticket/trace.  
- **Profiling Gate soft** attivo e tracciato negli esiti DQ.  
- **Eventi canonici** adottati (schema registry, DLQ, idempotenza).  
- **Coach Agent (pilot)** con Δ Noise/KO in miglioramento; **digest** attivi.  
- **Dashboard** per M1/M2/M3 + vista correlata per `DECISION_TRACE_ID`.  
- ADR approvate; RBAC & privacy validate; tag **v1.2** pubblicato.

---

## 6) Status update – 27/10/2025 (Playbook Catalog v1)
- Pubblicato il **Playbook Catalog (v1)** con 8 playbook: ENRICH‑02, UNIQ‑04, FRESH‑01, REF‑KEY‑03, FORMAT‑ENC‑01, DOMAIN‑WL‑02, PARTITION‑LATE‑01, SMALL‑FILES‑01.  
- Ogni scheda include **MODE** (AUTO_SAFE/ASSIST/MANUAL), **guardrail**, **backout**, **KPI**, messaggistica **ChatOps** e collegamenti a **Decision Trace**.  
- Impatti attesi: **MTTR↓**, **Noise↓**, **GPR↑**, migliore compliance a SLO/Policy.
