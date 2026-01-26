---
id: ew-automazione-export-log-su-datalake-e-compliance
title: automazione export log su datalake e compliance
tags: [domain/control-plane, layer/howto, audience/ops, audience/dev, privacy/internal, language/it]
owner: team-platform
summary: Automazione export dei log business/audit su Datalake (pipeline + azcopy) con security e audit trail.
status: active
llm:
  include: true
  pii: none
  chunk_hint: 250-400
  redaction: [email, phone]
entities: []
updated: '2026-01-05'
next: TODO - definire next step.
---
[Home](../../../../../../docs/project-root/DEVELOPER_START_HERE.md) > [[Domain - Control-Plane|Control-Plane]] > [[Layer - Howto|Howto]]

# Automazione export log su Datalake & Compliance

## Obiettivo
Centralizzare e storicizzare i log business/audit esportandoli su Azure Datalake  
in modo automatizzato, sicuro e compliant con policy GDPR, SOC2, DORA.

## Soluzione consigliata (EasyWay Data Portal)

- **Pipeline Azure DevOps** che esegue periodicamente (es. ogni notte) un export automatico dei file log (`logs/business.log.json`) sul Datalake (`/portal-logs/`).
- **Task di export** basato su [azcopy](https://learn.microsoft.com/en-us/azure/storage/common/storage-use-azcopy-v10)  
  (CLI ufficiale Microsoft, auditata e supportata).

---

## Flusso tecnico

1. **Scrittura dei log**:  
   Il backend scrive tutti i log business/audit in file JSON locali (`logs/business.log.json`).
2. **Automazione export**:  
   Una pipeline DevOps (o uno script schedulato) lancia azcopy per copiare i log sul container Datalake dedicato.
3. **Sicurezza**:  
   Solo l’identità di servizio della pipeline può scrivere su `/portal-logs/`.
4. **Audit trail**:  
   Ogni run della pipeline è tracciata (chi, quando, esito) e auditabile via Azure DevOps.

---

## Snippet esempio pipeline (YAML)

```yaml
trigger: none

schedules:
  - cron: "0 1 * * *"  # Ogni notte alle 01:00
    displayName: Export business log to Datalake
    branches:
      include: ["main"]

jobs:
- job: ExportBusinessLog
  pool:
    vmImage: 'ubuntu-latest'
  steps:
  - script: |
      azcopy copy "logs/business.log.json" "https://NOMESTORAGE.dfs.core.windows.net/portal-logs/business_$(date +%Y%m%d).log.json" --overwrite=true
    displayName: 'Upload log su Datalake'
    env:
      AZCOPY_SPA_CLIENT_SECRET: $(AZCOPY_SPA_CLIENT_SECRET)
```sql

Policy e best practice
----------------------

*   **Logga solo ciò che serve, maschera tutto il resto.**
    
*   **Mai dati sensibili in chiaro**: i log su Datalake non devono contenere password, hash, dati personali non mascherati, info sensibili (vedi policy log).
    
*   **Tutto il workflow di export è tracciato via pipeline,** con alert in caso di errore/fallimento.
    
*   **L’utenza di servizio usata da azcopy** è segregata e ha solo i permessi minimi necessari.
    

* * *

Alternative e note
------------------

*   Per esigenze ETL complesse o grandi volumi: valuta Azure Data Factory (ADF) per orchestrare export e trasformazioni log.
    
*   Composer/Airflow solo per ambienti già maturi DataOps o multi-cloud.
    
*   Mai export “a mano”: solo automazione tracciata.
    

* * *

Compliance
----------

*   **Soluzione auditabile, tracciata e gestita via Azure AD** (RBAC, Managed Identity).
    
*   Retention su Datalake secondo policy di sicurezza/legale.
    
*   Allineata a best practice Microsoft, GDPR, SOC2, DORA.
    

* * *

**Vedi anche:**
*   Sezione “Gestione Log”
    
*   Policy log dati sensibili

## Domande a cui risponde
- Cosa fa questa pagina?
- Quali sono i prerequisiti?
- Quali passi devo seguire?
- Quali sono gli errori comuni?
- Dove approfondire?


## Prerequisiti
- Accesso al repository e al contesto target (subscription/tenant/ambiente) se applicabile.
- Strumenti necessari installati (es. pwsh, az, sqlcmd, ecc.) in base ai comandi presenti nella pagina.
- Permessi coerenti con il dominio (almeno read per verifiche; write solo se whatIf=false/approvato).

## Passi
1. Raccogli gli input richiesti (parametri, file, variabili) e verifica i prerequisiti.
2. Esegui i comandi/azioni descritti nella pagina in modalita non distruttiva (whatIf=true) quando disponibile.
3. Se l'anteprima e' corretta, riesegui in modalita applicativa (solo con approvazione) e salva gli artifact prodotti.

## Verify
- Controlla che l'output atteso (file generati, risorse create/aggiornate, response API) sia presente e coerente.
- Verifica log/artifact e, se previsto, che i gate (Checklist/Drift/KB) risultino verdi.
- Se qualcosa fallisce, raccogli errori e contesto minimo (command line, parametri, correlationId) prima di riprovare.



