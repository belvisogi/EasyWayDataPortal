
# ARGOS – Alerting & Notifications Guide (v1.1)

> **Scopo:** definire la strategia completa di alerting e notifica per i Quality Gates e per l’intero ciclo ARGOS (Ops, Business, IT). Include canali, severità, dedup, hysteresis e integrazione con il Coach Agent.

---

## 1) Principi
1) **Un messaggio → un’azione**: ogni notifica deve indicare un’azione o un owner.  
2) **Rumore controllato**: gestito da **Noise Budget** e *suppression window*.  
3) **Contesto prima del dato**: i messaggi espongono gate, impatto e budget, non dettagli tecnici inutili.  
4) **Privacy e sicurezza**: mai PII; allegati sanificati; RBAC sugli endpoint.

---

## 2) Canali
- **Email** (ufficiale, owner/domain)
- **ChatOps** (Teams/Slack): thread per run/incident (`/argos run`, `/argos gate`, `/argos pb`)
- **Webhook/Incident Mgmt** (Jira/ServiceNow): per ticket automatici
- **Dashboard Digest** (giornaliero/settimanale): aggregato visivo su KPI Noise/Error/SLO.

---

## 3) Severità & mapping
| Gate Outcome | Severity messaggio | Destinatari | Azione |
|---|---|---|---|
| **FAIL** | CRITICAL | Ops + Owner + Governance | Ticket automatico (PB associato) |
| **DEFER** | WARN | Ops + Owner | Revisione manuale o safe-action |
| **PASS** | INFO | Owner (solo digest) | Nessuna azione |

**Coach Agent** genera **INFO/WARN** per i nudges; nessun CRITICAL.

---

## 4) Dedup & suppression
- **Dedup**: `(flow_id, instance_id, rule_id, reference_date, outcome)` entro finestra.  
- **Suppression window**: default 60 min per WARN ripetitivi.  
- **Quiet hours**: 22:00–06:00 UTC; compressione e invio digest.  
- **Escalation**: se stesso errore persiste > N run, promozione da WARN → CRITICAL.

---

## 5) Payload standard
**Campi chiave**: `run_id`, `domain/flow/instance`, `gate_type`, `outcome`, `controls_result`, `impact_score`, `error_budget_residuo`, `noise_budget_residuo`, `decision_trace_id`, `invalid_rows_path`, `scorecard_link`, `playbook_id?`, `ticket_id?`.

**Formato sintetico (email/chat)**  
```
[ARGOS][{domain}/{flow}] {gate_type}:{outcome} {controls_result}
Impact={impact_score:.2f} | ErrorBudget={err_budget:.2f} | NoiseBudget={noise_budget:.2f}
Run={run_id} | DecisionTrace={decision_trace_id}
{playbook_link}
```

---

## 6) Digest intelligenti
**Frequenza**: orario o giornaliero per dominio.  
**Contenuto**: 
- Top-N errori (Error Concentration)  
- Noise Budget usage (%)  
- GPR (Gate Pass Rate)  
- SLO breach (error/freshness)  
- Ticket aperti/chiusi, MTTR medio  
- Trend 7/30 gg  
**Distribuzione**: Owner + Governance + IT.

---

## 7) Integrazione con Coach Agent
- Quando un **NUDGE** viene inviato, genera evento `argos.coach.nudge.sent` → recap in digest business.  
- I **WARN ripetitivi** > Noise Budget triggerano **suggestion** di nudge automatico.  
- **Feedback**: lettura nudge riduce priorità alert per stesso produttore per 7 gg (cool-down).  
- **Metriche** condivise: `nudge_open_rate`, `confirm_read`, `noise_delta_after_nudge`.

---

## 8) Alert IT (Profiling)
- Drift HIGH → WARN IT + digest tecnico.  
- Job Failure/Throughput < baseline−10% → CRITICAL IT.  
- Small Files Rate > 5% → WARN IT.  
- Partition Lateness > 1% → WARN IT.  
- Storage Growth > +20%/mese → INFO (digest).  
**Destinatari**: IT Ops + Data Architect.

---

## 9) KPI di Alerting
- **Alert Volume (giornaliero)**, **Dedup Ratio**, **False Alarm Rate**, **MTTA (time-to-ack)**, **MTTR (time-to-resolve)**, **Digest Coverage (%)**, **User Engagement (open/click)**.

---

## 10) Definition of Done (v1.1)
- Severità e mapping completi per PASS/DEFER/FAIL.  
- Dedup, suppression, quiet hours documentati.  
- Payload standard con chiavi e link correlati (Decision Trace, Playbook, Scorecard).  
- Digest intelligenti attivi.  
- Integrazione con Coach Agent e Profiling Alert IT definita.  
- KPI di alerting stabiliti (volume, dedup, MTTA/MTTR, engagement).
