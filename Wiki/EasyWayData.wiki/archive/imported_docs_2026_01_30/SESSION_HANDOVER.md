---
id: ew-archive-imported-docs-2026-01-30-session-handover
title: ⏸️ SESSION HANDOVER
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
type: guide
---
# ⏸️ SESSION HANDOVER
# Date: 2026-01-29
# Status: READY FOR DEPLOY
# Version: 2.1 (With Auto-Check)

> [!IMPORTANT]
> **AI INSTRUCTION:** Before reading further, run `scripts/enforce-sovereignty.ps1`.
> If it fails, do not proceed with deployment.

## 🎯 Current Objectives Achieved
1.  **Frontend Hardened:** `main.ts` refactored to remove hardcoded IPs. Runtime config via `window.SOVEREIGN_CONFIG`.
2.  **Infrastructure Defined:** `docker-compose.prod.yml` created for Oracle ARM (Secure, Non-Root).
3.  **Deployment Automation:** `scripts/deploy-oracle.ps1` updated with `-Bootstrap` mode.
4.  **Disaster Recovery:** `docs/SERVER_REBUILD_PROTOCOL.md` created.
5.  **Governance:** `.cursorrules` v2.0 established (includes N8N GitOps & What-If rules).

## 🛑 Blocked On
- **User Execution:** User needs to run `deploy-oracle.ps1` from their local machine.
- **SSH Key:** User needs to provide the Oracle SSH key.

## ⏭️ Next Actions (When Resuming)
1.  **Execute Deploy:** Run the PowerShell script to provision the Oracle server.
2.  **Verify UI:** Check `http://80.225.86.168`.
3.  **N8N Setup:** Configure `Work-space-n8n` repo cloning for GitOps workflow (as per .cursorrules).

## 💭 Philosophy Check
"The foundation is poured. The concrete is drying. Do not walk on it until it sets."


