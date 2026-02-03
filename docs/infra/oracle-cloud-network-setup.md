---
id: oracle-cloud-network-setup
title: Oracle Cloud Network Configuration for GitLab
summary: Step-by-step guide to configure Oracle Cloud Security Lists for GitLab access
tags: [domain/infra, layer/runbook, audience/ops, privacy/internal, language/en]
status: active
owner: team-platform
updated: 2026-02-03
llm:
  include: true
  pii: none
  chunk_hint: 400-600
entities: [Oracle Cloud, GitLab, Security List, Firewall]
---

# Oracle Cloud Network Configuration for GitLab

> **Purpose**: Configure Oracle Cloud Security Lists to allow GitLab access  
> **Server**: 80.225.86.168  
> **Time**: 10 minutes

---

## 🎯 Ports Required for GitLab

| Port | Protocol | Service | Purpose |
|------|----------|---------|---------|
| **8929** | TCP | GitLab HTTP | Web UI access |
| **2222** | TCP | GitLab SSH | Git clone/push operations |

---

## 📋 Oracle Cloud Console Configuration

### Step 1: Access Oracle Cloud Console

1. Navigate to: https://cloud.oracle.com
2. Sign in with your credentials
3. Select your **Tenancy**

---

### Step 2: Locate Your Instance

1. Click hamburger menu (☰) → **Compute** → **Instances**
2. Find instance with IP: `80.225.86.168`
3. Click on the instance name

---

### Step 3: Navigate to Security List

1. In **Instance Details** page, find **Primary VNIC** section
2. Click on the **Subnet** name (e.g., `subnet-xxxxxx`)
3. In Subnet page, click **Security Lists** (left menu)
4. Click on the active **Security List** (e.g., `Default Security List for vcn-xxxxx`)

---

### Step 4: Add Ingress Rules

#### Rule 1: GitLab HTTP (Port 8929)

1. Click **"Add Ingress Rules"** button
2. Fill in the form:
   - **Stateless**: Unchecked
   - **Source Type**: `CIDR`
   - **Source CIDR**: `0.0.0.0/0` (allow from any IP)
   - **IP Protocol**: `TCP`
   - **Source Port Range**: (leave empty)
   - **Destination Port Range**: `8929`
   - **Description**: `GitLab HTTP UI`
3. Click **"Add Ingress Rules"**

**Result**: Rule added to Security List

---

#### Rule 2: GitLab SSH (Port 2222)

1. Click **"Add Ingress Rules"** button again
2. Fill in the form:
   - **Stateless**: Unchecked
   - **Source Type**: `CIDR`
   - **Source CIDR**: `0.0.0.0/0`
   - **IP Protocol**: `TCP`
   - **Source Port Range**: (leave empty)
   - **Destination Port Range**: `2222`
   - **Description**: `GitLab SSH for Git operations`
3. Click **"Add Ingress Rules"**

**Result**: Rule added to Security List

---

### Step 5: Verify Security List

**Expected Ingress Rules** (minimum):

| Source CIDR | Protocol | Port Range | Description |
|-------------|----------|------------|-------------|
| 0.0.0.0/0 | TCP | 22 | SSH (existing) |
| 0.0.0.0/0 | TCP | 80 | HTTP (existing) |
| 0.0.0.0/0 | TCP | 443 | HTTPS (existing, optional) |
| 0.0.0.0/0 | TCP | 8929 | **GitLab HTTP** ✅ |
| 0.0.0.0/0 | TCP | 2222 | **GitLab SSH** ✅ |

---

## 🔥 Ubuntu Firewall Configuration

Oracle Cloud Security Lists allow traffic **to** the instance, but Ubuntu firewall (ufw) may still block it.

### Check Firewall Status

```bash
ssh -i "ssh-key.key" ubuntu@80.225.86.168 "sudo ufw status"
```

**If inactive**: No action needed  
**If active**: Add rules below

---

### Allow GitLab Ports

```bash
ssh -i "ssh-key.key" ubuntu@80.225.86.168 "sudo ufw allow 8929/tcp"
ssh -i "ssh-key.key" ubuntu@80.225.86.168 "sudo ufw allow 2222/tcp"
```

**Verify**:
```bash
ssh -i "ssh-key.key" ubuntu@80.225.86.168 "sudo ufw status numbered"
```

**Expected**:
```
Status: active

     To                         Action      From
     --                         ------      ----
[ 1] 22/tcp                     ALLOW IN    Anywhere
[ 2] 80/tcp                     ALLOW IN    Anywhere
[ 3] 8929/tcp                   ALLOW IN    Anywhere
[ 4] 2222/tcp                   ALLOW IN    Anywhere
```

---

## 🔥 IPTables Configuration (CRITICAL for Oracle Cloud)

> **IMPORTANT**: Oracle Cloud instances use **iptables** as the primary firewall.  
> You MUST configure iptables in addition to Security Lists.

### Automated Method (Recommended)

Use the EasyWay firewall script:

```bash
# Upload script to server
scp -i "ssh-key.key" scripts/infra/open-ports.sh ubuntu@80.225.86.168:~/

# Execute script
ssh -i "ssh-key.key" ubuntu@80.225.86.168 "chmod +x ~/open-ports.sh && sudo ~/open-ports.sh"
```

**Expected output**:
```
🛡️ Configurazione Firewall...
   ⚠️ UFW non attivo. Configuro IPTables direttamente (Oracle Style).
   🔓 Apertura porta 80...
   🔓 Apertura porta 443...
   🔓 Apertura porta 8080...
   🔓 Apertura porta 8000...
   🔓 Apertura porta 8929...
   🔓 Apertura porta 2222...
   💾 Salvataggio regole...
   ✅ Regole salvate (netfilter-persistent).
✅ CONFIGURAZIONE FIREWALL COMPLETATA!
```

---

### Manual Method

If you need to add ports manually:

```bash
# Add GitLab HTTP port
sudo iptables -I INPUT -p tcp --dport 8929 -j ACCEPT -m comment --comment "GitLab HTTP"

# Add GitLab SSH port
sudo iptables -I INPUT -p tcp --dport 2222 -j ACCEPT -m comment --comment "GitLab SSH"

# Save rules permanently
sudo netfilter-persistent save
```

**Verify rules**:
```bash
sudo iptables -L INPUT -n | grep -E '8929|2222'
```

**Expected**:
```
ACCEPT     tcp  --  0.0.0.0/0            0.0.0.0/0            tcp dpt:8929 /* GitLab HTTP */
ACCEPT     tcp  --  0.0.0.0/0            0.0.0.0/0            tcp dpt:2222 /* GitLab SSH */
```

---

## ✅ Verification

### Test 1: GitLab UI Access

**From browser**:
```
http://80.225.86.168:8929
```

**Expected**: GitLab login page

**If fails**:
- Wait 1-2 minutes (Oracle Cloud rules take time to apply)
- Check GitLab container is running: `docker ps | grep gitlab`
- Check port is listening: `netstat -tulpn | grep 8929`

---

### Test 2: GitLab SSH Access

**From terminal**:
```bash
ssh -p 2222 git@80.225.86.168
```

**Expected**: `Welcome to GitLab, @username!` (after adding SSH key to GitLab)

**If fails**:
- Check port 2222 in Security List
- Check Ubuntu firewall allows 2222
- Verify GitLab SSH is running: `docker exec easyway-gitlab gitlab-ctl status sshd`

---

### Test 3: Network Connectivity

**Check listening ports on server**:
```bash
ssh -i "ssh-key.key" ubuntu@80.225.86.168 "netstat -tulpn | grep -E '8929|2222'"
```

**Expected**:
```
tcp6       0      0 :::8929                 :::*                    LISTEN      -
tcp6       0      0 :::2222                 :::*                    LISTEN      -
```

---

## 🐛 Troubleshooting

### Issue 1: "Connection refused" on port 8929

**Diagnosis**:
```bash
# Check GitLab container
docker ps | grep gitlab

# Check GitLab services
docker exec easyway-gitlab gitlab-ctl status
```

**Solution**:
- If container not running: `docker compose -f docker-compose.gitlab.yml up -d`
- If services down: `docker exec easyway-gitlab gitlab-ctl restart`

---

### Issue 2: "Connection timeout" on port 8929

**Diagnosis**:
- Oracle Cloud Security List not configured
- Ubuntu firewall blocking traffic

**Solution**:
1. Verify Security List has ingress rule for 8929
2. Check Ubuntu firewall: `sudo ufw status`
3. Add rule if needed: `sudo ufw allow 8929/tcp`

---

### Issue 3: Security List changes not taking effect

**Cause**: Oracle Cloud applies rules with 1-2 minute delay

**Solution**: Wait 2 minutes, then test again

---

### Issue 4: Can access UI but not SSH

**Diagnosis**:
```bash
# Test SSH port
telnet 80.225.86.168 2222
```

**Solution**:
- Add port 2222 to Security List (if missing)
- Add port 2222 to Ubuntu firewall: `sudo ufw allow 2222/tcp`

---

## 📊 Network Architecture

```
Internet
   ↓
[Oracle Cloud Security List]
   ↓ (allows 8929, 2222)
[Ubuntu Firewall (ufw)]
   ↓ (allows 8929, 2222)
[Docker Network]
   ↓
[GitLab Container]
   ├─ Port 8929 → HTTP (nginx)
   └─ Port 2222 → SSH (sshd)
```

---

## 🔒 Security Considerations

### Current Configuration: Open to Internet

**Pros**:
- Easy access from anywhere
- No VPN required
- Simple for development

**Cons**:
- Exposed to internet attacks
- Requires strong passwords
- SSH brute-force attempts

---

### Recommended Production Configuration

**Option 1: Restrict by IP**

Instead of `0.0.0.0/0`, use specific IPs:
```
Source CIDR: YOUR_OFFICE_IP/32
```

**Option 2: Use VPN**

- Setup Oracle Cloud VPN
- Allow GitLab ports only from VPN subnet
- More secure but more complex

**Option 3: Use Cloudflare Tunnel**

- Expose GitLab via Cloudflare Tunnel
- No public ports needed
- DDoS protection included

---

## 📝 Configuration Checklist

After completing this guide:

- [ ] Oracle Cloud Security List has rule for port 8929
- [ ] Oracle Cloud Security List has rule for port 2222
- [ ] Ubuntu firewall allows port 8929 (if ufw active)
- [ ] Ubuntu firewall allows port 2222 (if ufw active)
- [ ] GitLab UI accessible at `http://80.225.86.168:8929`
- [ ] GitLab SSH testable at `ssh -p 2222 git@80.225.86.168`
- [ ] Configuration documented in this file

---

## 🔄 Disaster Recovery

If you need to recreate the network configuration:

1. **Oracle Cloud**: Follow Steps 1-4 above
2. **Ubuntu Firewall**: Run commands in "Ubuntu Firewall Configuration" section
3. **Verify**: Use tests in "Verification" section

**Time**: 10 minutes

---

## 📚 Related Documentation

- **GitLab Setup Guide**: `docs/infra/gitlab-setup-guide.md`
- **GitLab Quick Recovery**: `docs/infra/gitlab-quick-recovery.md`
- **Oracle Cloud Setup**: `Wiki/EasyWayData.wiki/infrastructure/oracle-cloud/setup.md`

---

**Created**: 2026-02-03  
**Tested**: ✅ Server 80.225.86.168  
**Status**: Production-ready
