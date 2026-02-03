---
id: ai-agent-infra-guidelines
title: AI Agent Guidelines for Infrastructure Work
summary: Critical reminders and checklists for AI agents working on EasyWay infrastructure
tags: [domain/infra, layer/meta, audience/ai-agents, privacy/internal, language/en]
status: active
owner: team-platform
updated: 2026-02-03
llm:
  include: true
  pii: critical
  chunk_hint: 300-500
entities: [AI Agents, Infrastructure, Guidelines]
---

# AI Agent Guidelines for Infrastructure Work

> **Audience**: AI Agents (Claude, GPT, Gemini, etc.)  
> **Purpose**: Ensure consistent, complete infrastructure deployments  
> **Status**: MANDATORY - Read before any infrastructure work

---

## 🚨 CRITICAL: The 3-Layer Firewall Rule

**NEVER DEPLOY A SERVICE WITHOUT CONFIGURING ALL 3 LAYERS**:

1. **Oracle Cloud Security List** (Cloud Console)
2. **iptables** (Server: `/etc/iptables/rules.v4`)
3. **Application Firewall** (if any, e.g. ufw)

**Missing ANY layer = Service NOT accessible!**

---

## 📋 Mandatory Checklist Before Deployment

Before deploying ANY service on Oracle Cloud infrastructure:

- [ ] **Read**: `docs/infra/INFRA-DEPLOYMENT-CHECKLIST.md`
- [ ] **Check**: `scripts/infra/open-ports.sh` for existing port configuration
- [ ] **Update**: `scripts/infra/open-ports.sh` with new ports
- [ ] **Configure**: Oracle Cloud Security List (web console)
- [ ] **Execute**: `open-ports.sh` on server (iptables)
- [ ] **Verify**: All 3 firewall layers
- [ ] **Document**: Update `docs/infra/<service>-setup-guide.md`
- [ ] **Document**: Add Q&A entries to `docs/infra/<service>-qa.md`
- [ ] **Update**: `docs/infra/README.md` if new service

---

## 🎯 Key Files to Always Check

### Before Starting

1. **`docs/infra/README.md`** - Infrastructure documentation index
2. **`docs/infra/INFRA-DEPLOYMENT-CHECKLIST.md`** - Deployment procedure
3. **`scripts/infra/open-ports.sh`** - Current firewall configuration

### During Deployment

4. **`docs/infra/<service>-setup-guide.md`** - Service-specific guide
5. **`docs/infra/<service>-qa.md`** - Known issues and solutions

### After Deployment

6. **Update all modified files**
7. **Create walkthrough artifact** with proof of work

---

## 🔍 Common Mistakes to Avoid

### ❌ Mistake 1: Only configured Oracle Cloud Security List

**Symptom**: "Connection timeout" from browser  
**Why**: Forgot to configure iptables  
**Fix**: Always run `scripts/infra/open-ports.sh`

---

### ❌ Mistake 2: Didn't update open-ports.sh

**Symptom**: Manual iptables rules work, but not documented  
**Why**: Forgot to update the script  
**Fix**: ALWAYS update `scripts/infra/open-ports.sh` for reproducibility

---

### ❌ Mistake 3: Didn't document issues encountered

**Symptom**: Same error happens again in future deployments  
**Why**: Didn't add Q&A entry  
**Fix**: ALWAYS add Q&A entries to `docs/infra/<service>-qa.md`

---

### ❌ Mistake 4: Assumed firewall was like other clouds

**Symptom**: Service works on AWS/Azure but not Oracle Cloud  
**Why**: Oracle Cloud uses iptables, not just Security Groups  
**Fix**: Remember the 3-Layer Firewall Rule

---

## 📚 Documentation Standards

### When Creating Setup Guides

**Required sections**:
1. Prerequisites
2. Architecture
3. Installation Steps
4. Configuration
5. Backup Strategy
6. Disaster Recovery
7. Troubleshooting
8. Q&A Section

**Example**: `docs/infra/gitlab-setup-guide.md`

---

### When Creating Q&A Documents

**Format for each entry**:
```markdown
### Q<N>: <Short problem description>

**Symptoms**:
```
<Error message or behavior>
```

**Diagnosis**:
```bash
<Commands to diagnose>
```

**Root Cause**:
- <Explanation>

**Solution**:
```bash
<Commands to fix>
```

**Resolution**: ✅ **FIXED YYYY-MM-DD**
- <What was done>
- <Lessons learned>
```

**Example**: `docs/infra/gitlab-qa.md`

---

## 🔄 Workflow for Infrastructure Changes

### 1. Research Phase

```
1. Check docs/infra/README.md for existing documentation
2. Check scripts/infra/ for existing scripts
3. Search for similar services already deployed
4. Read INFRA-DEPLOYMENT-CHECKLIST.md
```

### 2. Planning Phase

```
1. Define ports needed
2. Check server resources
3. Create implementation plan artifact
4. Get user approval if needed
```

### 3. Execution Phase

```
1. Update scripts/infra/open-ports.sh
2. Configure Oracle Cloud Security List
3. Deploy service (Docker, systemd, etc.)
4. Execute open-ports.sh on server
5. Verify all 3 firewall layers
```

### 4. Verification Phase

```
1. Test from localhost
2. Test from external IP
3. Test from browser
4. Check all services running
5. Create walkthrough artifact
```

### 5. Documentation Phase

```
1. Create/update docs/infra/<service>-setup-guide.md
2. Create/update docs/infra/<service>-qa.md
3. Update docs/infra/README.md
4. Update scripts/infra/open-ports.sh comments
5. Commit all changes
```

---

## 🎓 Learning from Past Deployments

### GitLab Deployment (2026-02-03)

**Issues encountered**:
1. Docker Compose v2 syntax (`docker compose` not `docker-compose`)
2. `deploy.resources` not supported in standalone mode
3. Grafana config parse error
4. Oracle Cloud Security List configured but forgot iptables

**Lessons learned**:
- Always check Docker Compose version
- Test configuration incrementally
- **ALWAYS configure all 3 firewall layers**
- Document issues in real-time

**Reference**: `docs/infra/gitlab-qa.md`

---

## 🤖 AI Agent Best Practices

### When User Says "Deploy X"

1. **Don't assume** - Check existing infrastructure first
2. **Don't skip** - Follow ALL checklist steps
3. **Don't forget** - Update ALL documentation
4. **Don't rush** - Verify each layer before proceeding

### When Encountering Errors

1. **Document immediately** - Add to Q&A file
2. **Explain clearly** - Root cause, not just symptoms
3. **Provide solution** - Exact commands to fix
4. **Mark as resolved** - With date and what was done

### When Completing Work

1. **Create walkthrough** - Proof of work with screenshots/logs
2. **Update all docs** - Don't leave anything outdated
3. **Verify reproducibility** - Could another agent recreate this?
4. **Communicate clearly** - User should understand what was done

---

## 📊 Quick Reference

### Server Information

- **IP**: 80.225.86.168
- **RAM**: 23 GB
- **Storage**: 96 GB
- **CPU**: 4 cores
- **OS**: Ubuntu 22.04
- **SSH Key**: `C:\old\Virtual-machine\ssh-key-2026-01-25.key`

### Existing Services

| Service | HTTP Port | SSH Port | Status |
|---------|-----------|----------|--------|
| Portal Frontend | 8080 | - | ✅ Running |
| API Backend | 8000 | - | ✅ Running |
| GitLab | 8929 | 2222 | ✅ Running |
| n8n | 5678 | - | ✅ Running |

### Key Scripts

| Script | Purpose | Location |
|--------|---------|----------|
| `open-ports.sh` | Configure iptables | `scripts/infra/open-ports.sh` |
| `deploy-gitlab.sh` | Deploy GitLab | `scripts/infra/deploy-gitlab.sh` |
| `backup-gitlab.sh` | Backup GitLab | `scripts/infra/backup-gitlab.sh` |

---

## ✅ Success Criteria

A deployment is successful when:

- [ ] Service accessible from browser
- [ ] All 3 firewall layers configured
- [ ] `scripts/infra/open-ports.sh` updated
- [ ] Setup guide created/updated
- [ ] Q&A document created/updated
- [ ] README.md updated
- [ ] Walkthrough artifact created
- [ ] User can reproduce deployment from docs

---

## 🚀 Remember

**Your goal**: Make infrastructure **reproducible**, **documented**, and **antifragile**.

**How**: Follow checklists, update scripts, document everything.

**Why**: So humans (and future AI agents) can recreate this without you.

---

**Created**: 2026-02-03  
**Mandatory Reading**: YES  
**Applies To**: ALL AI agents working on EasyWay infrastructure
