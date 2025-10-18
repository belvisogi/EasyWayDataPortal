---
id: ew-step-3-—-gestione-configurazioni-(yaml-+-db)
title: STEP 3 — Gestione configurazioni (YAML + DB)
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
*   Vogliamo che **ogni parametro** (branding, label, path, preferenze) sia **parametrico, centralizzato e modificabile senza deploy**.
    
*   Serve poter cambiare “skin” e regole di business per ogni tenant,  
    senza toccare il codice ma solo modificando un file YAML (branding) o una riga di DB (configurazione runtime).
    
**A cosa serve:**
*   `/config/brandingLoader.ts` → carica la configurazione branding/label/path da YAML (su Datalake o sample locale)
    
*   `/config/dbConfigLoader.ts` → carica parametri runtime dal database SQL Server
    
*   `/types/config.d.ts` → assicura che tutte le configurazioni abbiano sempre la stessa forma e tipo
    
**Risultato:**  
**Qualsiasi nuovo tenant può avere la sua UI, label, logica e preferenze**  
– basta creare un nuovo file YAML o un record in tabella, senza scrivere o deployare nuovo codice.


**Questa sezione ti permette di leggere dinamicamente le configurazioni sia da YAML (Datalake) sia da DB, a runtime, in base al tenant.**
NB: L’accesso al Datalake qui è simulato (sample locale). L’integrazione reale la aggiungeremo in seguito (con Azure Blob SDK/credentials, etc).

**3.1 `src/config/brandingLoader.ts`**
--------------------------------------

```typescript
// easyway-portal-api/src/config/brandingLoader.ts
import fs from "fs";
import path from "path";
import YAML from "yaml";
import { TenantConfig } from "../types/config";

/**
 * Carica configurazione branding YAML per un tenant.
 * @param tenantId Tenant identificativo
 * @returns TenantConfig oggetto configurazione branding/label/path
 */
export function loadBrandingConfig(tenantId: string): TenantConfig {
  // In produzione: monta qui il path del file su Datalake/Blob
  const filePath = path.join(__dirname, "../../datalake-sample", `branding.${tenantId}.yaml`);
  if (!fs.existsSync(filePath)) {
    throw new Error(`Branding YAML for tenant "${tenantId}" not found`);
  }
  const fileContent = fs.readFileSync(filePath, "utf-8");
  const config = YAML.parse(fileContent);
  return config as TenantConfig;
}

```sql

**Dove va:**  
`easyway-portal-api/src/config/brandingLoader.ts`
**A cosa serve:**  
Legge il file di branding YAML (per ora locale), restituisce la configurazione tipizzata per il tenant richiesto.

* * *

**3.2 `src/config/dbConfigLoader.ts`**
--------------------------------------
```typescript
// easyway-portal-api/src/config/dbConfigLoader.ts
import sql from "mssql";

/**
 * Carica parametri di configurazione dal DB per un tenant.
 * @param tenantId Tenant identificativo
 * @param section  Sezione di configurazione (opzionale)
 * @returns Oggetto chiave/valore della config
 */
export async function loadDbConfig(
  tenantId: string,
  section?: string
): Promise<Record<string, string>> {
  // Connessione DB (parametri da .env)
  const pool = await sql.connect({
    user: process.env.DB_USER,
    password: process.env.DB_PASS,
    server: process.env.DB_HOST,
    database: process.env.DB_NAME,
    options: { encrypt: true }
  });

  let query = `SELECT config_key, config_value FROM PORTAL.CONFIGURATION WHERE tenant_id = @tenant_id AND enabled = 1`;
  if (section) query += ` AND section = @section`;

  const request = pool.request().input("tenant_id", sql.NVarChar, tenantId);
  if (section) request.input("section", sql.NVarChar, section);

  const result = await request.query(query);
  const config: Record<string, string> = {};
  result.recordset.forEach((row: any) => {
    config[row.config_key] = row.config_value;
  });
  return config;
}

```sql

**Dove va:**  
`easyway-portal-api/src/config/dbConfigLoader.ts`
**A cosa serve:**  
Legge parametri runtime (feature toggle, limiti, preferenze, ecc.) dal DB SQL Server, filtrando per tenant e (opzionale) sezione.

* * *

**3.3 `src/config/index.ts`**
-----------------------------

```typescript

// easyway-portal-api/src/config/index.ts
import { loadBrandingConfig } from "./brandingLoader";
import { loadDbConfig } from "./dbConfigLoader";

export { loadBrandingConfig, loadDbConfig };

```sql

**Dove va:**  
`easyway-portal-api/src/config/index.ts`
**A cosa serve:**  
Espone i loader di configurazione come modulo centralizzato.

* * *

* * *

**Con questa struttura puoi già**:
*   Leggere branding e parametri UI dal file YAML per ogni tenant
    
*   Leggere parametri runtime dal DB
    
*   Integrare tutto nei controller/endpoint in modo atomico e parametrico
    
* * *


## Domande a cui risponde
- Cosa fa questa pagina?
- Quali sono i prerequisiti?
- Quali passi devo seguire?
- Quali sono gli errori comuni?
- Dove approfondire?

