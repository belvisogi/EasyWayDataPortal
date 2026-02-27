---
title: Release Use Cases — Rilasci Selettivi e Interventi Urgenti
tags: [domain/control-plane, layer/spec, audience/dev, audience/ops, privacy/internal, language/it, release, git, workflow, use-cases, hotfix, certfix, selective-release]
status: active
updated: 2026-02-27
id: ew-control-plane-release-use-cases
type: guide
summary: Use case pratici per gestione rilasci selettivi e interventi urgenti su CERT/PROD. Copre selective release, hotfix su prod, fix diretto su cert, sync da GitHub esterno.
owner: team-platform
llm:
  include: true
  pii: none
  chunk_hint: 5000
  redaction: [email, phone]
pii: none
---

[[../start-here.md|Home]] > [[index.md|Control-Plane]] > Release Use Cases

# Release Use Cases — Rilasci Selettivi e Interventi Urgenti

Questo documento copre gli scenari operativi che si discostano dal flusso standard.
Flusso standard di riferimento: [[../standards/gitlab-workflow.md|GitLab Workflow Standard]].

---

## Contesto: il modello di riferimento

```
feat/* ──────────────────────────────────────► develop → DEV
                                                   │
                                              release/* → CERT (UAT)
                                                   │  ▲
                                                   │  └─ certfix/* (backport ↓)
                                                   │
                                                 main → PROD
                                                   │  ▲
                                                tag   └─ hotfix/* (backport ↓)
```

**Principio universale: Feature salgono, Fix scendono.**
Ogni fix applicato in alto DEVE essere backportato su tutti i branch inferiori — senza eccezioni.

---

## Use Case 1 — Rilascio Selettivo (una feature non è pronta)

### Scenario

Al tempo T, tre feature team completano gli sviluppi:

- **FT_1** → sviluppato su ADO → in `develop`
- **FT_2** → sviluppato su GitHub (sync tramite `sync/*`) → in `develop`
- **FT_3** → sviluppato su ADO → in `develop`

Viene creato `release/1.2.0` da `develop` e avviato lo UAT su CERT.

Al tempo T+1 emerge che **FT_3 non può essere rilasciato** (UAT negativo o blocco funzionale).
FT_1 e FT_2 sono pronti. Come si rilascia solo FT_1 + FT_2?

### Soluzione: revert chirurgico sul release branch

```
develop: ──FT_1──FT_2──FT_3──     ← FT_3 rimane intatto in develop
                  │
                  │ git checkout -b release/1.2.0 develop
                  ▼
release/1.2.0: ──FT_1──FT_2──FT_3──revert(FT_3)──
                                           │
                                     PR → main → PROD
```

**Passi concreti:**

```bash
# 1. Crea release branch da develop
git checkout -b release/1.2.0 develop

# 2. Revert chirurgico di FT_3 (tracciabile, non distruttivo)
git revert <commit-sha-FT_3>
# Se FT_3 è composto da più commit:
git revert <sha1> <sha2> <sha3>
# Messaggio commit: "revert: FT_3 escluso da release/1.2.0 — UAT negativo"

# 3. PR release/1.2.0 → main  (CI obbligatorio + 1 approval umano)
# 4. Deploy main → CERT (re-test FT_1+FT_2) → PROD dopo approvazione

# 5. OBBLIGATORIO dopo merge su main: re-merge release → develop
#    Porta il revert su develop — evita che FT_3 rientri silenziosamente al prossimo rilascio
git checkout develop
git merge release/1.2.0
```

### Perché NON revertire direttamente su `develop`

`develop` è il branch condiviso da tutti i team. Revertire lì elimina FT_3 per tutti,
incluso lo sprint successivo. Il revert sul release branch è chirurgico:
FT_3 resta intatto in `develop` e prende il prossimo "treno".

### Nota su FT_2 (venuto da GitHub)

Nessuna differenza operativa. Una volta cherry-pickato in `develop` tramite il sync workflow
(`sync/github-* → develop`), FT_2 è un commit come FT_1. Il release branch lo tratta in modo identico.

### Soluzione alternativa a lungo termine: Feature Flags

Se questo scenario si ripete frequentemente, la risposta strutturale è buildare le feature
con un flag on/off:

```
FT_3 è in develop, cert, prod — ma con flag DISABLED
Al tempo T+1 si rilascia tutto senza revert.
FT_3 si abilita via config quando è pronto — zero chirurgia sul codice.
```

---

## Use Case 2 — Hotfix su PRODUZIONE (incidente bloccante)

### Scenario

Un incidente critico si verifica in produzione. Non può attendere il ciclo standard
DEV → UAT → Release. Il servizio è bloccato.

### Soluzione: hotfix da `main` con backport obbligatorio

```
main (PROD): ──────── hotfix/devops/INC-001-login-crash
                              │
                         fix applicato
                              │
                     PR hotfix/* → main
                              │
                     deploy PROD ← servizio ripristinato

OBBLIGATORIO entro il giorno successivo:
                              │
                  ┌───────────┴───────────┐
                  ▼                       ▼
           merge → release/*        merge → develop
           attiva (se CERT          (il fix non va perso
           ha UAT in corso)          al prossimo rilascio)
```

**Passi concreti:**

```bash
# 1. Branch da main — NON da develop (PROD è su main)
git checkout -b hotfix/devops/INC-001-login-crash main

# 2. Applica fix, commit con Conventional Commits
git commit -m "fix(auth): corretto crash su token scaduto in produzione"

# 3. PR hotfix/* → main  (fast path: CI + 1 approval, senza aspettare UAT completo)
# 4. Deploy PROD

# 5. BACKPORT OBBLIGATORIO (non negoziabile)
git checkout develop
git merge hotfix/devops/INC-001-login-crash

# Se esiste una release/* attiva (UAT in corso su CERT):
git checkout release/1.2.0
git merge hotfix/devops/INC-001-login-crash
```

### Perché il backport è non negoziabile

Senza backport, al prossimo merge `develop → main` il bug originale rientra.
Il fix esiste solo in PROD ma non nella history di sviluppo. Al primo rilascio successivo, regressione garantita.

---

## Use Case 3 — Fix diretto su CERT (UAT bloccato)

### Scenario

Durante lo UAT su CERT, emerge un problema bloccante che non può aspettare
un nuovo ciclo DEV → PR → develop. Il fix deve essere applicato direttamente
sull'ambiente CERT per sbloccare i tester.

### Soluzione: certfix da `release/*` con backport

```
release/1.2.0 (CERT): ──────── certfix/INC-002-export-timeout
                                        │
                                   fix applicato
                                        │
                              PR certfix/* → release/1.2.0
                                        │
                              redeploy CERT ← UAT può continuare

BACKPORT OBBLIGATORIO:
                                        │
                                        ▼
                                merge → develop
                                (il fix non va perso)
```

**Passi concreti:**

```bash
# 1. Branch da release/* attiva — NON da develop
git checkout -b certfix/INC-002-export-timeout release/1.2.0

# 2. Fix, commit
git commit -m "fix(export): aumentato timeout per dataset grandi su CERT"

# 3. PR certfix/* → release/1.2.0
# 4. Redeploy CERT — UAT continua

# 5. BACKPORT OBBLIGATORIO
git checkout develop
git merge certfix/INC-002-export-timeout
```

### Differenza con hotfix

| | hotfix/* | certfix/* |
| :--- | :--- | :--- |
| Origine branch | `main` | `release/*` attiva |
| Ambiente target | PROD | CERT |
| Backport su `main` | Sì (è il target primario) | No (arriva a main via release/*) |
| Backport su `develop` | Sì (obbligatorio) | Sì (obbligatorio) |

---

## Use Case 4 — Contributo esterno da GitHub

### Scenario

Un contributor esterno apre una PR su GitHub e la fa mergiare su `main` di GitHub.
Il team interno non deve entrare nel mondo ADO ma vuole revisionare il contributo
prima che arrivi in produzione.

### Soluzione: sync automatico GitHub → ADO develop

Il workflow `.github/workflows/sync-to-ado.yml` gestisce questo automaticamente:

```
GitHub PR #42 (esterno) mergiata su GitHub main
              │
              ▼  GitHub Action (sync-to-ado.yml)
              │  loop-breaker: SHA comparison ADO vs GitHub
              │  cherry-pick commit nuovi su base ADO develop
              │
   sync/github-20260227-abc1234 (ADO)
              │
   PR auto → develop
   descrizione: link PR GitHub #42, autore, messaggio
              │
   CI gira su sync/* branch
   Team interno revisiona (diff pulito: solo commit esterni)
              │
   merge → develop → DEV
              │
   (ciclo normale: develop → release/* → main)
```

**Cosa contiene la PR ADO generata automaticamente:**
- Link alla GitHub PR originale (es. `#42 — feat: add export button`)
- Autore del contributor esterno
- Solo i commit nuovi (cherry-pick, non tutta la history di GitHub)
- Link al GitHub Actions run per tracciabilità

**Loop prevenuto:** quando ADO poi esegue il mirror `main → GitHub`, il GitHub Action
rileva che il SHA coincide con ADO main e non ri-triggera il sync (loop-breaker).

---

## Riepilogo regole universali

| Regola | Descrizione |
| :--- | :--- |
| **Feature salgono** | `feat/*` → `develop` → `release/*` → `main` |
| **Fix scendono sempre** | Ogni fix su main/cert backportato a tutti i branch inferiori |
| **Revert su release, mai su develop** | `develop` è condiviso — il revert chirurgico va sul release branch |
| **Backport obbligatorio** | `hotfix/*` → `main` + `release/*` + `develop`; `certfix/*` → `release/*` + `develop` |
| **UAT su CERT (release/*)** | Non su `develop`, non su `main` — troppo presto o troppo tardi |
| **Feature flags** *(long term)* | Selective release senza chirurgia sul codice |
| **Release train** | Cadenza fissa — feature non pronta prende il treno successivo |

---

## Vedi anche

- [[../standards/gitlab-workflow.md|GitLab Workflow Standard — Branch, Naming, Environment Map]]
- [[release-flow-alignment-2026-02-12.md|Release Flow Alignment (Agent Release)]]
- [[prd-agentic-release-multivcs-mvp.md|PRD Multi-VCS Release]]
- [[index.md|Control Plane — Panoramica]]
