# Best Practice: Strategie di Merge Git e Policy DevOps

## 1. Il Ciclo di Vita dei Branch (Gitflow Semplificato)

In EasyWayDataPortal adottiamo un modello Gitflow semplificato con due **Branch Eterni**:

| Branch | Scopo | Vita | Checkpoint |
|--------|-------|------|------------|
| **`main`** | Produzione stabile. Ogni commit è una release. | **ETERNA** (Mai cancellare) | Squash Commit |
| **`develop`** | Integrazione continua. Base per tutto il nuovo lavoro. | **ETERNA** (Mai cancellare) | Merge Commit |
| **`feature/*`** | Sviluppo di nuove funzionalità. | Effimera (Delete on merge) | Squash o Rebase |

## 2. Perché non cancellare MAI `develop`?

`develop` è la spina dorsale dello storico del progetto.
- Se cancelli `develop` dopo un merge su `main`, perdi il punto di divergenza per le feature future.
- Gitflow richiede che `develop` esista sempre parallelo a `main`.
- **Regola d'oro**: Nel pannello PR di Azure DevOps, quando il target è `main` e la source è `develop`, la spunta **"Delete source branch"** deve essere rigorosamente **VUOTA**.

## 3. Strategie di Merge (Squash vs Merge)

### Squash Commit (Obbligatorio su `main`)
**Cosa fa**: Prende tutti i commit della PR (es. 50 commit di feature) e li schiaccia in **uno solo**.
**Perché su Main**: Vogliamo che la history di produzione sia leggibile come un changelog:
- `v2.0 Release P3 Workflow Intelligence`
- `v1.5 Hotfix Security`
Non vogliamo vedere i "fix typo" o "wip" in produzione.

### Merge Commit (No Fast-Forward) (Obbligatorio su `develop`)
**Cosa fa**: Mantiene tutti i commit originali ma crea un nodo di unione esplicito.
**Perché su Develop**: Durante lo sviluppo, lo storico dettagliato è vitale per capire "chi ha rotto cosa" e in quale specifico commit. Il `Merge Commit` preserva il contesto di gruppo della feature.

## 4. Configurazione Policy Azure DevOps

Per garantire che queste regole siano rispettate meccanicamente:

1. Andare su **Project Settings** -> **Repositories** -> **Policies**.
2. Su **`main`**:
   - `Limit merge types`: Selezionare SOLO **Squash**.
   - `Block` Fast-Forward e Basic Merge.
3. Su **`develop`**:
   - `Limit merge types`: Selezionare **Merge (no fast-forward)** e **Squash**.
   - `Block` Fast-Forward (opzionale, ma consigliato per vedere i merge point).

Questa configurazione rende impossibile per errore fare un "Merge sporco" su main o uno "Squash distruttivo" su develop se non desiderato.
