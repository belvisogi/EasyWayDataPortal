---
title: Start Here - Link Essenziali
tags: [start-here, onboarding, agents, argos, language/it, domain/docs, layer/index, audience/non-expert, audience/dev, privacy/internal]
status: active
updated: 2026-01-16
redaction: [email, phone]
id: ew-start-here
chunk_hint: 200-300
entities: []
include: true
summary: Punti di ingresso canonici: orchestrazioni, intent, control-plane, UX, HOWTO e KB.
llm: 
  pii: none
  redaction: [email, phone]
pii: none
owner: team-platform

llm:
  redaction: [email, phone]
  include: true
  chunk_hint: 5000
type: guide
---
## Percorso rapido (Decision-Complete)

1) Se devi fare delivery (quando usarla: feature pronta per PR e validazione finale)
- Golden Path catalog: `docs/skills/catalog.json`
- Skill PR + Server Validation: `docs/skills/pr-server-validation/SKILL.md`
- Bridge generator: `scripts/pwsh/generate-macro-skills-registry.ps1`

2) Se devi capire il sistema agentico (quando usarla: onboarding tecnico e governance)
- Skills framework: `docs/wiki/Skills-Framework.md`
- Runtime skills registry: `agents/skills/registry.json`
- Macro skills index: `docs/skills/README.md`

3) Se devi operare la console (quando usarla: consultazione catalogo e troubleshooting)
- Console entrypoint: `apps/agent-console/index.html`
- Runtime data source: `agents/skills/registry.json`
- Macro data source: `docs/skills/catalog.generated.json`

3) Control Plane + Domini (skeleton)
- Control Plane: `control-plane/index.md`
- Domini: `domains/index.md`
- Policy ADO (Operating Model): `ado-operating-model.md`

4) UX Prompts (IT/EN)
- Copioni UI: `docs/agentic/templates/orchestrations/ux_prompts.it.json`, `docs/agentic/templates/orchestrations/ux_prompts.en.json`

5) HOWTO - WHAT-first + Diario
- Guida team: `howto-what-first-team.md`
- Audit doc agentica: `docs-agentic-audit.md`
- Onboarding dev (Step 1 - Setup ambiente): `easyway-webapp/05_codice_easyway_portale/easyway_portal_api/step-1-setup-ambiente.md`


5b) Tag taxonomy (controllata)
- Tag taxonomy: `docs-tag-taxonomy.md`
6) KB Ricette (comandi rapidi)
- Skeleton: `agents/kb/recipes.jsonl` (id: `kb-docs-skeleton-601`)
- Lint: `agents/kb/recipes.jsonl` (id: `kb-lint-whatfirst-602`)
- Setup env locale: `agents/kb/recipes.jsonl` (id: `kb-setup-env-001`)
- ADO operating model + bootstrap: `agents/kb/recipes.jsonl` (id: `kb-ado-operating-model-716`)

7) Materiale legacy / asset
- Contesto: `blueprints/legacy-reference-material.md`
- Branding: `UX/branding-assets.md`

8) Runbooks (Ops)
- Indice runbook: `Runbooks/index.md`
- Bootstrap Dual Server (Oracle Dev/Staging + Hetzner Prod): `Runbooks/dual-server-bootstrap.md`


---

## 9) 🛡️ Governance & Sovereign DevOps (Sovereignty Kit)
*   **Rules**: `standards/gitlab-workflow.md` (Branching, Naming, Labels)
*   **Release Flow (allineamento 2026-02-12)**: `control-plane/release-flow-alignment-2026-02-12.md` (perche/come/quando + Q&A anti-pattern)
*   **PRD Wishlist MVP (Multi-VCS)**: `control-plane/prd-agentic-release-multivcs-mvp.md` (ADO + Forgejo + GitHub)
*   **RBAC**: `governance/gitlab-rbac.md` (Groups, Roles, Security Split)
*   **Architecture**: `architecture/sovereign-gap-fillers.md` (Gap Fillers & RAG)
*   **Onboarding**: `guides/client-onboarding-iac.md` (Terraform Quickstart)
*   **Manifesto**: `manifesto-haka.md` (The Vision)

### ✍️ Authors
> **gbelviso78** & **Antigravity/Codex/ChatGPT** (The Agents)
> *"Ci adattiamo alle novità evolvendoci grazie a loro."*












