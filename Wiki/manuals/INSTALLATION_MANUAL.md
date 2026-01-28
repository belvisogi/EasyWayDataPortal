# EasyWay Installation & Operations Manual 📘

> **Version**: 1.0 (Hardened & GitOps Ready)
> **Date**: 2026-01-28
> **Target**: Ubuntu ARM64 (Oracle Cloud Ampere)

## 1. Prerequisites
-   **OS**: Ubuntu 22.04 LTS (ARM64)
-   **User**: `ubuntu` (UID 1000)
-   **Docker**: Installed & Running (User `ubuntu` in `docker` group)
-   **Repo Path**: `~/EasyWayDataPortal`

## 2. Infrastructure Deployment 🏗️

### A. Clone & Setup
```bash
git clone <repo-url> ~/EasyWayDataPortal
cd ~/EasyWayDataPortal
cp .env.example .env # Configure secrets!
```

### B. The Stack (Docker Compose)
We use a **Split-Stack** strategy:
1.  **Infrastructure** (`docker-compose.infra.yml`): Database, Gateway, Storage.
2.  **Apps** (`docker-compose.apps.yml`): API, Frontend, Agents, n8n.

**Launch Order:**
```bash
# 1. Start Support Services
docker compose -f docker-compose.infra.yml up -d

# 2. Start Applications (Dependent on Infra)
docker compose -f docker-compose.apps.yml up -d
```

## 3. Security Hardening (The "Standard") 🛡️

### A. User Isolation (UID 1000)
All containers **MUST** run as non-root users mapped to Host UID 1000.
-   **API**: Runs as `node` (UID 1000).
-   **n8n**: Configured with `user: "1000:1000"`.
-   **Agents**: Dockerfile creates `easyway` user (UID 1000).

### B. Resilience
All services usage `restart: unless-stopped`.

## 4. n8n GitOps ("The Factory") 🏭

We do **not** edit workflows directly on the server. We use a **GitOps** flow.

### A. Structure
-   `~/EasyWayDataPortal`: The Appliance (Runtime).
-   `~/Work-space-n8n`: The Factory (Source Code of workflows).

### B. Deployment
To update workflows on the server:
1.  **Pull** latest code in the Factory:
    ```bash
    cd ~/Work-space-n8n
    git pull
    ```
2.  **Deploy** to the Appliance:
    ```bash
    pwsh ~/EasyWayDataPortal/scripts/deploy-workflows.ps1
    ```
    *This script copies JSONs to the n8n container and imports them via CLI.*

## 5. Troubleshooting 🔧

### Check Status
```bash
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
```

### Access Logs
```bash
docker logs --tail 100 -f easyway-api
docker logs --tail 100 -f easyway-orchestrator
```

### Verification Endpoints
-   **Frontend**: `http://localhost:80` (via Tunnel) or Public IP.
-   **n8n**: `http://localhost:5678` (via Tunnel).
-   **API**: `http://localhost:3000` (via Tunnel).
