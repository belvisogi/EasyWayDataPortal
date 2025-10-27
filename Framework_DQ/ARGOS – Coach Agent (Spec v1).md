
# ARGOS – Coach Agent (Spec v1)

> **Scopo:** guidare produttori e team nel ridurre errori ricorrenti e rumore, attraverso **nudges** mirati, proposte di **tuning policy** e **patch di contratto**. Agente del modulo **M2 – Biz‑Learning**.

---

## 1) Missione & Value
- Ridurre **recidiva** e **Warning Noise** sulle stesse cause/elementi.
- Migliorare **Conformity (Without Warnings)** e **GPR** nel tempo.
- Restituire **tempo** a Ops/Business/IT con azioni mirate e spiegabili.

## 2) Trigger
- Consumo **Noise Budget** su dominio/istanza > soglia.
- **Error Concentration** stabile su stessi elementi/produttori.
- **Profiling drift** rilevante su pattern/valori (segnale M3).
- Esito gate **DEFER/FAIL** ricorrente su stessa regola.

## 3) Raccolta segnali
- Scorecard (Producer League, Error Concentration, Noise Usage).
- Decision Trace, invalid sample **sanificati**.
- Profiling events (PROFILE_DRIFT_EVENT) e file/partition health.

## 4) Selezione cause & destinatari
- Heuristics: % share causa, trend 7/30 gg, impatto (IMPACT_SCORE), effort stimato.
- **Ranking** destinatari (PRODUCER_ID) per priorità di intervento.

## 5) Azioni
- **NUDGE** (SUGGEST/ASSIST/AUTOPILOT) con template (email/chat).
- **POLICY PROPOSAL** (canary/A‑B) → `argos.policy.proposal`.
- **CONTRACT PROPOSAL** (patch additive) → `argos.contract.proposal`.
- **PLAYBOOK suggestion** (collegamento PB‑*).

## 6) Template Nudge (esempi)
- **SCHEMA/FORMAT**: “Hai cambiato l’encoding/delimiter? Ecco come esportare correttamente …”
- **DOMAIN**: “Nuovi valori su `customer_type`. In attesa di contratto aggiornato: whitelisting a TTL …”
- **FRESHNESS**: “Partizioni late sulla finestra X. Verifica watermark/pubblicazione …”

## 7) Output & Telemetria
- Evento `argos.coach.nudge.sent` (topic, cause_code, mode, follow_up_at).
- KPI: **Open/Click**, **Confirm_read**, **Δ Noise (7/30d)**, **Recidiva 30d**.
- Link a **Decision Trace** e scorecard.

## 8) Integrazioni
- **Gates**: consumano EXPERIMENT e possono alzare/abbassare severità dinamica.
- **Profiling**: fornisce drift/pattern utili a nudge e proposte.
- **Alerting**: digest includono nudge e risultati.

## 9) Rollout
- **Pilot** su 1–2 domini, modalità **ASSIST** (no AUTOPILOT).
- Valutare KPI outcome (Noise↓, recidiva↓, GPR↑).

## 10) RACI
- **A/R**: Coach Agent owner; **C**: DQ Engineer, Steward; **I**: Governance, Security.

## 11) DoD (v1)
- Nudge template disponibili, eventi emessi, KPI tracciati.
