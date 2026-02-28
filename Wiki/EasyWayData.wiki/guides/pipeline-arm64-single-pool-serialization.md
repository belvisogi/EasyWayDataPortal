# Lesson 57 — Pipeline ARM64 Single-Pool: Serializzare DeployDev e DeployMain

**Data**: 2026-02-28
**Categoria**: CI/CD, Pipeline, ADO, ARM64
**Severity**: MEDIUM — causa contesa di risorse e build failure in produzione

---

## Problema

Il server OCI (ARM64, Ubuntu) ospita **un singolo agente Azure DevOps** nel pool `Default`.
La pipeline `azure-pipelines.yml` include due stage di deploy:

- `DeployDev` — `docker compose up` sull'ambiente DEV (porte 3000/5678/...)
- `DeployMain` / `DeployProd` — `docker compose up` sull'ambiente PROD (stesse porte, stesso server)

Se entrambi i job vengono **accodati nello stesso momento** (es. merge rapidi su develop + main),
l'agente li esegue **sequenzialmente** (pool con 1 agente = 1 job alla volta), ma i log mostrano
pattern di interleaving nei momenti di transizione tra job che può causare:

1. **Contesa filesystem**: checkout git su `_work/` mentre il precedente job fa ancora cleanup
2. **Contesa docker**: `docker compose up --scale sql-edge=0` termina in overlap con un container
   ancora in shutdown dal job precedente
3. **Stato inconsistente**: un job legge `git status` mentre l'altro sta ancora facendo `git reset --hard`

### Evidenza concreta — PR #209

Il log `Worker_20260228-044653-utc.log` mostra:
```
[04:46:58Z] job state = 'Failed'
[04:46:58Z] Job: 'docker compose up — easyway-dev'
[04:47:01Z] Job completed - Final result: Failed
[04:47:01Z] Worker process termination - ExitCode:102
```

Il job **DeployDev** del run #209 fallì per due cause sovrapposte:
1. `azure-sql-edge:2.0.0` senza manifest ARM64 (fix: `--scale sql-edge=0` in PR #215)
2. Potenziale overlap con DeployMain in esecuzione contemporanea sullo stesso agent

---

## Causa Radice

```
[sviluppatore]
     │
     ├─ merge → develop   →  pipeline trigger  →  DeployDev (job A)
     │                                                    ↓
     └─ merge → main      →  pipeline trigger  →  DeployMain (job B)
                                                         ↓
                                          [stesso agente ARM64]
                                          [stesso server OCI]
                                          [stesso docker compose]
```

Con un singolo agente, ADO garantisce che i job non girino *contemporaneamente*,
ma **non garantisce** un intervallo sufficiente tra la fine di un job e l'inizio del successivo.
Il window di overlap avviene durante il post-job cleanup del primo job.

---

## Fix: Dipendenza Esplicita tra Stage

Aggiungere `dependsOn: DeployDev` nello stage `DeployMain` della pipeline:

```yaml
# azure-pipelines.yml

stages:
  - stage: DeployDev
    displayName: 'Deploy DEV'
    condition: and(succeeded('BuildAndTest'), eq(variables['Build.SourceBranch'], 'refs/heads/develop'))
    jobs:
      - job: DeployDev
        pool: Default
        steps:
          # ...

  - stage: DeployMain
    displayName: 'Deploy PROD'
    dependsOn:
      - BuildAndTest
      - DeployDev        # ← serializza: aspetta sempre che DeployDev finisca
    condition: |
      and(
        in(dependencies.BuildAndTest.result, 'Succeeded', 'SkippedDueToConditions'),
        in(dependencies.DeployDev.result, 'Succeeded', 'SkippedDueToConditions'),
        eq(variables['Build.SourceBranch'], 'refs/heads/main')
      )
    jobs:
      - job: DeployMain
        pool: Default
        steps:
          # ...
```

> **Nota sulla condition**: `SkippedDueToConditions` permette a DeployMain di girare anche
> quando DeployDev viene skippato (es. push diretto su main senza trigger su develop).

---

## Regola Operativa

**Su un pool con 1 agente ARM64 che condivide il server fisico di deploy:**

> I stage che eseguono `docker compose up` sullo stesso server
> DEVONO essere serializzati con `dependsOn` esplicito.

Non è sufficiente fidarsi dell'ordinamento ADO basato su agent capacity: la finestra di
post-job cleanup è reale e può durare secondi.

---

## Checklist Prima di Aggiungere un Nuovo Stage Deploy

- [ ] Il nuovo stage gira sullo stesso server fisico di un altro stage deploy?
- [ ] I container/porte si sovrappongono?
- [ ] La pipeline ha `dependsOn` esplicito per serializzare?
- [ ] La `condition` gestisce correttamente `SkippedDueToConditions`?

---

## Contesto Storico

| Data | Evento |
|------|--------|
| 2026-02-28 | PR #209: DeployDev fallisce — sql-edge ARM64 + potenziale contesa |
| 2026-02-28 | PR #215: fix `--scale sql-edge=0` (Session 40) |
| 2026-02-28 | Lesson 57 documentata (Session 41) |

---

## Riferimenti

- [Lesson 55](../deployment/server-deploy-guide.md) — Mai `git pull` in deploy; usare `fetch+reset`
- [Pipeline CI/CD](../devops/pipeline-architecture.md) — Struttura pipeline EasyWay
- [Multi-environment Docker Strategy](../deployment/multi-environment-docker-strategy.md) — Stack DEV e CERT
- [ADO Session Awareness](ado-session-awareness.md) — Layer 0 briefing pre-sessione
