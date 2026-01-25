# Agent Management Console - Database Impact Analysis

## 📊 Stima Crescita Database

### Scenario: 26 Agenti Attivi

#### Dati per Esecuzione
```sql
-- agent_executions: ~500 bytes per row
-- agent_metrics: ~200 bytes per row (2-3 per execution)
```

#### Calcolo Mensile

**Scenario Leggero (10 exec/giorno per agente):**
```
26 agenti × 10 exec/giorno × 30 giorni = 7,800 executions/mese

Storage:
- agent_executions: 7,800 × 500 bytes = ~3.9 MB/mese
- agent_metrics: 7,800 × 3 × 200 bytes = ~4.7 MB/mese
Total: ~8.6 MB/mese
```

**Scenario Medio (50 exec/giorno per agente):**
```
26 agenti × 50 exec/giorno × 30 giorni = 39,000 executions/mese

Storage:
- agent_executions: 39,000 × 500 bytes = ~19.5 MB/mese
- agent_metrics: 39,000 × 3 × 200 bytes = ~23.4 MB/mese
Total: ~43 MB/mese
```

**Scenario Pesante (200 exec/giorno per agente):**
```
26 agenti × 200 exec/giorno × 30 giorni = 156,000 executions/mese

Storage:
- agent_executions: 156,000 × 500 bytes = ~78 MB/mese
- agent_metrics: 156,000 × 3 × 200 bytes = ~93.6 MB/mese
Total: ~172 MB/mese
```

### Crescita Annuale

| Scenario | Mese | Anno | 3 Anni |
|----------|------|------|--------|
| Leggero | 8.6 MB | 103 MB | 309 MB |
| Medio | 43 MB | 516 MB | 1.5 GB |
| Pesante | 172 MB | 2 GB | 6 GB |

**Conclusione:** Anche nello scenario pesante, **6 GB in 3 anni è NULLA** per SQL Server! ✅

---

## 🗄️ Impatto Transaction Log

### Operazioni per Esecuzione

```sql
-- 1. Start execution
INSERT INTO agent_executions (...)  -- ~500 bytes

-- 2. Update to ONGOING
UPDATE agent_executions SET status='ONGOING' WHERE execution_id=X  -- ~200 bytes

-- 3. Record metrics (2-3 volte)
INSERT INTO agent_metrics (...)  -- ~200 bytes × 3 = 600 bytes

-- 4. Update to DONE
UPDATE agent_executions SET status='DONE', tokens_consumed=X, ...  -- ~300 bytes

Total per execution: ~1.6 KB transaction log
```

### Log Growth Mensile

**Scenario Medio (39,000 exec/mese):**
```
39,000 × 1.6 KB = ~62 MB/mese transaction log
```

**Con backup regolari:** Log si tronca automaticamente → **Impatto minimo**

---

## ⚡ Strategie di Ottimizzazione

### 1. **Retention Policy** (Raccomandato)

```sql
-- Stored Procedure: Cleanup vecchie esecuzioni
CREATE PROCEDURE AGENT_MGMT.sp_cleanup_old_executions
    @RetentionDays INT = 90
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @CutoffDate DATETIME2 = DATEADD(DAY, -@RetentionDays, GETDATE());
    
    -- Delete old metrics first (FK constraint)
    DELETE FROM AGENT_MGMT.agent_metrics
    WHERE execution_id IN (
        SELECT execution_id 
        FROM AGENT_MGMT.agent_executions
        WHERE completed_at < @CutoffDate
    );
    
    -- Delete old executions
    DELETE FROM AGENT_MGMT.agent_executions
    WHERE completed_at < @CutoffDate;
    
    -- Return rows deleted
    SELECT @@ROWCOUNT AS rows_deleted;
END;
GO

-- Schedule: Run monthly
-- Keeps last 90 days, deletes older
```

**Impatto:** Mantiene DB costante (~130 MB max nello scenario medio)

### 2. **Partitioning** (Solo se necessario)

```sql
-- Partiziona per mese (solo se >1M executions)
CREATE PARTITION FUNCTION pf_executions_monthly (DATETIME2)
AS RANGE RIGHT FOR VALUES (
    '2026-01-01', '2026-02-01', '2026-03-01', ...
);

-- Permette drop veloce di partizioni vecchie
```

**Quando:** Solo se superi 1 milione di executions (improbabile)

### 3. **Archiving** (Opzionale)

```sql
-- Archive to cheaper storage (Azure Blob, S3)
-- Keep last 30 days in SQL, rest in blob
CREATE PROCEDURE AGENT_MGMT.sp_archive_to_blob
    @ArchiveDays INT = 30
AS
BEGIN
    -- Export to JSON
    -- Upload to blob
    -- Delete from SQL
END;
```

**Quando:** Se vuoi storico infinito ma costi bassi

---

## 📈 Monitoring

### Query per Monitorare Crescita

```sql
-- 1. Dimensione tabelle
SELECT 
    t.name AS table_name,
    SUM(p.rows) AS row_count,
    SUM(a.total_pages) * 8 / 1024 AS size_mb
FROM sys.tables t
INNER JOIN sys.partitions p ON t.object_id = p.object_id
INNER JOIN sys.allocation_units a ON p.partition_id = a.container_id
WHERE t.schema_id = SCHEMA_ID('AGENT_MGMT')
    AND p.index_id IN (0,1)
GROUP BY t.name
ORDER BY size_mb DESC;

-- 2. Crescita giornaliera
SELECT 
    CAST(created_at AS DATE) as date,
    COUNT(*) as executions_count,
    SUM(tokens_consumed) as total_tokens
FROM AGENT_MGMT.agent_executions
WHERE created_at >= DATEADD(DAY, -30, GETDATE())
GROUP BY CAST(created_at AS DATE)
ORDER BY date DESC;

-- 3. Transaction log size
SELECT 
    name,
    size * 8 / 1024 AS size_mb,
    FILEPROPERTY(name, 'SpaceUsed') * 8 / 1024 AS used_mb
FROM sys.database_files
WHERE type_desc = 'LOG';
```

---

## ✅ Raccomandazioni

### Setup Iniziale

1. **Retention Policy: 90 giorni**
   ```sql
   -- Schedule job mensile
   EXEC AGENT_MGMT.sp_cleanup_old_executions @RetentionDays = 90;
   ```

2. **Backup Regolari**
   ```sql
   -- Full backup settimanale
   -- Differential backup giornaliero
   -- Log backup ogni 15 minuti (tronca log)
   ```

3. **Monitoring Alert**
   ```sql
   -- Alert se tabella > 1 GB
   -- Alert se log > 5 GB
   ```

### Limiti Consigliati

| Metrica | Limite | Azione |
|---------|--------|--------|
| Executions totali | < 500K | ✅ OK |
| Executions totali | 500K - 1M | ⚠️ Enable retention |
| Executions totali | > 1M | 🔴 Enable partitioning |
| DB size | < 5 GB | ✅ OK |
| DB size | 5-10 GB | ⚠️ Review retention |
| DB size | > 10 GB | 🔴 Enable archiving |

---

## 🎯 Conclusione

### Il DB va BENISSIMO! ✅

**Perché:**
- ✅ Crescita lenta (~43 MB/mese scenario medio)
- ✅ Facilmente gestibile con retention policy
- ✅ Nessun impatto su performance
- ✅ Transaction log controllabile con backup

**Azioni Immediate:**
1. ✅ Applica migration (safe!)
2. ✅ Setup retention policy (90 giorni)
3. ✅ Schedule backup regolari
4. ⏳ Monitor per 1 mese
5. ⏳ Adjust retention se necessario

**Worst Case (scenario pesante, no cleanup):**
- 6 GB in 3 anni
- SQL Server gestisce 100+ GB facilmente
- **Zero problemi!**

---

**TL;DR:** 
- **Impatto DB: MINIMO** 📉
- **Log: CONTROLLABILE** ✅
- **Vai tranquillo!** 🚀
