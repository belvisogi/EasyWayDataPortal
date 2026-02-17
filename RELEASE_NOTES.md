# 🚀 Release Notes: v1.0.0 (Post-Security Hardening)

**Date**: 2026-02-17
**Status**: RELEASED
**Codename**: "TenantGuard"

---

## 🔒 Security & Governance
- **TenantGuard**: Implemented `portal-api/src/utils/isolation.ts` for strict tenant isolation.
- **Agent Chat Security**: Added robust test coverage for `AgentChat` API.
- **Release Workflow**: Established "Atomic Merge" protocol and governance documentation in `docs/ops/`.

## 🛠️ API & Backend
- **Version Bump**: `portal-api` upgraded to `1.0.0`.
- **Testing**: Comprehensive penetration/fuzzing tests added (`__tests__/isolation.test.ts`).

---
---

# 🛡️ Release Notes: Hybrid Core v1.1 (The Governance Era)

**Date**: 2026-02-17
**Status**: RELEASED (MVP)
**Codename**: "Iron Dome"

---

## 🚀 Key Features

### 1. The Hybrid Core (Bridge)
- **Pipeline Pattern**: `Invoke-AgentTool` now supports standardized input via stdin (`|`).
- **Local Intelligence**: Levi Adapter and SQL Tools run locally, secured by the core.

### 2. Governance System (Shield)
- **Smart Commit (`ewctl commit`)**: Replaces `git commit`. Runs pre-flight checks.
- **Iron Dome**: Git Pre-Commit Hook that blocks syntax errors and secrets.
- **Policies**: Branch protection rules and "Automatic Reviewers" for email notifications.

### 3. Documentation (Knowledge)
- **MVP**: Full architecture documented in `docs/concepts/HYBRID_CORE_MVP.md`.
- **Product Strategy**: Defined distinction between Framework (Product) and Agents (IP).

---

## 📜 Usage
From now on, **do not use `git commit`**.
Run:
```powershell
ewctl commit -m "your message"
```
This ensures your code is audited by the Iron Dome before it enters the history.

---
---

# 🦅 Release Notes: Protocol v3.1 (Sovereign Symbiosis)

**Date**: 2026-01-30
**Status**: GOLD / RTM
**Codename**: "Prometheus Unbound"

---

## 🚀 Key Features

### 1. Sovereign Content Engine (The "Brain")
- **Dynamic Text**: All marketing and manifesto text is now served from `public/content.json`.
- **Zero-Code Updates**: Text changes no longer require HTML edits or rebuilds.
- **Manifesto v3.1**: Implemented the "Sovereign Choice" narrative.

### 2. Sovereign Theme Engine (The "Skin")
- **Dynamic Branding**: Colors and fonts are served from `public/branding.json`.
- **Semantic Variables**: Introduced `--bg-paper`, `--text-secondary`, `--form-input-bg` for agnostic theming.
- **Demo Page Refactor**: Removed 300+ lines of hardcoded CSS; now fully responsive to `branding.json`.

### 3. Architecture
- **Web Components**: Standardized `<sovereign-header>`.
- **Public/Private Split**: Traefik routing rules finalized.

---

## 📜 Deployment Instructions

To apply this update to the Live Oracle Node, execute:

```powershell
.\scripts\deploy-oracle.ps1 -TargetUser ubuntu -TargetIP 80.225.86.168
```

*Required: SSH Key for `ubuntu@80.225.86.168` loaded in Agent or available at `~/.ssh/id_rsa`.*

---
*EasyWay Data Portal - Sovereign Intelligence*
