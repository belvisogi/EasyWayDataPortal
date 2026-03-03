---
title: "Pietra Miliare Zero - La Fabbrica"
date: 2026-03-03
category: milestone
session: "S53"
tags: [chronicle, milestone]
---

## Cronaca

### Evento: Pietra Miliare Zero - La Fabbrica
### Data: 2026-03-03 06:05
**Session**: S53
### Categoria: milestone

### Cosa e' Successo

Oggi il progetto EasyWay compie il suo passo piu' importante da quando e' nato.

Dopo 53 sessioni di lavoro, un anno di crescita organica, il monorepo `EasyWayDataPortal`
ha raggiunto la massa critica. Quello che era iniziato come un singolo repository e' diventato
un ecosistema che contiene mondi diversi — e quei mondi ora chiedono di respirare.

**Foto dell'albero — com'e' oggi, prima del taglio:**

| Metrica | Valore |
|---------|--------|
| Branch corrente | `feat/wiki-publish-skill` @ `19eb28b` |
| Commit totali | 614 |
| File tracciati | 2.021 |
| Wiki (pagine) | 674 |
| Agenti | 491 file, 40 agenti attivi |
| Portal (app) | 113 file core |
| Scripts (DevOps) | 283 file |
| Skill registrate | 35 (registry v2.15.0) |
| Principi GEDI | 15 (ultimo: Vanilla Sky) |
| PR mergiate | 242 |
| Sessioni documentate | 53 |

**La decisione:** passare da monorepo a polyrepo — "La Fabbrica".
Ogni sezione diventa un repository indipendente. L'insieme dei repository
costituisce l'organismo. La struttura locale (`C:\old\easyway\`) sara' identica
a quella server (`/opt/easyway/`).

### Perche' Conta

Perche' questo non e' solo un refactoring tecnico. E' il riconoscimento che il progetto
e' cresciuto abbastanza da meritare una struttura adulta.

La wiki e' il libro da lasciare ai posteri. Non sara' solo qualcosa di digitale —
sara' la testimonianza di come un progetto "folle" e' diventato una piattaforma.
Se un giorno qualcuno vorra' continuare questo progetto, potra' farlo. Trovera' tutto:
cosa e' stato costruito, come, perche', e quali lezioni sono state apprese lungo il percorso.

E' anche la dimostrazione che DevOps e GitHub possono essere usati in modo veramente agentico —
non come buzzword, ma come pratica quotidiana con 40 agenti che lavorano, CI/CD che gira,
RAG che indicizza, e un cronista che registra ogni pietra miliare.

### Artefatti Correlati

- `C:\old\easyway\factory.yml` — la mappa della Fabbrica (8 repository, 4 fasi di migrazione)
- `agents/agent_gedi/manifest.json` — 15 principi (nuovo: "revolutionary_minute" da Vanilla Sky)
- `scripts/pwsh/Invoke-Chronicle.ps1` — il cronista e' ora operativo
- `Wiki/EasyWayData.wiki/chronicles/` — la nuova casa delle cronache
- `Wiki/EasyWayData.wiki/chronicles/_index.md` — indice cronologico

### Lezione Appresa

Il monorepo ha servito il suo scopo. 53 sessioni, 40+ agenti, 676 pagine wiki, 35 skill.
Ha permesso di sperimentare, iterare velocemente, tenere tutto insieme quando ancora non
si sapeva cosa sarebbe diventato.

Ora e' il momento di separarsi e crescere. Non perche' il monorepo sia sbagliato,
ma perche' il progetto lo ha superato.

> "Ogni minuto che passa e' un'occasione per rivoluzionare tutto completamente."
> — Vanilla Sky (2001)
