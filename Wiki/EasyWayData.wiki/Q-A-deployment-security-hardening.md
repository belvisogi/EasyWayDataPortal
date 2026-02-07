# ❓ Q&A - Deployment & Security Hardening

**Last Updated:** 2026-02-07
**Topic:** Production Deployment Process & Security Best Practices
**Related:** [production-deployment-2026-02-07.md](./deployment/production-deployment-2026-02-07.md)

---

## 🔐 Security & Credentials

### Q: Dove vengono archiviate le password di produzione?

**A:** Le password sono archiviate in `/home/ubuntu/EasyWayDataPortal/.env.prod` sul server di produzione.

**⚠️ IMPORTANTE:**
- Il file `.env.prod` è git-ignored e **non viene mai committato**
- **Best Practice:** Migrare le password in Azure Key Vault appena possibile
- Usare riferimenti Key Vault invece di plaintext:
  ```bash
  # Invece di:
  SQL_SA_PASSWORD=MyPlaintextPassword123

  # Usare:
  SQL_SA_PASSWORD=@Microsoft.KeyVault(SecretUri=https://vault.azure.net/secrets/SQL-PASSWORD/)
  ```

---

### Q: Come genero password sicure per i nuovi servizi?

**A:** Usare `openssl` per generare password crittograficamente sicure:

```bash
# Password generica (32 caratteri alfanumerici)
openssl rand -base64 32 | tr -d "=+/" | cut -c1-32

# Output esempio: WNY0e0n5vBT0CmpoGplkHOzYbll8gehX
```

**Per Traefik Basic Auth Hash:**
```bash
# 1. Genera password
PASSWORD=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-32)

# 2. Crea hash (username: admin)
htpasswd -nb admin "$PASSWORD"

# 3. Per docker-compose, raddoppia i $
# Manualmente cambia $ in $$ nel valore generato
```

---

### Q: Con quale frequenza devo ruotare le password?

**A:** **Policy standard:** Ogni 90 giorni

**Schedule consigliato:**
- **Database passwords:** 90 giorni
- **API keys:** 90 giorni
- **Service credentials:** 90 giorni
- **Certificates:** Rinnovo automatico 30 giorni prima scadenza

**Automazione:**
Usare **Agent Password Manager** (vedi sezione Agents) per rotazione automatica.

---

### Q: Cosa faccio se una password viene compromessa?

**A:** **Procedura di incident response:**

1. **Immediate (< 5 min):**
   ```bash
   # Genera nuova password
   NEW_PASSWORD=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-32)

   # Aggiorna .env.prod
   ssh ubuntu@server "cd ~/EasyWayDataPortal && \
     sed -i 's/OLD_PASSWORD/$NEW_PASSWORD/' .env.prod"

   # Restart container
   ssh ubuntu@server "cd ~/EasyWayDataPortal && \
     docker compose -f docker-compose.prod.yml restart <service>"
   ```

2. **Short term (< 1 hour):**
   - Audit logs per accessi non autorizzati
   - Verifica data breach scope
   - Update Azure Key Vault
   - Notify team

3. **Long term (< 24 hours):**
   - Root cause analysis
   - Update security procedures
   - Document incident in Wiki
   - Review password storage practices

---

## 🐳 Docker & Versioning

### Q: Perché abbiamo bannato il tag `:latest`?

**A:** **5 motivi critici:**

1. **Non riproducibile:**
   - `docker pull nginx:latest` oggi ≠ domani
   - Impossibile fare rollback esatto

2. **Breaking changes silenziosi:**
   - Update automatici possono rompere l'app
   - Nessun controllo su quando applicare update

3. **Supply chain risk:**
   - Attaccante può push immagine compromessa
   - Auto-pull distribuisce malware

4. **Debugging nightmare:**
   - "Funzionava ieri" senza saper quale versione
   - Impossibile correlare bug a release notes

5. **Compliance failure:**
   - Auditor chiede "quale versione software usate?"
   - Risposta "l'ultima" = audit fail

**Best Practice:**
```yaml
# ❌ MAI:
image: nginx:latest

# ✅ SEMPRE:
image: nginx:1.25.3-alpine
```

---

### Q: Come verifico se una versione Docker ha vulnerabilità?

**A:** **3 metodi:**

**1. Docker Scout (built-in):**
```bash
docker scout cves nginx:1.25.3-alpine
```

**2. Snyk:**
```bash
snyk container test nginx:1.25.3-alpine
```

**3. Trivy:**
```bash
trivy image nginx:1.25.3-alpine
```

**Automazione:**
Usare **Agent Vulnerability Scanner** per check giornalieri automatici.

---

### Q: Quando devo aggiornare le versioni pinnate?

**A:** **Policy di aggiornamento:**

**CRITICAL Security Patch:**
- ⏱️ Entro 48 ore
- 🧪 Test in staging
- 🚀 Deploy produzione

**HIGH Security Patch:**
- ⏱️ Entro 7 giorni
- 🧪 Test + QA
- 🚀 Deploy produzione

**Feature Release / Minor:**
- ⏱️ Review mensile (primo lunedì del mese)
- 🧪 Test approfondito
- 🚀 Deploy dopo 48h staging stabile

**Major Version:**
- ⏱️ Planning trimestrale
- 🧪 Staging esteso (1-2 settimane)
- 🚀 Deploy con rollback plan

**Esempio workflow:**
```bash
# 1. Check updates disponibili
docker run --rm registry:2 | grep nginx

# 2. Pull e test in staging
docker pull nginx:1.26.0-alpine
docker tag nginx:1.26.0-alpine staging/nginx:1.26.0

# 3. Update docker-compose.staging.yml
# 4. Test funzionale + performance
# 5. Se OK, update docker-compose.prod.yml
# 6. Git commit + push
# 7. Deploy produzione
```

---

## 🚀 Deployment Process

### Q: Come faccio un deploy in produzione?

**A:** **Segui il runbook:** [docs/PRODUCTION_DEPLOYMENT.md](../docs/PRODUCTION_DEPLOYMENT.md)

**Quick reference:**
```bash
# 1. Local: commit changes
git add docker-compose.prod.yml
git commit -m "feat: update service X to vY.Z"
git push origin main

# 2. Server: pull and deploy
ssh -i ~/.ssh/key ubuntu@server "cd ~/EasyWayDataPortal && \
  git pull && \
  docker compose -f docker-compose.prod.yml --env-file .env.prod up -d"

# 3. Verify
ssh -i ~/.ssh/key ubuntu@server "docker ps && \
  docker logs <service> --tail 50"
```

---

### Q: Come faccio rollback se il deploy va male?

**A:** **Rollback in 3 step:**

**Step 1: Stop nuovo deployment**
```bash
ssh ubuntu@server "cd ~/EasyWayDataPortal && \
  docker compose -f docker-compose.prod.yml down"
```

**Step 2: Revert git commit**
```bash
ssh ubuntu@server "cd ~/EasyWayDataPortal && \
  git reset --hard HEAD~1"
```

**Step 3: Redeploy versione precedente**
```bash
ssh ubuntu@server "cd ~/EasyWayDataPortal && \
  docker compose -f docker-compose.prod.yml --env-file .env.prod up -d"
```

**Verify:**
```bash
docker ps
docker logs <service> --tail 20
```

---

### Q: Perché il deploy ha fallito con "variable not set"?

**A:** **Causa:** Variabile mancante nel file `.env.prod`

**Diagnosi:**
```bash
# Check quale variabile manca
docker compose -f docker-compose.prod.yml config

# Verrà mostrato:
# WARNING: The VARIABLE_NAME variable is not set. Defaulting to a blank string.
```

**Fix:**
```bash
# Aggiungi variabile mancante
ssh ubuntu@server "cd ~/EasyWayDataPortal && \
  echo 'VARIABLE_NAME=value' >> .env.prod"

# Restart
docker compose -f docker-compose.prod.yml --env-file .env.prod up -d
```

**Prevention:**
- Usa `.env.prod.example` come template
- Verifica diff before deploy:
  ```bash
  diff .env.prod.example .env.prod
  ```

---

## 🔄 Traefik & Reverse Proxy

### Q: Perché Traefik v3 non funziona?

**A:** **Root cause:** Incompatibilità Docker API

**Dettagli tecnici:**
- Tutte le immagini Docker di Traefik (v2.x, v3.x) hanno Docker client **v1.24** hardcoded
- Docker Engine moderno richiede API **≥1.44**
- Errore: `client version 1.24 is too old`

**Tested & Failed:**
- ❌ Traefik v3.2
- ❌ Traefik v3.1
- ❌ Traefik v2.10
- ❌ Impostare `DOCKER_API_VERSION=1.45`
- ❌ Rimuovere `:ro` dal Docker socket

**Soluzioni disponibili:** Vedi [production-deployment-2026-02-07.md](./deployment/production-deployment-2026-02-07.md) § Recommended Solutions

---

### Q: Quale reverse proxy devo usare al posto di Traefik?

**A:** **Raccomandazione: Caddy** ⭐

**Comparison Matrix:**

| Feature | Caddy | Nginx | Traefik File |
|---------|-------|-------|--------------|
| **Automatic HTTPS** | ✅ Sì | ❌ No | ✅ Sì |
| **Docker Labels** | ✅ Sì | ❌ No | ❌ No |
| **Config Complexity** | 🟢 Low | 🟡 Medium | 🟡 Medium |
| **Performance** | 🟢 High | 🟢 Very High | 🟢 High |
| **Community** | 🟢 Active | 🟢 Huge | 🟡 Medium |
| **Learning Curve** | 🟢 Easy | 🟡 Medium | 🟡 Medium |

**Caddy Example:**
```yaml
# docker-compose.prod.yml
caddy:
  image: caddy:2.8-alpine
  ports:
    - "80:80"
    - "443:443"
  volumes:
    - ./Caddyfile:/etc/caddy/Caddyfile:ro
    - caddy_data:/data
    - caddy_config:/config
  restart: always
```

```caddyfile
# Caddyfile
n8n.yourdomain.com {
    reverse_proxy n8n:5678
    basicauth {
        admin JDJhJDE0JC4uLi4  # htpasswd hash
    }
}

qdrant.yourdomain.com {
    reverse_proxy qdrant:6333
    header {
        # Forward API key header
        >api-key {env.QDRANT_API_KEY}
    }
}
```

---

### Q: Come testo che il reverse proxy funziona?

**A:** **Test checklist:**

**1. Health Check:**
```bash
curl -I http://yourdomain.com
# Expected: HTTP 200 or 301 (redirect to HTTPS)
```

**2. Service Routing:**
```bash
# N8N
curl -u admin:password http://yourdomain.com/n8n/
# Expected: N8N HTML

# Qdrant
curl -H "api-key: $QDRANT_API_KEY" http://yourdomain.com/collections
# Expected: JSON collections list
```

**3. Authentication:**
```bash
# Without auth (should fail)
curl http://yourdomain.com/n8n/
# Expected: HTTP 401 Unauthorized

# Wrong password (should fail)
curl -u admin:wrongpass http://yourdomain.com/n8n/
# Expected: HTTP 401 Unauthorized
```

**4. HTTPS Redirect:**
```bash
curl -I http://yourdomain.com
# Expected: HTTP 301 → https://yourdomain.com
```

---

## 📊 Monitoring & Alerts

### Q: Come monitoro la salute dei container?

**A:** **3 livelli di monitoring:**

**Level 1: Docker Health Checks**
```bash
# Check status
docker ps --format 'table {{.Names}}\t{{.Status}}'

# Check unhealthy containers
docker ps --filter health=unhealthy
```

**Level 2: N8N Workflow (giornaliero)**
```yaml
# n8n workflow: daily-health-check
trigger: cron(0 6 * * *)
steps:
  1. Docker exec health checks
  2. HTTP endpoint tests
  3. Database connection tests
  4. Disk space check
  5. Certificate expiry check
  6. Send report to Slack
```

**Level 3: External Monitoring**
- **Uptime Robot:** HTTP endpoint monitoring (5 min interval)
- **Better Stack:** Log aggregation + alerting
- **Grafana + Prometheus:** Metrics visualization

---

### Q: Dove vedo i log di un container?

**A:** **Log commands:**

```bash
# Last 50 lines
docker logs <container-name> --tail 50

# Follow (live tail)
docker logs <container-name> --follow

# Since timestamp
docker logs <container-name> --since 2024-02-07T00:00:00

# Save to file
docker logs <container-name> > /tmp/container.log
```

**Log aggregation:**
```bash
# All containers
docker compose -f docker-compose.prod.yml logs --tail 100

# Specific service
docker compose -f docker-compose.prod.yml logs n8n --tail 50
```

---

## 🤖 Automation Agents

### Q: Come funziona l'Agent Password Manager?

**A:** **Agent Password Manager** - Gestione automatica password e rotazione

**Capabilities:**
1. **Generazione password sicure**
   - OpenSSL random (32 chars)
   - Complexity requirements enforced
   - Collision detection

2. **Storage sicuro**
   - Azure Key Vault integration
   - Encrypted at rest
   - Access audit trail

3. **Rotazione automatica**
   - Schedule: ogni 90 giorni (default)
   - Zero-downtime rotation
   - Rollback automatico se fail

4. **Deployment automatico**
   - SSH to server
   - Update `.env.prod`
   - Graceful container restart
   - Health check verification

**N8N Workflow:**
```
Trigger (cron: 0 0 1 */3 *)
  ↓
Generate New Passwords (OpenSSL)
  ↓
Store in Azure Key Vault
  ↓
Backup Current .env.prod
  ↓
SSH: Update .env.prod on server
  ↓
Docker Compose Restart (graceful)
  ↓
Verify Services Healthy
  ↓
Send Notification (Slack/Email)
```

**Manual Trigger:**
```bash
# Triggera rotazione via API
curl -X POST https://n8n.yourdomain.com/webhook/rotate-passwords \
  -H "Authorization: Bearer $N8N_API_KEY"
```

---

### Q: Come funziona l'Agent Vulnerability Scanner?

**A:** **Agent Vulnerability Scanner** - Daily security audit automation

**Capabilities:**
1. **CVE Detection**
   - Docker image vulnerability scan
   - NPM audit for Node.js dependencies
   - Python safety check
   - Database: NVD, Snyk, GitHub Advisory

2. **EOL Monitoring**
   - Check software End-of-Life dates
   - API: [endoflife.date](https://endoflife.date)
   - Alert 30 days before EOL
   - Services monitored:
     - Docker images
     - PostgreSQL
     - N8N
     - GitLab
     - Nginx/Caddy
     - Node.js versions
     - Python versions

3. **Certificate Expiry**
   - SSL/TLS certificate monitoring
   - Alert 14 days before expiry
   - Auto-renewal trigger

4. **Dependency Audit**
   - `npm audit` for all package.json
   - `pip-audit` for requirements.txt
   - Severity classification
   - Auto-PR for CRITICAL fixes

**N8N Workflow:**
```
Trigger (cron: 0 6 * * * - daily 6 AM)
  ↓
[Parallel Execution]
  ├─> Docker Image CVE Scan
  ├─> EOL Date Check (endoflife.date API)
  ├─> NPM Audit
  ├─> Python Safety Check
  └─> Certificate Expiry Check
  ↓
Aggregate Results
  ↓
Severity Classification
  ├─> CRITICAL → Slack + Email + PagerDuty
  ├─> HIGH → Slack + Email
  ├─> MEDIUM → Daily report
  └─> LOW → Weekly summary
  ↓
Generate Security Dashboard
  ↓
Update Wiki (security-status.md)
```

**Example Output (Slack):**
```
🛡️ Daily Security Scan - 2026-02-07

✅ No CRITICAL vulnerabilities
⚠️ 2 HIGH severity findings:
  • postgres:15.10-alpine - CVE-2024-XXXX (patch available: 15.11)
  • n8n npm dependency @types/node - outdated

📊 EOL Warnings:
  • GitLab CE 17.8.1 reaches EOL in 45 days
  • Node.js 18.x reaches EOL in 120 days

🔐 Certificates:
  • *.yourdomain.com - 87 days until expiry

📈 Full Report: https://wiki/security-status.md
```

---

### Q: Come configuro gli agent automatici?

**A:** **Setup guidato:**

**Step 1: Crea agent manifest**
```yaml
# .agent/workflows/agent_password_manager/manifest.json
{
  "name": "agent_password_manager",
  "type": "automation",
  "version": "1.0.0",
  "schedule": "0 0 1 */3 *",
  "permissions": [
    "azure.keyvault.write",
    "ssh.server.access",
    "docker.compose.restart"
  ],
  "notifications": {
    "success": ["slack", "email"],
    "failure": ["slack", "email", "pagerduty"]
  }
}
```

**Step 2: Implementa N8N workflow**
- Import workflow JSON da `.agent/workflows/`
- Configure credentials
- Test in staging

**Step 3: Enable automation**
```bash
# Enable agent
./scripts/pwsh/enable-agent.ps1 -AgentName password_manager

# Verify
./scripts/pwsh/list-agents.ps1 --status active
```

**Step 4: Monitor**
```bash
# Check logs
docker logs easyway-orchestrator | grep password_manager

# Dashboard
https://n8n.yourdomain.com/workflow/<workflow-id>
```

---

## 🎯 Best Practices Summary

### ✅ DO

- ✅ Pin Docker image versions
- ✅ Generate strong passwords (openssl)
- ✅ Store secrets in Azure Key Vault
- ✅ Rotate passwords every 90 days
- ✅ Test in staging before production
- ✅ Document every deployment
- ✅ Backup before making changes
- ✅ Use fail-fast configuration
- ✅ Monitor container health
- ✅ Audit security weekly

### ❌ DON'T

- ❌ Use `:latest` tags in production
- ❌ Commit `.env.prod` to git
- ❌ Use hardcoded passwords in code
- ❌ Skip staging environment
- ❌ Deploy on Fridays 😅
- ❌ Make changes without backup
- ❌ Ignore security alerts
- ❌ Share production passwords via email/Slack
- ❌ Deploy without testing
- ❌ Forget to update documentation

---

## 📚 Related Documentation

- [Production Deployment Log 2026-02-07](./deployment/production-deployment-2026-02-07.md)
- [PRODUCTION_DEPLOYMENT.md](../docs/PRODUCTION_DEPLOYMENT.md)
- [DOCKER_VERSIONS.md](../docs/DOCKER_VERSIONS.md)
- [N8N_CREDENTIALS_MIGRATION.md](../docs/N8N_CREDENTIALS_MIGRATION.md)
- [Security Threat Analysis](./security/threat-analysis-hardening.md)

---

**Maintained by:** EasyWay DevOps Team
**Last Review:** 2026-02-07
**Next Review:** 2026-03-07
