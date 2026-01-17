---
id: ew-step-4-query-dinamiche-locale-datalake
title: step 4 query dinamiche locale datalake
tags: [domain/frontend, layer/howto, audience/dev, privacy/internal, language/it]
owner: team-platform
summary: Gestione query SQL: versionamento locale + override su Blob/Datalake con fallback e audit.
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
[[start-here|Home]] > [[domains/frontend|frontend]] > [[Layer - Howto|Howto]]

### Gestione delle query SQL nel backend EasyWay

**Pattern adottato: “Locale + Custom/Blob”**

- Tutte le query core, CRUD, migration, viste e stored procedure sono versionate nella cartella `src/queries/` del backend.
    - Ogni modifica a queste query richiede una nuova versione e un deploy del backend (best practice per coerenza e audit).
    - Sono facilmente consultabili e manutenibili da tutto il team.
- In casi particolari (override temporanei, hotfix urgenti, necessità di patch “a caldo”, report dinamici multi-tenant):
    - Le query possono essere salvate su Azure Datalake/Blob sotto `/portal-config/queries/`.
    - Il backend è predisposto a cercare prima la versione custom (blob), e se non trovata, utilizza quella locale.
    - La pipeline DevOps gestisce versioning, update e audit anche dei file custom.

**Vantaggi:**
- Massima coerenza e sicurezza per la logica core.
- Flessibilità per esigenze particolari o evoluzioni future, senza cambiare il bundle del backend.


### **A. Struttura della cartella queries**

Crea questa struttura nel tuo progetto:
```sql
easyway-portal-api/
└─ src/
    └─ queries/
        ├─ users_insert.sql
        ├─ users_select_by_tenant.sql
        ├─ users_update.sql
        ├─ users_delete.sql
        └─ ... (aggiungi altre query quando servono)
```sql

B. Esempio di file SQL (users_insert.sql)

```sql
-- users_insert.sql
EXEC PORTAL.sp_debug_register_tenant_and_user
  @tenant_id = @tenant_id,
  @email = @email,
  @display_name = @display_name,
  @profile_id = @profile_id;
```sql

### **C. Funzione di caricamento query con fallback (custom su blob, locale default)**

`src/queries/queryLoader.ts`

```sql
import fs from "fs";
import path from "path";
import { loadSqlQueryFromBlob } from "../config/queryLoader";

/**
 * Carica una query SQL:
 * - Prima cerca su Blob Storage (custom override)
 * - Se non trovata, usa la versione locale sotto /src/queries
 */
export async function loadQueryWithFallback(fileName: string): Promise<string> {
  try {
    // Tenta override su Blob (custom)
    return await loadSqlQueryFromBlob(fileName);
  } catch (err) {
    // Se errore (es: blob non esiste), fallback su query locale
    const localPath = path.join(__dirname, fileName);
    if (!fs.existsSync(localPath)) {
      throw new Error(`Query "${fileName}" non trovata né su Blob né localmente`);
    }
    return fs.readFileSync(localPath, "utf-8");
  }
}
```sql

D. Uso nel controller utenti (esempio su createUser)
src/controllers/usersController.ts

```sql
import { loadQueryWithFallback } from "../queries/queryLoader";

export async function createUser(req: Request, res: Response) {
  try {
    const tenantId = (req as any).tenantId;
    const { email, display_name, profile_id } = req.body;
    const pool = await sql.connect(process.env.DB_CONN_STRING!);

    // Usa il loader "con fallback"
    const sqlQuery = await loadQueryWithFallback("users_insert.sql");

    const result = await pool.request()
      .input("tenant_id", sql.NVarChar, tenantId)
      .input("email", sql.NVarChar, email)
      .input("display_name", sql.NVarChar, display_name)
      .input("profile_id", sql.NVarChar, profile_id)
      .query(sqlQuery);

    res.status(201).json(result.recordset[0]);
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
}
```sql
(Stesso schema su tutte le altre operazioni CRUD)



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

---

### ⬇️ See also / Workflow correlati

- [n8n-db-table-create → Come creare una nuova tabella DB in modo agentico/automatizzato con intent, pipeline n8n, agent_dba e aggiornamento Wiki](../../../orchestrations/n8n-db-table-create.md)  
 Per accelerare e standardizzare la creazione di nuove tabelle versionate e documentate in EasyWay DataPortal, usa questo workflow orchestrato a partire da una “intent spec” e l’integrazione pipeline agent_dba+n8n.

