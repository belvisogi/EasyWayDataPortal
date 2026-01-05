---
id: ew-step-4-query-dinamiche-locale-datalake
title: step 4 query dinamiche locale datalake
tags: [domain/frontend, layer/howto, audience/dev, privacy/internal, language/it]
owner: team-platform
summary: Gestione query SQL: versionamento locale + override su Blob/Datalake con fallback e audit.
status: draft
llm:
  include: true
  pii: none
  chunk_hint: 250-400
  redaction: [email, phone]
entities: []
---
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








