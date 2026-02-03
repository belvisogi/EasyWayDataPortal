---
id: ew-dr-inventory-matrix
title: DR — Inventory & matrice componente → RTO / RPO
summary: Template di inventory DR con matrice componenti e target RTO/RPO, usabile come input per runbook-as-code e PoC di disaster recovery.
status: active
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
[Home](../../scripts/docs/project-root/DEVELOPER_START_HERE.md) > [[domains/docs-governance|Docs]] > [[Layer - Blueprint|Blueprint]]

# DR — Inventory & matrice componente → RTO / RPO

Scopo
- Fornire una matrice operativa che elenchi i componenti critici di EasyWayDataPortal con i relativi dati essenziali (resource type, resource name, RG, owner) e gli obiettivi RTO/RPO. Questo documento serve come output della Fase 0 e come input per le attività di POC DR (Terraform, runbook, sincronizzazione storage, segreti).

Nota
- Se possibile popolare automaticamente con lo script `scripts/collect_azure_inventory.ps1`. In alternativa, compilare manualmente il CSV sottostante.

Formato CSV (intestazione)
- Copia l'intestazione qui sotto in un file CSV (es. Wiki/EasyWayData.wiki/DR_Inventory_Matrix.csv) oppure usa il blocco CSV qui presente per lavorare direttamente.

CSV Header
Component,ComponentType,ResourceName,ResourceGroup,Subscription,Environment (prod/stg/dev),Owner (name/email),Criticality (P0/P1/P2),BusinessImpact (descrizione breve),RTO_target,RPO_target,RecoveryAction (runbook/terraform/module),Notes,Status

Esempio CSV (riga di esempio)
"Portal API","App Service","ew-portal-api","rg-ew-prod","subs-contoso-prod","prod","dbadmin@contoso.com","P0","Blocco operativo se down","04:00","00:15","Runbook-DB-Failover / TF-POC-GCP","Requires SID sync script","ToDo"

Blocco CSV (puoi copiare/incollare)
Component,ComponentType,ResourceName,ResourceGroup,Subscription,Environment (prod/stg/dev),Owner (name/email),Criticality (P0/P1/P2),BusinessImpact (descrizione breve),RTO_target,RPO_target,RecoveryAction (runbook/terraform/module),Notes,Status
"","", "", "", "", "", "", "P1", "", "04:00", "00:30", "", "", "TBD"

Linee guida per la compilazione
- Component: nome applicativo o componente (es. Portal API, Portal DB, Portal Storage, Auth service, CDN, DNS).
- ComponentType: tipo di risorsa (Azure SQL, Storage Account / ADLS Gen2, App Service, Container App, Key Vault, Front Door, Private Endpoint, etc.)
- RTO_target / RPO_target: formati consigliati hh:mm (es. 04:00, 00:15). Se non ancora definiti lascia "TBD".
- Criticality: P0 = critico (blocco produzione), P1 = degrado funzionale importante, P2 = non critico.
- RecoveryAction: link a runbook-as-code previsto o a modulo Terraform da eseguire in DR.
- Notes: indicare dipendenze (es. dipende da Key Vault X), presenza di Private Endpoint, necessità di SID sync, ecc.
- Status: ToDo / InProgress / Done / NotApplicable.

Priorità suggerita di popolamento
1. Raccogliere e compilare subito tutti i database e gli storage critici (Azure SQL, Storage Accounts, Key Vaults).
2. Compilare hostnames/endpoint per ingress (Front Door / App Gateway / Frontends) e DNS zones.
3. Identificare owner e contatti operativi (email) per ogni componente.
4. Per DB: indicare se esiste geo‑replica o failover group; se no, marcarlo come gap da colmare.

Output che genererò dopo popolamento
- Versione MD della matrice con riepilogo per criticality (tabella aggregata).
- CSV pronto per import in foglio di calcolo.
- Elenco gap operativi e deliverable immediati (es. script SID, Terraform POC per Cloud SQL/GCS, runbook teardown).
- PR in repo con runbook template + task list prioritarie.

Prossimi passi consigliati (azione)
- Esegui lo script `pwsh -NoProfile -ExecutionPolicy Bypass -File .\scripts\collect_azure_inventory.ps1 -OutputFile .\azure_inventory.json` e incolla qui la sezione SqlServers / SqlDatabases / KeyVaults / StorageAccounts / PrivateEndpoints / WebApps / FrontDoors / DnsZones.
- Oppure: scarica il CSV con intestazione e compila manualmente le righe principali (DB, Storage, Ingress, KeyVault).

Se vuoi, genero subito il file CSV fisico nella wiki (Wiki/EasyWayData.wiki/DR_Inventory_Matrix.csv) con l'intestazione: dimmi se preferisci che lo crei ora.









## Vedi anche

- [Cosa integrare da ADA per EasyWayDataPortal (approccio operativo e cosa aggiungere)](./dr-gaps-vs-ada.md)
- [what is inventory and missing items](./Runbooks/what_is_inventory_and_missing_items.md)
- [Integrare le best-practice ADA in EasyWayDataPortal](./easyway-webapp/02_logiche_easyway/integrate-ada-best-practices.md)
- [Deployment decision (MVP) — EasyWay Data Portal](./deployment-decision-mvp.md)
- [EasyWay Data Portal — Onboarding & Architettura (Sintesi Unificata)](./onboarding-architettura.md)





