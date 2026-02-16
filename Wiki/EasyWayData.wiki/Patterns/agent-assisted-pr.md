# Pattern: Agent-Assisted PR Creation (Human-in-the-Loop)

## 1. Il Concetto
Invece di far creare la Pull Request (PR) direttamente all'agente tramite CLI (`az repos pr create`), l'agente prepara tutto il lavoro (branch, commit, push, description) e fornisce all'utente un **link diretto pre-compilato** per creare la PR via web.

## 2. Il Flusso (Workflow)

| Step | Attore | Azione | Note |
|------|--------|--------|------|
| 1 | 🤖 **Agente** | **Prepare**: commit & push del feature branch | Assicura che il codice sia su `origin` |
| 2 | 🤖 **Agente** | **Draft Description**: genera titolo e descrizione | Basato su diff e template standard |
| 3 | 🤖 **Agente** | **Generate Link**: costruisce URL con parametri | `sourceRef`, `targetRef` |
| 4 | 👤 **Umano** | **Review & Click**: apre il link | Verifica visuale immediata |
| 5 | 👤 **Umano** | **Create**: conferma la creazione della PR | Click finale su "Create" |

## 3. Perché questo pattern? (Razionale)

### A. Sicurezza e Governance (Risk Mitigation)
- **Nessuna delega di credenziali**: L'agente non ha bisogno di un PAT (Personal Access Token) con permessi di scrittura PR.
- **Identità reale**: La PR risulta creata dall'utente umano (es. `mariorossi`), non da un account di servizio generico o dall'agente.
- **Audit naturale**: L'azione critica (apertura PR) è firmata da un umano responsabile.

### B. Robustezza Tecnica
- **Auth-agnostic**: Evita problemi complessi di autenticazione CLI (es. `az login` vs `az devops login`, scadenze token, MFA).
- **Zero dipendenze locali**: Funziona anche se `az` CLI non è installato o configurato sulla macchina.

### C. Human-in-the-Loop (HITL)
- **Last Mile Check**: L'umano è forzato a vedere la schermata di creazione, offrendo un'ultima possibilità di correggere titolo, target branch o descrizione prima che la PR esista.

## 4. Costruzione del Link (Azure DevOps)

Il formato standard per Azure DevOps è:

```
https://dev.azure.com/{Org}/{Project}/_git/{Repo}/pullrequestcreate?sourceRef={SourceBranch}&targetRef={TargetBranch}
```

L'agente deve fornire all'utente:
1. **Il Link**
2. **Titolo** (da copiare/incollare se non auto-popolato)
3. **Descrizione** (da copiare/incollare)

## 5. Quando usare questo pattern
- **Sempre**, a meno che non ci sia una CI/CD pipeline automatica specifica che richiede creazione non presidiata.
- **Obbligatorio** per agenti che operano in ambienti locali/misti dove l'autenticazione CLI non è garantita.
