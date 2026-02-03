---
document_type: audit_report_example
version: 1
language: it
redacted: true
notes: "Template/esempio redatto: sostituire i placeholder con dati NON sensibili o mantenere fuori repo."
---

# Audit Report (Esempio Redatto) - <system-name>

**Target**: `<host-or-environment>`  
**Data**: `<YYYY-MM-DD>`  
**Metodo**: Read-Only / Zero Trace  
**Auditor**: Guardiani del Codice (fase 1)  

## Executive Summary

### Stato Generale
- **Outcome**: `pass | warn | fail`
- **Tier (label)**: `Clean | Sharp | Untouchable` (solo se outcome != fail)
- **Tier (canonico)**: `Bronze | Silver | Gold` (solo se outcome != fail)
- **Score**: `<0-100>`

### Top Findings (esempio)
1. **CRITICAL**: Secrets esposti in chiaro (env/file)
2. **CRITICAL**: Data loss risk (volumi mancanti)
3. **HIGH**: CVE/RCE in componenti esposti
4. **HIGH**: Firewall/defense-in-depth incompleto
5. **MEDIUM**: Logging/observability incompleta

## Metodologia (WHAT)
- Comandi e tool usati devono essere riproducibili.
- Nessuna modifica persistente al target.
- Output salvato come evidenza (log/artefatti) e riferito nel report.

## Risk Matrix (riassunto)
| Categoria | Esito | Note |
|---|---:|---|
| Security Hardening | pass/warn/fail | <nota> |
| CVE/Vulnerability | pass/warn/fail | <nota> |
| Network Exposure | pass/warn/fail | <nota> |
| Operations / Data | pass/warn/fail | <nota> |
| Observability | pass/warn/fail | <nota> |

## Findings (formato standard)

### CRITICAL-001: <titolo>
- **Severity**: critical
- **Outcome**: fail
- **Perche' conta**: <business impact>
- **Evidence**:
  - `path/log`: `<artifact or log reference>`
  - `snippet`: `<redacted>`
- **Remediation (next)**:
  1) <azione 1>
  2) <azione 2>

### HIGH-001: <titolo>
- **Severity**: high
- **Outcome**: warn
- **Evidence**: <...>
- **Remediation**: <...>

## Allegati (artefatti)
- `out/guardians-audit.json`
- `out/issues.json`
- `out/evidence/` (log, output tool, screenshot) - opzionale

## Emissione attestato
- Se `outcome=fail`: emettere attestato negativo "Found Wanting" (senza tier).
- Se `outcome=warn`: attestato valido ma con riserve.
- Se `outcome=pass`: attestato pieno.
