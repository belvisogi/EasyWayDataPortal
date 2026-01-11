---
id: ew-dr-gaps-vs-ada
title: Cosa integrare da ADA per EasyWayDataPortal (approccio operativo e cosa aggiungere)
summary: Analisi operativa di cosa riusare da ADA per DR e cosa aggiungere in EasyWayDataPortal, con deliverable prioritizzati e stima fasi.
status: draft
owner: team-platform
tags: [docs, domain/docs, layer/blueprint, audience/ops, audience/dev, privacy/internal, language/it, dr]
llm:
  include: true
  pii: none
  chunk_hint: 250-400
  redaction: [email, phone]
entities: []
updated: '2026-01-05'
next: TODO - definire next step.
---
# Cosa integrare da ADA per EasyWayDataPortal (approccio operativo e cosa aggiungere)

Scopo
- Descrivere in modo operativo quali pratiche, pattern e componenti presi dall’esperienza ADA vanno riutilizzati o adattati per EasyWayDataPortal, e quali elementi nuovi è opportuno introdurre per ottenere una soluzione cloud‑native con capacità DR cross‑cloud (Azure primary, GCP DR). Componenti esclusi: Databricks, Informatica, Axon, Synapse.

Sintesi veloce
- ADA fornisce runbook consolidati, criteri di monitoraggio e policy di sicurezza utili come baseline. Per EasyWayDataPortal occorre:
  1) riutilizzare i processi maturi (checklist, criteri di accettazione, regole monitoring),
  2) riprogettarli come artefatti "as‑code" (Terraform, pipeline, runbook automatizzati),
  3) mappare le contromisure su servizi PaaS e su GCP per la parte DR.

Cosa prendere da ADA (da riutilizzare/adattare)
- Runbook e checklist DR: sequenze operative, test plan, criteri di accettazione da usare come base per runbook‑as‑code.
- Politiche di monitoraggio e soglie: regole di alerting e dashboard (App Insights / Log Analytics) da importare e adattare.
- Pattern di network isolation: principi di uso di Private Endpoints e segmentazione rete.
- Gestione centralizzata dei segreti: Key Vault + policy di rotazione e auditing.
- Strategia backup DB (geo‑replica, Failover Group) e procedure di test DR (template dei test).
- WAF/Application Gateway ruleset e procedure di hardening.

Cosa adattare per EasyWayDataPortal (trasformazione cloud‑native)
- Convertire runbook VM‑centrici in runbook PaaS/container‑centrici (Terraform + pipeline CI).
- Automatizzare switch/failover DNS tramite orchestrazione (minimizzare intervento manuale).
- Sostituire procedure manuali di segreti con pipeline sicure di sincronizzazione verso Secret Manager (GCP) per test DR.
- Containerizzare o spostare su App Service/Container Apps i componenti che lo consentono per ridurre il tempo di recovery.
- Implementare teardown automatico per ambienti DR temporanei (evitare costi e drift).
- Aggiungere test automatici che misurino RTO/RPO e producano report eseguibili on‑demand o schedulati.

Cosa aggiungere specifico per EasyWayDataPortal (deliverable essenziali)
1) Runbook‑as‑Code (MVP DR test)
   - Orchestrazione: replica DB → provisioning risorse PaaS minime su GCP → replica assets essenziali → aggiornamento segreti temporanei → smoke tests → teardown.
   - Tecnologie consigliate: Terraform, Azure Pipelines / GitHub Actions, PowerShell/Az CLI e Cloud Build (GCP).
2) Script sincronizzazione login SQL (SID) e permessi
   - Script parametrizzato (SQL + PowerShell) per ricreare login con SID su replica/DR.
3) Terraform modules per GCP (POC)
   - Cloud SQL, GCS, Secret Manager, Cloud Load Balancing, Cloud Armor.
4) Processo di sincronizzazione storage
   - azcopy/gsutil o job su Cloud Run/Dataflow per esportare/importare oggetti critici (config, assets, audit) con versioning.
5) Pipeline sicure per segreti e certificati
   - Processo controllato con audit trail e possibilità di rotazione temporanea per test DR.
6) DNS & Ingress playbook
   - Disegno Front Door ↔ Cloud LB con health probes; playbook DNS as‑code per cutover e rollback.
7) Monitoring & report automatico RTO/RPO
   - Dashboard centralizzata + runbook di test schedulato e report export.

Priorità raccomandata (MVP: DB + Storage + Ingress)
- Phase 0 — Inventory & RTO/RPO mapping: 5 giorni (matrice dettagliata).
- Phase 1 — Script SQL SID + runbook teardown + Terraform POC GCP (minimale): 7–12 giorni.
- Phase 2 — Runbook end‑to‑end, segreti sync, monitoring automazione: 10–20 giorni.
- Phase 3 — Test E2E, hardening e operationalization: 7–14 giorni.

Stima tempi complessivi
- MVP (DB + Storage + Ingress) : 6–8 settimane.
- Set completo multi‑cloud con automazioni e test continui: 11–14 settimane.

Raccomandazioni operative
- Iniziare dall’inventory tecnica (Fase 0) per ottenere nomi risorsa, owners e mapping delle dipendenze.
- Produrre prima i runbook minimi ripetibili (scripts + pipeline) e poi estendere il provisioning su GCP.
- Tenere tutte le procedure "as‑code" nella repo per audit, review e rollback ripetibili.
- Per componenti legacy non containerizzabili, prevedere immagine VM automatizzata come transizione temporanea.

Materiale ADA utile da riusare (reference)
- DR_Plan_ADA.docx — checklists, runbook manuali e sequenze test.
- ADA Reference Architecture.pptx — diagrammi rete, zonizzazione, failover patterns.
- Esempi di runbook e playbook operativi (estrarre e trasformare in script).

Output che posso produrre subito (se approvi)
- Matrice inventory→RTO/RPO dettagliata in 5 giorni (CSV + MD).
- Template runbook DR‑MVP (script + pipeline) per DB+Storage+Ingress in 7–10 giorni.
- Repo Terraform POC su GCP (DB+GCS+Secret Manager+LB) in 7–14 giorni.

Prossimi passi consigliati (azione immediata)
1. Conferma: procedo con l'inventory tecnica (Fase 0) e genero la matrice dettagliata entro 5 giorni.
2. Durante l'inventory, raccolgo i contatti/owners e i nomi risorsa; successivamente stabiliamo la priorità per Phase 1 (SQL SID + teardown).
3. Manteniamo la documentazione aggiornata in wiki e versioniamo tutti gli artefatti as‑code nel repository.









## Vedi anche

- [Integrare le best-practice ADA in EasyWayDataPortal](./easyway-webapp/02_logiche_easyway/integrate-ada-best-practices.md)
- [DR — Inventory & matrice componente → RTO / RPO](./dr-inventory-matrix.md)
- [what is inventory and missing items](./Runbooks/what_is_inventory_and_missing_items.md)
- [Deployment decision (MVP) — EasyWay Data Portal](./deployment-decision-mvp.md)
- [EasyWay Data Portal — Onboarding & Architettura (Sintesi Unificata)](./onboarding-architettura.md)

