---
title: Validazione Output Agenti in CI
summary: Come validare rapidamente gli output JSON degli agenti in pipeline usando lo script PowerShell dedicato.
tags: [ci, gates, agents, domain/control-plane, layer/gate, audience/dev, audience/ops, privacy/internal, language/it]
id: ew-agent-output-validation-ci
status: draft
owner: team-platform
llm:
  include: true
  pii: none
  chunk_hint: 250-400
  redaction: [email, phone]
entities: []
updated: '2026-01-05'
next: TODO - definire next step.
---

# Validazione Output Agenti in CI
Breadcrumb: Home / CI / Output Validation

Strumento
- Script: `scripts/validate-action-output.ps1` (input JSON tramite parametro `-InputJson`)
- (Batch) Script: `scripts/ci-validate-agent-output.ps1 -Path <file|directory> [-FailOnError]`

Uso
- Salva l’output JSON dell’agente su file (es. `out/agent-result.json`)
- Esegui: `pwsh scripts/ci-validate-agent-output.ps1 -Path out -FailOnError`
- Esito: stampa report JSON per ogni file e restituisce exit code 1 se `-FailOnError` e mancano chiavi contrattuali

Integrazione (Azure DevOps) – esempio
```
- task: PowerShell@2
  displayName: 'Validate agent outputs (WhatIf)'
  condition: and(succeeded(), eq(variables['VALIDATE_AGENT_OUTPUT'], 'true'))
  inputs:
    targetType: 'inline'
    script: |
      pwsh scripts/ci-validate-agent-output.ps1 -Path out -FailOnError
```

Note
- Il contratto base è descritto in `Wiki/EasyWayData.wiki/output-contract.md` e nello schema `agents/core/schemas/action-result.schema.json`.
- Mantieni gli output concisi per ridurre costi/token e favorire parsing da LLM.






## Vedi anche

- [Doc Alignment Gate](./doc-alignment-gate.md)
- [Verifica CI – ewctl gates e Flyway (branch non-main)](./ci-verifica-ewctl-gates-e-flyway.md)
- [ADO – Segnare un job come Required nelle PR](./checklist-ado-required-job.md)
- [Multi‑Agent & Governance – EasyWay](./agents-governance.md)
- [Metodo di Lavoro Agent‑First](./agent-first-method.md)

