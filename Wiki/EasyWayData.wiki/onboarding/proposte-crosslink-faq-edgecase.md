---
id: ew-proposte-crosslink-faq-edgecase
title: Proposte Cross-link, FAQ mancanti, Ricette edge-case e automazioni
tags: [onboarding, devx, faq, edgecase, crosslink, test, automation, audience/dev, language/it]
summary: Suggerimenti concreti per migliorare la navigabilità, la praticità e la robustezza della knowledge base EasyWay DataPortal.
status: draft
owner: team-platform
updated: '2026-01-06'
---

[Home](../../../docs/project-root/DEVELOPER_START_HERE.md)

# 🧩 Suggerimenti mirati: cross-link, FAQ mancanti, edge-case, automation

Questa tabella suggerisce punti pratici in cui arricchire la kb repo EasyWay con link, FAQ, ricette, mock e automation — per una developer/agent experience ancora più potente e self-healing.

## Contesto (repo)
- Obiettivi e principi: `agents/goals.json`
- Orchestrazione/gates (entrypoint): `scripts/ewctl.ps1`
- Ricette operative (KB): `agents/kb/recipes.jsonl`
- Standard contesto: `Wiki/EasyWayData.wiki/onboarding/documentazione-contesto-standard.md`

| File/cartella target                                                             | Azione                                                          | Esempio/patch da aggiungere                                                           |
|----------------------------------------------------------------------------------|------------------------------------------------------------------|---------------------------------------------------------------------------------------|
| README.md (root)                                                                 | Cross-link diretto alle guide sandbox/zero-trust, best practice  | `- Setup sandbox/Zero Trust: wiki/EasyWayData.wiki/onboarding/setup-playground-zero-trust.md` <br> `- Scripting cross-platform: wiki/EasyWayData.wiki/onboarding/best-practice-scripting.md`|
|                                                           | Inserire blocco “Domande frequenti”/FAQ                          | `## FAQ Onboarding` <br> “Come faccio test senza DB?” <br> “Come riparto se fallisce uno script?”|
| wiki/EasyWayData.wiki/glossario-errori-faq.md                                    | Nuove FAQ edge/casi+ricorrenti                                   | “❓ Come forzo mock sandbox se DB non disponibile?” <br> “❓ Perché lo script richiede pwsh 7+?” |
| agents/agent_dba/README.md & agent_docs_review/README.md                         | “See also” a sandbox, setup sicurezza e script test/mock         | `- Guida sandbox/zero trust: ../wiki/EasyWayData.wiki/onboarding/setup-playground-zero-trust.md`<br> `- Mock credenziali/script: ../wiki/EasyWayData.wiki/onboarding/best-practice-scripting.md` |
| scripts/readme.md                                                                | Indicare best practice test/locali/lint                          | “⚙️ Lancia sempre test/lint in sandbox PRIMA di run in ambiente reale.”                  |
| atomic_flows/templates/ (e agent_X/templates/)                                   | Ricetta edge-case: rollback, recovery, failed run                | file markdown “recipe-edgecase-rollback.md” con esempio di fail/fix/ricezione alert     |
| Wiki/EasyWayData.wiki/onboarding/README.md                                       | Cross-link a tutte le guide “safety”, edge-case, troubleshooting | Lista puntata di tutte le pagine sandbox, FAQ, policy zero trust, ecc.                  |
| agents/core/ o scripts/automation-entrypoint.md                                  | Script che lancia batch di test/lint/consistency in ogni agent   | Nuovo script test-all-agents.ps1 <br> e checklist output unico                          |
| agents/agent_docs_review/*                                                       | Ricetta auto-test: come testare/integrare il check-portability   | “Esegui check-portabilita-ps1.ps1 ad ogni PR su script, vedi report/avvertenze”          |
| mock/ o test/data/                                                               | Aggiungere dati demo per sandbox (CSV, JSON, sql)                | Es: `demo-users-mock.json`, `sample-output-agentdba.json`                               |
| ogni README agent/test/recipe                                                    | Banner “Testato in sandbox Zero Trust, mock env ONLY!”           | > ⚠️ Questa ricetta/script è sicura solo se eseguita in [sandbox](...)                  |

---

**Nota:** ogni patch può essere proposta via PR, segnalata come TODO o automatizzata con agent_docs_review/test-all.

Suggerisci altri punti pratici via issue o PR!



