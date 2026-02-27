---
type: standard
status: active
tags:
  - layer/process
  - domain/devops
  - tool/gitlab
created: 2026-02-04
---

# 🦊 GitLab Workflow Standard & Branching Strategy

Questo documento definisce le regole di ingaggio per il versionamento, il branching e la CI/CD su GitLab.
Obiettivo: Garantire stabilità, tracciabilità e una collaborazione fluida tra Umani e Agenti.

---

## 1. 🌳 Branching Strategy (I 4 Pilastri)

### `main` (ex master)
*   **Ruolo**: Produzione / Release-Ready.
*   **Regola Aurea**: Deve essere SEMPRE deployabile.
*   **Accesso**: Read-Only per tutti. Scrittura solo via **Merge Request**.
*   **Requirements**: Pipeline Green ✅ + 1 Approval (Human or Release Agent).

### `develop`
*   **Ruolo**: Integrazione Continua (Pre-Prod).
*   **Flusso**: Tutte le feature e bugfix confluiscono qui.
*   **Accesso**: Merge Request obbligatoria.
*   **Stabilità**: Può essere instabile, ma la pipeline deve passare.

### `hotfix/*`
*   **Ruolo**: Urgenze su Produzione.
*   **Origine**: Staccato da `main`.
*   **Destinazione**: Merge su `main` **E** su `develop` (per evitare regressioni future).
*   **Naming**: `hotfix/devops/INC-XXX-descrizione` oppure `hotfix/devops/BUG-XXX-descrizione`

### `release/*`
*   **Ruolo**: Release candidate — codice pronto per UAT su CERT.
*   **Origine**: Staccato da `develop`.
*   **Destinazione**: Merge su `main` dopo UAT superato.
*   **Naming**: `release/X.Y.Z` (es. `release/1.2.0`)
*   **Regola**: Solo bugfix/revert ammessi. Nessuna nuova feature.
*   **Backport obbligatorio**: Dopo merge su `main`, ri-mergiare `release/*` su `develop`.

### `certfix/*`
*   **Ruolo**: Fix urgente applicato direttamente su CERT quando UAT è bloccato.
*   **Origine**: Staccato dalla `release/*` attiva (NON da `develop`).
*   **Destinazione**: Merge su `release/*` **E** backport obbligatorio su `develop`.
*   **Naming**: `certfix/INC-XXX-short-desc` oppure `certfix/BUG-XXX-short-desc`
*   **Quando usare**: Solo se il fix non può attendere il ciclo standard.

### `baseline`
*   **Ruolo**: Base stabile per Vendor / Freeze specifici.
*   **Regola di Flusso**: Si aggiorna **SOLO da develop** (o main).
*   **VIETATO**: Merge diretto da feature branch a baseline.
*   **Uso**: Snapshot controllato. Non è un branch di lavoro quotidiano.

---

## 2. 🏷️ Naming Conventions

Standardizzare i nomi permette agli Agenti di capire il contesto.

| Tipo | Pattern Branch | Titolo PR |
| :--- | :--- | :--- |
| **Feature (DevOps)** | `feature/devops/PBI-000-short-desc` | `PBI-000: Titolo descrittivo` |
| **Feature (Domain)** | `feature/<domain>/PBI-000-short-desc` | `PBI-000: Titolo descrittivo` |
| **Chore (DevOps)** | `chore/devops/PBI-000-short-desc` | `PBI-000: Titolo descrittivo` |
| **Bugfix** | `bugfix/FIX-000-short-desc` | `FIX-000: Titolo descrittivo` |
| **Hotfix (PROD)** | `hotfix/devops/INC-000-short-desc` o `hotfix/devops/BUG-000-short-desc` | `INC-000/BUG-000: Titolo urgente` |
| **Release** | `release/X.Y.Z` | `Release X.Y.Z` |
| **Certfix (CERT)** | `certfix/INC-000-short-desc` o `certfix/BUG-000-short-desc` | `INC-000/BUG-000: Fix CERT` |
| **Sync GitHub** | `sync/github-YYYYMMDD-SHORTSHA` | `[GitHub Sync] Titolo commit` |

**Descrizione PR Template**:
> **Cosa cambia**: ...
> **Come testare**: ...
> **Impatti**: ...

### 🔗 Il "Magic Link" (Traceability)
Usando questi prefissi, GitLab collega automaticamente il codice ai requisiti:
1.  **Issue #101**: "Creare Login" (Label: `PBI`)
2.  **Branch**: `feature/devops/PBI-101-login`
3.  **Risultato**: Nella Issue vedrai il link alla Merge Request. Nella MR vedrai "Closes #101".
**Senza ID nel nome, si perde la tracciabilità.**

---

## 3. 🔄 Rebase Policy ("Keep it Clean")

La regola è **Rebase su Develop**.

*   **Routine**:
    1.  `git fetch origin`
    2.  `git rebase origin/develop`
*   **Quando**:
    *   Prima di aprire la PR.
    *   Quando la PR è in draft.
*   **Vietato**: Rebase su branch condivisi (pushati) su cui altri stanno lavorando (usare merge in quel caso).

---

## 4. 🚨 Protocolli di Urgenza (Vendor/Admin)

Definizione esplicita di "Urgenza" per bypassare il flusso standard (es. Giovedì Release).

### Il "Passpartout" Admin
In caso di blocco bloccante (Severity 1), gli Admin possono mergiare con procedura ridotta:

**Checklist Obbligatoria**:
1.  [ ] Pipeline Verde (Test automatici passati).
2.  [ ] Almeno 1 Reviewer notificato (anche se asincrono).
3.  [ ] Link al Ticket/PBI con motivazione urgenza.
4.  [ ] Rollback Plan definito.

*Se non è urgente: si attende lo slot standard o meeting dedicato.*

---

## 5. ❌ Gestione Errori (Wrong Target)

Cosa fare se una PR viene aperta verso il branch sbagliato (es. Feature -> Main)?

### Caso A: PR Aperta (Non Mergiata)
1.  **Azione**: CHIUDERE la PR (Close/Abandon).
2.  **Motivo**: Cambiare target al volo sporca la history e la review.
3.  **Next**: Aprire nuova PR con target corretto. Commentare nella vecchia: *"Target errato. Riaperta come #NewID"*.

### Caso B: PR Mergiata (Danno Fatto)
1.  **Se su Main**: Revert immediato del Commit di Merge. Poi PR corretta su Develop.
2.  **Se su Develop**: Si valuta. Spesso si lascia e si corregge con PR successiva, a meno che non rompa la build.

---

## 7. 🎫 Issue Standard (Naming & Tags)

Per evitare confusione solo con i colori, usiamo una nomenclatura esplicita anche nei Titoli.

### 📝 Title Convention (Analytics Ready)
Per facilitare l'estrazione dati (Dashboard), usiamo il pattern **Fixed-Prefix**:

`TYPE-SCOPE: Descrizione`

*   ✅ `PBI-Levi: Login Page` (Facile da parsare: Tipo=PBI, Scope=Levi)
*   ✅ `BUG-Finance: Calcolo IVA errato`
*   ✅ `REL-Levi: v2026.1.0`

**Perché `TYPE` all'inizio?**
Se devi fare una query "Quanti BUG abbiamo in azienda?", basta cercare `Title LIKE 'BUG-%'`. È computazionalmente più veloce e ordinato.

> **Consiglio sull'Anno**: Evita di scrivere l'anno nel titolo (es. `PBI-Levi-2026`). Se il ticket slitta a Gennaio 2027, il titolo diventa "vecchio". Usa le **Milestones** o la data di creazione per filtrare l'anno nelle dashboard.

### 🏷️ Tags (Labels)
Su GitLab i "Tags" si chiamano **Labels**. Abbiamo definito queste Standard (Scoped):
*   `type::feature` (🔵) -> Indica un PBI.
*   `type::bug` (🔴) -> Indica un Errore.
*   `priority::high` (🚨) -> Indica Urgenza.

> **Regola**: Il Titolo parla agli Umani (`PBI: Login`), la Label parla al Sistema (`type::feature`). Usali entrambi.

---

## 8. 🌍 Environment Mapping (Branch → Ambiente)

Ogni ambiente di deploy corrisponde a un branch specifico. Nessuna ambiguità.

| Branch | Ambiente | Deploy | Trigger |
| :--- | :--- | :--- | :--- |
| `develop` | **DEV** | Automatico | Merge su `develop` |
| `release/*` | **CERT** | Automatico | Creazione branch `release/*` |
| `main` | **PROD** | Manuale + approval gate | PR `release/*` → `main` mergiata |

### Principio universale: Feature salgono, Fix scendono

```
feat/* ──────────────────────────────────────► develop → DEV
                                                   │
                                              release/* → CERT (UAT)
                                                   │  ▲
                                                   │  └─ certfix/* (backport ↓ obbligatorio)
                                                   │
                                                 main → PROD
                                                   │  ▲
                                                tag   └─ hotfix/* (backport ↓ obbligatorio)
```

**Regola**: ogni fix applicato su un ambiente superiore DEVE essere backportato su tutti i branch inferiori. Un fix su PROD che non scende su `develop` verrà sovrascritto al prossimo rilascio.

### Backport obbligatorio

| Scenario | Backport richiesto |
| :--- | :--- |
| `hotfix/*` mergiato su `main` | → `release/*` attiva (se presente) + `develop` |
| `certfix/*` mergiato su `release/*` | → `develop` |
| `release/*` mergiato su `main` | → `develop` (porta i revert/fix del release branch) |

---

## 9. 🗑️ Branch Retention Policy (Lifecycle)

### Branch permanenti — MAI cancellare

| Branch | Motivo |
| :--- | :--- |
| `main` | Storia di produzione — perdere commit = perdere prod |
| `develop` | Spina dorsale dell'integrazione continua |
| `baseline` | Snapshot frozen per vendor/freeze — cancellare = perdere il riferimento |

### Branch effimeri — cancellare dopo merge

| Tipo | Quando cancellare | Note |
| :--- | :--- | :--- |
| `feature/*`, `chore/*`, `bugfix/*` | Dopo merge su `develop` + pipeline verde | Manuale — `Delete source branch` disattivato di default |
| `hotfix/*` | Dopo merge su `main` **E** backport su `develop` completato | Non cancellare prima del backport |
| `certfix/*` | Dopo merge su `release/*` **E** backport su `develop` completato | Non cancellare prima del backport |
| `release/*` | Dopo merge su `main` + tag `vX.Y.Z` creato + backport su `develop` | Archiviare con tag prima di cancellare |
| `sync/github-*` | Dopo merge su `develop`, max 7 giorni | Branch auto-creati dal workflow GitHub→ADO |

### Regola pre-cancellazione

Prima di cancellare qualsiasi branch effimero, verificare:
1. Pipeline verde sul branch di destinazione
2. Backport completato (dove obbligatorio)
3. Tag creato (solo per `release/*`)

> **Recupero da cancellazione accidentale**: `git reflog` + `git push origin <sha>:refs/heads/<branch>`

---

## 10. 🔗 Linking & Grouping (Le Relazioni)

Come colleghiamo tutto insieme?

### 📅 Milestones (Il "Quando")
**Usa le Milestone per le Release, non per le Epiche.**
*   Esempio Milestone: `Release v1.2 (Q1 2026)`
*   Se assegni 10 PBI a questa Milestone, sai cosa esce e quando.

### 🔗 Issue Links (Il "Perché")
Puoi collegare le Issue tra loro (comandi rapidi nei commenti):
*   **Relazione**: `/relates_to #102` -> "Questo PBI c'entra con quel Bug".
*   **Blocco**: `/blocks #103` -> "Non puoi fare il Deploy finché non risolvi questo".
*   **Gerarchia**: Nella versione Free, usa la descrizione per linkare i figli:
    *   *Epic Issue*: "Rifacimento Portale"
    *   *Child Lists*: `- [ ] #101 Login`, `- [ ] #102 Home`

Per automatizzare questo flusso, introdurremo i seguenti Agenti collaborativi:

*   **👮 Guard Agent (CI)**: Blocca PR se naming/target sono errati.
*   **🕵️ Review Agent**: Controlla checklist (Tests, Docs) e approva PR banali.
*   **🚀 Release Agent**: Gestisce il merge da Develop a Main e i back-merge degli Hotfix.

> *"Gli agenti non violano le regole. Le applicano con rigore assoluto."*
