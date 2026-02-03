---
id: infra-deployment-checklist
title: Infrastructure Deployment Checklist
summary: Complete checklist for deploying services on Oracle Cloud infrastructure
tags: [domain/infra, layer/runbook, audience/ops, privacy/internal, language/en]
status: active
owner: team-platform
updated: 2026-02-03
llm:
  include: true
  pii: none
  chunk_hint: 400-600
entities: [Oracle Cloud, Infrastructure, Deployment, Checklist]
---

# Infrastructure Deployment Checklist

> **Purpose**: Ensure all infrastructure layers are configured when deploying new services  
> **Use**: Reference this checklist for every new service deployment on Oracle Cloud

---

## 🎯 The 3-Layer Firewall Rule

**CRITICAL**: Oracle Cloud requires configuration at **3 levels**:

1. **Oracle Cloud Security List** (Cloud level)
2. **iptables** (Server level)
3. **Application Firewall** (App level, if any)

**Forgetting any layer = Service not accessible!**

---

## 📋 New Service Deployment Checklist

### Phase 1: Planning

- [ ] Define service ports (HTTP, SSH, custom)
- [ ] Review security requirements
- [ ] Check server resources (RAM, CPU, storage)
- [ ] Document deployment in `docs/infra/`

---

### Phase 2: Oracle Cloud Configuration

#### Security List Configuration

- [ ] Navigate to: Compute → Instances → Select instance
- [ ] Click Subnet → Security Lists → Default Security List
- [ ] Add Ingress Rules for each port:
  - [ ] Source CIDR: `0.0.0.0/0` (or restrict to specific IPs)
  - [ ] IP Protocol: `TCP`
  - [ ] Destination Port Range: `<PORT>`
  - [ ] Description: `<SERVICE_NAME>`

**Example ports**:
- GitLab HTTP: 8929
- GitLab SSH: 2222
- Portal Frontend: 8080
- API Backend: 8000

---

### Phase 3: Server-Level Firewall (iptables)

#### Option A: Use EasyWay Script (Recommended)

1. **Update** `scripts/infra/open-ports.sh`:
   ```bash
   # Add your ports to the script
   open_port 8929  # Your service
   open_port 2222  # Your service SSH
   ```

2. **Upload and execute**:
   ```bash
   scp -i ssh-key.key scripts/infra/open-ports.sh ubuntu@SERVER:~/
   ssh ubuntu@SERVER "chmod +x ~/open-ports.sh && sudo ~/open-ports.sh"
   ```

3. **Verify**:
   ```bash
   ssh ubuntu@SERVER "sudo iptables -L INPUT -n | grep <PORT>"
   ```

#### Option B: Manual iptables

```bash
# Add rule
sudo iptables -I INPUT -p tcp --dport <PORT> -j ACCEPT -m comment --comment "<SERVICE>"

# Save permanently
sudo netfilter-persistent save
```

---

### Phase 4: Application Deployment

- [ ] Deploy Docker containers or services
- [ ] Verify services are listening on correct ports
  ```bash
  ss -tlnp | grep <PORT>
  ```
- [ ] Check service logs for errors
  ```bash
  docker logs <container> --tail 50
  ```

---

### Phase 5: Verification

#### Network Connectivity

- [ ] **From server** (localhost):
  ```bash
  curl -s -o /dev/null -w '%{http_code}' http://localhost:<PORT>
  ```
  Expected: `200` or `301`

- [ ] **From external** (your PC):
  ```bash
  curl -s -o /dev/null -w '%{http_code}' http://<SERVER_IP>:<PORT>
  ```
  Expected: `200` or `301`

- [ ] **From browser**:
  ```
  http://<SERVER_IP>:<PORT>
  ```
  Expected: Service UI loads

#### Firewall Verification

- [ ] **Oracle Cloud Security List**:
  - Navigate to Security List
  - Verify ingress rule exists for port

- [ ] **iptables**:
  ```bash
  sudo iptables -L INPUT -n | grep <PORT>
  ```
  Expected: `ACCEPT` rule visible

- [ ] **Application firewall** (if ufw active):
  ```bash
  sudo ufw status | grep <PORT>
  ```
  Expected: Port allowed

---

### Phase 6: Documentation

- [ ] Update `scripts/infra/open-ports.sh` with new ports
- [ ] Document service in `docs/infra/<service>-setup-guide.md`
- [ ] Add troubleshooting to `docs/infra/<service>-qa.md`
- [ ] Update this checklist if new steps discovered
- [ ] Commit changes to Git

---

## 🚨 Common Mistakes

### Mistake 1: Only configured Oracle Cloud Security List

**Symptom**: "Connection timeout" from browser  
**Fix**: Also configure iptables (see Phase 3)

---

### Mistake 2: iptables rules not persisted

**Symptom**: Service accessible until server reboot, then fails  
**Fix**: Always run `sudo netfilter-persistent save`

---

### Mistake 3: Forgot to update open-ports.sh

**Symptom**: Manual iptables rules work, but not documented  
**Fix**: Update `scripts/infra/open-ports.sh` for reproducibility

---

### Mistake 4: Wrong port in Security List

**Symptom**: iptables shows ACCEPT, but still can't connect  
**Fix**: Double-check port number in Oracle Cloud Security List

---

## 📊 Quick Reference: EasyWay Services

| Service | HTTP Port | SSH Port | Script Updated | Docs |
|---------|-----------|----------|----------------|------|
| **Portal Frontend** | 8080 | - | ✅ | `docs/infra/portal-setup.md` |
| **API Backend** | 8000 | - | ✅ | `docs/infra/api-setup.md` |
| **GitLab** | 8929 | 2222 | ✅ | `docs/infra/gitlab-setup-guide.md` |
| **n8n** | 5678 | - | ⏳ | `docs/infra/n8n-setup.md` |

---

## 🔄 Disaster Recovery

If you need to recreate firewall configuration on new server:

1. **Oracle Cloud**: Follow Phase 2 checklist
2. **iptables**: Run `scripts/infra/open-ports.sh`
3. **Verify**: Follow Phase 5 checklist

**Time**: 15 minutes

---

## 📝 Template: New Service Deployment

Copy this template for new service deployments:

```markdown
# <SERVICE_NAME> Deployment - <DATE>

## Ports
- HTTP: <PORT>
- SSH: <PORT> (if applicable)

## Oracle Cloud Security List
- [x] Added ingress rule for port <PORT>

## iptables
- [x] Updated scripts/infra/open-ports.sh
- [x] Executed script on server
- [x] Verified rules with `sudo iptables -L`

## Verification
- [x] Service accessible from localhost
- [x] Service accessible from external IP
- [x] Service accessible from browser

## Documentation
- [x] Created docs/infra/<service>-setup-guide.md
- [x] Updated this checklist
- [x] Committed to Git
```

---

## 🎓 Learning Resources

- **Oracle Cloud Networking**: `docs/infra/oracle-cloud-network-setup.md`
- **iptables Guide**: `scripts/infra/open-ports.sh` (commented)
- **GitLab Example**: `docs/infra/gitlab-setup-guide.md` (complete example)

---

**Created**: 2026-02-03  
**Last Updated**: 2026-02-03  
**Tested**: ✅ GitLab deployment (80.225.86.168)
