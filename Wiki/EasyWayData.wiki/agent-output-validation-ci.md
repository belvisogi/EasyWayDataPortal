---
title: Validazione Output Agenti in CI
summary: Come validare rapidamente gli output JSON degli agenti in pipeline usando lo script PowerShell dedicato.
tags: [ci, gates, agents]
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

