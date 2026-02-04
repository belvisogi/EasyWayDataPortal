---
title: "QA & Troubleshooting - ADO Operations"
category: troubleshoot
domain: ado-qa
features:
  - faq
  - debugging
  - common-issues
entities: []
tags: [troubleshoot, faq, ado, pbi, export]
id: ew-archive-imported-docs-2026-01-30-agent-rules-qa-troubleshooting
summary: TODO - aggiungere un sommario breve.
status: draft
owner: team-platform
llm:
  include: true
  pii: none
  chunk_hint: 250-400
  redaction: [email, phone]
type: guide
---

# ❓ QA & TROUBLESHOOTING - ADO Operations

Raccolta di errori comuni e soluzioni incontrati durante l'utilizzo degli Agent ADO e SQL.

---

## 🛠️ Azure DevOps (ADO)

### Q: `ado:pipeline.list` o `history` restituisce "404 Not Found"
**Errore:**
```
Response status code does not indicate success: 404 (Not Found).
```
**Causa:**
Spesso accade se il nome del progetto contiene spazi (es. "ADA Project") e non viene codificato correttamente nell'URL, oppure se manca uno slash tra l'Organizzazione e il Progetto.
**Soluzione:**
Assicurarsi che l'URL sia costruito con `[uri]::EscapeDataString($Project)` e che la struttura sia:
`https://dev.azure.com/Org/Project%20Encoded/_apis/...`
Lo script `agent-ado-scrummaster.ps1` è stato aggiornato per gestire questo automaticamente.

### Q: `ado:userstory.export` impiega troppo tempo
**Causa:**
Se si usa `--WorkItemType 'All'` senza filtri, l'agent scarica l'intero backlog.
**Soluzione:**
Aggiungere sempre un filtro temporale o per tag:
```powershell
axctl --intent ado-export --WorkItemType 'All' --Query "SELECT ... WHERE [System.ChangedDate] > @today-7"
```

### Q: `ado:pbi.get` non mostra parent/children/test cases
**Causa:**
Versione obsoleta dello script o work item senza relazioni configurate in ADO.
**Soluzione:**
1. Verificare di usare la versione aggiornata di `agent-ado-scrummaster.ps1` (con API 7.0)
2. Controllare in ADO che il work item abbia effettivamente relazioni (parent, children) configurate
3. Le relazioni devono essere di tipo `System.LinkTypes.Hierarchy-Forward/Reverse`

### Q: `ado:pbi.children` restituisce "No children found"
**Causa:**
Il work item non ha figli configurati in ADO oppure usa relazioni di tipo diverso.
**Soluzione:**
1. Verificare in ADO Web UI che esistano work items linkati come "Child"
2. I children devono usare la relazione `Parent` (che crea `Hierarchy-Forward` nel parent)
3. Per Epic → Feature → PBI, verificare che la gerarchia sia corretta

---

## 🔌 SQL & Database

### Q: Errore "Login failed for user" o "Could not discover a user realm"
**Errore:**
```
Sqlcmd: Error: Microsoft ODBC Driver 17 for SQL Server ... Login failed ...
```
**Causa:**
Si sta tentando una connessione `AAD` (Active Directory) senza essere loggati interactivemente o senza aver passato credenziali esplicite.
**Soluzione:**
1. Eseguire `az login` nel terminale prima di lanciare `axctl`.
2. Usare l'opzione `--AuthType 'SQL'` e fornire Username/Password in `secrets.json`.
3. Se si è in un ambiente non interattivo, usare un Service Principal.

### Q: `axctl` non riconosce il parametro (es. "Ambiguous parameter")
**Errore:**
```
Parameter cannot be processed because the parameter name '' is ambiguous.
```
**Causa:**
PowerShell cerca di associare un argomento (es. `synapse-prod`) a un parametro sbagliato (es. `-Engine`).
**Soluzione:**
Passare esplicitamente i nomi dei parametri o usare `--` come separatore (anche se `--` può essere a sua volta ambiguo in certi contesti PowerShell).
Meglio: `axctl --intent sql-check -ExtraArgs synapse-prod`

---

## ⚙️ Configurazione & Manifest

### Q: Errore JSON nel Manifest ("Duplicate object key" o "Expected comma")
**Causa:**
Modifiche manuali al file `manifest.json` dove si copia/incolla senza controllare le virgole di chiusura `},` o si duplicano chiavi.
**Soluzione:**
Usare un validatore JSON o eseguire:
```powershell
Get-Content manifest.json | ConvertFrom-Json
```
Se questo comando fallisce, il JSON è invalido.

### Q: Warning "Exit code: 1" da `validate-action-output.ps1`
**Causa:**
L'agent ha prodotto un output (JSON), ma magari manca qualche campo obbligatorio richiesto dallo schema di validazione, o lo script di validazione ha regole troppo rigide.
**Soluzione:**
Controllare che l'oggetto `$result` nello script PowerShell dell'agent abbia tutti i campi standard: `ok`, `status`, `data`.

---

## 💻 Environment & Dipendenze

### Q: Errore "The term 'sqlcmd' is not recognized"
**Causa:**
Il connector `sql-check` richiede che l'utility [sqlcmd](https://learn.microsoft.com/en-us/sql/tools/sqlcmd-utility) sia installata e nel PATH.
**Soluzione:**
Installare i command line tools di SQL Server (o `choco install sqlserver-cmdline-utils`).

### Q: "The term 'pwsh' is not recognized"
**Causa:**
`axctl.ps1` usa internamente `pwsh` per lanciare i sottoprocessi in un ambiente pulito (PowerShell Core).
**Soluzione:**
Installare PowerShell 7+ e assicurarsi che `pwsh` sia eseguibile da terminale.

### Q: ADO PAT Error "Unauthorized" o "401"
**Causa:**
Il Personal Access Token (PAT) è scaduto, errato, o non ha i permessi "Read" su Work Items e Build.
**Soluzione:**
1. Rigenerare il PAT in ADO (User Settings -> Personal Access Tokens).
2. Aggiornare `Rules.Vault/config/secrets.json` o la variabile d'ambiente `$env:ADO_PAT`.

### Q: Marea di Warning "The cmdlet ... uses an unapproved verb"
**Causa:**
Durante l'esecuzione appaiono molti warning gialli. Questo è dovuto ai Linter di PowerShell che segnalano che nomi di funzioni come `Ensure-Dir` o `Run-PSAgent` non usano verbi standard (Get, Set, New...).
**Soluzione:**
Sono solo avvisi stilistici per lo sviluppatore. Non impattano il funzionamento. Possono essere ignorati dall'utente finale.

---

## ☁️ ServiceNow & Power Platform

### Q: `snow-check` fallisce con "Missing Credentials"
**Causa:**
Le credenziali in `secrets.json` per la chiave `snow-main` sono ancora impostate su `CHANGE_ME`.
**Soluzione:**
Aggiornare `username` e `password` con un utente ServiceNow valido (Basic Auth).

### Q: Errore di connessione Power Platform ("pac is not recognized")
**Causa:**
L'agente Power Platform richiede la [Microsoft Power Platform CLI](https://learn.microsoft.com/en-us/power-platform/developer/cli/introduction) installata.
**Soluzione:**
Installare la CLI con `dotnet tool install --global Microsoft.PowerApps.CLI.Tool` oppure via MSI.





