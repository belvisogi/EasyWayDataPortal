---
title: ADO – Segnare un job come Required nelle PR
tags: [ado, branch-policies, governance, domain/control-plane, layer/gate, audience/dev, audience/ops, privacy/internal, language/it, ci]
status: active
id: ew-checklist-ado-required-job
summary: TODO - aggiungere un sommario breve.
owner: team-platform
llm:
  include: true
  pii: none
  chunk_hint: 250-400
  redaction: [email, phone]
entities: []
---

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




