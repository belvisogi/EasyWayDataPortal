# Database Guardrails - Living Standard

## 🎯 Cos'è

**Guardrails** = Regole automaticamente validate dagli agent per garantire qualità, sicurezza e consistenza del database.

**Owner**: `agent_dba` (operational governance)  
**Advisory**: `agent_gedi` (feedback strategico, mai bloccante)  
**Status**: Living document - si arricchisce nel tempo  
**Versione**: 1.0.0

---

## 🚨 Come Funziona

```
Developer/AI crea/modifica oggetto DB
           ↓
agent_dba valida vs Guardrails
           ↓
    PASS → Deploy
    FAIL → Report violations + suggestions
           ↓
Developer fix violations
           ↓
Deploy proceeds
           ↓
[In parallelo, sempre]
agent_gedi 🦗 → Fornisce feedback strategico
  "Questo guardrail potrebbe impattare la roadmap X"
  "Considera di aggiungere guardrail Y per coerenza"
  (Mai bloccante, solo advisory)
```

---

## 📋 Guardrails Attivi

### G1: Stored Procedures Standard
**Severity**: 🔥 CRITICAL  
**Owner**: agent_dba

**Rules**:
- [ ] Nome: `sp_action_entity` (lowercase, underscore)
- [ ] `SET NOCOUNT ON` presente
- [ ] TRY...CATCH error handling
- [ ] Transaction (BEGIN TRAN / COMMIT / ROLLBACK)
- [ ] Logging: chiamata a `sp_log_stats_execution`
- [ ] Output standard: `status`, `id`, `error_message`, `rows_affected`
- [ ] Extended property con descrizione
- [ ] Schema prefix (`PORTAL.sp_*`)

**Auto-fix Available**: ✅ Partial (SET NOCOUNT ON, schema prefix)

**Examples**:
```sql
-- ✅ GOOD
CREATE PROCEDURE PORTAL.sp_insert_user
AS
BEGIN
  SET NOCOUNT ON;
  BEGIN TRY
    BEGIN TRAN;
    -- logic
    COMMIT;
    SELECT 'OK' AS status, @user_id AS id;
  END TRY
  BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK;
    SELECT 'ERROR' AS status, ERROR_MESSAGE() AS error_message;
  END CATCH
END;

-- ❌ BAD
CREATE PROC InsertUser  -- Wrong name, no schema
AS
  INSERT INTO USERS...;  -- No error handling, no transaction
```

---

### G2: Technical Fields Required
**Severity**: 🔥 CRITICAL  
**Owner**: agent_dba

**Rules**: Ogni tabella DEVE avere:
- [ ] `created_by NVARCHAR(255) NOT NULL DEFAULT 'SYSTEM'`
- [ ] `created_at DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME()`
- [ ] `updated_at DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME()`
- [ ] `ext_attributes NVARCHAR(MAX)` (extensibility)
- [ ] `status NVARCHAR(32)` (soft state machine)

**Optional but Recommended**:
- `updated_by NVARCHAR(255)` (audit trail)
- `deleted_at DATETIME2` (soft delete)
- `deleted_by NVARCHAR(255)` (who deleted)
- `version INT DEFAULT 1` (optimistic locking)

**Exceptions**: System tables (sequences, schemas)

**Auto-fix Available**: ✅ Yes - genera migration per aggiungere campi

---

### G3: Multi-Tenancy Required
**Severity**: 🔥 CRITICAL (Security!)  
**Owner**: agent_dba

**Rules**: Tabelle business DEVONO avere:
- [ ] `tenant_id NVARCHAR(50) NOT NULL`
- [ ] Index su `tenant_id` (performance)
- [ ] RLS policy definita
- [ ] RLS policy testata (SESSION_CONTEXT check)

**Exceptions**: 
- Tabelle di configurazione globale
- Log/audit centrali
- Lookup tables condivise

**Auto-fix Available**: ⚠️ Partial - richiede review manuale

---

### G4: Primary Keys Standard
**Severity**: 🟡 HIGH  
**Owner**: agent_dba

**Rules**:
- [ ] Nome colonna: `id` (simple, standard)
- [ ] Tipo: `BIGINT IDENTITY(1,1)` (large tables) o `INT IDENTITY` (small)
- [ ] Constraint: `PRIMARY KEY`
- [ ] Nome constraint: `PK_TABLENAME` (readable)

**Auto-fix Available**: ✅ Yes - rename constraints

---

### G5: Business Keys Recommended
**Severity**: 🟡 MEDIUM  
**Owner**: agent_dba

**Rules**:
- [ ] Tabelle anagrafiche DOVREBBERO avere chiave naturale
- [ ] Pattern comune: `{entity}_code`, `{entity}_ref`, `external_id`
- [ ] UNIQUE constraint su business key
- [ ] Index su business key

**Example**:
```sql
CREATE TABLE PORTAL.CUSTOMER (
  id BIGINT IDENTITY PRIMARY KEY,
  customer_code NVARCHAR(50) NOT NULL,  -- ✅ Business key
  tenant_id NVARCHAR(50) NOT NULL,
  name NVARCHAR(255),
  CONSTRAINT UX_CUSTOMER_tenant_code UNIQUE(tenant_id, customer_code)
);
```

**Auto-fix Available**: ❌ No - richiede decisione business

---

### G6: Extended Properties Required
**Severity**: 🟡 MEDIUM  
**Owner**: agent_dba

**Rules**:
- [ ] Ogni tabella deve avere `MS_Description`
- [ ] Colonne chiave devono avere `MS_Description`
- [ ] Campi PII marcati con `PII=true` extended property
- [ ] SP con esempi di chiamata in extended property

**Auto-fix Available**: ✅ Partial - AI genera descrizioni da naming

---

### G7: Conversational Intelligence Ready
**Severity**: 🔥 CRITICAL (Differentiatore!)  
**Owner**: agent_dba

**Rules**: Ogni SP deve essere AI-friendly:
- [ ] Parametri self-documenting (`@tenant_id` not `@tid`)
- [ ] Output JSON-parsable (SELECT con colonne fisse)
- [ ] Logging su `STATS_EXECUTION_LOG`
- [ ] Extended property con esempio prompt
- [ ] Versione DEBUG disponibile (`sp_debug_*`)

**Example Extended Property**:
```sql
EXEC sp_addextendedproperty 
  @name = 'AI_Prompt_Example',
  @value = 'Crea utente per tenant TEN001: EXEC sp_insert_user @tenant_id=''TEN001'', @email=''user@test.com''',
  @level0type = 'SCHEMA', @level0name = 'PORTAL',
  @level1type = 'PROCEDURE', @level1name = 'sp_insert_user';
```

**Auto-fix Available**: ✅ Partial - standardizza output format

---

### G8: Security - No SQL Injection
**Severity**: 🔥 CRITICAL (Security!)  
**Owner**: agent_dba + agent_security

**Rules**:
- [ ] NEVER string concatenation in dynamic SQL
- [ ] Use `sp_executesql` con parametri
- [ ] Input validation su pattern (email, phone, etc.)
- [ ] Escape user input

**Example**:
```sql
-- ❌ BAD - SQL Injection risk!
EXEC('SELECT * FROM USERS WHERE email = ''' + @email + '''');

-- ✅ GOOD
EXEC sp_executesql 
  N'SELECT * FROM USERS WHERE email = @e',
  N'@e NVARCHAR(320)',
  @e = @email;
```

**Auto-fix Available**: ⚠️ Detection only - fix richiede review

---

### G9: PII/GDPR Compliance
**Severity**: 🔥 CRITICAL (Legal!)  
**Owner**: agent_dba + agent_gedi

**Rules**:
- [ ] Campi PII identificati e marcati (extended property)
- [ ] Masking policy per PII
- [ ] Retention policy documentata
- [ ] Access audit per PII

**PII Fields Pattern**:
- Email, phone, SSN, IP address
- Name, surname, date of birth
- Location, address
- Credit card, bank account

**Auto-fix Available**: ✅ Detection + masking policy generation

---

### G10: Migration Quality
**Severity**: 🟡 MEDIUM  
**Owner**: agent_dba

**Rules**:
- [ ] Nome file: `V{N}__{description}.sql`
- [ ] Header comment con scopo + ticket
- [ ] Idempotent (IF NOT EXISTS pattern)
- [ ] 1 file = 1 scopo (no mix CREATE + INSERT)
- [ ] Rollback script generato (DOWN migration)

**Auto-fix Available**: ✅ Yes - rename, add headers, split files

---

## 🔄 Guardrail Lifecycle

### Come Aggiungere Nuovo Guardrail

```
1. Pain Point Discovered
   "Troviamo sempre SP senza indexes sulle FK"

2. Formalize Rule
   G11: Foreign Key Indexes Required

3. Define Check
   - Scan all FK
   - Check if index exists on FK column
   - Report missing indexes

4. Implement Validator
   Add rule to validator.js

5. Add to Guardrails.md
   Document + esempi

6. Comunica Team
   Announce new guardrail

7. Grace Period
   Warning-only per 2 settimane

8. Enforce
   Block deploy se violation
```

### Versioning

```
Version: MAJOR.MINOR.PATCH

MAJOR: Breaking change (new CRITICAL guardrail)
MINOR: New guardrail (non-breaking)
PATCH: Clarification, esempi

History:
- 1.0.0 (2026-01-15): Initial 10 guardrails
```

---

## 🤖 Agent Responsibilities

### agent_dba (Operational Owner)
- **Valida** guardrails su ogni deploy/PR
- **Genera** report violations automatici
- **Suggerisce** fix automatici
- **Applica** auto-fix se safe
- **Propone** nuovi guardrails da pattern
- **Mantiene** GUARDRAILS.md aggiornato
- **Risponde** a `db-guardrails:check` calls

### agent_gedi (Il "Grillo Parlante" 🦗 - Guardian EasyWay Delle Intenzioni)
- **Custode del Manifesto**: Ricorda principi EasyWay a tutti
- **Advisory ONLY** - NON può bloccare deploy
- **Chiamato a fine lavoro** da ogni agent per feedback filosofico
- **Commenta** su decisioni architetturali (quality > speed?)
- **Suggerisce** miglioramenti basati su principi manifesto
- **Review** quality gates e decisioni strategiche
- **Sempre presente**, mai bloccante

**Principi che Protegge**:
- Qualità > Velocità
- Misuriamo due, tagliamo una
- Il percorso conta
- Lasciare impronta tangibile
- "Non ne parliamo, risolviamo" (Velasco)

**Filosofia**: 
> "agent_gedi è la coscienza del sistema - ti ricorda i principi EasyWay e ti dice se qualcosa puzza filosoficamente, ma sei TU che decidi se procedere"

**Separation of Concerns**:
- agent_dba = "Poliziotto" 👮 (enforce technical rules, può bloccare)
- agent_gedi = "Grillo Parlante" 🦗 (ricorda principi filosofici, mai blocca)

**Pattern**: Tutti gli agent chiamano GEDI a fine lavoro per philosophical review.  
**Dettagli**: Vedi `agents/GEDI_INTEGRATION_PATTERN.md`

---

## 📊 Compliance Dashboard

```
agent_dba.execute({
  action: "guardrails:check",
  scope: "all"  // o "sp" o "tables" o specifico
});

Output:
{
  "compliance_score": 85,
  "total_guardrails": 10,
  "passed": 8,
  "failed": 2,
  "violations": [
    {
      "guardrail": "G2",
      "severity": "CRITICAL",
      "count": 3,
      "objects": ["LEGACY_TABLE1", "LEGACY_TABLE2", "TEMP_DATA"]
    }
  ],
  "recommendations": [
    "Add technical fields to 3 tables",
    "Enable RLS on 2 policies"
  ]
}
```

---

## 🎯 Roadmap

**Q1 2026**:
- [ ] Implement top 5 guardrails (G1, G2, G3, G7, G8)
- [ ] CI/CD integration (block merge se CRITICAL fail)
- [ ] Dashboard web per compliance

**Q2 2026**:
- [ ] Implement remaining guardrails
- [ ] Auto-fix per tutti i possibili
- [ ] Historical tracking violations

**Q3 2026**:
- [ ] ML-based anomaly detection (nuovi pattern)
- [ ] Cross-database guardrails (Oracle, PostgreSQL)
- [ ] Community-contributed rules

---

## 📝 Governance Process

**Monthly**:
- Review violations
- Discuss new guardrails da proporre
- Update documentation

**Quarterly**:
- Compliance audit completo
- Version bump se necessario
- Team training su nuove regole

**On-Demand**:
- Exception request process
- Emergency guardrail disable (incident)

---

**Living Document** - Questo file evolverà con voi! 🚀

**Last Updated**: 2026-01-15  
**Next Review**: 2026-02-15  
**Owners**: agent_dba, agent_gedi
