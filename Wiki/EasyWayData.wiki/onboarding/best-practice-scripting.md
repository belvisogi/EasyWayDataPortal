---
id: ew-best-practice-scripting
title: Scripting Best Practice (Cross-platform, PowerShell, Bash)
tags: [onboarding, devx, scripting, crossplatform, ps1, bash, style, audience/dev, language/it]
summary: Linee guida essenziali per scrivere/gestire script agentici portabili nel progetto EasyWay DataPortal.
status: draft
owner: team-platform
updated: '2026-01-06'
llm:
  include: true
  pii: none
  chunk_hint: 250-400
  redaction: [email, phone]
entities: []
type: guide
---

[Home](./start-here.md)

# Best Practice Scripting (PowerShell, Bash, Node.js, Linux/Windows)

**EasyWay DataPortal** punta a massima portabilità: tutti gli script agentici devono poter funzionare sia su Windows che su Linux/macOS.  
Usa queste best practice ogni volta che contribuisci uno script `.ps1`, `.sh` o CLI!

---

## 1. Usa solo PowerShell Core (pwsh) ≥ 7

- Tutti i `.ps1` devono essere eseguiti con `pwsh`, non con Windows PowerShell.
- Evita moduli/cmdlet solo Windows (WMI, reg, COM) e preferisci funzioni cross-platform (file, json, path, text, http, ...).
- Se usi script Bash o Node.js, assicurati che l’uso sia documentato e la logica sia equivalente.

## 2. Struttura e shebang cross-platform

- In cima allo script, inserisci come buona pratica:
  ```powershell
  #!/usr/bin/env pwsh
  ```
- Rendi lo script eseguibile su Linux:
  ```bash
  chmod +x script.ps1
  ```

## 3. Percorsi e variabili

- Usa sempre funzioni cross-platform per i path (es: `Join-Path`, nessuna backslash hardcoded).
- Non dare per scontata la presenza di strumenti Windows-only (ad esempio `sqlcmd.exe`)
- Se serve select tool, verifica OS all’avvio e guida/messaggio adattivo.

## 4. Versione alternativa: Bash/Node.js/Python

- Se una CLI o orchestrazione è critica per il workflow dev/agent, proponi versione parallela `.sh` o `.js`/`.py` oppure aggiungi una recipe di sintesi passo-passo.

## 5. Onboarding contributor Linux/macOS

- Nel README/onboarding specifica: serve `pwsh` installato (`sudo apt install powershell`), v7+ consigliato.
- Offri sempre uno “starter env” mock/safe, no cloud cred reali richieste di default.

---

## 6. Automatizza il check di portabilità

- agent_docs_review effettua controllo periodico sugli script:
  - Segnala cmdlet/tool solo Windows.
  - Avvisa se manca shebang.
  - Verifica che README/onboarding presenti info Linux/macOS.
  - Suggerisce PR di patch se serve migliorare portabilità.

---

**Esempio check shell (PowerShell):**
```powershell
if ($PSVersionTable.Platform -ne "Unix" -and $env:OS -eq $null) {
    Write-Warning "Questo script potrebbe non essere compatibile fuori da Windows!"
}
```sql

**Se trovi uno script poco portabile, crea una issue o PR di suggestion!**



