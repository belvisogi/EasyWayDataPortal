---
id: gitlab-qa
title: GitLab Setup - Q&A and Troubleshooting Log
summary: Real-world issues encountered during GitLab setup and their solutions
tags: [domain/infra, layer/reference, audience/ops, privacy/internal, language/it]
status: active
owner: team-platform
updated: 2026-02-03
llm:
  include: true
  pii: none
  chunk_hint: 300-500
entities: [GitLab, Docker, Troubleshooting]
---

# GitLab Setup - Q&A and Troubleshooting Log

> **Purpose**: Document real issues and solutions for future reference  
> **Philosophy**: Every error is a learning opportunity  
> **Updated**: As issues occur

---

## Setup Issues

### Q0: Cannot access GitLab UI from browser

**Symptoms**:
```
http://80.225.86.168:8929
# Connection timeout or refused
```

**Diagnosis**:
```bash
# Check if GitLab is running
docker ps | grep gitlab

# Check if port is listening
netstat -tulpn | grep 8929
```

**Root Cause**:
- Oracle Cloud Security List not configured
- Ports 8929 and 2222 not open in firewall

**Solution**:

**1. Oracle Cloud Console**:
- Navigate to: Compute → Instances → Select instance
- Click Subnet → Security Lists → Default Security List
- Add Ingress Rules:
  - Port 8929 (GitLab HTTP)
  - Port 2222 (GitLab SSH)
- Source CIDR: `0.0.0.0/0`

**2. Ubuntu Firewall** (if active):
```bash
sudo ufw allow 8929/tcp
sudo ufw allow 2222/tcp
```

**Resolution**: ✅ **FIXED 2026-02-03**
- Added ports 8929 and 2222 to Oracle Cloud Security List
- Configured Ubuntu firewall rules
- GitLab UI accessible at `http://80.225.86.168:8929`
- Full documentation: `docs/infra/oracle-cloud-network-setup.md`
- **CRITICAL**: Also needed to add iptables rules (see Q0b below)

---

### Q0b: GitLab UI still not accessible after Oracle Cloud Security List configured

**Symptoms**:
```
http://80.225.86.168:8929
# Connection timeout (even with Security List configured)
```

**Diagnosis**:
```bash
# Check iptables rules
sudo iptables -L INPUT -n | grep -E '8929|2222'
```

**Root Cause**:
- Oracle Cloud instances use **iptables** for firewall
- Need to configure BOTH Oracle Cloud Security List AND iptables
- Ports must be opened in `/etc/iptables/rules.v4`

**Solution**:

Use the existing `scripts/infra/open-ports.sh` script:

```bash
# Upload updated script
scp -i ssh-key.key scripts/infra/open-ports.sh ubuntu@SERVER:~/

# Run script
ssh ubuntu@SERVER "chmod +x ~/open-ports.sh && sudo ~/open-ports.sh"
```

**Manual alternative**:
```bash
# Add iptables rules
sudo iptables -I INPUT -p tcp --dport 8929 -j ACCEPT -m comment --comment "GitLab HTTP"
sudo iptables -I INPUT -p tcp --dport 2222 -j ACCEPT -m comment --comment "GitLab SSH"

# Save rules
sudo netfilter-persistent save
```

**Resolution**: ✅ **FIXED 2026-02-03**
- Updated `scripts/infra/open-ports.sh` to include ports 8929 and 2222
- Executed script on server
- iptables rules added and persisted
- GitLab UI now accessible

**Resolution**: ✅ **FIXED 2026-02-03**
- Updated `scripts/infra/open-ports.sh` to include ports 8929 and 2222
- Executed script on server
- iptables rules added and persisted
- GitLab UI now accessible

**Lesson Learned**: Oracle Cloud requires **3 layers** of firewall configuration:
1. Oracle Cloud Security List (web console)
2. iptables rules (server-level)
3. Application firewall (if any, e.g. ufw)

---

### Q4: "Connection reset by peer" - Docker Port Mapping Mismatch

**Symptoms**:
```bash
curl -v http://localhost:8929
# Recv failure: Connection reset by peer
```
- Browser: "Unable to connect"
- Container running, ports open

**Diagnosis**:
- `external_url` in gitlab.rb has port: `http://IP:8929`
- Docker mapping was: `8929:80`

**Root Cause**:
- When `external_url` specifies a port, GitLab configures internal Nginx to listen on that port (8929)
- Docker was blindly forwarding 8929 to 80 (where nothing was listening)

**Solution**:
Change `docker-compose.gitlab.yml`:
```yaml
ports:
  - "8929:8929"  # Was 8929:80
```

**Resolution**: ✅ **FIXED 2026-02-03**
- Updated Docker Compose port mapping
- Redeployed container (`docker compose up -d`)
- Access restored

---

### Q1: "docker-compose: command not found" error

**Symptoms**:
```bash
~/deploy-gitlab.sh
# bash: line 1: docker-compose: command not found
```

**Diagnosis**:
```bash
docker compose version
# Docker Compose version v2.x.x
```

**Root Cause**:
- Server uses Docker Compose v2 (`docker compose`) not v1 (`docker-compose`)
- Deployment script uses old syntax

**Solution**:
```bash
# Use Docker Compose v2 syntax
docker compose -f docker-compose.gitlab.yml up -d

# NOT: docker-compose -f docker-compose.gitlab.yml up -d
```

**Resolution**: ✅ **FIXED 2026-02-03**
- Updated deployment workflow to use `docker compose` (v2)
- GitLab deployed successfully with v2 syntax

---

### Q2: GitLab container exits immediately after start

**Symptoms**:
```bash
docker ps | grep gitlab
# No output - container not running
```

**Diagnosis**:
```bash
docker logs easyway-gitlab
# Check for errors
```

**Common Causes**:
1. **Port conflict**: Another service using 8929 or 2222
2. **Permission error**: Data directory not writable
3. **Out of memory**: Insufficient RAM

**Solutions**:
```bash
# 1. Check port conflicts
sudo netstat -tulpn | grep -E '8929|2222'

# 2. Fix permissions
sudo chown -R 1000:1000 ~/gitlab

# 3. Check memory
free -h
```

**Resolution**: [To be filled when encountered]

---

### Q2: "502 Bad Gateway" when accessing GitLab UI

**Symptoms**:
- GitLab container running
- Browser shows "502 Bad Gateway"

**Diagnosis**:
```bash
docker exec easyway-gitlab gitlab-ctl status
# Check which services are down
```

**Common Causes**:
1. **GitLab still starting**: Takes 2-5 minutes on first run
2. **Service crashed**: Puma or Sidekiq not running
3. **Database issue**: PostgreSQL not initialized

**Solutions**:
```bash
# 1. Wait and check logs
docker logs -f easyway-gitlab | grep "gitlab Reconfigured"

# 2. Restart services
docker exec easyway-gitlab gitlab-ctl restart

# 3. Check database
docker exec easyway-gitlab gitlab-rake gitlab:check
```

**Resolution**: [To be filled when encountered]

---

### Q3: Can't clone repository via SSH

**Symptoms**:
```bash
git clone ssh://git@80.225.86.168:2222/group/project.git
# Permission denied (publickey)
```

**Diagnosis**:
```bash
# Test SSH connection
ssh -p 2222 git@80.225.86.168
```

**Common Causes**:
1. **SSH key not added**: Key not in GitLab profile
2. **Wrong port**: Using 22 instead of 2222
3. **Firewall**: Port 2222 blocked

**Solutions**:
```bash
# 1. Add SSH key to GitLab
# Profile → SSH Keys → Add key

# 2. Use correct port
git clone ssh://git@80.225.86.168:2222/group/project.git

# 3. Check firewall
sudo ufw status
sudo ufw allow 2222/tcp
```

**Resolution**: ✅ **FIXED 2026-02-03**
- Removed `grafana['enable']` and `prometheus_monitoring['enable']` lines
- These services are disabled by default in GitLab CE
- GitLab started successfully without explicit disable

---

### Q3: GitLab container restart loop - deploy.resources error

**Symptoms**:
```bash
docker ps -a | grep gitlab
# Container status: Restarting (1) 25 seconds ago
```

**Diagnosis**:
```bash
docker logs easyway-gitlab --tail 50
# Check for configuration errors
```

**Root Cause**:
- `deploy.resources` section in docker-compose.yml not supported in standalone mode
- Only works in Docker Swarm mode
- Causes container to fail startup

**Solution**:
```yaml
# REMOVE this section from docker-compose.gitlab.yml
deploy:
  resources:
    limits:
      memory: 8G
    reservations:
      memory: 4G
```

**Alternative** (if resource limits needed):
```bash
# Use runtime flags instead
docker run --memory=8g --memory-reservation=4g gitlab/gitlab-ce
```

**Resolution**: ✅ **FIXED 2026-02-03**
- Removed `deploy.resources` section from docker-compose.gitlab.yml
- GitLab started successfully without resource limits
- Server has 23GB RAM, no limits needed

---

## Performance Issues

### Q4: GitLab using too much RAM

**Symptoms**:
```bash
docker stats easyway-gitlab
# Memory usage >8GB
```

**Diagnosis**:
```bash
# Check GitLab processes
docker exec easyway-gitlab gitlab-ctl status
```

**Solutions**:
```ruby
# Edit gitlab.rb
docker exec -it easyway-gitlab editor /etc/gitlab/gitlab.rb

# Reduce workers
puma['worker_processes'] = 2  # Default: 4
sidekiq['max_concurrency'] = 10  # Default: 25

# Apply
docker exec easyway-gitlab gitlab-ctl reconfigure
```

**Resolution**: [To be filled when encountered]

---

### Q5: Backup takes too long

**Symptoms**:
- Backup running for >30 minutes
- High disk I/O

**Solutions**:
```bash
# Use incremental backups
docker exec easyway-gitlab gitlab-backup create STRATEGY=copy INCREMENTAL=yes

# Exclude artifacts (if not needed)
docker exec easyway-gitlab gitlab-backup create SKIP=artifacts
```

**Resolution**: [To be filled when encountered]

---

## CI/CD Issues

### Q6: GitLab Runner not picking up jobs

**Symptoms**:
- Pipeline stuck in "pending"
- No runner available

**Diagnosis**:
```bash
# Check runner status
docker exec easyway-gitlab-runner gitlab-runner list

# Check GitLab UI
# Admin Area → CI/CD → Runners
```

**Common Causes**:
1. **Runner not registered**: Need to register with token
2. **Runner offline**: Container stopped
3. **Tags mismatch**: Job requires tags runner doesn't have

**Solutions**:
```bash
# 1. Register runner
docker exec -it easyway-gitlab-runner gitlab-runner register

# 2. Start runner
docker start easyway-gitlab-runner

# 3. Check tags in .gitlab-ci.yml
```

**Resolution**: [To be filled when encountered]

---

## Disaster Recovery

### Q7: How to restore from backup after server crash

**Scenario**: Server crashed, need to restore GitLab on new server

**Steps**:
```bash
# 1. Setup new server with same specs
# 2. Install Docker and Docker Compose
# 3. Copy backup files to new server
scp -i ssh-key.key backup.tar ubuntu@NEW_IP:~/

# 4. Extract backup
tar -xzf backup.tar -C ~/

# 5. Deploy GitLab
docker-compose -f docker-compose.gitlab.yml up -d

# 6. Wait for GitLab to start
docker logs -f easyway-gitlab

# 7. Restore backup
docker exec easyway-gitlab gitlab-backup restore BACKUP=TIMESTAMP

# 8. Reconfigure
docker exec easyway-gitlab gitlab-ctl reconfigure

# 9. Restart
docker exec easyway-gitlab gitlab-ctl restart
```

**Time**: <1 hour

**Resolution**: [To be filled when tested]

---

## Migration Issues

### Q8: How to migrate from Azure DevOps to GitLab

**Steps**:
```bash
# 1. Export Azure DevOps repos
az repos list --organization https://dev.azure.com/ORG --project PROJECT

# 2. Clone each repo
git clone https://dev.azure.com/ORG/PROJECT/_git/REPO

# 3. Create GitLab project
# Via UI or API

# 4. Push to GitLab
cd REPO
git remote add gitlab ssh://git@80.225.86.168:2222/group/project.git
git push gitlab --all
git push gitlab --tags

# 5. Migrate issues (manual or via API)
# 6. Migrate CI/CD pipelines (convert to .gitlab-ci.yml)
```

**Resolution**: [To be filled when executed]

---

## Template for New Issues

### QX: [Issue Title]

**Symptoms**:
- [What you observed]

**Diagnosis**:
```bash
# Commands to diagnose
```

**Common Causes**:
1. [Cause 1]
2. [Cause 2]

**Solutions**:
```bash
# Solution commands
```

**Resolution**: [What actually worked]

---

**Maintained by**: EasyWay Platform Team  
**Last Updated**: 2026-02-03  
**Status**: Living document - update as issues occur
