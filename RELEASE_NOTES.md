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
