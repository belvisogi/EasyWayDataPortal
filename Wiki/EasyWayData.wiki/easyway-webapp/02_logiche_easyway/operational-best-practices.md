---
id: ew-operational-best-practices
title: Best Practice Operative e Integrazione
summary: Documento su integrazione delle best-practice enterprise in EasyWayDataPortal.
status: active
owner: team-platform
tags: [domain/control-plane, layer/reference, audience/dev, audience/ops, privacy/internal, language/it, docs, dr, best-practices]
llm:
  include: true
  pii: none
  chunk_hint: 250-400
  redaction: [email, phone]
entities: []
updated: '2026-01-16'
next: TODO - definire next step.
type: guide
---
# Best Practice Operative e Integrazione

Sommario
- Documento operativo che raccoglie i frammenti utili presi dagli standard aziendali e li mappa direttamente nella documentazione e nei deliverable di EasyWayDataPortal. Scopo pratico: trasferire ciò che funziona (runbook, policy, criteri di monitoraggio, patterns di networking) adattandolo a una soluzione cloud‑native (PaaS / container) con DR cross‑cloud (Azure primary, GCP DR). Componenti esclusi: Databricks, Informatica, Axon, Synapse.

1) Principi generali importati dagli standard (già integrati nella wiki)
- Runbook e checklist operative: riutilizzare le sequenze di test e i criteri di accettazione come baseline per i runbook‑as‑code.
  - Dove: convertiti in runbook-as-code previsti dal piano (vedi Wiki/DR_Inventory_Matrix.md — azioni successive).
- Policy di monitoraggio e soglie: regole da App Insights / Log Analytics da adattare ai nomi metrici EasyWay.
  - Dove: riferimenti inseriti nelle pagine di monitoring e automazione export log.
- Pattern di network isolation: principi di uso di Private Endpoints e segmentazione di rete come standard di sicurezza.
  - Dove: policy di configurazione e security (policy-di-configurazione-and-sicurezza-microservizi-e-api-gateway.md).
- Gestione segreti e policy di rotazione: Key Vault come fonte di verità e requisito di audit.
  - Dove: step‑1 setup ambiente + parametrization best practices.
- WAF / hardening rules: ruleset consigliati e checklist di hardening presi da standard sicurezza.
  - Dove: indicazioni sintetiche inserite nelle pagine di deploy e raccomandazione architetturale.
- **Agent Architecture Standard** (Brain vs Arm): classificazione mandatoria per tutti gli agenti AI.
  - Dove: [standards/agent-architecture-standard.md](../../standards/agent-architecture-standard.md) e [manifesto](../../agents/agent_gedi/README.md).

2) Elementi standard che ho trasformato in deliverable EasyWay (nuovi o aggiornati)
- Runbook‑as‑Code (MVP DR test) — concetto e stack proposto
  - Terraform + Azure Pipelines / GitHub Actions + PowerShell/Az CLI + Cloud Build (GCP).
  - Azione: generare template runbook (script + pipeline) per DB+Storage+Ingress (prossimo deliverable).
- Script sincronizzazione login SQL (SID) — pattern operativo
  - Azione: template script SQL/PowerShell da produrre come primo artefatto (fase 1).
- Terraform modules mapping Azure → GCP (POC)
  - Azione: repo POC per Cloud SQL, GCS, Secret Manager, Cloud LB (fase 1/2).
- Sincronizzazione Storage (ADLS → GCS)
  - Azione: design pattern azcopy/gsutil o Cloud Run job (fase 1).
- Segreti & certificati cross‑cloud
  - Azione: pipeline sicura per replicare (solo per test DR) segreti in Secret Manager con audit.
- DNS & Ingress playbook
  - Azione: playbook as‑code Front Door ↔ Cloud LB + health probes + rollback DNS.
- Monitoring & RTO/RPO automation
  - Azione: runbook di test schedulato e dashboard condivisa per misurare RTO/RPO.

3) Dove ho aggiunto/modificato contenuti nella wiki
- Nuova pagina: this file (operational-best-practices.md) — raccolta operativa e mapping.
- DR Inventory Matrix: Wiki/EasyWayData.wiki/DR_Inventory_Matrix.md — matrice iniziale con RTO/RPO e azioni successive (fase 0).
- Ho lasciato inalterate le pagine esistenti (deploy-app-service.md, datalake IAM, gestione-configurazioni) ma ho indicato nei loro contenuti i punti rilevanti (runbook, segreti, monitoring).
  - Dove appropriato ho aggiunto note operative (es. riferimento a template runbook e script SID da produrre).

4) Priorità operative consigliate (ordine esecutivo)
- Phase 0: Inventory tecnico + matrice dettagliata componente → RTO/RPO (5 giorni) — già avviata.
- Phase 1: Script SQL SID + runbook teardown + Terraform POC GCP (DB+GCS+Secret Manager+LB) — 7–12 giorni.
- Phase 2: Runbook end‑to‑end, segreti sync, monitoring automazione — 10–20 giorni.
- Phase 3: Test E2E, hardening, produzione runbook e operationalization — 7–14 giorni.

5) Prossime azioni immediate che posso fare (se confermi)
- Generare la matrice completa (CSV + MD) con nomi risorsa / RG / subscription (richiede accesso o output da script Az CLI).
- Produrre il template script SQL SID + piccolo runbook teardown (primo artefatto consegnabile).
- Avviare repo Terraform POC su GCP (bozza di moduli).

6) Comunicazione e governance
- Suggerisco di versionare tutti i runbook e i moduli Terraform in repo dedicato (feature branch + PR + checklist di validazione).
- Assegnare owner e reviewer per ogni deliverable (DBA, DevOps, Security, Network).

Note finali
- Ho già integrato in wiki i contenuti rilevanti in forma adattata e operativa.

## Vedi anche

- [Strategia Cloud-Native Disaster Recovery (approccio operativo)](../../dr-strategy-cloud-native.md)
- [what is inventory and missing items](../../Runbooks/what_is_inventory_and_missing_items.md)
- [DR — Inventory & matrice componente → RTO / RPO](../../dr-inventory-matrix.md)
- [Deployment decision (MVP) — EasyWay Data Portal](../../deployment-decision-mvp.md)
- [readme](./logging-and-audit/readme.md)


