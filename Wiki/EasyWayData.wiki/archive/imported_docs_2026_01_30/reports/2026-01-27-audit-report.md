---
id: ew-archive-imported-docs-2026-01-30-reports-2026-01-27-audit-report
title: 🕵️ EasyWay System Audit Report - 2026-01-27
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
# 🕵️ EasyWay System Audit Report - 2026-01-27

> **Status**: 🟡 **PARTIALLY STANDARDIZED**
> **Core**: 🟢 Ready (Portable Brain Standard)
> **Periphery**: 🔴 Legacy (Script-only)

## 1. Agent Standardization Status

| Agent | Status | Notes |
|-------|--------|-------|
| `agent-gedi.ps1` | 🟢 **Standard** | Philosophy Engine ready. |
| `agent-security.ps1` | 🟢 **Standard** | Supported `security:analyze`. |
| `agent-retrieval.ps1` | 🟢 **Standard** | Replaced `rag_agent.ps1`. |
| `agent-chronicler.ps1`| 🟢 **Standard** | New logbook manager. |
| `agent-ado-governance.ps1` | 🟢 **Standard** | Gatekeeper ready. |
| `agent-backend.ps1` | 🔴 **Legacy** | Missing `Provider/Model`. Native script only. |
| `agent-frontend.ps1` | 🔴 **Legacy** | Missing `Provider/Model`. |
| `agent-dba.ps1` | 🔴 **Legacy** | Complex logic, needs partial refactor. |
| `agent-docs-*.ps1` | 🔴 **Legacy** | 3 agents to unify/standardize. |
| `agent-pr/release.ps1`| 🔴 **Legacy** | CI/CD agents. |

**Observation**: The "Brain" is modern, the "Hands" (Domain Agents) are still old-school. They work, but cannot execute intelligent decisions independently (they need n8n or GEDI to drive them).

## 2. Documentation & Wiki Gaps

✅ **FIXED** (2026-01-27)
Previously found 6 files referencing the deprecated `rag_agent.ps1`.
All references have been updated to point to `agent-retrieval.ps1`.

- `standards/easyway-server-standard.md` (Updated)
- `standards/agent-environment-standard.md` (Updated)
- `infrastructure/oracle-agent-software-inventory.md` (Updated)
- `infrastructure/oracle-cloud/*.md` (Updated)

**Risk**: ~~A user following old docs might look for `rag_agent.ps1`~~ **RESOLVED**.

## 3. Recommendations

1.  **Delete/Archive `rag_agent.ps1`**: Eliminate confusion.
2.  **Batch Refactor Domain Agents**:
    - Don't rewrite logic.
    - Just wrap them in the `agent-template.ps1` structure so they accept `-Provider`.
    - Allow them to "Ask for help" if an error occurs.
3.  **Wiki cleanup**: Run a `sed` replacement to change `rag_agent.ps1` -> `agent-retrieval.ps1` in all docs.


## 4. Server & Infrastructure Audit (2026-01-27)

| Check | Status | Notes |
|-------|--------|-------|
| **n8n Container** | 🟢 **Standard** | Refactored to "Appliance Mode" (Bind Mounts). |
| **Permissions** | 🟢 **Fixed** | `/opt/easyway/containers` owned by `easyway` (UID 1003). |
| **Bind Mounts** | ✅ **Active** | Data visible in `./data` (No Docker Volumes). |
| **Ports** | 🟢 **Clean** | Conflict resolved (Removed legacy `easyway-orchestrator`). |


### 4.1 User Isolation Audit
| Service | Checks | User | Status |
|---------|--------|------|--------|
| **Host** | SSH Access | `ubuntu` (Admin), `easyway` (Agent) | 🟢 **Separated** |
| **Ollama** | Systemd Service | `ollama` (Dynamic User) | 🟢 **Isolated** |
| **n8n** | Docker User | `1003` (easyway) | 🟢 **Mapped** |
| **Files** | `/opt/easyway` | `root:easyway` (Binaries), `easyway:easyway` (Data) | 🟢 **Compliant** |

**Conclusion**: Multi-user isolation is active. We employ "User per Ecosystem" (EasyWay user for all Agent tools) and "User per Service" (Ollama user for LLM).

### 4.2 Role Policy Audit (The Lego Model)
| Check | Status | Finding |
|-------|--------|---------|
| **Runtime Root** | 🟢 **None** | No application running as root. |
| **Service Sudo** | 🟢 **Denied** | User `easyway` is NOT in sudoers. |

### 4.3 Cleanup Audit (Spring Cleaning) 🧹
| Category | Action | Status |
|----------|--------|--------|
| **Garbage Files** | Deleted `~/rag_agent.ps1` and dupes | 🟢 **Clean** |
| **Old Backups** | Archived to `/opt/easyway/var/backup/archive` | 🟢 **Archived** |
| **Docker Prune** | Reclaimed ~4.3 GB space | 🟢 **Optimized** |
| **n8n Recovery** | Fixed Permissions via `/data` Remap | 🟢 **Stable** |

**Final Verdict**: Server is clean, logical, and TESS compliant.


