---
id: ew-archive-imported-docs-2026-01-30-technical-debt-strategy
title: 🧹 TECHNICAL DEBT STRATEGY
summary: TODO - aggiungere un sommario breve.
status: draft
owner: team-platform
tags: [domain/docs, layer/reference, privacy/internal, language/it, audience/dev]
llm:
  include: true
  pii: none
  chunk_hint: 250-400
  redaction: [email, phone]
entities: []
---
# 🧹 TECHNICAL DEBT STRATEGY
# Status: ACTIVE
# Context: Clean Code / Sovereign Architecture

## 1. The "Ghost Agent" Policy
If `agents/<folder>` contains only documentation (`CONCEPT.md`, `README.md`) and no code:
- **DO NOT DELETE:** The idea might be valuable.
- **DO MARK:** Create a `manifest.json` with `"status": "concept"`.
- **WHY:** This allows the Governance Agents (ewctl) to track it as backlog instead of labeling it as an error.

## 2. System Folders Exemption
The following directories in `agents/` are structural, not agents:
- `core/` (Shared logic, n8n workflows)
- `kb/` (Knowledge Base recipes)
- `logs/` (Execution logs)
- `templates/` (Scaffolding)

**Action:** Governance scripts must exclude these by name.

## 3. Keyword Policy (TODO/FIXME)
- **TODO**: Must be followed by a clear action or Ticket ID.
    - ❌ `// TODO: fix this`
    - ✅ `// TODO: Refactor loop for O(n) performance (Ticket-123)`
- **FIXME**: Critical. Should block deployment to Production unless explicitly waived.
- **HACK**: Acceptable ONLY if accompanied by a comment explaining WHY the hack is necessary (e.g., "Library X bug").

## 4. Hardcoding Remediation
If hardcoded IPs/Secrets are found during audit:
1.  **Immediate Rotation:** Assume the secret is compromised.
2.  **Refactor:** Move to `.env` or `config.js`.
3.  **Add to Linter:** Update `scripts/audit-hardcoding.ps1` to catch this pattern in future.


