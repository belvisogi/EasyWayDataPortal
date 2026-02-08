---
description: Deploy GitLab self-managed on production server 80.225.86.168
---

# GitLab Self-Managed Deployment Workflow

Complete workflow for deploying GitLab on production server with full documentation.

// turbo-all

---

## 📋 Prerequisites

### Step 1: Verify Server Access
```powershell
ssh -i "C:\old\Virtual-machine\ssh-key-2026-01-25.key" ubuntu@80.225.86.168 "echo 'Connection OK'"
```

**Expected**: `Connection OK`

---

## 🚀 Phase 1: Upload Files to Server

### Step 2: Upload Docker Compose File
```powershell
scp -i "C:\old\Virtual-machine\ssh-key-2026-01-25.key" `
  docker-compose.gitlab.yml `
  ubuntu@80.225.86.168:~/docker-compose.gitlab.yml
```

### Step 3: Upload Deployment Script
```powershell
scp -i "C:\old\Virtual-machine\ssh-key-2026-01-25.key" `
  scripts/infra/deploy-gitlab.sh `
  ubuntu@80.225.86.168:~/deploy-gitlab.sh
```

### Step 4: Upload Backup Script
```powershell
scp -i "C:\old\Virtual-machine\ssh-key-2026-01-25.key" `
  scripts/infra/backup-gitlab.sh `
  ubuntu@80.225.86.168:~/backup-gitlab.sh
```

### Step 5: Make Scripts Executable
```powershell
ssh -i "C:\old\Virtual-machine\ssh-key-2026-01-25.key" ubuntu@80.225.86.168 `
  "chmod +x ~/deploy-gitlab.sh ~/backup-gitlab.sh"
```

---

## 🏗️ Phase 2: Deploy GitLab

### Step 6: Run Deployment Script
```powershell
ssh -i "C:\old\Virtual-machine\ssh-key-2026-01-25.key" ubuntu@80.225.86.168 `
  "~/deploy-gitlab.sh"
```

**Expected**:
- Directories created
- Docker images pulled
- GitLab container started
- Access information displayed

**Time**: 5-10 minutes (image download + first start)

---

## ✅ Phase 3: Verification

### Step 7: Check GitLab Container Status
```powershell
ssh -i "C:\old\Virtual-machine\ssh-key-2026-01-25.key" ubuntu@80.225.86.168 `
  "docker ps | grep gitlab"
```

**Expected**: Two containers running:
- `easyway-gitlab`
- `easyway-gitlab-runner`

### Step 8: Check GitLab Services
```powershell
ssh -i "C:\old\Virtual-machine\ssh-key-2026-01-25.key" ubuntu@80.225.86.168 `
  "docker exec easyway-gitlab gitlab-ctl status"
```

**Expected**: All services `run` status

### Step 9: Get Initial Root Password
```powershell
ssh -i "C:\old\Virtual-machine\ssh-key-2026-01-25.key" ubuntu@80.225.86.168 `
  "docker exec easyway-gitlab cat /etc/gitlab/initial_root_password"
```

**Save this password** - needed for first login

---

## 🌐 Phase 4: Initial Configuration

### Step 10: Access GitLab UI
Open browser: `http://80.225.86.168:8929`

**Login**:
- Username: `root`
- Password: (from Step 9)

### Step 11: Change Root Password
1. Click profile icon → Preferences
2. Password section → Change password
3. Save new password securely

### Step 12: Create Admin User
1. Admin Area → Users → New user
2. Username: `gitlab-admin`
3. Email: (your email)
4. Access level: Admin
5. Create user
6. Set password

### Step 13: Disable Sign-ups (Security)
1. Admin Area → Settings → General
2. Sign-up restrictions → Expand
3. Uncheck "Sign-up enabled"
4. Save changes

---

## 🔄 Phase 5: Setup Automated Backups

### Step 14: Configure Cron Job
```powershell
ssh -i "C:\old\Virtual-machine\ssh-key-2026-01-25.key" ubuntu@80.225.86.168 `
  "crontab -e"
```

**Add this line**:
```
0 2 * * * ~/backup-gitlab.sh >> ~/backups/gitlab/backup.log 2>&1
```

**Why**: Daily backup at 2 AM with logging

### Step 15: Test Backup Manually
```powershell
ssh -i "C:\old\Virtual-machine\ssh-key-2026-01-25.key" ubuntu@80.225.86.168 `
  "~/backup-gitlab.sh"
```

**Expected**: Backup created in `~/backups/gitlab/`

---

## 🏃 Phase 6: Setup GitLab Runner (CI/CD)

### Step 16: Get Runner Registration Token
1. GitLab UI → Admin Area → CI/CD → Runners
2. Copy registration token

### Step 17: Register Runner
```powershell
ssh -i "C:\old\Virtual-machine\ssh-key-2026-01-25.key" ubuntu@80.225.86.168 `
  "docker exec -it easyway-gitlab-runner gitlab-runner register"
```

**Prompts**:
- GitLab URL: `http://80.225.86.168:8929`
- Token: (from Step 16)
- Description: `easyway-runner-1`
- Tags: `docker,linux`
- Executor: `docker`
- Default image: `alpine:latest`

### Step 18: Verify Runner
1. GitLab UI → Admin Area → CI/CD → Runners
2. Check runner appears with green status

---

## 📊 Phase 7: Create First Project (DQF Agent)

### Step 19: Create Group
1. GitLab UI → Groups → New group
2. Group name: `easyway`
3. Visibility: Private
4. Create group

### Step 20: Create Project
1. Groups → easyway → New project
2. Project name: `dqf-agent`
3. Visibility: Private (will be public later)
4. Initialize with README: Yes
5. Create project

### Step 21: Clone Project Locally
```powershell
git clone ssh://git@80.225.86.168:2222/easyway/dqf-agent.git
cd dqf-agent
```

**Note**: Add SSH key to GitLab profile first (Profile → SSH Keys)

---

## 🔍 Phase 8: Monitoring and Maintenance

### Step 22: Check Disk Usage
```powershell
ssh -i "C:\old\Virtual-machine\ssh-key-2026-01-25.key" ubuntu@80.225.86.168 `
  "du -sh ~/gitlab/*"
```

**Alert threshold**: >40 GB

### Step 23: Check Memory Usage
```powershell
ssh -i "C:\old\Virtual-machine\ssh-key-2026-01-25.key" ubuntu@80.225.86.168 `
  "docker stats easyway-gitlab --no-stream"
```

**Alert threshold**: >8 GB

### Step 24: View Logs
```powershell
ssh -i "C:\old\Virtual-machine\ssh-key-2026-01-25.key" ubuntu@80.225.86.168 `
  "docker logs easyway-gitlab --tail 100"
```

---

## 📚 Documentation References

- **Setup Guide**: `docs/infra/gitlab-setup-guide.md`
- **Troubleshooting**: `docs/infra/gitlab-qa.md`
- **Docker Compose**: `docker-compose.gitlab.yml`
- **Deployment Script**: `scripts/infra/deploy-gitlab.sh`
- **Backup Script**: `scripts/infra/backup-gitlab.sh`

---

## 🚨 Troubleshooting

### GitLab Won't Start
```powershell
# Check logs
ssh -i "C:\old\Virtual-machine\ssh-key-2026-01-25.key" ubuntu@80.225.86.168 `
  "docker logs easyway-gitlab --tail 50"

# Restart container
ssh -i "C:\old\Virtual-machine\ssh-key-2026-01-25.key" ubuntu@80.225.86.168 `
  "docker restart easyway-gitlab"
```

### Can't Access UI
```powershell
# Check firewall
ssh -i "C:\old\Virtual-machine\ssh-key-2026-01-25.key" ubuntu@80.225.86.168 `
  "sudo ufw status"

# Open port if needed
ssh -i "C:\old\Virtual-machine\ssh-key-2026-01-25.key" ubuntu@80.225.86.168 `
  "sudo ufw allow 8929/tcp"
```

### SSH Clone Fails
```powershell
# Test SSH
ssh -p 2222 git@80.225.86.168

# Open SSH port if needed
ssh -i "C:\old\Virtual-machine\ssh-key-2026-01-25.key" ubuntu@80.225.86.168 `
  "sudo ufw allow 2222/tcp"
```

---

## ✅ Success Criteria

- [ ] GitLab UI accessible at `http://80.225.86.168:8929`
- [ ] Root password changed
- [ ] Admin user created
- [ ] Sign-ups disabled
- [ ] Automated backups configured
- [ ] GitLab Runner registered
- [ ] First project created (dqf-agent)
- [ ] Can clone via SSH
- [ ] Documentation complete

---

**Time Estimate**: 30-45 minutes (excluding image download)  
**Complexity**: Medium  
**Risk**: Low (fully documented, reversible)
