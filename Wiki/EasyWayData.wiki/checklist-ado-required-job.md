---
title: ADO – Segnare un job come Required nelle PR
tags: [ado, branch-policies, governance, domain/control-plane, layer/gate, audience/dev, audience/ops, privacy/internal, language/it, ci]
status: active
updated: 2026-01-16
redaction: [email, phone]
id: ew-checklist-ado-required-job
chunk_hint: 250-400
entities: []
include: true
summary: Procedura per rendere il job EnforcerCheck un check Required nelle PR (Azure Repos branch policies) per far rispettare i guardrail.
llm: 
pii: none
owner: team-platform

llm:
  include: true
  chunk_hint: 5000---

[Home](../../docs/project-root/DEVELOPER_START_HERE.md) > [[Domain - Control-Plane|Control-Plane]] > [[Layer - Gate|Gate]]

Obiettivo
- Rendere il job `EnforcerCheck` obbligatorio nelle Pull Request verso `develop`/`main` in Azure Repos.

Prerequisiti
- Permessi di maintainer su Azure DevOps (Project Settings).
- Pipeline già configurata con stage `PreChecks` → job `EnforcerCheck`.

Passi UI in Azure DevOps (Branch Policies)
- Vai a Repos → Branches → seleziona `develop` (ripeti per `main`).
- Clicca sui tre puntini → Branch policies.
- Sezione “Build validation” → Add build policy:
  - Seleziona la pipeline CI del repository.
  - Opzioni: Required = ON; Trigger: Automatic; Policy requirement: Required.
  - Facoltativo: Path filters se vuoi limitare.
  - Salva.
- Verifica che il job `EnforcerCheck` compaia tra i checks richiesti nelle PR.

Note
- Motivo del guardrail: bloccare “azioni fuori scope” in modo automatico e precoce, verificando gli `allowed_paths` degli agenti.
- Se la pipeline ha più job, il sistema considera l’esito generale; per granularità, usa checks associati al job o separa pipeline.

Riferimenti
- `Wiki/EasyWayData.wiki/enforcer-guardrail.md`
- `docs/ci/ewctl-gates.md`
- `scripts/enforcer.ps1`






## Vedi anche

- [EnforcerCheck – Guardrail allowed_paths in CI](./enforcer-guardrail.md)
- [Verifica CI – ewctl gates e Flyway (branch non-main)](./ci-verifica-ewctl-gates-e-flyway.md)
- [Validazione Output Agenti in CI](./agent-output-validation-ci.md)
- [Multi‑Agent & Governance – EasyWay](./agents-governance.md)
- [Deploy su Azure App Service – Pipeline & Variabili](./deploy-app-service.md)





