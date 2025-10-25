# Agent Datalake – Gestione Operativa e Compliance

## Scopo
Automatizza e governa le attività di gestione del Datalake su EasyWayDataPortal, garantendo naming, ACL, audit, retention, export log e compliance secondo policy aziendali e best practice.

## Uso rapido
- Interattivo (consigliato):
  - `pwsh scripts/agent-datalake.ps1`
- Selezione esplicita:
  - `pwsh scripts/agent-datalake.ps1 -Naming -ACL -Retention -ExportLog`
- Esegui tutto:
  - `pwsh scripts/agent-datalake.ps1 -All`
- Dry-run:
  - `pwsh scripts/agent-datalake.ps1 -WhatIf`

## Attività principali
- **Naming & Provisioning**: verifica e crea la struttura standard (landing/, staging/, official/, invalidrows/, technical/).
- **ACL & RBAC**: controlla e applica policy IAM (grp.portal.datalake.*), verifica assenza accessi diretti in produzione.
- **Retention & Compliance**: applica e verifica policy di retention su directory chiave.
- **Export Log**: automatizza export log, maschera dati sensibili, mantiene audit trail.
- **Audit & Policy**: verifica compliance, aggiorna documentazione e knowledge base.

## Prerequisiti
- PowerShell 7+
- Permessi su Azure Storage/Datalake
- azcopy installato e configurato
- Terraform (per provisioning avanzato)
- Accesso ai knowledge sources indicati in manifest.json

## Note
- Le regole operative sono definite in `priority.json`.
- Aggiornare la documentazione e la knowledge base dopo ogni modifica strutturale o policy.
- Per dettagli sulle policy naming, ACL e retention, consultare:
  - `EasyWay_WebApp/03_datalake_dev/easyway-dataportal-standard-accesso-storage-e-datalake-iam-and-naming.md`
