---
id: ew-runbooks-what-is-inventory-and-missing-items
title: what is inventory and missing items
summary: Spiega cos’è l’inventory (CSV/JSON), perché serve per DR e quali gap tipici emergono (runbook-as-code, SID sync, IaC, sync storage, ingress, monitoring).
status: active
owner: team-platform
tags: [docs, domain/control-plane, layer/reference, audience/ops, privacy/internal, language/it, inventory]
llm:
  include: true
  pii: none
  chunk_hint: 250-400
  redaction: [email, phone]
entities: []
updated: '2026-01-05'
next: TODO - definire next step.
---
Che cos'è l'"inventory" e a cosa serve (breve guida operativa)

1) Cos'è l'inventory
- L'inventory è un elenco strutturato e verificabile delle risorse tecniche che compongono EasyWayDataPortal: tipi di risorsa (Azure SQL, Storage Account/ADLS, App Service, Container App, Key Vault, Front Door, DNS zone, Private Endpoint, ecc.), nomi, resource group, subscription, endpoint/host, tag, owner operativo (nome/email) e informazioni minime utili (es. presenza di geo‑replica, HNS su storage, private endpoint).
- Formato tipico: CSV (riga = componente) + file JSON di supporto (esportato dallo script PowerShell).

2) A cosa serve l'inventory (per il progetto DR)
- Stabilire la "fotografia" completa e non ambigua dell'ambiente per:
  - identificare componenti critici da proteggere (P0/P1/P2),
  - definire RTO/RPO target per ciascun componente,
  - individuare dipendenze (es. DB dipende da Key Vault X / Hostname Y),
  - generare runbook automatizzabili (IaC + pipeline),
  - stimare effort e ordine di intervento per POC DR (GCP).
- L'inventory è prerequisito per costruire la matrice componente → RTO/RPO e per trasformare i runbook ADA‑centrici in artefatti "as‑code".

3) Output attesi dall'operazione di inventory
- File azure_inventory.json (output dello script) — raw export.
- DR_Inventory_Matrix.csv / .md — tabella sintetica con colonne: Component, ComponentType, ResourceName, ResourceGroup, Subscription, Environment, Owner, Criticality, BusinessImpact, RTO_target, RPO_target, RecoveryAction, Notes, Status.
- Report iniziale dei gap operativi (elenco prioritizzato).
- PR/issue list con attività tecniche (es. produrre script SID, TF POC GCP, runbook teardown).

4) Come useremo l'inventory per documentare cosa manca
- Parserò il JSON (o il CSV compilato) e popolerò DR_Inventory_Matrix.md/.csv.
- Per ogni componente identificherò:
  - se esistono meccanismi di recovery (geo‑replica, backup, failover group),
  - dipendenze critiche (Key Vault, private endpoints, DNS),
  - gap immediati (mancano script SID, mancanti moduli Terraform per GCP, sync storage, ecc.).
- Produrrò una lista actionabile: per ogni gap indicherò deliverable, priorità, owner raccomandato e stima sforzo.

5) Sintesi dei gap principali (riassunto rapido — cosa manca oggi)
- Runbook DR "as‑code" end‑to‑end — orchestrazione automatica per test DR (MVP required).
- Script sincronizzazione login SQL (SID) e permessi — necessario per DB senza autenticazione federata.
- Terraform / IaC per provisioning DR su GCP (Cloud SQL, GCS, Secret Manager, LB).
- Sincronizzazione storage (ADLS → GCS) con versioning.
- Segreti & certificati cross‑cloud (Key Vault ↔ Secret Manager) — pipeline sicura per test DR.
- Ingress / Global routing cross‑cloud (Front Door ↔ Cloud LB) + DNS failover playbook.
- Monitoring & test automation per misurare RTO/RPO (dashboard + runbook).
- Networking multi‑cloud mapping (Private Endpoint ↔ PSC/VPC) e regole firewall.
- Playbook rollback / teardown automatico per evitare costi e drift.

6) Prossimi passi concreti che posso fare ora (scegliere 1 o più)
- A) Generare e popolare DR_Inventory_Matrix.csv automaticamente a partire da azure_inventory.json (io eseguo parsing e creo CSV/MD).
- B) Creare la prima bozza del template script SQL SID + runbook teardown (artifact immediato).
- C) Creare il repo/bozza Terraform POC su GCP per Cloud SQL + GCS + Secret Manager (bozza).
- D) Preparare lista gap dettagliata ordinata per priorità (deliverable + effort stimato).

Indica quale azione vuoi che esegua subito (A, B, C o D) oppure conferma "procedi con A" se vuoi che inizi da inventory e matrice.









## Vedi anche

- [Integrare le best-practice ADA in EasyWayDataPortal](../easyway-webapp/02_logiche_easyway/integrate-ada-best-practices.md)
- [DR — Inventory & matrice componente → RTO / RPO](../dr-inventory-matrix.md)
- [Cosa integrare da ADA per EasyWayDataPortal (approccio operativo e cosa aggiungere)](../dr-gaps-vs-ada.md)
- [instructions collect azure inventory](./instructions_collect_azure_inventory.md)
- [iac](../easyway-webapp/05_codice_easyway_portale/iac.md)

