---
title: EnforcerCheck – Guardrail allowed_paths in CI
tags: [ci, guardrail, governance]
status: active
---

Perché
- Serve a bloccare azioni “fuori scope” in modo automatico e precoce. In pratica, verifica che i file toccati da una PR rientrino negli `allowed_paths` dell’agente responsabile (da `manifest.json`).

Cosa fa
- Esegue `scripts/enforcer.ps1` su `git diff` per gli agenti chiave: `agent_governance`, `agent_docs_review`, `agent_pr_manager`.
- In caso di violazioni, il job fallisce subito (fail early) prima di build/test/gates.

Dove sta in pipeline
- Stage iniziale `PreChecks`, job `EnforcerCheck` (in `azure-pipelines.yml`).

Come renderlo obbligatorio in PR
- In Azure Repos → Branch Policies della branch di destinazione (`develop`, `main`):
  - Aggiungi la pipeline come build validation.
  - Seleziona il job `EnforcerCheck` come `required`.

Benefici
- Riduce il rischio operativo e impedisce scope creep.
- Rende vincolanti gli `allowed_paths` dei manifest agent.
- Fornisce feedback chiaro e tracciabile su violazioni.

Riferimenti
- `azure-pipelines.yml` (stage `PreChecks` → job `EnforcerCheck`)
- `scripts/enforcer.ps1`
- `agents/agent_*/manifest.json`

