---
title: Agent – DQ Blueprint (Spec v0)
tags:
  - agents
  - argos
  - dq
  - domain/control-plane
  - layer/spec
  - audience/dev
  - privacy/internal
  - language/it
status: active
updated: 2026-01-16
redaction:
  - email
  - phone
id: ew-agent-dq-blueprint
chunk_hint: 250-400
entities: []
include: true
summary: Agente che genera un blueprint iniziale di regole DQ (Policy Proposal + Policy Set) da CSV/XLSX o schema, integrato con ARGOS.
llm:
  include: true
  chunk_hint: 5000
type: agent
---

[Home](./start-here.md) >  > 

# Agent – DQ Blueprint (Spec v0)

Missione
- Ridurre i tempi di on‑boarding proponendo automaticamente un set iniziale di regole DQ per un flusso/istanza, con descrizioni, severità e soglie ragionevoli, a partire da CSV/XLSX o da uno schema DB.

Input
- File: CSV/XLSX (intestazioni, N righe di sample) o introspezione tabella.
- Meta (opz.): `domain_id`, `flow_id`, `instance_id`, chiavi candidate, IMPACT di default, mapping referenziali noti.

Output
- `out/blueprint/policy_proposals.json`: elenco di proposte conformi alla DSL (categoria, check, mostly, severity_base, descrizione).
- `out/blueprint/policy_set.json`: set minimale con `RULE_VERSION` placeholder e mapping allo scope.
- Facoltativo: YAML generati on‑the‑fly (via generator) come artifact CI.

Intent (mini‑DSL)
```json
{
  "action": "blueprint-from-file",
  "input": { "path": "path/to/file.csv", "format": "csv" },
  "scope": { "domain_id": "customer", "flow_id": "orders", "instance_id": "ord_v2_daily" },
  "options": { "sample_rows": 2000, "impact_default": 0.5 }
}
```sql

Esito strutturato
```json
{
  "ok": true,
  "summary": { "columns": 24, "rules_proposed": 18 },
  "policy_proposals": [ { "rule_id": "R_FMT_EMAIL", "category": "FORMAT", ... } ],
  "policy_set": { "id": "<generated>", "rules": [ { "rule_id": "R_FMT_EMAIL", "rule_version": "0.1.0" } ] },
  "notes": ["Regole marcate BLOCKING su colonne id/key"],
  "artifacts": ["out/blueprint/policy_proposals.json", "out/blueprint/policy_set.json"]
}
```sql

Heuristics v0 (estratto)
- FORMAT: email/iban/phone/cf/piva/zip/pattern alfanumerico da regex note.
- COMPLETENESS: `is not null` per colonne senza null nel sample.
- DOMAIN: per cardinalità bassa (<=K) con whitelist proposta; valori sanificati.
- UNIQUENESS: candidate key se distinct≈rows su 1..N colonne.
- REFERENTIAL: suggerimento se nome colonna combina `*_id` e master noto.
- FRESHNESS: colonna data con differenza vs run_date (soglia da meta/sla).
- PROBABILISTIC: drift/shape su numeriche ad alta variabilità (PSI) e su volume.

Comandi (skeleton)
- TS: `node ts-node agents/agent_dq_blueprint/src/cli.ts --action blueprint-from-file --input path/to.csv --domain customer --flow orders --instance ord_v2_daily`
- PS: `pwsh agents/agent_dq_blueprint/run.ps1 -Action blueprint-from-file -Input path/to.csv -Domain customer -Flow orders -Instance ord_v2_daily`

Integrazione ARGOS
- Genera Policy Proposal + Policy Set (JSON) e opzionalmente YAML via `scripts/argos-generate-yaml.mjs`.
- Invio evento `argos.policy.proposal` (opzionale) e collegamento a Decision Trace.

RACI
- A/R: DQ Governance & Data Steward per approvare/promuovere; Team Prodotto valida impatti; Coach integra feedback su rumore/recidiva.

Sicurezza & Privacy
- Sanificare campioni/whitelist; mai PII in output; RBAC lato portale.

Definition of Done (v0)
- Intent JSON supportato, output strutturato, heuristics v0, CLI TS/PS skeleton, esempi e cartella artifact.

Riferimenti
- ARGOS – Policy DSL: `argos/argos-policy-dsl.md`
- Quality Gates: `argos/argos-quality-gates.md`
- Governance DQ: `governance-dq.md`










