# Agent Audit 👮
**Role**: Inspector

## Overview
Questo agente è il **Guardiano dello Standard**.
Il suo compito è scansionare tutti gli altri agenti e verificare che rispettino la "Constitutional Architecture" definita in `standards/agent-architecture-standard.md`.

## Capabilities
- **Architecture Validation**: Verifica presenza di Manifest e README.
- **Schema Validation**: Controlla che `manifest.json` abbia tutti i campi obbligatori (`role`, `readme`, `knowledge_sources`).
- **Integrity Check**: Verifica che gli script eferenziati nel manifest esistano davvero su disco.
- **Auto-Fix** 🚑: È in grado di "sanare" automaticamente violazioni comuni (es. Missing README, Missing Manifest Fields).

## Architecture
- **Script**: `scripts/agent-audit.ps1`
- **Memory**: Scansiona la directory `agents/`.
- **Reference**: `Wiki/EasyWayData.wiki/standards/agent-architecture-standard.md`

## Usage
```powershell
# Esegui audit completo (Read-Only)
pwsh scripts/agent-audit.ps1

# Auto-Fix (Tenta di riparare gli agenti rotti)
pwsh scripts/agent-audit.ps1 -AutoFix

# DryRun (Simulazione)
pwsh scripts/agent-audit.ps1 -DryRun
```

## Principles
- **Strict but Fair**: Segnala errori bloccanti (Missing Manifest) e Warning (Missing Description).
- **Healer**: Se autorizzato (`-AutoFix`), interviene per ripristinare lo standard minimo.

## Maintainers
- **Team**: Platform / Governance
