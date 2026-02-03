---
id: gitlab-setup-guide
title: GitLab Self-Managed Setup Guide
summary: Complete guide for deploying and managing GitLab on 80.225.86.168
tags: [domain/infra, layer/runbook, audience/ops, privacy/internal, language/it]
status: active
owner: team-platform
updated: 2026-02-03
llm:
  include: true
  pii: none
  chunk_hint: 400-600
entities: [GitLab, Docker, Traefik, Backup]
---

# GitLab Self-Managed Setup Guide

> **Server**: 80.225.86.168  
> **Purpose**: Sovereign DevOps platform for EasyWay projects  
> **Philosophy**: Antifragile, documented, reproducible

---

## 📋 Table of Contents

1. [Why GitLab Self-Managed](#why-gitlab-self-managed)
2. [Server Requirements](#server-requirements)
3. [Architecture Overview](#architecture-overview)
4. [Firewall Configuration (CRITICAL)](#firewall-configuration-critical)
5. [Deployment](#deployment)
6. [Configuration](#configuration)
7. [Backup Strategy](#backup-strategy)
8. [Troubleshooting](#troubleshooting)
9. [Disaster Recovery](#disaster-recovery)

---

## 1. Why GitLab Self-Managed

### Strategic Reasons (from `migr-devops-to-gitlab.md`)

- ✅ **Sovereign**: Full control over code and metadata
- ✅ **Antifragile**: Can migrate to any Git platform in <1 hour
- ✅ **Agent-Native**: API access for automated workflows
- ✅ **Privacy**: No external SaaS dependencies
- ✅ **Portability**: Standard Git, no vendor lock-in

### Technical Reasons

- ✅ **Integrated CI/CD**: GitLab Runner included
- ✅ **Issue Tracking**: Built-in project management
- ✅ **Container Registry**: Docker image hosting
- ✅ **API-First**: Full REST/GraphQL API for agents

---

## 2. Server Requirements

### Current Server Status (2026-02-03)

| Resource | Total | Used | Available | GitLab Needs | Status |
|----------|-------|------|-----------|--------------|--------|
| **RAM** | 23 GB | 2.5 GB | 20 GB | 4-8 GB | ✅ Excellent |
| **Storage** | 96 GB | 39 GB | 57 GB | 20-50 GB | ✅ Good |
| **CPU** | 4 cores | - | 4 cores | 2-4 cores | ✅ Sufficient |

**Verification Command**:
```bash
ssh -i "C:\old\Virtual-machine\ssh-key-2026-01-25.key" ubuntu@80.225.86.168 \
  "free -h && df -h && nproc"
```

### Existing Services (10 Docker containers)

1. `easyway-portal` - Frontend Valentino
2. `easyway-runner` - Agent runner
3. `easyway-api` - Backend API
4. `easyway-gateway` - Traefik reverse proxy ⚠️ (will integrate with GitLab)
5. `easyway-memory` - Qdrant
6. `easyway-orchestrator` - n8n
7. `easyway-db` - SQL Server
8. `easyway-storage-s3` - MinIO
9. `easyway-storage` - Azurite
10. `easyway-cortex` - ChromaDB

---

## 3. Architecture Overview

### Network Architecture

```
Internet
   ↓
[Traefik Reverse Proxy] :80, :443
   ↓
   ├─→ [Frontend] :3000 → http://80.225.86.168/
   ├─→ [GitLab HTTP] :8929 → http://80.225.86.168:8929/
   └─→ [GitLab SSH] :2222 → ssh://git@80.225.86.168:2222
```

### Storage Layout

```
/home/ubuntu/
├── docker-compose.yml           # Main stack (existing)
├── docker-compose.gitlab.yml    # GitLab stack (new)
│   ├── ports:
│   │   - "8929:8929"    # HTTP (GitLab UI) - Must match external_url port
│   │   - "2222:22"      # SSH (Git operations)
├── gitlab/                      # GitLab data (new)
│   ├── config/                  # Configuration files
│   ├── logs/                    # Application logs
│   └── data/                    # Git repositories, DB, uploads
└── backups/                     # Backup destination
    └── gitlab/                  # GitLab backups
```

---

## 4. Installation Steps

### Step 1: Create GitLab Directory Structure

**Command**:
```bash
ssh -i "C:\old\Virtual-machine\ssh-key-2026-01-25.key" ubuntu@80.225.86.168 << 'EOF'
mkdir -p ~/gitlab/{config,logs,data}
mkdir -p ~/backups/gitlab
sudo chown -R 1000:1000 ~/gitlab
EOF
```

**Why**:
- `config/`: GitLab configuration files (gitlab.rb, etc.)
- `logs/`: Application logs for debugging
- `data/`: Git repositories, database, uploads (most important)
- `backups/`: Backup destination (separate from data)

**Verification**:
```bash
ssh -i "C:\old\Virtual-machine\ssh-key-2026-01-25.key" ubuntu@80.225.86.168 \
  "ls -la ~/gitlab && ls -la ~/backups"
```

---

### Step 2: Create Docker Compose File

**File**: `~/docker-compose.gitlab.yml`

**Why separate file**:
- ✅ Isolates GitLab from main stack
- ✅ Can be started/stopped independently
- ✅ Easier to backup/restore
- ✅ Clear separation of concerns

**Content**: See `docker-compose.gitlab.yml` in this directory

---

### Step 3: Deploy GitLab

**Command**:
```bash
ssh -i "C:\old\Virtual-machine\ssh-key-2026-01-25.key" ubuntu@80.225.86.168 << 'EOF'
cd ~
docker-compose -f docker-compose.gitlab.yml up -d
EOF
```

**Expected Output**:
```
Creating network "ubuntu_gitlab" with the default driver
Creating easyway-gitlab ... done
```

**Verification**:
```bash
ssh -i "C:\old\Virtual-machine\ssh-key-2026-01-25.key" ubuntu@80.225.86.168 \
  "docker ps | grep gitlab"
```

**Expected**: Container `easyway-gitlab` running

---

### Step 4: Wait for GitLab to Start

**Why**: GitLab takes 2-5 minutes to initialize on first run

**Command**:
```bash
ssh -i "C:\old\Virtual-machine\ssh-key-2026-01-25.key" ubuntu@80.225.86.168 \
  "docker logs -f easyway-gitlab"
```

**Wait for**: `gitlab Reconfigured!` message

**Alternative** (check health):
```bash
ssh -i "C:\old\Virtual-machine\ssh-key-2026-01-25.key" ubuntu@80.225.86.168 \
  "docker exec easyway-gitlab gitlab-ctl status"
```

**Expected**: All services `run` status

---

### Step 5: Get Initial Root Password

**Command**:
```bash
ssh -i "C:\old\Virtual-machine\ssh-key-2026-01-25.key" ubuntu@80.225.86.168 \
  "docker exec easyway-gitlab cat /etc/gitlab/initial_root_password"
```

**Save this password** - needed for first login

**Username**: `root`  
**Password**: (from command above)  
**URL**: `http://80.225.86.168:8929`

---

### Step 6: Initial Configuration

**Access GitLab**:
1. Open browser: `http://80.225.86.168:8929`
2. Login as `root` with password from Step 5
3. Change root password immediately
4. Create admin user (recommended: `gitlab-admin`)

**Disable Sign-ups** (security):
- Admin Area → Settings → General → Sign-up restrictions
- Uncheck "Sign-up enabled"
- Save changes

**Configure SSH** (optional):
- Admin Area → Settings → Network → Outbound requests
- Allow requests to local network (if needed for webhooks)

---

## 5. Configuration

### GitLab Configuration File

**Location**: `~/gitlab/config/gitlab.rb`

**Edit**:
```bash
ssh -i "C:\old\Virtual-machine\ssh-key-2026-01-25.key" ubuntu@80.225.86.168 \
  "docker exec -it easyway-gitlab editor /etc/gitlab/gitlab.rb"
```

**Key Settings**:
```ruby
# External URL
external_url 'http://80.225.86.168:8929'

# SSH port
gitlab_rails['gitlab_shell_ssh_port'] = 2222

# Backup settings
gitlab_rails['backup_path'] = "/var/opt/gitlab/backups"
gitlab_rails['backup_keep_time'] = 604800  # 7 days

# Email (optional)
gitlab_rails['smtp_enable'] = false  # Configure later if needed
```

**Apply changes**:
```bash
ssh -i "C:\old\Virtual-machine\ssh-key-2026-01-25.key" ubuntu@80.225.86.168 \
  "docker exec easyway-gitlab gitlab-ctl reconfigure"
```

---

### GitLab Runner Setup (CI/CD)

**Why**: Needed for running CI/CD pipelines

**Command**:
```bash
ssh -i "C:\old\Virtual-machine\ssh-key-2026-01-25.key" ubuntu@80.225.86.168 << 'EOF'
docker run -d --name easyway-gitlab-runner \
  --restart always \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v ~/gitlab-runner/config:/etc/gitlab-runner \
  gitlab/gitlab-runner:latest
EOF
```

**Register Runner**:
1. Get registration token: GitLab → Admin Area → CI/CD → Runners
2. Register:
```bash
ssh -i "C:\old\Virtual-machine\ssh-key-2026-01-25.key" ubuntu@80.225.86.168 \
  "docker exec -it easyway-gitlab-runner gitlab-runner register"
```

**Prompts**:
- GitLab URL: `http://80.225.86.168:8929`
- Token: (from GitLab UI)
- Description: `easyway-runner-1`
- Tags: `docker,linux`
- Executor: `docker`
- Default image: `alpine:latest`

---

## 6. Backup Strategy

### Automated Daily Backups

**Cron Job** (on server):
```bash
# Edit crontab
ssh -i "C:\old\Virtual-machine\ssh-key-2026-01-25.key" ubuntu@80.225.86.168 \
  "crontab -e"

# Add this line:
0 2 * * * docker exec easyway-gitlab gitlab-backup create STRATEGY=copy
```

**Why 2 AM**: Low traffic, won't impact users

**Backup Location**: `~/gitlab/data/backups/`

---

### Manual Backup

**Create backup**:
```bash
ssh -i "C:\old\Virtual-machine\ssh-key-2026-01-25.key" ubuntu@80.225.86.168 \
  "docker exec easyway-gitlab gitlab-backup create"
```

**List backups**:
```bash
ssh -i "C:\old\Virtual-machine\ssh-key-2026-01-25.key" ubuntu@80.225.86.168 \
  "docker exec easyway-gitlab ls -lh /var/opt/gitlab/backups"
```

**Download backup** (to local):
```bash
scp -i "C:\old\Virtual-machine\ssh-key-2026-01-25.key" \
  ubuntu@80.225.86.168:~/gitlab/data/backups/TIMESTAMP_gitlab_backup.tar \
  C:\old\backups\gitlab\
```

---

### Backup Contents

**Included**:
- ✅ Git repositories
- ✅ Database (PostgreSQL)
- ✅ Uploads (avatars, attachments)
- ✅ CI/CD artifacts
- ✅ Container registry images

**NOT included** (backup separately):
- ⚠️ Configuration files (`gitlab.rb`)
- ⚠️ SSL certificates
- ⚠️ SSH host keys

**Backup config**:
```bash
ssh -i "C:\old\Virtual-machine\ssh-key-2026-01-25.key" ubuntu@80.225.86.168 \
  "tar -czf ~/backups/gitlab/config-$(date +%Y%m%d).tar.gz ~/gitlab/config"
```

---

## 7. Troubleshooting

### GitLab Won't Start

**Check logs**:
```bash
ssh -i "C:\old\Virtual-machine\ssh-key-2026-01-25.key" ubuntu@80.225.86.168 \
  "docker logs easyway-gitlab --tail 100"
```

**Common issues**:
1. **Port conflict**: Another service using 8929 or 2222
   - Solution: Change ports in `docker-compose.gitlab.yml`
2. **Out of memory**: GitLab needs 4GB minimum
   - Solution: Stop other services or increase RAM
3. **Permission errors**: Data directory not writable
   - Solution: `sudo chown -R 1000:1000 ~/gitlab`

---

### Can't Access GitLab UI

**Check container**:
```bash
ssh -i "C:\old\Virtual-machine\ssh-key-2026-01-25.key" ubuntu@80.225.86.168 \
  "docker ps | grep gitlab"
```

**Check firewall**:
```bash
ssh -i "C:\old\Virtual-machine\ssh-key-2026-01-25.key" ubuntu@80.225.86.168 \
  "sudo ufw status"
```

**Open port if needed**:
```bash
ssh -i "C:\old\Virtual-machine\ssh-key-2026-01-25.key" ubuntu@80.225.86.168 \
  "sudo ufw allow 8929/tcp && sudo ufw allow 2222/tcp"
```

---

### Git Push Fails

**Check SSH**:
```bash
ssh -i "C:\old\Virtual-machine\ssh-key-2026-01-25.key" -p 2222 git@80.225.86.168
```

**Expected**: `Welcome to GitLab, @username!`

**If fails**:
1. Check SSH port in `gitlab.rb`
2. Verify SSH key added to GitLab profile
3. Check firewall allows port 2222

---

## 8. Disaster Recovery

### Scenario 1: GitLab Container Deleted

**Recovery**:
```bash
# Data is in ~/gitlab/data (persistent)
cd ~
docker-compose -f docker-compose.gitlab.yml up -d
# GitLab will use existing data
```

**Time**: <5 minutes

---

### Scenario 2: Server Crash

**Recovery**:
1. **Setup new server** (same specs)
2. **Restore data**:
```bash
# Copy backup to new server
scp -i "ssh-key.key" backup.tar ubuntu@NEW_IP:~/

# Extract
ssh ubuntu@NEW_IP "tar -xzf backup.tar -C ~/"

# Deploy GitLab
ssh ubuntu@NEW_IP "docker-compose -f docker-compose.gitlab.yml up -d"

# Restore backup
ssh ubuntu@NEW_IP "docker exec easyway-gitlab gitlab-backup restore BACKUP=TIMESTAMP"
```

**Time**: <1 hour

---

### Scenario 3: Migrate to Different Platform

**Options**:
1. **GitHub**: Export repos as Git bundles, import to GitHub
2. **Gitea**: Similar to GitLab, easy migration
3. **Self-hosted Git**: Use bare Git repos

**Export all repos**:
```bash
ssh ubuntu@80.225.86.168 << 'EOF'
cd ~/gitlab/data/git-data/repositories
for repo in */*.git; do
  git clone --mirror $repo ~/exports/$(basename $repo)
done
EOF
```

**Time**: <2 hours for 100 repos

---

## 9. Maintenance

### Update GitLab

**Check current version**:
```bash
ssh -i "C:\old\Virtual-machine\ssh-key-2026-01-25.key" ubuntu@80.225.86.168 \
  "docker exec easyway-gitlab cat /opt/gitlab/version-manifest.txt | head -1"
```

**Update**:
```bash
ssh -i "C:\old\Virtual-machine\ssh-key-2026-01-25.key" ubuntu@80.225.86.168 << 'EOF'
# Backup first!
docker exec easyway-gitlab gitlab-backup create

# Pull new image
docker pull gitlab/gitlab-ce:latest

# Recreate container
docker-compose -f docker-compose.gitlab.yml up -d
EOF
```

**Verify**:
```bash
ssh -i "C:\old\Virtual-machine\ssh-key-2026-01-25.key" ubuntu@80.225.86.168 \
  "docker exec easyway-gitlab gitlab-ctl status"
```

---

### Monitor Disk Usage

**Command**:
```bash
ssh -i "C:\old\Virtual-machine\ssh-key-2026-01-25.key" ubuntu@80.225.86.168 \
  "du -sh ~/gitlab/*"
```

**Alert threshold**: >40 GB (80% of available 57 GB)

**Cleanup old backups**:
```bash
ssh -i "C:\old\Virtual-machine\ssh-key-2026-01-25.key" ubuntu@80.225.86.168 \
  "find ~/gitlab/data/backups -type f -mtime +7 -delete"
```

---

## 10. Q&A (Troubleshooting Log)

### Q: GitLab uses too much RAM

**A**: Reduce workers in `gitlab.rb`:
```ruby
puma['worker_processes'] = 2  # Default: 4
sidekiq['max_concurrency'] = 10  # Default: 25
```

---

### Q: Backup takes too long

**A**: Use incremental backups:
```bash
docker exec easyway-gitlab gitlab-backup create STRATEGY=copy INCREMENTAL=yes
```

---

### Q: Can't push large files

**A**: Increase max size in `gitlab.rb`:
```ruby
gitlab_rails['max_attachment_size'] = 100  # MB
```

---

## 11. Next Steps

After GitLab is running:

1. ✅ Create first project (DQF Agent)
2. ✅ Setup GitHub mirror
3. ✅ Configure CI/CD pipeline
4. ✅ Test backup/restore
5. ✅ Document project-specific workflows

---

**Maintained by**: EasyWay Platform Team  
**Last Updated**: 2026-02-03  
**Status**: Production-ready
