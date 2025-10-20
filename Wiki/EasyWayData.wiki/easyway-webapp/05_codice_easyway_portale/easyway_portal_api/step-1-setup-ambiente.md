---
id: ew-step-1-setup-ambiente
title: step 1 setup ambiente
summary: 
owner: 
tags:
  - 
  - privacy/internal
  - language/it
llm:
  include: true
  pii: 
  chunk_hint: 400-600
  redaction: [email, phone]
entities: []
---
**Perché lo facciamo:**
*   Mettere le fondamenta tecniche della WebApp, in modo che sia **gestibile**, **scalabile**, e facile da sviluppare/manutenere.
    
*   Centralizzare tutte le dipendenze, script, regole TypeScript, e le istruzioni base per chi ci lavorerà.
    
**A cosa serve:**
*   `package.json` → gestisce tutte le dipendenze e i comandi del progetto
    
*   `tsconfig.json` → configura TypeScript per build e qualità del codice
    
*   `README.md` → punto di partenza per qualsiasi sviluppatore o nuovo membro del team
    
*   `/datalake-sample/` → fornisce un **esempio** di configurazione YAML, modello per tutte le personalizzazioni future
    
**Risultato:**  
Hai un **progetto Node.js/TypeScript “pulito”**, pronto a crescere e completamente standard.

A) Struttura cartelle iniziale

```sql
easyway-portal-api/
│
├─ package.json           # [Root del progetto] Configurazione NPM (codice, mai su datalake)
├─ tsconfig.json          # [Root del progetto] Config TypeScript (codice, mai su datalake)
├─ README.md              # [Root del progetto] Guida tecnica (codice, mai su datalake)
│
├─ /src                   # [Root del progetto] Codice TypeScript dell’app API
│
├─ /datalake-sample       # [Root del progetto] Solo esempi locali dei file YAML (brand/config), NON in produzione!
│
└─ /deploy                # [Root del progetto] File di pipeline o script CI/CD
```sql

### **B) Dove stanno i file realmente**

*   **package.json, tsconfig.json, README.md, src/**  
    Sono **file e cartelle di codice**:
    *   **Vanno SEMPRE nella root del repository di codice** (`easyway-portal-api/`)
        
    *   **Non devono mai stare sul Datalake**, né in cartelle dati, né su storage pubblico
        
    *   Sono gestiti da Git/Azure DevOps come ogni altro codice di backend
        

* * *

### **C) Cosa metti (e NON metti) su Datalake**

*   **Su Datalake** metterai SOLO i file di configurazione/branding YAML “produttivi”,  
    cioè quelli che l’app dovrà leggere per mostrare i colori, le etichette, le immagini per ciascun tenant.
    
*   **Nel repo di codice** tieni una cartella `/datalake-sample` (o simile)  
    **solo per esempi** e versionamento degli “schemi” di configurazione  
    (non è usata a runtime, serve solo come template/copia).
    

* * *

### **D) Dettaglio file per file**

* * *

#### **1. package.json**

*   **Dove va:**  
    `easyway-portal-api/package.json` (root della repo del codice, **mai su datalake**)
    
*   **A cosa serve:**  
    File di **configurazione NPM**.  
    Contiene:
    *   Nome progetto
        
    *   Versione
        
    *   Script di avvio/build/test
        
    *   Dipendenze (librerie di Node.js e TypeScript)
        
*   **Perché serve:**  
    Senza questo, il progetto non è gestibile da Node.js, non puoi installare o usare dipendenze, né fare il deploy.
    

* * *

#### **2. tsconfig.json**

*   **Dove va:**  
    `easyway-portal-api/tsconfig.json`
    
*   **A cosa serve:**  
    File di **configurazione TypeScript** (regole di compilazione, output, etc.)
    
*   **Perché serve:**  
    Permette di scrivere in TypeScript e ottenere il codice pronto da eseguire su Node.js.
    

* * *

#### **3. README.md**

*   **Dove va:**  
    `easyway-portal-api/README.md`
    
*   **A cosa serve:**  
    Guida tecnica per chi lavora sul progetto.  
    Spiega comandi, cartelle, configurazioni minime, come avviare/localmente/buildare.
    

* * *

#### **4. /src/**

*   **Dove va:**  
    `easyway-portal-api/src/`
    
*   **A cosa serve:**  
    Contiene **TUTTO il codice sorgente** della webapp (Express, middleware, API, ecc.)
    
*   **Perché serve:**  
    Qui scrivi e mantieni tutto il backend dell’applicazione.
    

* * *

#### **5. /datalake-sample/**

*   **Dove va:**  
    `easyway-portal-api/datalake-sample/`
    
*   **A cosa serve:**  
    **Solo per esempio/template** dei file di configurazione YAML da usare/produrre su Datalake.
    
*   **Cosa va davvero su Datalake:**  
    Solo i file definitivi, tipo `/portal-assets/config/branding.tenant01.yaml`  
    (i file di esempio sono solo reference per sviluppatori).
    

* * *

#### **6. /deploy/**

*   **Dove va:**  
    `easyway-portal-api/deploy/`
    
*   **A cosa serve:**  
    File di pipeline Azure DevOps (`azure-pipelines.yml`), script di deploy CI/CD,  
    **mai su datalake**, solo nel repo di codice o su Azure DevOps.
    

* * *

**In sintesi pratica**
----------------------

*   **Tutto il codice (Node.js/TypeScript, config progetti, pipeline) sta nella repo codice.**
    
*   **Solo le configurazioni di branding, label, path, ecc. che servono all’app in runtime, vanno in Datalake (e ci vanno tramite pipeline/script, non “a mano”).**
    
*   **Tutto ciò che riguarda tabelle e insert DB, sta solo nella chat DB, mai qui.**

## Domande a cui risponde
- Cosa fa questa pagina?
- Quali sono i prerequisiti?
- Quali passi devo seguire?
- Quali sono gli errori comuni?
- Dove approfondire?

