
# ARGOS – Playbook Catalog (v1)

> **Scopo:** catalogo dei playbook operativi di ARGOS per remediation e prevenzione. Documento **agnostico** (nessun codice), con struttura standard, criteri **AUTO_SAFE**, guardrail, backout e metriche. Integrato con **Quality Gates v1.1**, **Policy DSL v1.1**, **Alerting v1.1**, **Coach Agent**, **Tech Profiling**.

---

## 0) Principi
1) **Safety‑first**: ogni PB indica se è **AUTO_SAFE** (eseguibile dall’agente) o **ASSIST** (richiede conferma umana).  
2) **Minimo intervento**: modificare solo ciò che serve; tracciare sempre **Decision Trace** e **ticket**.  
3) **Backout pronto**: per ogni azione esiste un piano di rientro atomico e testabile.  
4) **Misurabile**: ogni PB definisce KPI di esito (es. **MTTR**, **Δ Noise**, **recidiva**).  
5) **Privacy**: campioni sanificati; PII segregata; RBAC su evidenze.

---

## 1) Struttura standard Playbook
**Metadati**  
- `PB_ID`, `TITLE`, `VERSION`, `OWNER`, `SEVERITY_TARGET (CRITICAL|MAJOR|MINOR)`, `MODE (AUTO_SAFE|ASSIST|MANUAL_ONLY)`, `SCOPE (DOMAIN|FLOW|INSTANCE|ELEMENT)`, `TAGS[]`.

**Trigger**  
- Eventi (`argos.gate.decision`, `argos.profile.drift`, `ticket.opened`), soglie SLO/Budget, chiamata ChatOps (`/argos pb <id>`).

**Precondizioni & Guardrail**  
- `IMPACT_SCORE` ≤ threshold?  
- `error/noise budget` sufficiente?  
- `max_rows_affected_pct` (default 1%)  
- `data_freshness` entro X giorni  
- `can_run_in_quiet_hours?` (bool)  
- **Privacy**: allegati solo sanificati.

**Procedura**  
1) **Diagnosi rapida** (link Decision Trace, invalid sample, viste)  
2) **Azione** (passi atomici, idempotenti)  
3) **Verifica** (criteri di successo, convalida KPI)  
4) **Backout** (istruzioni precise)  
5) **Chiusura ticket** (note & evidenze)

**Output & Telemetria**  
- `AUTO_SAFE_APPLIED (BOOL)`, `ACTION_LOG`, `Δ Noise`, `MTTR`, `recidiva_30d`.  
- Emissione eventi: `argos.ticket.opened`/`updated`/`closed`.

---

## 2) Indice dei Playbook (selezione v1)
- **PB‑ENRICH‑02** — Arricchimento referenziale da master (ID/lookup) — *AUTO_SAFE: Condizionale*  
- **PB‑UNIQ‑04** — Dedup controllato su chiave natural/business — *AUTO_SAFE: Condizionale*  
- **PB‑FRESH‑01** — Backfill partizioni tardive con watermark — *AUTO_SAFE: NO*  
- **PB‑REF‑KEY‑03** — Ripristino chiavi referenziali (FK→master) — *AUTO_SAFE: NO*  
- **PB‑FORMAT‑ENC‑01** — Re‑parse file con encoding/delimiter errati — *AUTO_SAFE: SÌ*  
- **PB‑DOMAIN‑WL‑02** — Whitelist temporanea valori di dominio — *AUTO_SAFE: Condizionale*  
- **PB‑PARTITION‑LATE‑01** — Quarantena & re‑ingest partizione in ritardo — *AUTO_SAFE: SÌ*  
- **PB‑SMALL‑FILES‑01** — Compaction small files — *AUTO_SAFE: SÌ (IT)*

---

## 3) Schede Playbook (template + esempi)
### PB‑ENRICH‑02 — Arricchimento referenziale da master (ID/lookup)
**Uso**: record con `customer_id` mancante/invalido.  
**Trigger**: DQ Gate `ALERT_WITH_DISCARD` su DOMAIN/REFERENTIAL; Coach segnala Producer rumoroso.  
**MODE**: **AUTO_SAFE (condizionale)**.  
**Guardrail**: `IMPACT_SCORE ≤ 0.6`; `noise_budget_residuo ≥ 0.05`; `max_rows_affected_pct ≤ 0.5`; master **fresh** ≤ 24h.  
**Passi**: (1) estrai invalid sanificati; (2) join con master referenziale; (3) riempi ID mancanti se match univoco; (4) logga `ACTION_LOG`; (5) re‑valuta regola; (6) allega delta al ticket.  
**Backout**: revert delta; re‑taggare righe come invalid.  
**KPI**: **Δ WARN↓**, **Pass Rate↑**, **recidiva 30d↓**.

### PB‑UNIQ‑04 — Dedup controllato su chiave natural/business
**Uso**: duplicati su `key=(id, reference_date)` o similar.  
**Trigger**: DQ Gate `BLOCKING`; Profiling indica skew.  
**MODE**: **AUTO_SAFE (condizionale)**.  
**Guardrail**: `IMPACT_SCORE ≤ 0.5`; `error_budget_residuo ≥ 0.2`; `max_rows_affected_pct ≤ 0.2`; regola di scelta deterministica (es. timestamp più recente).  
**Passi**: (1) identifica cluster duplicati; (2) seleziona record vincente; (3) marca gli altri come scarto controllato; (4) ricostruisci indici; (5) verifica unicità; (6) aggiorna Decision Trace.  
**Backout**: ripristina cluster originari da snapshot.  
**KPI**: **Blocking Rate↓**, **MTTR↓**.

### PB‑FRESH‑01 — Backfill partizioni tardive con watermark
**Uso**: partizioni `dt` mancanti o arrivate in ritardo.  
**Trigger**: Profiling Gate → `PARTITION_HEALTH.LATE_FLAG`; alert IT.  
**MODE**: **ASSIST** (no AUTO_SAFE).  
**Guardrail**: coordinamento con scheduler a valle; `watermark` definito; comunicazione ai consumer.  
**Passi**: (1) identifica range mancante; (2) re‑ingest sorgente; (3) ricalcola aggregati; (4) allinea watermark; (5) rilascia reference; (6) notifica.  
**Backout**: riporta reference alla versione precedente.  
**KPI**: **Late Partition Rate↓**, **Freshness↑**.

### PB‑REF‑KEY‑03 — Ripristino chiavi referenziali (FK→master)
**Uso**: alti tassi di FK non risolte.  
**Trigger**: DQ Gate DOMAIN/REFERENTIAL; Coach segnala Producer; Profiling drift pattern su ID.  
**MODE**: **MANUAL_ONLY**.  
**Guardrail**: revisione di business rule; sincronizzazione con owner master.  
**Passi**: (1) estrai sample sanificato; (2) verifica mapping; (3) applica correzioni batch; (4) aggiorna contratto (whitelist/regex); (5) canary su 10%.  
**Backout**: rollback mapping + vista di compatibilità.  
**KPI**: **Conformity_Wo↑**, **Warn Noise↓**.

### PB‑FORMAT‑ENC‑01 — Re‑parse file (encoding/delimiter)
**Uso**: KO Ingress per encoding/delimiter/quote errati.  
**Trigger**: Ingress Gate FAIL/DEFER; Profiling File Health.  
**MODE**: **AUTO_SAFE**.  
**Guardrail**: nessun impatto su business semantics; `max_rows_affected_pct ≤ 100%` (tutti i record).  
**Passi**: (1) rileva encoding/delimiter; (2) re‑parse; (3) aggiorna metadata; (4) re‑valuta Ingress; (5) allega sample sanificato.  
**Backout**: ripristina file originale; fall‑back parser precedente.  
**KPI**: **MTTR↓**, **GPR↑** su ingress.

### PB‑DOMAIN‑WL‑02 — Whitelist temporanea valori
**Uso**: valori nuovi ma legittimi che rompono DOMAIN.  
**Trigger**: DQ Gate WARN ripetitivi; superamento Noise Budget; Coach propone.  
**MODE**: **AUTO_SAFE (condizionale)**.  
**Guardrail**: approvazione four‑eyes; TTL whitelist ≤ 14 gg; `IMPACT_SCORE ≤ 0.4`.  
**Passi**: (1) crea whitelist con TTL; (2) logga eccezione; (3) avvisa Producer; (4) pianifica patch contratto.  
**Backout**: scadenza TTL o rimozione manuale.  
**KPI**: **Noise↓**, **Flapping↓**.

### PB‑PARTITION‑LATE‑01 — Quarantena & re‑ingest partizione tardiva
**Uso**: partizione attesa non arrivata o incompleta.  
**Trigger**: Profiling Gate; Alert IT.  
**MODE**: **AUTO_SAFE**.  
**Guardrail**: `max_days_late ≤ 2`; impatto su downstream notificato.  
**Passi**: (1) sposta partizione in quarantine; (2) notifica owner; (3) re‑ingest job; (4) verifica completezza; (5) promuovi reference.  
**Backout**: ripristina partizione precedente.  
**KPI**: **Late Partition Rate↓**.

### PB‑SMALL‑FILES‑01 — Compaction small files
**Uso**: eccesso di file piccoli che degrada performance/costi.  
**Trigger**: Profiling File Health: `SMALL_FILE_FLAG` diffuso.  
**MODE**: **AUTO_SAFE (IT)**.  
**Guardrail**: run in finestre off‑peak; `target_file_size` definito; test su partizione campione.  
**Passi**: (1) identifica set; (2) merge/compact; (3) aggiorna metadata; (4) misura throughput; (5) salva profilo post‑azione.  
**Backout**: ripristina snapshot/manifest precedente.  
**KPI**: **Throughput↑**, **Cost/1M rows↓**.

---

## 4) ChatOps & Template messaggi
- **Comandi**: `/argos pb list` · `/argos pb open PB-UNIQ-04 --run {run_id}` · `/argos gate {run}` · `/argos run {flow}`  
- **Notifica apertura**: `[#PB][{pb_id}] {title} · {severity_target} · run={run_id} · trace={decision_trace_id}`  
- **Nota chiusura**: `{pb_id} chiuso · Δ Noise={pct}% · MTTR={h} · recidiva_30d={pct}%`

---

## 5) Governance & Versioning
- Ogni PB ha **OWNER** e **MANUTENZIONE trimestrale**.  
- Cambi **MAJOR** richiedono ADR + prova **canary** (quando applicabile).  
- **AUTO_SAFE** ammesso solo per PB certificati e con guardrail soddisfatti.

---

## 6) Definition of Done (v1)
- Schede PB minime pubblicate (ENRICH, UNIQ, FRESH, REF‑KEY, FORMAT‑ENC, DOMAIN‑WL, PARTITION‑LATE, SMALL‑FILES).  
- Integrazione con **Alerting** e **Quality Gates** (ticket & trace).  
- KPI di esito raccolti e collegati a digest.  
- Flag **AUTO_SAFE** e guardrail definiti; backout esplicito; privacy rispettata.
