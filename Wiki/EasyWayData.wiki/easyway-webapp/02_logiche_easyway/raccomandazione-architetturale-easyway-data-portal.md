---
id: ew-raccomandazione-architetturale-–-easyway-data-portal
title: Raccomandazione Architetturale – EasyWay Data Portal
summary: 'Documento su Raccomandazione Architetturale – EasyWay Data Portal.'
status: active
owner: team-docs
created: '2025-01-01'
updated: '2025-01-01'
tags: [domain/control-plane, layer/spec, audience/dev, audience/ops, privacy/internal, language/it, architecture]
title: raccomandazione architetturale easyway data portal
llm:
  include: true
  pii: none
  chunk_hint: 250-400
  redaction: [email, phone]
entities: []
next: TODO - definire next step.
---
[Home](.././start-here.md) >  > 

**EasyWay Data Portal** nasce come piattaforma SaaS multi-tenant, orientata alla scalabilità, alla sicurezza e alla modularità, con un’architettura a microservizi/container, rigorosamente separata per domini funzionali e tenant.

**Raccomandazione:**  
Si consiglia di adottare, per la fase di rilascio MVP e per le prime evoluzioni produttive, una **soluzione basata su Azure App Service Plan e/o Azure Container Apps**, orchestrando i microservizi come container indipendenti e gestendo il routing, l’autenticazione e la sicurezza tramite Azure API Management.

Questa scelta consente di:
- **Accelerare la delivery** e semplificare la gestione, mantenendo costi contenuti e prevedibili
- **Centralizzare policy di sicurezza, naming, audit, template e configurazione** secondo quanto definito nell’analisi funzionale
- **Testare e iterare rapidamente** nuove funzionalità, onboarding di tenant/clienti, evoluzioni API e servizi esterni
- **Mantenere la portabilità dei microservizi**: la stessa logica, i container e le pipeline potranno essere in futuro migrati su Azure Kubernetes Service (AKS), senza bisogno di refactoring profondo

**Prevedere l’adozione graduale di AKS** come step successivo quando il volume di utenti, la richiesta di alta disponibilità e la necessità di features avanzate (mesh, multi-region, federazione, multi-cloud) lo richiederanno, sfruttando la piena compatibilità con le best practice già impostate.

**Questa strategia bilancia rapidità, governance, costi e “future proofing”**, garantendo la continuità di sviluppo e la scalabilità della piattaforma,  
senza vincolare la crescita futura o la sicurezza operativa.

> Tutte le scelte architetturali sono state validate sulla base dell’analisi funzionale, delle best practice enterprise e delle esigenze specifiche di business.


#Valutazione tecnica

**1. Cos’è (e cosa deve essere) EasyWay Data Portal**
-----------------------------------------------------

### **Dalle chat emerge chiaramente che:**

*   EasyWay Data Portal è un **SaaS B2B multi-tenant** moderno, orientato a:
    *   **Data platform** e dashboard multi-dominio (economics, sostenibilità, data quality, e-commerce, integrazione API esterne…)
        
    *   **Accesso controllato e segregato per tenant/cliente** (e per ruoli/profili/gruppi ACL)
        
    *   **Sicurezza, compliance (GDPR/SOC2/DORA), tracciabilità, versioning e audit trail** a livello enterprise
        
    *   **Alta configurabilità**, template e workflow personalizzabili, onboarding flessibile, policy gestite via DB/parametri
        
*   Vuoi una piattaforma **“future proof”**: pronta per nuove estensioni, microservizi, federazione, API, crescita dei dati
    
*   **Centralità di:**
    *   DB relazionale strutturato (SQL Server, modelli GOLD/BRONZE/PORTAL…)
        
    *   Storage Datalake (Azure)
        
    *   Microservizi/Container come logica di servizio (gestione domini, ACL, integrazione API)
        
    *   Provisioning e gestione accessi via Azure Entra ID, policy IAM strutturata, naming convenzionato
        
*   Vuoi evitare “monoliti” e preferisci una **Web App composta da microservizi/container**,  
    ma con governance semplice, sicurezza top, e capacità di deployment e test anche su ambiente dev/local
    

* * *

**2. Che alternative architetturali abbiamo su Azure?**
-------------------------------------------------------

### **A. Azure App Service Plan + Container**

*   Containerizzando i microservizi ma deployando su istanze PaaS, con scaling gestito da Azure
    
*   **Pro:**
    *   Semplicità di setup, costi prevedibili, nessuna gestione cluster/VM
        
    *   Perfetto per MVP, PoC e piccoli team
        
    *   Facile da integrare con pipeline Azure DevOps/GitHub Actions
        
*   **Contro:**
    *   Limitato nel clustering avanzato, scaling multi-regione, service mesh, gestione segreti evoluta
        
    *   Più “monolitico” in gestione release: meno adatto per decine di microservizi indipendenti
        

### **B. Azure Container Apps**

*   Un’evoluzione tra App Service e AKS: gestisce il deployment di container, scaling on demand, senza dover gestire un cluster AKS
    
*   **Pro:**
    *   Molta elasticità, auto-scaling anche su eventi/kafka
        
    *   Più economico di AKS per carichi fluttuanti/batch
        
    *   Perfetto per microservizi indipendenti, senza overhead di cluster management
        
*   **Contro:**
    *   Più nuovo/meno maturo di App Service o AKS (meno documentazione, meno automazioni enterprise)
        
    *   Limiti su networking avanzato rispetto ad AKS puro
        

### **C. AKS – Azure Kubernetes Service (full cluster Kubernetes)**

*   Il top della flessibilità, ma anche della complessità gestionale
    
*   **Pro:**
    *   Standard de facto per microservizi/container a livello enterprise, multi-cloud, multi-region
        
    *   Gestione service mesh, ingress, segreti, RBAC, operator, custom CRD, rolling update, canary deploy, blue/green…
        
    *   Pronto per federazioni, evoluzioni architetturali, orchestrazione avanzata
        
*   **Contro:**
    *   Curva di apprendimento, overhead gestionale (patch, backup, monitoring, logging cluster)
        
    *   Costi fissi (minimo 1-3 VM sempre attive, anche a carico zero)
        
    *   Pipeline CI/CD più complesse, più error-prone se il team non è già formato su Kubernetes
        

* * *

**3. Quale scegliere per EasyWay Data Portal?**
-----------------------------------------------

**La tua vision** (dalle chat) indica una piattaforma che:
*   Deve **scalare e federarsi** in futuro, ma che **vuoi lanciare in modo rapido e ordinato** oggi
    
*   Prevede tanti microservizi, ma con processi chiari di audit, naming, e gestione template
    
*   Vuole essere sempre pronta a “migrare di livello” senza bloccare il delivery
    

### **La mia raccomandazione pratica:**

### **Fase 1 (MVP, primo go-live, delivery rapido):**

*   **App Service Plan + Container Apps**
    *   Sfrutta i microservizi come container (con Azure Container Registry)
        
    *   Deploy su App Service Plan o Azure Container Apps
        
    *   Governa routing via Azure API Management Developer (per dev) o Standard (per prod)
        
    *   **PRO:**
        *   Semplicità, rapidità di sviluppo, test locale immediato, costi bassi (vedi sotto)
            
        *   Governance IAM, naming, logging già allineati a quanto progettato
            

### **Fase 2 (Crescita, enterprise, federazione, multi-region):**

*   **Migrazione graduale ad AKS**
    *   Una volta consolidati processi, security, pipeline, si può spostare (anche uno alla volta) i microservizi/container su AKS
        
    *   Permette di scalare, isolare, federare a piacere, e aggiungere advanced features (service mesh, autoscaling, multi-cloud ecc.)
        

* * *

**4. Forecast costi (2025)**
----------------------------

### **Scenario 1 – App Service Plan + Container Apps + Dev API Management**

*   **App Service Plan S1**: ~65 €/mese per app (scalabile, ma puoi partire anche con meno)
    
*   **Azure Container Registry**: ~4 €/mese (Basic, storage immagini)
    
*   **Container Apps**: pay-per-use, costi bassi per microservizi “sleeping”
    
*   **API Management Developer**: 45 €/mese (dev/test, nessun SLA)
    
*   **Storage Account (LRS)**: ~20 €/mese (datalake dev, prezzi variabili)
    
*   **DB SQL Server**: da ~15-80 €/mese (dev/test, si adatta a carico, DTU/Managed Instance)
    

> **Stima costi DEV/PoC**:  
> ~150-250 €/mese per tutto il core, **se tieni poche risorse attive** e spegni/elimini quelle non usate (es. API Mgmt).

> **Stima costi PROD primo go-live**:  
> 250-400 €/mese se attivi almeno 2-3 microservizi/container, API Mgmt Standard, storage + DB SQL, scaling base.

* * *

### **Scenario 2 – AKS (Kubernetes Full)**

*   **AKS cluster**: almeno 2 nodi VM (B2s): ~50 €/mese per nodo = 100 €/mese
    
*   **Load balancer pubblico AKS**: ~18 €/mese
    
*   **Container Registry**: 4 €/mese
    
*   **API Mgmt Standard**: 700 €/mese (se vuoi alta disponibilità, proxy, multi-tenant)
    
*   **Storage + DB**: come sopra (~20 + 80 €/mese)
    

> **Stima minima mensile, anche a risorse spente:**  
> AKS+API Mgmt Standard: **~900-1.000 €/mese** per ambiente produzione  
> (con opzione di abbassare i costi solo riducendo i nodi o scegliendo API Mgmt Basic).

* * *

### **Scenario 3 – Hybrid/Container Apps**

*   **Container Apps**: se usi scaling su eventi, batch, lavori saltuari
    
*   Costi elastici (scali a zero se nessun traffico)
    
*   Perfetto per ambienti dev, test, PoC, e per servizi accessori
    

* * *

**5. PRO/CONTRO – Tabella pratica**
-----------------------------------

| Approccio | PRO | CONTRO | Quando preferirlo |
| --- | --- | --- | --- |
| App Service Plan | Semplicità, costi bassi, poco setup, start veloce | Meno custom/scalabile di AKS | MVP, go-live veloce, team piccolo |
| Container Apps | Scalabilità elastica, poco management, pay per use | Meno maturo, meno networking avanzato | Batch, microservizi separati, PoC |
| AKS (Kubernetes) | Enterprise, massima flessibilità, standard de facto | Costi fissi, curva learning, più devops | Espansione, federazione, grandi volumi |

* * *

**6. Visione d’insieme / Best Practice finale**
-----------------------------------------------

**Iniziare con App Service Plan/Container Apps** è la scelta migliore per EasyWay Data Portal ora:
*   Delivery rapido, costi sotto controllo, possibilità di test locale
    
*   Puoi implementare TUTTE le best practice già progettate (ACL, logging, security, onboarding, API Mgmt)
    
*   **Quando (e se) crescerai**: potrai fare “lift & shift” su AKS gradualmente,  
    riutilizzando pipeline, container, policy e naming (già standardizzato)
    
**AKS sarà lo step naturale appena serviranno:**
*   Multi-region
    
*   Migliaia di utenti/concurrency elevata
    
*   Custom routing/networking/mesh avanzate
    
*   Federation/multi-cloud
    

* * *

### **Azioni pratiche immediate**

*   Prepara i manifest/container e pipeline **in modo che siano già “portabili”** (Dockerfile, IaC, template versionati)
    
*   Centralizza policy e naming in repository/Key Vault, come già previsto
    
*   **Non fossilizzarti ora su AKS**: è la naturale evoluzione, ma puoi starci dopo con calma e senza ansie di lock-in
    

* * *

**7. Forecast futuro**
----------------------

*   **Dev/test:** puoi mantenere costi <200€/mese
    
*   **Prod**: per tutto il portale “base”, stimerei **300-500€/mese** in modalità PaaS/container,  
    salendo a >900€/mese solo scegliendo full AKS con API Mgmt Standard/Premium.


## Domande a cui risponde
- Cosa fa questa pagina?
- Quali sono i prerequisiti?
- Quali passi devo seguire?
- Quali sono gli errori comuni?
- Dove approfondire?












