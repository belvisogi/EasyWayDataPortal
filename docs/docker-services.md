# Docker Services Reference

> **Purpose**: Quick reference for all Docker services in EasyWay Core to avoid "treasure hunting" during deployments.

---

## Service Architecture

```
Internet → Traefik (Gateway) → Services (Frontend, API, etc.)
                              ↓
                          Backends (DB, Storage, Vector DB)
```

**Key Principle**: Traefik handles all routing. Frontend serves static files only (see `docs/nginx-antifragile-pattern.md`).

---

## Service Inventory

### 1. **frontend** (easyway-portal)
- **Container Name**: `easyway-portal`
- **Image**: `easyway/frontend:latest`
- **Purpose**: Serves static frontend (SPA)
- **Port**: 8080 (internal)
- **Path**: `/opt/easyway/apps/portal-frontend`
- **Build**: Multi-stage (Node.js build → Nginx serve)
- **Healthcheck**: `wget http://127.0.0.1:8080/`

**Deployment**:
```bash
cd /opt/easyway
sudo docker compose build frontend
sudo docker compose up -d frontend
```

**Common Issues**:
- `npm ci` fails → Use `npm install` (see Dockerfile)
- 404 on new pages → Check `public/pages/pages.manifest.json`

---

### 2. **traefik** (easyway-gateway)
- **Container Name**: `easyway-gateway`
- **Purpose**: Reverse proxy + SSL termination + service discovery
- **Ports**: 80 (HTTP), 443 (HTTPS), 8080 (dashboard)
- **Config**: Labels in `docker-compose.yml`

**Routes**:
- `/` → frontend
- `/api/qdrant/` → qdrant
- `/api/n8n/` → n8n (if enabled)

**Docs**: `docs/nginx-antifragile-pattern.md`

---

### 3. **api** (easyway-api)
- **Container Name**: `easyway-api`
- **Purpose**: Backend REST API
- **Path**: `/opt/easyway/apps/portal-api` (assumed)
- **Port**: 3000 (internal, proxied via Traefik)

---

### 4. **postgres** (easyway-db)
- **Container Name**: `easyway-db`
- **Purpose**: PostgreSQL database
- **Port**: 5432 (internal)
- **Volume**: `postgres-data`

---

### 5. **qdrant** (easyway-memory)
- **Container Name**: `easyway-memory`
- **Purpose**: Vector database for semantic search
- **Port**: 6333 (internal)
- **Volume**: `qdrant-data`
- **Route**: `/api/qdrant/` (via Traefik)

---

### 6. **minio** (easyway-storage)
- **Container Name**: `easyway-storage`
- **Purpose**: S3-compatible object storage
- **Ports**: 9000 (API), 9001 (Console)

---

### 7. **minio-s3** (easyway-storage-s3)
- **Container Name**: `easyway-storage-s3`
- **Purpose**: Secondary MinIO instance (?)
- **Note**: Verify if this is duplicate or separate use case

---

### 8. **n8n** (easyway-orchestrator)
- **Container Name**: `easyway-orchestrator`
- **Purpose**: Workflow automation (n8n)
- **Port**: 5678 (internal)
- **Route**: `/api/n8n/` (via Traefik, if enabled)

---

### 9. **cortex** (easyway-cortex)
- **Container Name**: `easyway-cortex`
- **Purpose**: AI/ML service (?)
- **Note**: Verify purpose and dependencies

---

### 10. **runner** (easyway-runner)
- **Container Name**: `easyway-runner`
- **Purpose**: Background job runner (?)
- **Note**: Verify purpose (cron jobs? async tasks?)

---

## Server Directory Structure

```
/home/ubuntu/EasyWayDataPortal/    # Git repository (development)
    ├── apps/
    │   ├── portal-frontend/
    │   └── portal-api/
    └── ...

/opt/easyway/                       # Production code (Docker mounts)
    ├── apps/
    │   ├── portal-frontend/        # Synced from git repo
    │   └── portal-api/
    ├── docker-compose.yml
    └── ...
```

**Workflow**:
1. `git pull` in `/home/ubuntu/EasyWayDataPortal`
2. `rsync` to `/opt/easyway`
3. `docker compose build` + `up -d`

---

## Common Commands

### List Services
```bash
sudo docker compose ps --services
```

### List Running Containers
```bash
sudo docker ps --format '{{.Names}}'
```

### Rebuild Service
```bash
cd /opt/easyway
sudo docker compose build <service-name>
sudo docker compose up -d <service-name>
```

### View Logs
```bash
sudo docker logs <container-name>
sudo docker logs -f <container-name>  # Follow
```

### Restart Service
```bash
sudo docker restart <container-name>
```

### Full Stack Restart
```bash
cd /opt/easyway
sudo docker compose down
sudo docker compose up -d
```

---

## Deployment Checklist

- [ ] Local: Commit + push to `origin/main`
- [ ] Server: `cd /home/ubuntu/EasyWayDataPortal && git pull`
- [ ] Server: `sudo rsync -av apps/ /opt/easyway/apps/ --exclude node_modules --exclude dist`
- [ ] Server: `cd /opt/easyway && sudo docker compose build <service>`
- [ ] Server: `sudo docker compose up -d <service>`
- [ ] Verify: `curl -I http://80.225.86.168/<route>`

---

## Troubleshooting

### Service Won't Start
```bash
# Check logs
sudo docker logs <container-name>

# Check if port is in use
sudo netstat -tulpn | grep <port>

# Remove old container
sudo docker rm -f <container-name>
```

### Build Fails
```bash
# Clear build cache
sudo docker builder prune

# Rebuild without cache
sudo docker compose build --no-cache <service>
```

### Service Not Found
```bash
# List services in docker-compose.yml
grep -E '^  [a-z-]+:$' /opt/easyway/docker-compose.yml
```

---

## References

- **Architecture**: `README.md` (Docker Native, Sovereign Appliance)
- **Nginx Pattern**: `docs/nginx-antifragile-pattern.md`
- **Deployment**: `docs/qa-log.md` (Docker Deployment Process section)
- **Azure Deployment**: `Wiki/EasyWayData.wiki/deployment-decision-mvp.md`

---

**Last Updated**: 2026-02-02  
**Maintainer**: team-platform
