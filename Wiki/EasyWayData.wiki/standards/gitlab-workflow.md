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
*   **Naming**: `hotfix/PBI-XXX-descrizione`

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
| **Feature** | `feature/PBI-000-short-desc` | `PBI-000: Titolo descrittivo` |
| **Bugfix** | `bugfix/PBI-000-short-desc` | `FIX-000: Titolo descrittivo` |
| **Hotfix** | `hotfix/INC-000-short-desc` | `HOTFIX: Titolo urgente` |

**Descrizione PR Template**:
> **Cosa cambia**: ...
> **Come testare**: ...
> **Impatti**: ...

### 🔗 Il "Magic Link" (Traceability)
Usando questi prefissi, GitLab collega automaticamente il codice ai requisiti:
1.  **Issue #101**: "Creare Login" (Label: `PBI`)
2.  **Branch**: `feature/PBI-101-login`
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

## 8. 🔗 Linking & Grouping (Le Relazioni)

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
