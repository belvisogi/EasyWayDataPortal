# Security Strategy: User Isolation (Least Privilege)

## 🎯 Objective
Run all application containers as **non-root users** to strictly limit the blast radius of any potential compromise.

## 🚫 Anti-Pattern: "Too Many Users"
Creating a different user for every service (e.g., `user-api`, `user-n8n`, `user-agent`) on the host makes managing shared files (like the Wiki or datasets) a nightmare of permission errors (`EACCES`).

## ✅ Proposed Strategy: The "Unified App Runner" (UID 1000)
We standardize on a single internal User ID (**UID 1000**) across all containers.
- **Why?**
  - **Shared Access**: Agents, API, and n8n can all read/write the shared `Wiki` volume without permission conflicts.
  - **Security**: None of them are `root`. A hack in one container doesn't give root access to the host.
  - **Simplicity**: No complex ACLs needed on the host folder.

## 🛠️ Implementation Plan

### 1. `easyway-api` (Status: ✅ Done)
- Running as: `node` (UID 1000).
- Hardening: Log directory permissions fixed.

### 2. `easyway-orchestrator` (n8n) (Status: ⚠️ Mixed)
- Current: Runs as `node` (UID 1000) by default.
- **Action**: Explicitly enforce `user: "1000:1000"` in `docker-compose.yml` to prevent accidental root fallback.

### 3. `easyway-runner` (Agents) (Status: 🔴 Root)
- Current: Runs as `root` (Ubuntu default).
- **Action**:
  - Create user `easyway` (UID 1000) in Dockerfile.
  - Grant strictly necessary permissions (e.g. `sudo` only if absolutely needed for specific tools, otherwise none).
  - Switch `USER easyway`.

### 4. `easyway-portal` (Frontend) (Status: 🟡 Nginx Root failover)
- Current: Nginx starts as root (to bind port 80), then drops to `nginx` user.
- **Action**: Acceptable for now. Ideal hardening: Run as `nginx` (UID 101) on port 8080.

## 📝 Next Steps
Shall we apply this strategy to **n8n** and **easyway-runner**?
