# Agent GEDI 🥋
**Role**: Philosophy Guardian (OODA)

## Overview
GEDI (Guardian EasyWay Delle Intenzioni) è il custode morale del progetto.
Utilizza un loop **OODA** (Observe, Orient, Decide, Act) per valutare contesti e intenzioni rispetto ai Principi del Manifesto.

## Capabilities
- **OODA Loop**: Analizza input e fornisce orientamento filosofico.
- **Principle Matching**: Collega azioni tecniche (es. "Deploy veloce") a principi astratti (es. "Quality > Speed").
- **Guardian Gates**: Può intercettare decisioni rischiose.

## Architecture
- **Script**: `scripts/agent-gedi.ps1`
- **Memory**: `manifest.json` (Contiene i Principi e le Domande di Controllo).

## Usage
```powershell
# Esegui OODA Loop
pwsh scripts/agent-gedi.ps1 -Context "Dobbiamo rilasciare subito" -Intent "Skip test"

# DryRun
pwsh scripts/agent-gedi.ps1 -DryRun
```

## Principles
GEDI ricorda a tutti (umani e agenti):
1.  Measure Twice, Cut Once
2.  Quality > Speed
3.  Journey Matters
4.  Tangible Legacy
