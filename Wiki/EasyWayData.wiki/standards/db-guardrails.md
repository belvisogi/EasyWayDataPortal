---
title: "DB Guardrails"
category: standards
domain: db
tags: sql, guardrails, dba, best-practices
priority: critical
audience:
  - developers
  - dba
last-updated: 2026-01-17
---

# DB Guardrails

Standard di sviluppo database per EasyWayDataPortal.

## 🔴 Critical Rules (MUST)

### 1. Insert: Explicit Columns
**Regola**: Mai usare `INSERT INTO table SELECT ...` senza specificare le colonne.
**Perché**: Se l'ordine fisico delle colonne cambia (o se ne aggiungono di nuove), lo script si rompe o inserisce dati nella colonna sbagliata.
**Esempio**:
```sql
-- ❌ BAD
INSERT INTO TargetTable
SELECT * FROM SourceTable;

-- ✅ GOOD
INSERT INTO TargetTable (ColA, ColB, ColC)
SELECT ColA, ColB, ColC FROM SourceTable;
```sql

### 2. Primary Keys & Not Nulls
**Regola**: Assicurarsi di popolare tutte le colonne NOT NULL e Primary Key, anche se non presenti nella source immediata.
**Perché**: Evita failure a runtime.
**Esempio**:
Se `TargetTable` ha `LEGAL_ENTITY_BRANCH` come PK, non puoi ignorarla.
```sql
-- ✅ GOOD
INSERT INTO TargetTable (LEGAL_ENTITY_BRANCH, Code, Description)
SELECT 
    'GLD&A',  -- Default/Explicit Value for PK
    Code, 
    Description 
FROM SourceTable;
```sql

### 3. Avoid Random DISTINCT
**Regola**: Evitare `SELECT DISTINCT` su tutto il set senza analisi.
**Perché**: `DISTINCT` è costoso e maschera problemi di duplicazione (cartesian products) a monte. Se `perimeter` o `local_hub` tornano più righe del previsto, rischi insert multipli non voluti.
**Better Approach**:
- Identifica la chiave univoca della source.
- Usa `GROUP BY` o `ROW_NUMBER()` se devi deduplicare.
- Fai join esplicite sulle chiavi.

## 🟡 Best Practices (SHOULD)

- **Naming**: UpperSnakeCase per tabelle e colonne (es. `CUSTOMER_DATA`).
- **Idempotenza**: Gli script devono poter essere rieseguiti senza errori (`IF NOT EXISTS`).
