---
id: why-not-flyway
title: Perché NON usare Flyway per questo progetto
summary: Analisi e decisione di dismettere Flyway in favore di approccio Git + SQL diretto per EasyWayDataPortal.
status: active
owner: team-data
created: '2026-01-14'
updated: '2026-01-18'
tags:
  - layer/reference
  - privacy/internal
  - language/it
  - decision-record
llm:
  include: true
  pii: none
  chunk_hint: 400-600
  redaction: [email, phone]
entities: []
---

> [!IMPORTANT]
> **✅ Decisione Confermata: 2026-01-18**
> 
> Questa decisione è stata confermata e implementata. Flyway è ufficialmente dismesso per EasyWayDataPortal.
> 
> **Approccio attuale**: Git + SQL Diretto
> 
> **Guida canonica**: [db-migrations.md](./db-migrations.md)

# Perché NON usare Flyway per questo progetto

## TL;DR
Flyway aggiunge complessità senza benefici sufficienti per database SQL Server con stored procedures complesse.

## Contesto
Dopo 2+ ore di debugging, abbiamo scoperto che Flyway richiede una gestione perfetta dei batch separator `GO` che SQL Server usa tra CREATE PROCEDURE/FUNCTION statements. Nel nostro caso con 50+ stored procedures, questo è diventato ingestibile.

## Problemi Riscontrati

### 1. **Batch Separator (`GO`) Nightmare**
SQL Server richiede `GO` tra:
- Ogni CREATE PROCEDURE
- Ogni CREATE FUNCTION  
- Alcuni DDL statements

Flyway processa questi in modo particolare, causando errori criptici tipo:
- "must be the first statement in a query batch"
- "uniqueidentifier is incompatible with int" (quando batch errati causano ordine sbagliato)

### 2. **SQL Server 2014 Compatibility Hell**
Il database era su SQL Server 2014 (compatibility level 120), che non supporta:
- `CREATE OR ALTER` (introdotto in SQL 2016)
- `STRING_SPLIT()` (introdotto in SQL 2016)

Abbiamo dovuto:
- Riscrivere 6 file SQL (V6, V9, V11, V101, V102, V103)
- Sostituire CREATE OR ALTER con IF EXISTS + DROP + CREATE + GO
- Sostituire STRING_SPLIT con workaround XML
- Upgrade finale a SQL 2019 per risolvere

### 3. **Migration Version Chaos**
16 file di migrazione (V1-V11, V100-V103) hanno creato:
- Dipendenze non chiare tra versioni
- Difficoltà nel debug (quale file sta fallendo?)
- Schema corrotto da migrazioni parzialmente applicate

### 4. **Overhead vs Benefici**
**Costi**:
- 2+ ore di debugging
- Complessità di configurazione
- File multipli da gestire
- Errori difficili da capire

**Benefici** (per noi):
- Tracking versioni → **GIT lo fa già**
- Rollback automatico → **Non supportato da Flyway Community**
- Multi-environment → **Abbiamo solo DEV per ora**

## Soluzione Adottata: SQL Diretto

### Approccio
1. **File consolidato**: `V1__initial_schema.sql` (unico file con tutto lo schema)
2. **Applicazione diretta**: `sqlcmd` o Azure Portal Query Editor
3. **Versioning**: Git commit del file SQL

### Vantaggi
✅ **Semplicità**: Un comando, zero configurazione  
✅ **Debugging**: Errori SQL chiari e immediati  
✅ **Controllo**: Vedi esattamente cosa viene eseguito  
✅ **Velocità**: 30 secondi vs 2 ore di setup Flyway  
✅ **Manutenibilità**: Facile aggiungere V2, V3 in futuro

### Per Migrazioni Future
```powershell
# 1. Crea nuovo file
# db/migrations/V2__add_notifications.sql

# 2. Applica direttamente
sqlcmd -S server -d database -U user -P pass -i V2__add_notifications.sql

# 3. Commit in git
git add db/migrations/V2__add_notifications.sql
git commit -m "Migration V2: Add notifications feature"
```sql

## Quando Flyway È Utile

Flyway è eccellente quando:
✅ Database PostgreSQL, MySQL (meno problemi con batch)  
✅ Schema semplice senza molte stored procedures  
✅ Team grande che lavora su branch multipli  
✅ Deployment automatizzato in CI/CD con rollback  
✅ Multi-environment complesso (10+ ambienti)

## Quando NON Usare Flyway

❌ SQL Server con molte stored procedures/functions  
❌ Team piccolo (1-2 dev)  
❌ Progetto semplice con poche migrazioni  
❌ Database legacy con compatibility issues  
❌ Quando Git + SQL manuale sono sufficienti

## Conclusione

Per **EasyWayDataPortal**:
- Team: 1-2 dev
- Database: SQL Server con 50+ stored procedures
- Ambienti: Solo DEV per ora
- Frequenza migrazioni: Bassa

**Decisione**: Git + SQL diretto è la scelta migliore. Semplice, veloce, manutenibile.

## Alternative Considerate

1. **Liquibase** - Stesso problema con batch separators
2. **EF Core Migrations** - Richiede Entity Framework, overkill
3. **SSDT Database Projects** - Microsoft-specific, complesso setup
4. **Git + SQL Manuale** - ✅ **SCELTO**

## Note Tecniche

### Upgrade Fatto
- Database compatibility level: 120 → 150 (SQL Server 2019)
- Comando: `ALTER DATABASE EASYWAY_PORTAL_DEV SET COMPATIBILITY_LEVEL = 150;`
- Impatto costi: Zero
- Benefici: Supporto CREATE OR ALTER, STRING_SPLIT, performance migliori

### File Consolidato
- Tutti i 16 file V1-V103 uniti in `V1__initial_schema.sql`
- Include: DDL tables, functions, stored procedures, seed data
- Dimensione: ~40KB
- Pronto per applicazione diretta

---

**Data decisione**: 2026-01-14  
**Flyway utilizzato**: No  
**Alternativa**: sqlcmd + Git

