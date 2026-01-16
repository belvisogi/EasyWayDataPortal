---
id: ew-step-3---gestione-configurazioni-(yaml-+-db)
title: STEP 3 - Gestione configurazioni (YAML + DB)
tags: [domain/control-plane, layer/howto, audience/dev, audience/ops, privacy/internal, language/it, configuration, secrets]
owner: team-platform
summary: 'Documento su STEP 3 - Gestione configurazioni (YAML + DB).'
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
**Perché lo facciamo:**
* Vogliamo che ogni parametro (branding, label, path, preferenze) sia parametrico, centralizzato e modificabile senza deploy.
* Serve poter cambiare "skin" e regole di business per ogni tenant senza toccare il codice, ma solo modificando un file YAML (branding) o una riga di DB (configurazione runtime).

**A cosa serve:**
* `/config/brandingLoader.ts` — carica la configurazione branding/label/path da YAML (Blob/Datalake) con fallback al sample locale
* `/config/dbConfigLoader.ts` — carica parametri runtime dal database SQL Server
* `/types/config.d.ts` — tipizza le configurazioni, garantendo forma coerente nel codice

**Risultato:**
Qualsiasi nuovo tenant può avere UI, label, logica e preferenze dedicate creando un file YAML o record in tabella, senza scrivere o deployare nuovo codice.

**Questa sezione legge dinamicamente le configurazioni da YAML (Datalake) e da DB, a runtime, in base al tenant.**
Nota: l’accesso al Datalake è implementato via Azure Blob SDK con fallback su sample locale. Richiede env: `AZURE_STORAGE_CONNECTION_STRING` oppure Managed Identity con `AZURE_STORAGE_ACCOUNT`, oltre a `BRANDING_CONTAINER` e `BRANDING_PREFIX` (default `config`).

**3.1 `src/config/brandingLoader.ts`**
--------------------------------------

```typescript
// easyway-portal-api/src/config/brandingLoader.ts
import fs from "fs";
import path from "path";
import YAML from "yaml";
import { BlobServiceClient } from "@azure/storage-blob";
import { TenantConfig } from "../types/config";

/**
 * Carica configurazione branding YAML per un tenant.
 * Precede da Blob (container: BRANDING_CONTAINER, prefix: BRANDING_PREFIX, default "config/")
 * e fa fallback su sample locale.
 */
export async function loadBrandingConfig(tenantId: string): Promise<TenantConfig> {
  const connectionString = process.env.AZURE_STORAGE_CONNECTION_STRING;
  const containerName = process.env.BRANDING_CONTAINER;
  const prefix = process.env.BRANDING_PREFIX || "config";

  if (connectionString && containerName) {
    try {
      const blobServiceClient = BlobServiceClient.fromConnectionString(connectionString);
      const containerClient = blobServiceClient.getContainerClient(containerName);
      const blobName = `${prefix}/branding.${tenantId}.yaml`;
      const blockBlobClient = containerClient.getBlockBlobClient(blobName);
      if (await blockBlobClient.exists()) {
        const download = await blockBlobClient.download();
        const text = await streamToString(download.readableStreamBody as NodeJS.ReadableStream);
        return YAML.parse(text) as TenantConfig;
      }
    } catch { /* fallback */ }
  }

  const filePath = path.join(__dirname, "../../datalake-sample", `branding.${tenantId}.yaml`);
  if (!fs.existsSync(filePath)) throw new Error(`Branding YAML for tenant "${tenantId}" not found`);
  const fileContent = fs.readFileSync(filePath, "utf-8");
  return YAML.parse(fileContent) as TenantConfig;
}

async function streamToString(stream: NodeJS.ReadableStream): Promise<string> {
  const chunks: Buffer[] = [];
  return await new Promise((resolve, reject) => {
    stream.on("data", (d: Buffer) => chunks.push(d));
    stream.on("end", () => resolve(Buffer.concat(chunks).toString("utf-8")));
    stream.on("error", reject);
  });
}

```sql

**Dove va:**  
`easyway-portal-api/src/config/brandingLoader.ts`
**A cosa serve:**  
Legge il file di branding YAML prima da Blob (`BRANDING_CONTAINER`/`BRANDING_PREFIX` → `branding.{tenantId}.yaml`), altrimenti da sample locale; restituisce la configurazione tipizzata per il tenant richiesto.

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

Con questa struttura puoi già:
- Leggere branding e parametri UI dal file YAML per ogni tenant.
- Leggere parametri runtime dal DB.
- Integrare tutto nei controller/endpoint in modo atomico e parametrico.

* * *

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



## Vedi anche

- [create json](./step-1-setup-ambiente/create-json.md)
- [STEP 2 - Struttura src e primi file](./STEP-2-—-Struttura-src-e-primi-file.md)
- [checklist di test api](../../02_logiche_easyway/api-esterne-integrazione/checklist-di-test-api.md)
- [come si testa](./ENDPOINT/Template-ENDPOINT/come-si-testa.md)
- [step 1 setup ambiente](./step-1-setup-ambiente.md)
