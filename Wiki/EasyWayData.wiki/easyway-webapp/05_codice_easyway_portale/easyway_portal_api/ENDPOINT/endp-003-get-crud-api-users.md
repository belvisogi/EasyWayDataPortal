---
id: ew-endp-003
title: CRUD /api/users
summary: Gestione utenti per tenant (elenco, creazione, aggiornamento, disattivazione).
status: active
owner: team-api
created: '2025-01-01'
updated: '2025-01-01'
tags: [artifact-endpoint, domain/frontend, layer/reference, audience/dev, privacy/internal, language/it]
title: endp 003 get crud api users
llm:
  include: true
  pii: none
  chunk_hint: 250-400
  redaction: [email, phone]
entities: []
next: TODO - definire next step.
---
### ENDPOINT: CRUD `/api/users`

**Descrizione**
> Permette la gestione completa degli utenti di un tenant (elenco, creazione, modifica, cancellazione/disattivazione).
> Tutto filtrato per `tenantId`, nessun tenant può accedere agli utenti degli altri.
Gestione completa degli utenti per tenant, tutto filtrato su `tenantId`.
Le query SQL vengono caricate dalla cartella `src/queries/` (fallback su custom Blob se serve).

**Best Practice**
- Validazione input obbligatoria (header, body)
- Tutte le operazioni sono sempre scoperte solo per il tenant corrente
- Risposta coerente e tipizzata, errori gestiti e chiari
- Logging di tutte le operazioni (minimo su console/logger, poi DB/audit trail)
- Testabilità garantita via Postman, REST Client, cURL
- Validazione input e sicurezza sempre attiva (header, body)
- Risposta coerente, errori gestiti
- Logging delle operazioni consigliato

**Cosa fa tecnicamente**
1. Recupera il `tenantId` dal middleware
2. Esegue query solo su utenti del tenant
3. Per ogni operazione (GET, POST, PUT, DELETE) aggiorna solo record del tenant
4. Restituisce risposta JSON, o errore
5. Recupera `tenantId` via middleware
6. Esegue query SQL caricata con fallback (Blob o locale)
7. Ogni endpoint risponde solo per il tenant corrente

**Come si testa**
- Avvia il backend (`npm run dev`)
- GET `/api/users` con header `X-Tenant-Id: tenant01` (elenco utenti tenant)
- POST `/api/users` con body JSON (creazione utente)
- PUT `/api/users/:user_id` (aggiornamento)
- DELETE `/api/users/:user_id` (disattivazione)


**Endpoint CRUD Utenti Multi-Tenant**
-------------------------------------

**Obiettivo:**  
Creare gli endpoint CRUD (Create, Read, Update, Delete) per la tabella `USERS`,  
seguendo le best practice multi-tenant e la struttura già definita.

### **A. Logica e best practice**

*   **Ogni operazione su USERS è SEMPRE filtrata su `tenantId`** (nessun utente di un tenant può vedere o modificare utenti di un altro tenant)
    
*   **Risposta e input sempre in JSON**
    
*   **Errori gestiti e descrittivi**
    
*   **Tipizzazione tramite TypeScript**
    
*   **Logging di operazioni CRUD (minimo via logger, poi estendibile su DB)**
    

* * *

### **B. Struttura dei nuovi file**

```sql
/src/
├─ controllers/
│    └─ usersController.ts
├─ models/
│    └─ user.ts
└─ routes/
     └─ users.ts
```sql

### **C. 1. Model (tipizzazione)**

`src/models/user.ts`

```sql
// easyway-portal-api/src/models/user.ts

export interface User {
  user_id: string;        // NDG, es: CDI0000010001
  tenant_id: string;
  email: string;
  display_name: string;
  is_active: boolean;
  profile_id: string;
  created_at: Date;
  updated_at: Date;
}
```sql

### **C. 2. Controller (logica CRUD base)**

`src/controllers/usersController.ts`

```sql
// easyway-portal-api/src/controllers/usersController.ts
import { Request, Response } from "express";
import sql from "mssql";
import { User } from "../models/user";

// Utility per estrarre tenant da req
function getTenantId(req: Request): string {
  return (req as any).tenantId;
}

// GET /api/users - lista utenti per tenant
export async function getUsers(req: Request, res: Response) {
  try {
    const tenantId = getTenantId(req);
    const pool = await sql.connect(process.env.DB_CONN_STRING!);

    const result = await pool.request()
      .input("tenant_id", sql.NVarChar, tenantId)
      .query("SELECT * FROM PORTAL.USERS WHERE tenant_id = @tenant_id");

    res.json(result.recordset as User[]);
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
}

// POST /api/users - crea utente per tenant
export async function createUser(req: Request, res: Response) {
  try {
    const tenantId = getTenantId(req);
    const { email, display_name, profile_id } = req.body;

    const pool = await sql.connect(process.env.DB_CONN_STRING!);
    // Generate nuovo NDG
    // Qui puoi mettere la tua logica: esempio con sequence SQL Server

    const result = await pool.request()
      .input("tenant_id", sql.NVarChar, tenantId)
      .input("email", sql.NVarChar, email)
      .input("display_name", sql.NVarChar, display_name)
      .input("profile_id", sql.NVarChar, profile_id)
      .query(`
        INSERT INTO PORTAL.USERS (tenant_id, email, display_name, profile_id, is_active, created_at, updated_at)
        VALUES (@tenant_id, @email, @display_name, @profile_id, 1, SYSUTCDATETIME(), SYSUTCDATETIME());
        SELECT * FROM PORTAL.USERS WHERE user_id = SCOPE_IDENTITY();
      `);

    res.status(201).json(result.recordset[0] as User);
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
}

// PUT /api/users/:user_id - aggiorna utente per tenant
export async function updateUser(req: Request, res: Response) {
  try {
    const tenantId = getTenantId(req);
    const { user_id } = req.params;
    const { email, display_name, profile_id, is_active } = req.body;

    const pool = await sql.connect(process.env.DB_CONN_STRING!);

    const result = await pool.request()
      .input("user_id", sql.NVarChar, user_id)
      .input("tenant_id", sql.NVarChar, tenantId)
      .input("email", sql.NVarChar, email)
      .input("display_name", sql.NVarChar, display_name)
      .input("profile_id", sql.NVarChar, profile_id)
      .input("is_active", sql.Bit, is_active)
      .query(`
        UPDATE PORTAL.USERS
        SET email = @email,
            display_name = @display_name,
            profile_id = @profile_id,
            is_active = @is_active,
            updated_at = SYSUTCDATETIME()
        WHERE user_id = @user_id AND tenant_id = @tenant_id;
        SELECT * FROM PORTAL.USERS WHERE user_id = @user_id AND tenant_id = @tenant_id;
      `);

    res.json(result.recordset[0] as User);
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
}

// DELETE /api/users/:user_id - disattiva utente per tenant
export async function deleteUser(req: Request, res: Response) {
  try {
    const tenantId = getTenantId(req);
    const { user_id } = req.params;

    const pool = await sql.connect(process.env.DB_CONN_STRING!);

    await pool.request()
      .input("user_id", sql.NVarChar, user_id)
      .input("tenant_id", sql.NVarChar, tenantId)
      .query(`
        UPDATE PORTAL.USERS
        SET is_active = 0,
            updated_at = SYSUTCDATETIME()
        WHERE user_id = @user_id AND tenant_id = @tenant_id;
      `);

    res.status(204).send();
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
}
```sql

### **C. 4. Aggiornamento app.ts**

Aggiungi l'import:

```sql
import usersRoutes from "./routes/users";

```sql

E sotto le altre route:
```sql
app.use("/api/users", usersRoutes);
```sql








## Domande a cui risponde
- Cosa fa questa pagina?
- Quali sono i prerequisiti?
- Quali passi devo seguire?
- Quali sono gli errori comuni?
- Dove approfondire?









