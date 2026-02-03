---
document_type: remediation_plan_example
version: 1
language: it
redacted: true
notes: "Template/esempio redatto: i dettagli operativi sensibili (IP, key name, credenziali) devono stare fuori repo."
---

# Remediation Plan (Esempio Redatto) - <system-name>

**Baseline**: Audit Report `<YYYY-MM-DD>`  
**Target**: Compliance/Best Practices  
**Timeline**: `<N settimane>`  

## Obiettivo
Ridurre rischio e aumentare affidabilita' fino a raggiungere almeno:
- `Clean (Bronze)` come baseline
- `Sharp (Silver)` come target operativo
- `Untouchable (Gold)` come hardening serio

## Priorita' (phased)

### Fase 1 - CRITICAL (entro 48h)
- CRITICAL-001: <titolo> -> <azione> (checkpoint + rollback)
- CRITICAL-002: <titolo> -> <azione>

### Fase 2 - HIGH (entro 1-2 settimane)
- HIGH-001: <titolo> -> <azione>
- HIGH-002: <titolo> -> <azione>

### Fase 3 - MEDIUM/LOW (entro 3-4 settimane)
- MEDIUM-001: <titolo> -> <azione>

## Playbook per ogni item (formato standard)

### <ID>: <titolo>
- **Severity**: critical|high|medium|low
- **Owner**: <team/ruolo>
- **Effort**: <ore>
- **Prerequisiti**: <lista>
- **Step**:
  1) <step 1>
  2) <step 2>
- **Checkpoint**: <condizione verificabile>
- **Rollback**: <come tornare indietro>
- **Evidence da produrre**:
  - log/comandi
  - configurazione (redatta)
  - screenshot/metriche

## Uscita (Definition of Done)
- Tutti i CRITICAL chiusi.
- Nessun secrets exposure.
- Evidenze archiviate.
- Re-run audit: outcome migliora e tier raggiunto.
