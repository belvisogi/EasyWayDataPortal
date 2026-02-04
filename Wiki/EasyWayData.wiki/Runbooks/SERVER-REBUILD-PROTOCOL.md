---
id: ew-runbooks-server-rebuild-protocol
title: 🏛️ SERVER REBUILD PROTOCOL (Drill: < 1h)
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
# 🏛️ SERVER REBUILD PROTOCOL (Drill: < 1h)
# Status: ACTIVE
# Target: Oracle Cloud (ARM)

## 🚨 EMERGENCY / NEW DEPLOYMENT PROCEDURE

If the server is compromised, deleted, or a new environment is required (e.g., GPU Monster Rent), follow this protocol EXACTLY.

### 📋 Phase 0: Pre-Flight Checklist (5 mins)

1.  **Workstation:** Ensure you are on the Windows Dev Machine with PowerShell 7+.
2.  **SSH Key:** Ensure you have the Private Key (`.key` or `.pem`) used to create the VM.
3.  **Secrets:** Ensure `c:\old\EasyWayDataPortal\.env.prod` exists and is populated.
    - If missing: `cp .env.prod.example .env.prod` and fill values.
    - *CRITICAL:* Do not proceed without valid API Keys in this file.

### 🚀 Phase 1: The One-Shot Deploy (15 mins)

We treat the server as ephemeral cattle, not a pet. We nuke and pave.

**Command:**
Open PowerShell in `c:\old\EasyWayDataPortal\scripts`

```powershell
.\deploy-oracle.ps1 `
  -TargetUser "ubuntu" `           # or "opc" for Oracle Linux
  -TargetIP "80.225.86.168" `      # Your static IP
  -KeyPath "C:\path\to\key.key" `  # Path to your private key
  -Bootstrap                       # <--- IMPORTANT: Installs Docker/Firewall
```

**What happens automatically:**
1.  **Bootstrap:** Updates OS, installs Docker, configures UFW Firewall.
2.  **Packaging:** Zips frontend, n8n config, docker-compose.prod.yml.
3.  **Transfer:** Uploads package to `/opt/easyway`.
4.  **Ignition:** Starts the Sovereign Stack with `docker compose up`.

### 🧩 Phase 1.5: Restore Intelligence (GitOps)

After the stack is running, we must injection the "brain" (N8N Workflows).

1.  **Run the Bridge Script:**
    ```powershell
    .\scripts\ops\deploy-n8n-workflows.ps1 -SourcePath "..\Work-space-n8n"
    ```
2.  **Verify:** Check n8n UI for imported workflows.

### 🧪 Phase 2: Smoke Test (5 mins)

1.  **Public Zone (Marketing):**
    *   Open `http://80.225.86.168` -> Should load Home (NO Auth).
    *   Open `http://80.225.86.168/demo.html` -> Should load Demo Form (NO Auth).
2.  **Private Zone (Intranet):**
    *   Open `http://80.225.86.168/memory.html` -> Should ask for **Login**.
    *   Open `http://80.225.86.168/n8n/` -> Should ask for **Login**.
    *   *Creds:* `test` / `test` (or whatever is in `.env`).
3.  **Qdrant:** `curl http://80.225.86.168/collections` (Protected).

### ♻️ Phase 3: Data Restoration (Optional)

If this is a recovery (not a fresh test), restore the volumes.

**Restore Script (Manual):**
```bash
# SSH into server
ssh ubuntu@80.225.86.168

# Stop services
cd /opt/easyway
docker compose down

# Upload backup tarballs (from your local backup location)
# ... SCP commands here ...

# Restore volumes
docker run --rm -v easyway_qdrant-data:/data -v $(pwd):/backup alpine tar xzf /backup/qdrant.tar.gz
docker run --rm -v easyway_n8n-data:/data -v $(pwd):/backup alpine tar xzf /backup/n8n.tar.gz

# Restart
docker compose up -d
```

### 🛑 Emergency Stop

If the AI goes rogue or costs spike:

```powershell
ssh ubuntu@80.225.86.168 "docker compose down"
```

---
**Protocol Owner:** gbelviso78 & Antigravity
**Last Verified:** 2026-01-30



