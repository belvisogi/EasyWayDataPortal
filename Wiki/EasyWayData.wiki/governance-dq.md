---
title: Governance DQ – RACI, Processi e Checklist
tags: [dq, governance, argos, agents, domain/control-plane, layer/spec, audience/ops, audience/dev, privacy/internal, language/it, data-quality]
status: active
updated: 2026-01-16
redaction: [email, phone]
id: ew-governance-dq
chunk_hint: 250-400
entities: []
include: true
summary: Modello operativo per definire, validare e rilasciare regole DQ (proposal → linter → rollout) in EasyWayDataPortal.
llm: 
pii: none
owner: team-platform

llm:
  include: true
  chunk_hint: 5000---

[Home](../../docs/project-root/DEVELOPER_START_HERE.md) > [[Domain - Control-Plane|Control-Plane]] > [[Layer - Spec|Spec]]

# Governance DQ – RACI, Processi e Checklist

Scopo
- Fornire una guida pratica per proporre, validare, rilasciare e mantenere le regole di Data Quality in EasyWayDataPortal, integrando ARGOS (Gates, DSL, Profiling, Coach) e le pipeline CI/CD.

RACI sintetico
- Domain Owner & Data Steward – A/R requisiti di qualità, IMPACT e SLO business; C su rollout; I su alert/digest.
- Team Prodotto Dati (Flow/Instance) – A/R implementazione, evidenze, backout; C su proposal; I su policy set.
- DQ Governance – A/R DSL/Registry, SemVer, linter e review; approva MAJOR; gestisce override/backout registry.
- Gatekeeper/Ops – A/R gestione gates, quarantine, roll‑out in CI; C su incident; I su nudges.
- Platform/IT Ops – A/R Profiling & IT Health; C su severity dinamica; I su digest IT.
- Coach Agent Owner – A/R nudges/proposals e misurazione outcome; C su tuning; I su gates.

Oggetti governati (minimi)
- Dominio (domain_id) e Flusso/Istanza (flow_id/instance_id) con owner e SLO.
- Policy (regola singola) e Policy Set (pacchetto coerente per istanza).
- Budget: Error/Noise Budget per dominio/istanza.
- SLO & KPI: Conformity_Wo, GPR, MTTR, Δ Noise, Freshness, ecc.

Processo end‑to‑end (proposal → linter → rollout)
1) Proposal (creazione/modifica)
- Chi: Data Steward/Team Prodotto/Coach.
- Artefatto: proposta Policy/Policy Set (JSON/YAML) con campi chiave: RULE_ID, RULE_VERSION (proposta), CATEGORY, SCOPE, ELEMENT_REF, SEVERITY_BASE, MOSTLY, IMPACT_SCORE, WHERE, EXPERIMENT?, BACKOUT_PLAN_REF.
- Registri: crea/aggiorna voce in Registry (STATE=DRAFT→PROPOSED, CHANGE_TYPE=PATCH|MINOR|MAJOR).

2) Pre‑check (Linter)
- Regole: naming/stile; severity base coerente con IMPACT; privacy (no PII in esempi/valori); efficacia/rumore (NOISE_BUDGET_HINT); performance/costi.
- Strumenti: comando agente linter e gate INGRESS; report allegato alla Decision Trace del run di validazione.

3) Review & approvazione
- Four‑eyes: DQ Governance + Steward/Owner.
- MAJOR: ADR richiesta; prevedere dual‑read/dual‑write e vista di compatibilità.
- Output: Policy in STATE=APPROVED, Policy Set in STAGING (non prod).

4) Rollout Gate (controllato)
- Shadow: monitoraggio senza effetto su esito gate.
- Canary: `min_runs` + `success_criteria` (Δ Noise, Conformity_Wo ≥ baseline, GPR ≥ baseline).
- A/B: selezione variante vincente su KPI; Early stop → Backout.

5) Promotion & aggiornamenti
- Promuovi Policy Set in produzione; aggiorna Registry (changelog), Wiki e KB.
- Eventi: emetti `argos.policy.proposal` (proposta) e note in `argos.gate.decision` (experiment_ref/override_ref se presenti).
- Budget: ricalibra NOISE/ERROR se necessario (con governance).

6) Monitoraggio & miglioramento (Coach)
- Nudges mirati per recidive/rumore; follow‑up e digest.
- KPI outcome: Δ Noise (7/30d), Recidiva 30d, GPR, MTTR; cool‑down post‑tuning, freeze prima di picchi.

Checklist operativa (DoD)
- Proposal pronta (campi obbligatori + backout plan) e registrata nel Registry.
- Linter eseguito e superato (report allegato).
- Review four‑eyes completata; CHANGE_TYPE classificato (PATCH/MINOR/MAJOR).
- Rollout definito (Shadow/Canary/A‑B) con min_runs e success_criteria.
- Gates aggiornati e `Decision Trace` abilitata (coverage ≥ 99%).
- Eventi schema‑validi (`argos.*`) e payload di esempio aggiornati.
- Wiki & KB aggiornate; digest/alerting mappati; privacy ok.

Selezione dei flussi (priorità)
- IMPACT alto (business‑critical), instabilità storica (GPR basso/Noise alto), SLO stringenti (freshness/accuratezza), dipendenze a valle critiche.
- Roadmap: Mese 1 (top 2 domini, 3–5 istanze); Mese 2 (Profiling Gate soft); Mese 3 (Coach in ASSIST, nudges/proposals).

Template & artefatti suggeriti
- Policy Set (YAML on‑the‑fly) – vedi generatore `scripts/argos-generate-yaml.mjs` e samples.
- Event Schema (JSON) – vedi cartella `docs/agentic/templates/events` (schemas + samples).
- PR Template – vedi `PULL_REQUEST_TEMPLATE.md` (check front‑matter Wiki/LLM e gates verdi).

Riferimenti
- ARGOS – Overview: `argos/argos-overview.md`
- Quality Gates: `argos/argos-quality-gates.md`
- Policy DSL & Registry: `argos/argos-policy-dsl.md`
- Tech Profiling: `argos/argos-tech-profiling.md`
- Coach Agent: `argos/argos-coach-agent.md`
- Event Schema: `argos/argos-event-schema.md`










